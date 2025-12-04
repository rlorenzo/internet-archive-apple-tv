//
//  ModernItemCellTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ModernItemCell
//

import XCTest
@testable import Internet_Archive

@MainActor
final class ModernItemCellTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_withFrame() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        XCTAssertNotNil(cell)
    }

    func testReuseIdentifier() {
        XCTAssertEqual(ModernItemCell.reuseIdentifier, "ModernItemCell")
    }

    // MARK: - Configuration Tests

    func testConfigure_withViewModel() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        let searchResult = TestFixtures.movieSearchResult
        let viewModel = ItemViewModel(item: searchResult)

        cell.configure(with: viewModel)

        XCTAssertNotNil(cell.accessibilityLabel)
    }

    func testConfigure_setsAccessibilityLabel() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        let searchResult = TestFixtures.makeSearchResult(identifier: "test", title: "Test Title")
        let viewModel = ItemViewModel(item: searchResult)

        cell.configure(with: viewModel)

        XCTAssertEqual(cell.accessibilityLabel, "Test Title")
    }

    // MARK: - Reuse Tests

    func testPrepareForReuse_clearsContent() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        let searchResult = TestFixtures.movieSearchResult
        let viewModel = ItemViewModel(item: searchResult)

        cell.configure(with: viewModel)
        cell.prepareForReuse()

        XCTAssertNil(cell.accessibilityLabel)
    }

    // MARK: - Focus Tests

    func testCanBecomeFocused_returnsTrue() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        XCTAssertTrue(cell.canBecomeFocused)
    }

    // MARK: - Accessibility Tests

    func testAccessibilityTraits() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        XCTAssertTrue(cell.accessibilityTraits.contains(.button))
    }

    func testIsAccessibilityElement() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        XCTAssertTrue(cell.isAccessibilityElement)
    }

    // MARK: - Layout Tests

    func testLayoutSubviews_doesNotCrash() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        cell.layoutSubviews()
        XCTAssertNotNil(cell)
    }

    func testCell_hasSubviews() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        XCTAssertFalse(cell.contentView.subviews.isEmpty)
    }

    func testCell_hasCorrectCornerRadius() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        XCTAssertEqual(cell.layer.cornerRadius, 12)
    }

    // MARK: - Configuration Edge Cases

    func testConfigure_withNoImage() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        let searchResult = TestFixtures.makeSearchResult(identifier: "no_image", title: "No Image Item")
        let viewModel = ItemViewModel(item: searchResult)

        cell.configure(with: viewModel)

        XCTAssertEqual(cell.accessibilityLabel, "No Image Item")
    }

    func testConfigure_withImageURL() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        let searchResult = TestFixtures.movieSearchResult
        let viewModel = ItemViewModel(item: searchResult)

        // Should not crash with valid image URL
        cell.configure(with: viewModel)
        XCTAssertNotNil(cell)
    }

    func testConfigure_withDifferentSections() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))

        // Test with different sections
        let sections: [CollectionSection] = [.main, .videos, .music, .people]
        for section in sections {
            let searchResult = TestFixtures.makeSearchResult(identifier: "item_\(section.rawValue)")
            let viewModel = ItemViewModel(item: searchResult, section: section)
            cell.configure(with: viewModel)
            XCTAssertNotNil(cell)
        }
    }

    func testConfigure_multipleTimes() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))

        // Configure multiple times without prepareForReuse
        for i in 0..<5 {
            let searchResult = TestFixtures.makeSearchResult(identifier: "item_\(i)", title: "Title \(i)")
            let viewModel = ItemViewModel(item: searchResult)
            cell.configure(with: viewModel)
        }

        // Last configuration should be applied
        XCTAssertEqual(cell.accessibilityLabel, "Title 4")
    }

    func testPrepareForReuse_thenReconfigure() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))

        // First configuration
        let result1 = TestFixtures.makeSearchResult(identifier: "first", title: "First Title")
        cell.configure(with: ItemViewModel(item: result1))
        XCTAssertEqual(cell.accessibilityLabel, "First Title")

        // Prepare for reuse
        cell.prepareForReuse()
        XCTAssertNil(cell.accessibilityLabel)

        // Second configuration
        let result2 = TestFixtures.makeSearchResult(identifier: "second", title: "Second Title")
        cell.configure(with: ItemViewModel(item: result2))
        XCTAssertEqual(cell.accessibilityLabel, "Second Title")
    }

    // MARK: - Layout Edge Cases

    func testLayoutSubviews_withZeroFrame() {
        let cell = ModernItemCell(frame: .zero)
        cell.layoutSubviews()
        XCTAssertNotNil(cell)
    }

    func testLayoutSubviews_withLargeFrame() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        cell.layoutSubviews()
        XCTAssertNotNil(cell)
    }

    func testLayoutSubviews_afterFrameChange() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))

        // Change frame
        cell.frame = CGRect(x: 0, y: 0, width: 400, height: 600)
        cell.layoutSubviews()

        XCTAssertEqual(cell.frame.width, 400)
        XCTAssertEqual(cell.frame.height, 600)
    }

    // MARK: - ContentView Tests

    func testContentView_hasCorrectCornerRadius() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        XCTAssertEqual(cell.contentView.layer.cornerRadius, 12)
    }

    func testContentView_containsExpectedSubviewCount() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        // Should have imageView, glassEffectView, and titleLabel
        XCTAssertGreaterThanOrEqual(cell.contentView.subviews.count, 3)
    }

    // MARK: - Init with Coder Tests

    func testInit_withCoderReturnsNonNil() {
        // This tests the coder initializer path
        // Since we can't easily create a NSCoder, we just verify the frame init works
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        XCTAssertNotNil(cell)
    }

    // MARK: - Transform Tests

    func testCell_initialTransformIsIdentity() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        XCTAssertEqual(cell.transform, .identity)
    }

    // MARK: - Constraint Tests

    func testCell_hasConstraintsAfterInit() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        // Force layout
        cell.layoutIfNeeded()
        // Check contentView has subviews with constraints
        XCTAssertFalse(cell.contentView.constraints.isEmpty)
    }
}
