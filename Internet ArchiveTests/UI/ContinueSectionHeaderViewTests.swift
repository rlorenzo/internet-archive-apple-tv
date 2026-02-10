//
//  ContinueSectionHeaderViewTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ContinueSectionHeaderView reusable header
//

import XCTest
@testable import Internet_Archive

@MainActor
final class ContinueSectionHeaderViewTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_createsView() {
        let view = ContinueSectionHeaderView(frame: CGRect(x: 0, y: 0, width: 1920, height: 60))
        XCTAssertNotNil(view)
    }

    func testInit_hasSubviews() {
        let view = ContinueSectionHeaderView(frame: CGRect(x: 0, y: 0, width: 1920, height: 60))
        XCTAssertFalse(view.subviews.isEmpty)
    }

    func testReuseIdentifier() {
        XCTAssertEqual(ContinueSectionHeaderView.reuseIdentifier, "ContinueSectionHeaderView")
    }

    // MARK: - Accessibility Tests

    func testAccessibility_isAccessibilityElement() {
        let view = ContinueSectionHeaderView(frame: CGRect(x: 0, y: 0, width: 1920, height: 60))
        XCTAssertTrue(view.isAccessibilityElement)
    }

    func testAccessibility_hasHeaderTrait() {
        let view = ContinueSectionHeaderView(frame: CGRect(x: 0, y: 0, width: 1920, height: 60))
        XCTAssertTrue(view.accessibilityTraits.contains(.header))
    }

    // MARK: - Configure Tests

    func testConfigure_setsAccessibilityLabel() {
        let view = ContinueSectionHeaderView(frame: CGRect(x: 0, y: 0, width: 1920, height: 60))
        view.configure(with: "Continue Watching")
        XCTAssertEqual(view.accessibilityLabel, "Continue Watching section")
    }

    func testConfigure_differentTitles() {
        let view = ContinueSectionHeaderView(frame: CGRect(x: 0, y: 0, width: 1920, height: 60))

        view.configure(with: "Continue Listening")
        XCTAssertEqual(view.accessibilityLabel, "Continue Listening section")

        view.configure(with: "Featured")
        XCTAssertEqual(view.accessibilityLabel, "Featured section")
    }

    func testConfigure_emptyTitle() {
        let view = ContinueSectionHeaderView(frame: CGRect(x: 0, y: 0, width: 1920, height: 60))
        view.configure(with: "")
        XCTAssertEqual(view.accessibilityLabel, " section")
    }

    // MARK: - Prepare For Reuse Tests

    func testPrepareForReuse_doesNotCrash() {
        let view = ContinueSectionHeaderView(frame: CGRect(x: 0, y: 0, width: 1920, height: 60))
        view.configure(with: "Title")
        view.prepareForReuse()
        XCTAssertNotNil(view)
    }

    func testPrepareForReuse_thenReconfigure() {
        let view = ContinueSectionHeaderView(frame: CGRect(x: 0, y: 0, width: 1920, height: 60))
        view.configure(with: "Old Title")
        view.prepareForReuse()
        view.configure(with: "New Title")
        XCTAssertEqual(view.accessibilityLabel, "New Title section")
    }
}
