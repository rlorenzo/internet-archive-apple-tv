//
//  NowPlayingControlsView.swift
//  Internet Archive
//
//  Transport controls for the Now Playing screen (shuffle, previous, play/pause, next, repeat)
//

import UIKit

/// Protocol for Now Playing control actions
@MainActor
protocol NowPlayingControlsDelegate: AnyObject {
    func controlsDidTapPlayPause()
    func controlsDidTapNext()
    func controlsDidTapPrevious()
    func controlsDidTapShuffle()
    func controlsDidTapRepeat()
}

/// Transport controls for the Now Playing screen
@MainActor
final class NowPlayingControlsView: UIView {

    // MARK: - Properties

    weak var delegate: NowPlayingControlsDelegate?

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 50
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var shuffleButton: UIButton = createControlButton(
        systemName: "shuffle",
        action: #selector(shuffleTapped),
        size: 36
    )

    private lazy var previousButton: UIButton = createControlButton(
        systemName: "backward.fill",
        action: #selector(previousTapped),
        size: 44
    )

    private lazy var playPauseButton: UIButton = createControlButton(
        systemName: "play.fill",
        action: #selector(playPauseTapped),
        size: 72
    )

    private lazy var nextButton: UIButton = createControlButton(
        systemName: "forward.fill",
        action: #selector(nextTapped),
        size: 44
    )

    private lazy var repeatButton: UIButton = createControlButton(
        systemName: "repeat",
        action: #selector(repeatTapped),
        size: 36
    )

    /// Current playback state
    private(set) var isPlaying: Bool = false

    /// Current shuffle state
    private(set) var isShuffled: Bool = false

    /// Current repeat mode
    private(set) var repeatMode: AudioQueueManager.RepeatMode = .off

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupAccessibility()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupAccessibility()
    }

    private func setupViews() {
        addSubview(stackView)

        stackView.addArrangedSubview(shuffleButton)
        stackView.addArrangedSubview(previousButton)
        stackView.addArrangedSubview(playPauseButton)
        stackView.addArrangedSubview(nextButton)
        stackView.addArrangedSubview(repeatButton)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }

    private func setupAccessibility() {
        playPauseButton.accessibilityLabel = "Play"
        playPauseButton.accessibilityHint = "Double-tap to play or pause"

        previousButton.accessibilityLabel = "Previous track"
        previousButton.accessibilityHint = "Double-tap to go to the previous track"

        nextButton.accessibilityLabel = "Next track"
        nextButton.accessibilityHint = "Double-tap to go to the next track"

        shuffleButton.accessibilityLabel = "Shuffle"
        shuffleButton.accessibilityValue = "Off"
        shuffleButton.accessibilityHint = "Double-tap to toggle shuffle mode"

        repeatButton.accessibilityLabel = "Repeat"
        repeatButton.accessibilityValue = "Off"
        repeatButton.accessibilityHint = "Double-tap to cycle through repeat modes"
    }

    private func createControlButton(
        systemName: String,
        action: Selector,
        size: CGFloat
    ) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: .medium)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: action, for: .primaryActionTriggered)
        return button
    }

    // MARK: - State Updates

    /// Update the play/pause button state
    /// - Parameter playing: Whether audio is currently playing
    func setPlaying(_ playing: Bool) {
        isPlaying = playing
        let iconName = playing ? "pause.fill" : "play.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 72, weight: .medium)
        playPauseButton.setImage(UIImage(systemName: iconName, withConfiguration: config), for: .normal)
        playPauseButton.accessibilityLabel = playing ? "Pause" : "Play"
    }

    /// Update the shuffle button state
    /// - Parameter shuffled: Whether shuffle mode is enabled
    func setShuffled(_ shuffled: Bool) {
        isShuffled = shuffled
        shuffleButton.tintColor = shuffled ? .systemBlue : .white
        shuffleButton.accessibilityValue = shuffled ? "On" : "Off"
    }

    /// Update the repeat button state
    /// - Parameter mode: The current repeat mode
    func setRepeatMode(_ mode: AudioQueueManager.RepeatMode) {
        repeatMode = mode
        let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .medium)
        repeatButton.setImage(UIImage(systemName: mode.iconName, withConfiguration: config), for: .normal)
        repeatButton.tintColor = mode.isActive ? .systemBlue : .white
        repeatButton.accessibilityValue = mode.accessibilityLabel
    }

    /// Update the next button enabled state
    /// - Parameter hasNext: Whether there is a next track
    func setHasNext(_ hasNext: Bool) {
        nextButton.isEnabled = hasNext
        nextButton.alpha = hasNext ? 1.0 : 0.4
    }

    /// Update the previous button enabled state
    /// - Parameter hasPrevious: Whether there is a previous track
    func setHasPrevious(_ hasPrevious: Bool) {
        previousButton.isEnabled = hasPrevious
        previousButton.alpha = hasPrevious ? 1.0 : 0.4
    }

    // MARK: - Focus

    /// Returns all focusable buttons for focus guide setup
    var focusableButtons: [UIButton] {
        [shuffleButton, previousButton, playPauseButton, nextButton, repeatButton]
    }

    /// The default focused button (play/pause)
    var defaultFocusedButton: UIButton {
        playPauseButton
    }

    // MARK: - Actions

    @objc private func shuffleTapped() {
        delegate?.controlsDidTapShuffle()
    }

    @objc private func previousTapped() {
        delegate?.controlsDidTapPrevious()
    }

    @objc private func playPauseTapped() {
        delegate?.controlsDidTapPlayPause()
    }

    @objc private func nextTapped() {
        delegate?.controlsDidTapNext()
    }

    @objc private func repeatTapped() {
        delegate?.controlsDidTapRepeat()
    }
}
