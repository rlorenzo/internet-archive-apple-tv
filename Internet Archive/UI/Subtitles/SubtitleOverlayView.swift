//
//  SubtitleOverlayView.swift
//  Internet Archive
//
//  Displays subtitle text over video playback
//

import UIKit
import AVFoundation

/// View that displays subtitle cues synchronized with video playback
@MainActor
final class SubtitleOverlayView: UIView {

    // MARK: - Properties

    /// The subtitle cues to display
    private var cues: [SubtitleCue] = []

    /// Current player time observer token
    private var timeObserverToken: Any?

    /// Weak reference to the player being observed
    private weak var player: AVPlayer?

    /// Currently displayed cue
    private var currentCue: SubtitleCue?

    /// Cleanup handler that can be called from nonisolated deinit
    /// Captures player and token at setup time for safe cleanup
    nonisolated(unsafe) private var cleanupHandler: (() -> Void)?

    // MARK: - UI Elements

    /// Container for subtitle text with background
    private lazy var textContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()

    /// Label displaying the subtitle text
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 42, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    deinit {
        // Call the cleanup handler which was set up with captured values
        cleanupHandler?()
    }

    // MARK: - Setup

    private func setupUI() {
        isUserInteractionEnabled = false

        addSubview(textContainer)
        textContainer.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            // Position container at bottom with margins
            textContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            textContainer.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -60),
            textContainer.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 100),
            textContainer.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -100),

            // Label inside container with padding
            subtitleLabel.topAnchor.constraint(equalTo: textContainer.topAnchor, constant: 12),
            subtitleLabel.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor, constant: -12),
            subtitleLabel.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor, constant: -20)
        ])

        setupAccessibility()
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .staticText
        accessibilityLabel = "Subtitles"
    }

    // MARK: - Public API

    /// Configure the overlay with subtitle cues and start observing the player
    /// - Parameters:
    ///   - cues: Array of subtitle cues to display
    ///   - player: The AVPlayer to observe for time updates
    func configure(with cues: [SubtitleCue], player: AVPlayer) {
        self.cues = cues
        self.player = player
        removeTimeObserver()
        addTimeObserver(to: player)
        isHidden = false
    }

    /// Update with new cues (e.g., when changing subtitle tracks)
    func updateCues(_ cues: [SubtitleCue]) {
        self.cues = cues
        currentCue = nil
        updateSubtitle(for: player?.currentTime().seconds ?? 0)
    }

    /// Stop displaying subtitles
    func stop() {
        removeTimeObserver()
        cues = []
        currentCue = nil
        hideSubtitle()
        isHidden = true
    }

    // MARK: - Time Observation

    private func addTimeObserver(to player: AVPlayer) {
        // Update subtitles every 0.1 seconds for smooth display
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        let token = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                self?.updateSubtitle(for: time.seconds)
            }
        }
        timeObserverToken = token

        // Set up cleanup handler with captured values for safe deinit access
        cleanupHandler = { [weak player] in
            if let player = player {
                player.removeTimeObserver(token)
            }
        }
    }

    private func removeTimeObserver() {
        if let token = timeObserverToken, let player = player {
            player.removeTimeObserver(token)
        }
        timeObserverToken = nil
        cleanupHandler = nil
    }

    // MARK: - Subtitle Display

    private func updateSubtitle(for time: Double) {
        // Find active cue at current time
        let activeCue = cues.first { $0.isActive(at: time) }

        // Only update if cue changed
        guard activeCue != currentCue else { return }

        currentCue = activeCue

        if let cue = activeCue {
            showSubtitle(cue.text)
        } else {
            hideSubtitle()
        }
    }

    private func showSubtitle(_ text: String) {
        subtitleLabel.text = text
        accessibilityValue = text

        UIView.animate(withDuration: 0.15) {
            self.textContainer.isHidden = false
            self.textContainer.alpha = 1
        }
    }

    private func hideSubtitle() {
        UIView.animate(withDuration: 0.15) {
            self.textContainer.alpha = 0
        } completion: { _ in
            self.textContainer.isHidden = true
            self.subtitleLabel.text = nil
            self.accessibilityValue = nil
        }
    }
}
