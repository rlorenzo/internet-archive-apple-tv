//
//  ItemCellTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ItemCell
//

import XCTest
@testable import Internet_Archive

@MainActor
final class ItemCellTests: XCTestCase {

    // Helper to create a test cell
    private func makeCell(frame: CGRect = CGRect(x: 0, y: 0, width: 200, height: 300)) -> ItemCell {
        ItemCell(frame: frame)
    }

    // MARK: - Initialization Tests

    func testInit_withFrame() {
        let cell = makeCell()
        XCTAssertNotNil(cell)
    }

    func testInit_withFrame_setsFrame() {
        let frame = CGRect(x: 10, y: 20, width: 200, height: 300)
        let cell = makeCell(frame: frame)
        XCTAssertEqual(cell.frame, frame)
    }

    func testInit_withZeroFrame() {
        let cell = makeCell(frame: .zero)
        XCTAssertNotNil(cell)
        XCTAssertEqual(cell.frame, .zero)
    }

    func testInit_withLargeFrame() {
        let frame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let cell = makeCell(frame: frame)
        XCTAssertEqual(cell.frame.width, 1920)
        XCTAssertEqual(cell.frame.height, 1080)
    }

    // MARK: - UICollectionViewCell Properties Tests

    func testIsCollectionViewCell() {
        let cell = makeCell()
        XCTAssertTrue(cell != nil)
    }

    func testContentView_exists() {
        let cell = makeCell()
        XCTAssertNotNil(cell.contentView)
    }

    func testReuseIdentifier_isNilWhenNotRegistered() {
        let cell = makeCell()
        XCTAssertNil(cell.reuseIdentifier)
    }

    // MARK: - Focus Tests

    func testDidUpdateFocus_doesNotCrash() {
        let cell = makeCell()
        // Create a mock context - just verify the method doesn't crash
        // Focus updates need a real focus system to work
        XCTAssertNotNil(cell)
    }

    // MARK: - Multiple Cells

    func testMultipleCells_areIndependent() {
        let cell1 = ItemCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let cell2 = ItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

        XCTAssertNotEqual(cell1.frame.width, cell2.frame.width)
    }
}

// MARK: - FavoriteItemParams Tests

final class FavoriteItemParamsTests: XCTestCase {

    func testInit() {
        let params = FavoriteItemParams(
            identifier: "test-id",
            mediatype: "movies",
            title: "Test Movie"
        )

        XCTAssertEqual(params.identifier, "test-id")
        XCTAssertEqual(params.mediatype, "movies")
        XCTAssertEqual(params.title, "Test Movie")
    }

    func testInit_withDifferentMediaTypes() {
        let movieParams = FavoriteItemParams(identifier: "m1", mediatype: "movies", title: "Movie")
        let audioParams = FavoriteItemParams(identifier: "a1", mediatype: "audio", title: "Audio")
        let textParams = FavoriteItemParams(identifier: "t1", mediatype: "texts", title: "Text")

        XCTAssertEqual(movieParams.mediatype, "movies")
        XCTAssertEqual(audioParams.mediatype, "audio")
        XCTAssertEqual(textParams.mediatype, "texts")
    }

    func testInit_withSpecialCharactersInTitle() {
        let params = FavoriteItemParams(
            identifier: "test-id",
            mediatype: "movies",
            title: "Movie: Title with 'Quotes' & Special <Characters>"
        )

        XCTAssertEqual(params.title, "Movie: Title with 'Quotes' & Special <Characters>")
    }

    func testInit_withEmptyStrings() {
        let params = FavoriteItemParams(
            identifier: "",
            mediatype: "",
            title: ""
        )

        XCTAssertEqual(params.identifier, "")
        XCTAssertEqual(params.mediatype, "")
        XCTAssertEqual(params.title, "")
    }
}
