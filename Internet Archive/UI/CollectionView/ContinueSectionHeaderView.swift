//
//  ContinueSectionHeaderView.swift
//  Internet Archive
//
//  Section header view for Continue Watching/Listening sections
//

import UIKit

/// Reusable section header view for Continue Watching/Listening sections
@MainActor
final class ContinueSectionHeaderView: UICollectionReusableView {

    // MARK: - Properties

    static let reuseIdentifier = "ContinueSectionHeaderView"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 38, weight: .bold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Setup

    private func setupViews() {
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -60),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // Accessibility: Mark as header
        isAccessibilityElement = true
        accessibilityTraits = .header
    }

    // MARK: - Configuration

    func configure(with title: String) {
        titleLabel.text = title
        accessibilityLabel = "\(title) section"
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }
}
