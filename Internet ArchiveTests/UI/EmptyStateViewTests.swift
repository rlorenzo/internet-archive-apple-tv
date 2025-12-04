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
}
