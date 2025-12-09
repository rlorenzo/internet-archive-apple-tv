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

    /// The item identifier for logging
    private var itemIdentifier: String?

    /// Flag to defer control setup if viewDidLoad runs before init completes
    private var needsControlSetup = false

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

    /// Create a video player with subtitle support
    /// - Parameters:
    ///   - player: The AVPlayer instance
    ///   - subtitleTracks: Available subtitle tracks
    ///   - identifier: Item identifier for logging
    init(player: AVPlayer, subtitleTracks: [SubtitleTrack], identifier: String?) {
        // Store tracks before super.init since AVPlayerViewController may trigger viewDidLoad during init
        self._subtitleTracks = subtitleTracks
        self.itemIdentifier = identifier
        self.needsControlSetup = true
        super.init(nibName: nil, bundle: nil)
        self.player = player

        // If viewDidLoad already ran (during super.init), setup controls now
        if isViewLoaded && needsControlSetup {
            setupCustomControls()
            loadPreferredSubtitles()
            needsControlSetup = false
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubtitleOverlay()

        // Only setup controls if init has completed (tracks are set)
        if !subtitleTracks.isEmpty || !needsControlSetup {
            setupCustomControls()
            loadPreferredSubtitles()
            needsControlSetup = false
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure subtitle overlay matches content view
        subtitleOverlay.frame = contentOverlayView?.bounds ?? view.bounds
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

    // MARK: - Subtitle Management

    /// Select a subtitle track and load its cues
    /// - Parameter track: The track to select, or nil to disable subtitles
    func selectSubtitleTrack(_ track: SubtitleTrack?) {
        selectedSubtitleTrack = track

        if let track = track {
            loadSubtitleCues(for: track)
            SubtitleManager.shared.saveTrackSelection(track)
            updateSubtitleButtonAppearance()

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
