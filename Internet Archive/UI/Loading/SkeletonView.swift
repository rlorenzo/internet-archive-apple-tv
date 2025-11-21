//
//  SkeletonView.swift
//  Internet Archive
//
//  Created by Sprint 9: UI Modernization
//  Copyright © 2025 Internet Archive. All rights reserved.
//

import UIKit

/// Skeleton view for loading states with shimmer effect
@MainActor
final class SkeletonView: UIView {

    // MARK: - Properties

    private let gradientLayer = CAGradientLayer()
    private var isAnimating = false

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .systemGray.withAlphaComponent(0.2)
        layer.cornerRadius = 12
        clipsToBounds = true

        // Setup gradient layer for shimmer
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)

        let baseColor = UIColor.systemGray.withAlphaComponent(0.3).cgColor
        let highlightColor = UIColor.systemGray.withAlphaComponent(0.5).cgColor

        gradientLayer.colors = [
            baseColor,
            highlightColor,
            baseColor
        ]

        gradientLayer.locations = [0, 0.5, 1]
        layer.addSublayer(gradientLayer)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    // MARK: - Animation

    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "shimmer")
    }

    func stopAnimating() {
        isAnimating = false
        gradientLayer.removeAnimation(forKey: "shimmer")
    }
}

// MARK: - Skeleton Grid Cell

/// Skeleton cell for collection view loading states
@MainActor
final class SkeletonItemCell: UICollectionViewCell {

    static let reuseIdentifier = "SkeletonItemCell"

    private let skeletonView = SkeletonView()
    private let titleSkeleton = SkeletonView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        skeletonView.translatesAutoresizingMaskIntoConstraints = false
        titleSkeleton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(skeletonView)
        contentView.addSubview(titleSkeleton)

        NSLayoutConstraint.activate([
            // Main skeleton (image)
            skeletonView.topAnchor.constraint(equalTo: contentView.topAnchor),
            skeletonView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            skeletonView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            skeletonView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.75),

            // Title skeleton
            titleSkeleton.topAnchor.constraint(equalTo: skeletonView.bottomAnchor, constant: 10),
            titleSkeleton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleSkeleton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            titleSkeleton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func startAnimating() {
        skeletonView.startAnimating()
        titleSkeleton.startAnimating()
    }

    func stopAnimating() {
        skeletonView.stopAnimating()
        titleSkeleton.stopAnimating()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopAnimating()
    }
}

// MARK: - Collection View Extensions

extension UICollectionView {

    /// Show skeleton loading state
    /// - Parameter itemCount: Number of skeleton items to show
    func showSkeletonLoading(itemCount: Int = 20) {
        // Register skeleton cell if not already registered
        register(
            SkeletonItemCell.self,
            forCellWithReuseIdentifier: SkeletonItemCell.reuseIdentifier
        )

        // Implementation note: View controllers should handle showing skeleton cells
        // by providing skeleton data in their data source
    }
}
