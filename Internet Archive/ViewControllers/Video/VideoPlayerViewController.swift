//
//  VideoPlayerViewController.swift
//  Internet Archive
//
//  Custom video player with subtitle support
//

import UIKit
import AVKit

/// Video player with integrated subtitle support
@MainActor
final class VideoPlayerViewController: AVPlayerViewController {

    // MARK: - Properties

    // Note: Using backing storage pattern because AVPlayerViewController may call viewDidLoad
    // during super.init(), before we can set instance properties in our initializer.
    // This allows us to set _subtitleTracks before super.init() is called.

    /// Available subtitle tracks for the current video (backing storage)
    private var _subtitleTracks: [SubtitleTrack] = []

    /// Available subtitle tracks for the current video
    private(set) var subtitleTracks: [SubtitleTrack] {
        get { _subtitleTracks }
        set { _subtitleTracks = newValue }
    }

    /// Currently selected subtitle track
    private(set) var selectedSubtitleTrack: SubtitleTrack?

    /// Current subtitle cues
    private var subtitleCues: [SubtitleCue] = []

    /// The item identifier for logging and progress tracking
    private var itemIdentifier: String?

    /// The video filename for progress tracking
    private var videoFilename: String?

    /// The video title for progress display
    private var videoTitle: String?

    /// The thumbnail URL for Continue Watching display
    private var thumbnailURL: String?

    /// Timer for periodic progress saving
    private var progressSaveTimer: Timer?

    /// Whether we should resume from a saved position
    private var resumeFromTime: Double?

    /// Flag to defer control setup if viewDidLoad runs before init completes
    private var needsControlSetup = false

    /// Flag to track if KVO observer was added (to avoid removing a non-existent observer)
    private var isObservingPlayer = false

    /// Reference to player for cleanup in deinit (nonisolated access)
    nonisolated(unsafe) private var playerForCleanup: AVPlayer?

    /// Subtitle overlay view
    private lazy var subtitleOverlay: SubtitleOverlayView = {
        let overlay = SubtitleOverlayView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        return overlay
    }()

    /// Subtitle button for the transport bar
    private lazy var subtitleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "captions.bubble"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(showSubtitleMenu), for: .primaryActionTriggered)
        button.accessibilityLabel = "Subtitles"
        button.accessibilityHint = "Double-tap to change subtitle settings"
        return button
    }()

    // MARK: - Initialization

    /// Create a video player with subtitle support and progress tracking
    /// - Parameters:
    ///   - player: The AVPlayer instance
    ///   - subtitleTracks: Available subtitle tracks
    ///   - identifier: Item identifier for logging and progress tracking
    ///   - filename: Video filename for progress tracking
    ///   - title: Video title for Continue Watching display
    ///   - thumbnailURL: Thumbnail URL for Continue Watching display
    ///   - resumeFromTime: Optional time to resume from (in seconds)
    init(
        player: AVPlayer,
        subtitleTracks: [SubtitleTrack],
        identifier: String?,
        filename: String? = nil,
        title: String? = nil,
        thumbnailURL: String? = nil,
        resumeFromTime: Double? = nil
    ) {
        // Store tracks before super.init since AVPlayerViewController may trigger viewDidLoad during init
        self._subtitleTracks = subtitleTracks
        self.itemIdentifier = identifier
        self.videoFilename = filename
        self.videoTitle = title
        self.thumbnailURL = thumbnailURL
        self.resumeFromTime = resumeFromTime
        self.needsControlSetup = true
        super.init(nibName: nil, bundle: nil)
        self.player = player
        self.playerForCleanup = player

        // If viewDidLoad already ran (during super.init), we need to complete setup now
        // that player is available
        if isViewLoaded {
            // Setup observer now that player is available
            if !isObservingPlayer {
                observePlayerItem()
                disableNativeSubtitles()
            }
            if needsControlSetup {
                setupCustomControls()
                loadPreferredSubtitles()
                needsControlSetup = false
            }
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubtitleOverlay()

        // Set ourselves as delegate to receive transport bar visibility notifications
        delegate = self

        // Only setup controls if init has completed (tracks are set)
        if !subtitleTracks.isEmpty || !needsControlSetup {
            setupCustomControls()
            loadPreferredSubtitles()
            needsControlSetup = false
        }

        // Start progress tracking
        startProgressTracking()

        // Handle resume if needed
        if let resumeTime = resumeFromTime, resumeTime > 0 {
            seekToResumePosition(resumeTime)
        }

        // Observe app backgrounding to save progress
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Save progress when leaving the player
        saveCurrentProgress()
        stopProgressTracking()
    }

    // MARK: - Setup

    private func setupSubtitleOverlay() {
        // Add to content overlay view (on top of video but below controls)
        if let contentOverlay = contentOverlayView {
            contentOverlay.addSubview(subtitleOverlay)
            NSLayoutConstraint.activate([
                subtitleOverlay.topAnchor.constraint(equalTo: contentOverlay.topAnchor),
                subtitleOverlay.bottomAnchor.constraint(equalTo: contentOverlay.bottomAnchor),
                subtitleOverlay.leadingAnchor.constraint(equalTo: contentOverlay.leadingAnchor),
                subtitleOverlay.trailingAnchor.constraint(equalTo: contentOverlay.trailingAnchor)
            ])
        }

        // Disable AVPlayer's native subtitle/caption rendering
        // We use our own custom overlay instead
        disableNativeSubtitles()
        observePlayerItem()
    }

    deinit {
        if isObservingPlayer {
            // Use nonisolated(unsafe) playerForCleanup since deinit cannot access @MainActor isolated player
            playerForCleanup?.removeObserver(self, forKeyPath: "currentItem")
        }
        // Note: progressSaveTimer is invalidated in viewWillDisappear/stopProgressTracking
        // Cannot access Timer from deinit due to Swift 6 Sendable requirements
        NotificationCenter.default.removeObserver(self)
    }

    /// Disable AVPlayer's automatic subtitle selection to prevent duplicate captions
    private func disableNativeSubtitles() {
        guard let player = player else { return }

        // Observe when the player item becomes ready, then disable native subtitles
        Task {
            // Wait for the current item to be available
            guard let playerItem = player.currentItem else { return }

            do {
                let asset = playerItem.asset

                // Wait for the asset to load its media selection options
                let characteristics = try await asset.load(.availableMediaCharacteristicsWithMediaSelectionOptions)

                // Disable legible (subtitle/caption) tracks
                if characteristics.contains(.legible),
                   let legibleGroup = try await asset.loadMediaSelectionGroup(for: .legible) {
                    // Select no option (disable subtitles)
                    await MainActor.run {
                        playerItem.select(nil, in: legibleGroup)
                    }
                }
            } catch {
                // Asset may not have media selection options - that's fine, ignore silently
            }
        }
    }

    /// Observe player item changes to disable native subtitles on new items
    private func observePlayerItem() {
        // Use KVO to observe currentItem changes
        // Only add observer if player is set (may be nil if viewDidLoad runs during super.init)
        guard player != nil else { return }
        player?.addObserver(self, forKeyPath: "currentItem", options: [.new], context: nil)
        isObservingPlayer = true
    }

    // swiftlint:disable:next block_based_kvo
    override nonisolated func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "currentItem" {
            Task { @MainActor in
                self.disableNativeSubtitles()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    private func setupCustomControls() {
        // Only add subtitle controls if we have subtitle tracks
        guard !subtitleTracks.isEmpty else { return }

        // Add subtitle menu to the transport bar (swipe up to reveal, then navigate right)
        setupTransportBarSubtitleMenu()
        updateSubtitleButtonAppearance()
    }

    private func setupTransportBarSubtitleMenu() {
        // Build menu actions for each subtitle track
        var menuActions: [UIAction] = []

        // Add "Off" option
        let offAction = UIAction(
            title: "Off",
            image: UIImage(systemName: "captions.bubble.slash"),
            state: selectedSubtitleTrack == nil ? .on : .off
        ) { [weak self] _ in
            self?.selectSubtitleTrack(nil)
            self?.setupTransportBarSubtitleMenu() // Refresh menu state
        }
        menuActions.append(offAction)

        // Add each subtitle track - include format if there are duplicates
        let displayNames = subtitleTracks.map { $0.languageDisplayName }
        let hasDuplicateNames = Set(displayNames).count < displayNames.count

        for track in subtitleTracks {
            // Add format suffix if there are tracks with the same display name
            let title = hasDuplicateNames
                ? "\(track.languageDisplayName) (\(track.format.rawValue.uppercased()))"
                : track.languageDisplayName

            let action = UIAction(
                title: title,
                image: UIImage(systemName: "captions.bubble"),
                state: selectedSubtitleTrack?.identifier == track.identifier ? .on : .off
            ) { [weak self] _ in
                self?.selectSubtitleTrack(track)
                self?.setupTransportBarSubtitleMenu() // Refresh menu state
            }
            menuActions.append(action)
        }

        // Create the menu
        let subtitleMenu = UIMenu(
            title: "Subtitles",
            image: UIImage(systemName: "captions.bubble"),
            children: menuActions
        )

        // Add to transport bar custom menu items
        transportBarCustomMenuItems = [subtitleMenu]
    }

    private func loadPreferredSubtitles() {
        guard !subtitleTracks.isEmpty else { return }

        // Check if subtitles should be enabled based on user preference
        if let preferredTrack = SubtitleManager.shared.preferredTrack(from: subtitleTracks) {
            selectSubtitleTrack(preferredTrack)
        }
    }

    // MARK: - Progress Tracking

    /// Start periodic progress saving
    private func startProgressTracking() {
        // Only track if we have the required info
        guard itemIdentifier != nil, videoFilename != nil else { return }

        // Save progress every 10 seconds
        progressSaveTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.saveCurrentProgress()
            }
        }
    }

    /// Stop progress tracking
    private func stopProgressTracking() {
        progressSaveTimer?.invalidate()
        progressSaveTimer = nil
    }

    /// Save current playback progress
    private func saveCurrentProgress() {
        guard let identifier = itemIdentifier,
              let filename = videoFilename,
              let player = player,
              let currentItem = player.currentItem else {
            return
        }

        let currentTime = player.currentTime().seconds

        // Don't save if at the very beginning (less than 10 seconds)
        guard currentTime >= 10 else { return }

        // Get duration and save progress on MainActor
        Task { [weak self] in
            guard let self else { return }
            do {
                let duration = try await currentItem.asset.load(.duration)
                let durationSeconds = duration.seconds

                // Don't save if duration is invalid
                guard durationSeconds > 0, !durationSeconds.isNaN, !durationSeconds.isInfinite else { return }

                let progress = PlaybackProgress.video(MediaProgressInfo(
                    identifier: identifier,
                    filename: filename,
                    currentTime: currentTime,
                    duration: durationSeconds,
                    title: videoTitle,
                    imageURL: thumbnailURL
                ))

                await MainActor.run {
                    PlaybackProgressManager.shared.saveProgress(progress)
                }
            } catch {
                // Duration not available yet, skip saving
            }
        }
    }

    /// Seek to the resume position
    private func seekToResumePosition(_ time: Double) {
        guard let player = player else { return }

        let targetTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    /// Called when app is going to background
    @objc private func appWillResignActive() {
        saveCurrentProgress()
    }

    // MARK: - Subtitle Management

    /// Select a subtitle track and load its cues
    /// - Parameter track: The track to select, or nil to disable subtitles
    func selectSubtitleTrack(_ track: SubtitleTrack?) {
        selectedSubtitleTrack = track

        if let track = track {
            loadSubtitleCues(for: track)
            SubtitleManager.shared.saveTrackSelection(track)
            updateSubtitleButtonAppearance()
            setupTransportBarSubtitleMenu()  // Refresh menu to show correct selection

            ErrorLogger.shared.logSuccess(
                operation: .unknown,
                info: [
                    "action": "subtitle_selected",
                    "language": track.languageDisplayName,
                    "identifier": itemIdentifier ?? "unknown"
                ]
            )
        } else {
            subtitleOverlay.stop()
            subtitleCues = []
            SubtitleManager.shared.clearTrackSelection()
            updateSubtitleButtonAppearance()
            setupTransportBarSubtitleMenu()  // Refresh menu to show "Off" selected
            // Also ensure native subtitles are disabled
            disableNativeSubtitles()

            ErrorLogger.shared.logSuccess(
                operation: .unknown,
                info: [
                    "action": "subtitles_disabled",
                    "identifier": itemIdentifier ?? "unknown"
                ]
            )
        }
    }

    /// Load and parse subtitle cues for a track
    private func loadSubtitleCues(for track: SubtitleTrack) {
        Task {
            do {
                // Convert SRT to VTT if necessary
                let vttURL: URL
                if track.format.isNativelySupported {
                    vttURL = track.url
                } else {
                    vttURL = try await SRTtoVTTConverter.shared.convertSRTtoVTT(
                        from: track.url,
                        filename: track.filename
                    )
                }

                // Parse the VTT file
                let cues = try await SubtitleParser.shared.parse(from: vttURL)
                subtitleCues = cues

                // Configure overlay
                if let player = player {
                    subtitleOverlay.configure(with: cues, player: player)
                }

            } catch {
                ErrorLogger.shared.log(
                    error: error,
                    context: ErrorContext(
                        operation: .unknown,
                        userFacingTitle: "Subtitle Error",
                        additionalInfo: [
                            "action": "subtitle_load_failed",
                            "track": track.filename,
                            "identifier": itemIdentifier ?? "unknown"
                        ]
                    )
                )

                // Show error to user
                let alert = UIAlertController(
                    title: "Subtitle Error",
                    message: "Unable to load subtitles. \(error.localizedDescription)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }

    private func updateSubtitleButtonAppearance() {
        let hasSubtitles = selectedSubtitleTrack != nil
        subtitleButton.tintColor = hasSubtitles ? .systemBlue : .white
        subtitleButton.accessibilityValue = hasSubtitles
            ? "On - \(selectedSubtitleTrack?.languageDisplayName ?? "")"
            : "Off"
    }

    // MARK: - Actions

    @objc private func showSubtitleMenu() {
        let selectionVC = SubtitleSelectionViewController(
            tracks: subtitleTracks,
            selectedTrack: selectedSubtitleTrack
        )
        selectionVC.delegate = self
        present(selectionVC, animated: true)
    }
}

// MARK: - SubtitleSelectionDelegate

extension VideoPlayerViewController: SubtitleSelectionDelegate {
    func subtitleSelection(_ controller: SubtitleSelectionViewController, didSelect track: SubtitleTrack) {
        selectSubtitleTrack(track)
    }

    func subtitleSelectionDidTurnOff(_ controller: SubtitleSelectionViewController) {
        selectSubtitleTrack(nil)
    }
}

// MARK: - AVPlayerViewControllerDelegate

extension VideoPlayerViewController: AVPlayerViewControllerDelegate {
    /// Called when the transport bar visibility is about to change
    /// Use this to adjust subtitle position so they don't overlap with the transport bar
    nonisolated func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willTransitionToVisibilityOfTransportBar visible: Bool,
        with coordinator: AVPlayerViewControllerAnimationCoordinator
    ) {
        // Animate subtitle position change in sync with transport bar animation
        coordinator.addCoordinatedAnimations({
            Task { @MainActor in
                self.subtitleOverlay.updateSubtitlePosition(controlsVisible: visible)
            }
        }, completion: nil)
    }
}
