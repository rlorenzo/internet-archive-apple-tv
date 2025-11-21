//
//  EmptyStateView.swift
//  Internet Archive
//
//  Created by Sprint 9: UI Modernization
//  Copyright © 2025 Internet Archive. All rights reserved.
//

import UIKit

/// Empty state view for when there's no content to display
@MainActor
final class EmptyStateView: UIView {

    // MARK: - Properties

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabel
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 36, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Initialization

    init(
        image: UIImage?,
        title: String,
        message: String? = nil
    ) {
        super.init(frame: .zero)
        setupViews()
        configure(image: image, title: title, message: message)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        addSubview(stackView)

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(messageLabel)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 60),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -60),

            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    // MARK: - Configuration

    func configure(image: UIImage?, title: String, message: String?) {
        imageView.image = image
        titleLabel.text = title
        messageLabel.text = message
        messageLabel.isHidden = message == nil
    }
}

// MARK: - Presets

extension EmptyStateView {

    /// Empty state for no search results
    static func noSearchResults() -> EmptyStateView {
        EmptyStateView(
            image: UIImage(systemName: "magnifyingglass"),
            title: "No Results Found",
            message: "Try adjusting your search terms"
        )
    }

    /// Empty state for no favorites
    static func noFavorites() -> EmptyStateView {
        EmptyStateView(
            image: UIImage(systemName: "heart"),
            title: "No Favorites Yet",
            message: "Add items to your favorites to see them here"
        )
    }

    /// Empty state for no items in collection
    static func noItems() -> EmptyStateView {
        EmptyStateView(
            image: UIImage(systemName: "tray"),
            title: "No Items",
            message: "This collection is empty"
        )
    }

    /// Empty state for network error
    static func networkError() -> EmptyStateView {
        EmptyStateView(
            image: UIImage(systemName: "wifi.exclamationmark"),
            title: "Connection Error",
            message: "Please check your internet connection and try again"
        )
    }

    /// Empty state for generic error
    static func error(message: String? = nil) -> EmptyStateView {
        EmptyStateView(
            image: UIImage(systemName: "exclamationmark.triangle"),
            title: "Something Went Wrong",
            message: message ?? "An error occurred while loading content"
        )
    }
}

// MARK: - UIViewController Extension

extension UIViewController {

    /// Show empty state view
    /// - Parameter emptyStateView: The empty state view to show
    func showEmptyState(_ emptyStateView: EmptyStateView) {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// Hide empty state view
    func hideEmptyState() {
        view.subviews
            .compactMap { $0 as? EmptyStateView }
            .forEach { $0.removeFromSuperview() }
    }
}
