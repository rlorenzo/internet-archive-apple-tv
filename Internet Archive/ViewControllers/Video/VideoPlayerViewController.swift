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

    /// Available subtitle tracks for the current video
    private(set) var subtitleTracks: [SubtitleTrack] = []

    /// Currently selected subtitle track
    private(set) var selectedSubtitleTrack: SubtitleTrack?

    /// Current subtitle cues
    private var subtitleCues: [SubtitleCue] = []

    /// The item identifier for logging
    private var itemIdentifier: String?

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
        super.init(nibName: nil, bundle: nil)
        self.player = player
        self.subtitleTracks = subtitleTracks
        self.itemIdentifier = identifier
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubtitleOverlay()
        setupCustomControls()
        loadPreferredSubtitles()
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
        // Only add subtitle button if we have subtitle tracks
        guard !subtitleTracks.isEmpty else { return }

        // Add custom action for subtitle menu
        // Note: On tvOS, we use the menu button or a custom gesture
        let menuTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(showSubtitleMenu))
        menuTapRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        view.addGestureRecognizer(menuTapRecognizer)

        // We can also add info panel customization
        updateSubtitleButtonAppearance()
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
