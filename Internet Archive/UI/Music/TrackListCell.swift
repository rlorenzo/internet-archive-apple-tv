//
//  TrackListCell.swift
//  Internet Archive
//
//  Collection view cell for displaying a track in the Now Playing track list
//

import UIKit

/// Cell for displaying a track in the playlist with tvOS focus engine support
@MainActor
final class TrackListCell: UICollectionViewCell {

    // MARK: - Reuse Identifier

    static let reuseIdentifier = "TrackListCell"

    // MARK: - UI Components

    private let trackNumberLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 28, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let nowPlayingIndicator: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let view = UIImageView()
        view.image = UIImage(systemName: "speaker.wave.2.fill", withConfiguration: config)
        view.tintColor = .systemBlue
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .medium)
        label.textColor = .label
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 28, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var isNowPlaying: Bool = false

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
        contentView.addSubview(containerView)
        containerView.addSubview(trackNumberLabel)
        containerView.addSubview(nowPlayingIndicator)
        containerView.addSubview(titleLabel)
        containerView.addSubview(durationLabel)

        NSLayoutConstraint.activate([
            // Container fills cell
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            // Track number on the left
            trackNumberLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            trackNumberLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            trackNumberLabel.widthAnchor.constraint(equalToConstant: 50),

            // Now playing indicator overlays track number
            nowPlayingIndicator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            nowPlayingIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            nowPlayingIndicator.widthAnchor.constraint(equalToConstant: 36),
            nowPlayingIndicator.heightAnchor.constraint(equalToConstant: 28),

            // Title in the middle
            titleLabel.leadingAnchor.constraint(equalTo: trackNumberLabel.trailingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -20),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            // Duration on the right
            durationLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            durationLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 90)
        ])
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    // MARK: - Configuration

    /// Configure the cell with a track
    /// - Parameters:
    ///   - track: The audio track to display
    ///   - isPlaying: Whether this track is currently playing
    func configure(with track: AudioTrack, isPlaying: Bool) {
        self.isNowPlaying = isPlaying

        // Set track number
        if let number = track.trackNumber {
            trackNumberLabel.text = String(format: "%02d", number)
        } else {
            trackNumberLabel.text = ""
        }

        // Set title
        titleLabel.text = track.title

        // Set duration
        durationLabel.text = track.formattedDuration

        // Update now playing state
        updateNowPlayingState(isPlaying)

        // Accessibility
        accessibilityLabel = buildAccessibilityLabel(track: track, isPlaying: isPlaying)
        accessibilityHint = "Double-tap to play this track"
    }

    private func updateNowPlayingState(_ isPlaying: Bool) {
        trackNumberLabel.isHidden = isPlaying
        nowPlayingIndicator.isHidden = !isPlaying

        if isPlaying {
            titleLabel.textColor = .systemBlue
            titleLabel.font = .systemFont(ofSize: 32, weight: .semibold)
        } else {
            titleLabel.textColor = .label
            titleLabel.font = .systemFont(ofSize: 32, weight: .medium)
        }
    }

    private func buildAccessibilityLabel(track: AudioTrack, isPlaying: Bool) -> String {
        var components: [String] = []

        if isPlaying {
            components.append("Now playing")
        }

        if let number = track.trackNumber {
            components.append("Track \(number)")
        }

        components.append(track.title)
        components.append(track.formattedDuration)

        return components.joined(separator: ", ")
    }

    // MARK: - Focus

    override var canBecomeFocused: Bool {
        true
    }

    override func didUpdateFocus(
        in context: UIFocusUpdateContext,
        with coordinator: UIFocusAnimationCoordinator
    ) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.containerView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
                self.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
                self.layer.shadowColor = UIColor.black.cgColor
                self.layer.shadowOffset = CGSize(width: 0, height: 10)
                self.layer.shadowOpacity = 0.3
                self.layer.shadowRadius = 20
            } else {
                self.containerView.backgroundColor = .clear
                self.transform = .identity
                self.layer.shadowOpacity = 0
            }
        }, completion: nil)
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        trackNumberLabel.text = nil
        titleLabel.text = nil
        durationLabel.text = nil
        isNowPlaying = false
        nowPlayingIndicator.isHidden = true
        trackNumberLabel.isHidden = false
        titleLabel.textColor = .label
        titleLabel.font = .systemFont(ofSize: 32, weight: .medium)
        transform = .identity
        containerView.backgroundColor = .clear
        layer.shadowOpacity = 0
    }
}
