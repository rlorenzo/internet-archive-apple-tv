//
//  ContinueWatchingCell.swift
//  Internet Archive
//
//  Cell for displaying Continue Watching/Listening items with progress indicator
//

import UIKit
import AlamofireImage

/// Collection view cell for Continue Watching/Listening sections
@MainActor
final class ContinueWatchingCell: UICollectionViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "ContinueWatchingCell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray.withAlphaComponent(0.15)
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 26, weight: .medium)
        label.textColor = .label
        label.textAlignment = .left
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let timeRemainingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let progressBar: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.trackTintColor = UIColor.black.withAlphaComponent(0.5)
        progress.progressTintColor = .systemBlue
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.layer.cornerRadius = 2
        progress.clipsToBounds = true
        return progress
    }()

    private let playIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "play.circle.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.alpha = 0
        return imageView
    }()

    private let glassEffectView: UIVisualEffectView = {
        let view: UIVisualEffectView
        if #available(tvOS 26.0, *) {
            view = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        } else {
            view = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        }
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let shadowLayer: CALayer = {
        let layer = CALayer()
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.shadowRadius = 20
        return layer
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupAccessibility()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupConstraints()
        setupAccessibility()
    }

    // MARK: - Setup

    private func setupViews() {
        // Add shadow layer
        contentView.layer.insertSublayer(shadowLayer, at: 0)

        // Add subviews
        contentView.addSubview(imageView)
        contentView.addSubview(glassEffectView)
        contentView.addSubview(progressBar)
        contentView.addSubview(playIconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(timeRemainingLabel)

        // Configure corner radius
        contentView.layer.cornerRadius = 12
        layer.cornerRadius = 12
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Image view - takes up most of the cell height
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.65),

            // Glass effect view (same frame as image)
            glassEffectView.topAnchor.constraint(equalTo: imageView.topAnchor),
            glassEffectView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            glassEffectView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            glassEffectView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),

            // Progress bar - at bottom of image
            progressBar.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            progressBar.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 4),

            // Play icon - centered on image
            playIconView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            playIconView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            playIconView.widthAnchor.constraint(equalToConstant: 60),
            playIconView.heightAnchor.constraint(equalToConstant: 60),

            // Title label - below image
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            // Time remaining label - below title
            timeRemainingLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            timeRemainingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            timeRemainingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            timeRemainingLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    // MARK: - Configuration

    func configure(with progress: PlaybackProgress) {
        // Set title
        titleLabel.text = progress.title ?? "Untitled"
        accessibilityLabel = progress.title

        // Set time remaining
        timeRemainingLabel.text = progress.formattedTimeRemaining

        // Set progress
        progressBar.progress = Float(progress.progressPercentage)

        // Load image
        if let thumbnailURL = progress.thumbnailURL {
            imageView.af.setImage(
                withURL: thumbnailURL,
                placeholderImage: UIImage(systemName: progress.isVideo ? "film" : "music.note"),
                filter: nil,
                imageTransition: .crossDissolve(0.3)
            )
        } else {
            imageView.image = UIImage(systemName: progress.isVideo ? "film" : "music.note")
        }

        // Accessibility
        accessibilityValue = progress.formattedTimeRemaining
        accessibilityHint = "Double-tap to resume"
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.af.cancelImageRequest()
        imageView.image = nil
        titleLabel.text = nil
        timeRemainingLabel.text = nil
        progressBar.progress = 0
        accessibilityLabel = nil
        accessibilityValue = nil
    }

    // MARK: - Focus Engine

    override var canBecomeFocused: Bool {
        true
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.applyFocusedAppearance()
            } else {
                self.applyUnfocusedAppearance()
            }
        }, completion: nil)
    }

    private func applyFocusedAppearance() {
        // Scale up
        transform = CGAffineTransform(scaleX: 1.05, y: 1.05)

        // Shadow
        shadowLayer.shadowOpacity = 0.3
        shadowLayer.frame = bounds
        shadowLayer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: 12
        ).cgPath

        // Focus outline border
        layer.borderWidth = 4
        layer.borderColor = UIColor.white.cgColor

        // Glass effect
        if #available(tvOS 26.0, *) {
            glassEffectView.alpha = 0.2
        } else {
            glassEffectView.alpha = 0.1
        }

        // Show play icon
        playIconView.alpha = 1

        // Label emphasis
        titleLabel.textColor = .white
    }

    private func applyUnfocusedAppearance() {
        // Reset transform
        transform = .identity

        // Remove shadow
        shadowLayer.shadowOpacity = 0

        // Remove focus outline border
        layer.borderWidth = 0

        // Remove glass effect
        glassEffectView.alpha = 0

        // Hide play icon
        playIconView.alpha = 0

        // Reset label
        titleLabel.textColor = .label
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowLayer.frame = bounds
    }
}
