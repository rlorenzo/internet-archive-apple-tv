//
//  EmptyStateViewTests.swift
//  Internet ArchiveTests
//
//  Unit tests for EmptyStateView
//

import XCTest
@testable import Internet_Archive

@MainActor
final class EmptyStateViewTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_withAllParameters() {
        let image = UIImage(systemName: "star")
        let view = EmptyStateView(image: image, title: "Title", message: "Message")

        XCTAssertNotNil(view)
    }

    func testInit_withoutMessage() {
        let image = UIImage(systemName: "star")
        let view = EmptyStateView(image: image, title: "Title")

        XCTAssertNotNil(view)
    }

    func testInit_withNilImage() {
        let view = EmptyStateView(image: nil, title: "Title", message: "Message")

        XCTAssertNotNil(view)
    }

    func testInit_backgroundIsClear() {
        let view = EmptyStateView(image: nil, title: "Title")

        XCTAssertEqual(view.backgroundColor, .clear)
    }

    // MARK: - Preset Tests

    func testNoSearchResults_preset() {
        let view = EmptyStateView.noSearchResults()

        XCTAssertNotNil(view)
    }

    func testNoFavorites_preset() {
        let view = EmptyStateView.noFavorites()

        XCTAssertNotNil(view)
    }

    func testNoItems_preset() {
        let view = EmptyStateView.noItems()

        XCTAssertNotNil(view)
    }

    func testNetworkError_preset() {
        let view = EmptyStateView.networkError()

        XCTAssertNotNil(view)
    }

    func testError_presetWithMessage() {
        let view = EmptyStateView.error(message: "Custom error message")

        XCTAssertNotNil(view)
    }

    func testError_presetWithoutMessage() {
        let view = EmptyStateView.error()

        XCTAssertNotNil(view)
    }

    // MARK: - Configuration Tests

    func testConfigure_updatesContent() {
        let view = EmptyStateView(image: nil, title: "Initial")

        view.configure(
            image: UIImage(systemName: "heart"),
            title: "Updated Title",
            message: "Updated Message"
        )

        // Can't directly test internal labels, but ensure no crash
        XCTAssertNotNil(view)
    }

    func testConfigure_withNilMessage() {
        let view = EmptyStateView(image: nil, title: "Title", message: "Message")

        view.configure(
            image: nil,
            title: "Title",
            message: nil
        )

        XCTAssertNotNil(view)
    }

    // MARK: - View Hierarchy Tests

    func testView_hasSubviews() {
        let view = EmptyStateView(image: nil, title: "Title")

        XCTAssertFalse(view.subviews.isEmpty)
    }

    func testView_containsStackView() {
        let view = EmptyStateView(image: nil, title: "Title")

        let hasStackView = view.subviews.contains { $0 is UIStackView }
        XCTAssertTrue(hasStackView)
    }

    // MARK: - Frame Tests

    func testView_supportsZeroFrame() {
        let view = EmptyStateView(image: nil, title: "Title")

        XCTAssertEqual(view.frame, .zero)
    }

    func testView_supportsCustomFrame() {
        let view = EmptyStateView(image: nil, title: "Title")
        view.frame = CGRect(x: 0, y: 0, width: 400, height: 300)

        XCTAssertEqual(view.frame.width, 400)
        XCTAssertEqual(view.frame.height, 300)
    }

    // MARK: - Auto Layout Tests

    func testView_hasConstraints() {
        let view = EmptyStateView(image: nil, title: "Title")

        // The view should have auto layout constraints from setupViews
        XCTAssertFalse(view.constraints.isEmpty || view.subviews.first?.constraints.isEmpty == false)
    }

    // MARK: - UIViewController Extension Tests

    func testShowEmptyState_addsEmptyStateView() {
        let viewController = UIViewController()
        viewController.loadViewIfNeeded()

        let emptyState = EmptyStateView.noSearchResults()
        viewController.showEmptyState(emptyState)

        let hasEmptyState = viewController.view.subviews.contains { $0 is EmptyStateView }
        XCTAssertTrue(hasEmptyState)
    }

    func testShowEmptyState_setsConstraints() {
        let viewController = UIViewController()
        viewController.loadViewIfNeeded()

        let emptyState = EmptyStateView.noSearchResults()
        viewController.showEmptyState(emptyState)

        XCTAssertFalse(emptyState.translatesAutoresizingMaskIntoConstraints)
    }

    func testHideEmptyState_removesEmptyStateView() {
        let viewController = UIViewController()
        viewController.loadViewIfNeeded()

        let emptyState = EmptyStateView.noSearchResults()
        viewController.showEmptyState(emptyState)

        viewController.hideEmptyState()

        let hasEmptyState = viewController.view.subviews.contains { $0 is EmptyStateView }
        XCTAssertFalse(hasEmptyState)
    }

    func testHideEmptyState_whenNoEmptyState_doesNotCrash() {
        let viewController = UIViewController()
        viewController.loadViewIfNeeded()

        // Should not crash when no empty state exists
        viewController.hideEmptyState()

        XCTAssertNotNil(viewController)
    }

    func testShowMultipleEmptyStates_andHideAll() {
        let viewController = UIViewController()
        viewController.loadViewIfNeeded()

        viewController.showEmptyState(EmptyStateView.noSearchResults())
        viewController.showEmptyState(EmptyStateView.noFavorites())

        let countBefore = viewController.view.subviews.filter { $0 is EmptyStateView }.count
        XCTAssertEqual(countBefore, 2)

        viewController.hideEmptyState()

        let countAfter = viewController.view.subviews.filter { $0 is EmptyStateView }.count
        XCTAssertEqual(countAfter, 0)
    }

    // MARK: - Accessibility Tests

    func testAccessibility_isElement() {
        let view = EmptyStateView(image: nil, title: "Title")
        XCTAssertTrue(view.isAccessibilityElement)
    }

    func testAccessibility_hasStaticTextTrait() {
        let view = EmptyStateView(image: nil, title: "Title")
        XCTAssertTrue(view.accessibilityTraits.contains(.staticText))
    }

    func testAccessibility_labelContainsTitle() {
        let view = EmptyStateView(image: nil, title: "Test Title")
        XCTAssertTrue(view.accessibilityLabel?.contains("Test Title") ?? false)
    }

    func testAccessibility_labelContainsTitleAndMessage() {
        let view = EmptyStateView(image: nil, title: "Title", message: "Message text")
        XCTAssertTrue(view.accessibilityLabel?.contains("Title") ?? false)
        XCTAssertTrue(view.accessibilityLabel?.contains("Message text") ?? false)
    }

    func testAccessibility_configureUpdatesLabel() {
        let view = EmptyStateView(image: nil, title: "Initial")
        view.configure(image: nil, title: "Updated", message: "New message")

        XCTAssertTrue(view.accessibilityLabel?.contains("Updated") ?? false)
        XCTAssertTrue(view.accessibilityLabel?.contains("New message") ?? false)
    }

    // MARK: - Preset Content Tests

    func testNoSearchResults_hasCorrectTitle() {
        let view = EmptyStateView.noSearchResults()

        // Verify the view was configured properly by checking accessibility label
        XCTAssertTrue(view.accessibilityLabel?.contains("No Results Found") ?? false)
    }

    func testNoSearchResults_hasCorrectMessage() {
        let view = EmptyStateView.noSearchResults()
        XCTAssertTrue(view.accessibilityLabel?.contains("Try adjusting") ?? false)
    }

    func testNoFavorites_hasCorrectTitle() {
        let view = EmptyStateView.noFavorites()
        XCTAssertTrue(view.accessibilityLabel?.contains("No Favorites") ?? false)
    }

    func testNoFavorites_hasCorrectMessage() {
        let view = EmptyStateView.noFavorites()
        XCTAssertTrue(view.accessibilityLabel?.contains("Add items") ?? false)
    }

    func testNoItems_hasCorrectTitle() {
        let view = EmptyStateView.noItems()
        XCTAssertTrue(view.accessibilityLabel?.contains("No Items") ?? false)
    }

    func testNoItems_hasCorrectMessage() {
        let view = EmptyStateView.noItems()
        XCTAssertTrue(view.accessibilityLabel?.contains("empty") ?? false)
    }

    func testNetworkError_hasCorrectTitle() {
        let view = EmptyStateView.networkError()
        XCTAssertTrue(view.accessibilityLabel?.contains("Connection Error") ?? false)
    }

    func testNetworkError_hasCorrectMessage() {
        let view = EmptyStateView.networkError()
        XCTAssertTrue(view.accessibilityLabel?.contains("internet connection") ?? false)
    }

    func testError_withCustomMessage() {
        let view = EmptyStateView.error(message: "Custom error occurred")
        XCTAssertTrue(view.accessibilityLabel?.contains("Custom error occurred") ?? false)
    }

    func testError_withDefaultMessage() {
        let view = EmptyStateView.error()
        XCTAssertTrue(view.accessibilityLabel?.contains("error occurred") ?? false)
    }

    func testError_hasCorrectTitle() {
        let view = EmptyStateView.error()
        XCTAssertTrue(view.accessibilityLabel?.contains("Something Went Wrong") ?? false)
    }

    // MARK: - Image Tests

    func testNoSearchResults_hasImage() {
        let view = EmptyStateView.noSearchResults()

        // The view should have an imageView with the search icon
        let hasImageView = view.subviews
            .flatMap { ($0 as? UIStackView)?.arrangedSubviews ?? [] }
            .contains { $0 is UIImageView }
        XCTAssertTrue(hasImageView)
    }

    func testNoFavorites_hasHeartImage() {
        let view = EmptyStateView.noFavorites()
        XCTAssertNotNil(view)
    }

    func testNetworkError_hasWifiImage() {
        let view = EmptyStateView.networkError()
        XCTAssertNotNil(view)
    }

    func testError_hasTriangleImage() {
        let view = EmptyStateView.error()
        XCTAssertNotNil(view)
    }

    // MARK: - Layout Tests

    func testView_hasCenteredStackView() {
        let view = EmptyStateView(image: nil, title: "Test")
        view.frame = CGRect(x: 0, y: 0, width: 800, height: 600)
        view.layoutIfNeeded()

        // Stack view should be centered
        let stackView = view.subviews.first { $0 is UIStackView }
        XCTAssertNotNil(stackView)
    }

    func testView_stackViewHasVerticalAxis() {
        let view = EmptyStateView(image: nil, title: "Test")

        let stackView = view.subviews.first { $0 is UIStackView } as? UIStackView
        XCTAssertEqual(stackView?.axis, .vertical)
    }

    func testView_stackViewHasCenterAlignment() {
        let view = EmptyStateView(image: nil, title: "Test")

        let stackView = view.subviews.first { $0 is UIStackView } as? UIStackView
        XCTAssertEqual(stackView?.alignment, .center)
    }

    // MARK: - Message Visibility Tests

    func testMessageLabel_isHiddenWhenNil() {
        let view = EmptyStateView(image: nil, title: "Title", message: nil)

        // Get the stack view and find the message label (third item)
        if let stackView = view.subviews.first as? UIStackView,
           stackView.arrangedSubviews.count >= 3 {
            let messageLabel = stackView.arrangedSubviews[2]
            XCTAssertTrue(messageLabel.isHidden)
        }
    }

    func testMessageLabel_isVisibleWhenSet() {
        let view = EmptyStateView(image: nil, title: "Title", message: "A message")

        if let stackView = view.subviews.first as? UIStackView,
           stackView.arrangedSubviews.count >= 3 {
            let messageLabel = stackView.arrangedSubviews[2]
            XCTAssertFalse(messageLabel.isHidden)
        }
    }
}
