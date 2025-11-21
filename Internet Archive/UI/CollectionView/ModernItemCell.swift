//
//  ModernItemCell.swift
//  Internet Archive
//
//
//  Copyright © 2025 Internet Archive. All rights reserved.
//

import UIKit
import AlamofireImage

/// Modern collection view cell with liquid glass effects and enhanced focus
@MainActor
final class ModernItemCell: UICollectionViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "ModernItemCell"

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
        label.font = .systemFont(ofSize: 28, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let glassEffectView: UIVisualEffectView = {
        let view: UIVisualEffectView
        if #available(tvOS 26.0, *) {
            // Liquid Glass for tvOS 26+
            view = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        } else {
            // Standard blur for tvOS 17-25
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
        contentView.addSubview(titleLabel)

        // Configure corner radius
        contentView.layer.cornerRadius = 12
        layer.cornerRadius = 12
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Image view
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.75),

            // Glass effect view (same frame as image)
            glassEffectView.topAnchor.constraint(equalTo: imageView.topAnchor),
            glassEffectView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            glassEffectView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            glassEffectView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),

            // Title label
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    // MARK: - Configuration

    func configure(with viewModel: ItemViewModel) {
        let item = viewModel.item

        // Set title
        titleLabel.text = item.title
        accessibilityLabel = item.title

        // Load image
        if let imageURL = item.imageURL {
            imageView.af.setImage(
                withURL: imageURL,
                placeholderImage: UIImage(systemName: "film"),
                filter: nil,
                imageTransition: .crossDissolve(0.3)
            )
        } else {
            imageView.image = UIImage(systemName: "film")
        }
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.af_cancelImageRequest()
        imageView.image = nil
        titleLabel.text = nil
        accessibilityLabel = nil
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

        // Glass effect (subtle overlay)
        if #available(tvOS 26.0, *) {
            // Enhanced liquid glass on focus
            glassEffectView.alpha = 0.2
        } else {
            // Standard blur effect
            glassEffectView.alpha = 0.1
        }

        // Label emphasis
        titleLabel.textColor = .white
    }

    private func applyUnfocusedAppearance() {
        // Reset transform
        transform = .identity

        // Remove shadow
        shadowLayer.shadowOpacity = 0

        // Remove glass effect
        glassEffectView.alpha = 0

        // Reset label
        titleLabel.textColor = .label
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        shadowLayer.frame = bounds
    }
}
