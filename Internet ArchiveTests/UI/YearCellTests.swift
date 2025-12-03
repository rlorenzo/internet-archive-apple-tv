//
//  YearCellTests.swift
//  Internet ArchiveTests
//
//  Unit tests for YearCell
//

import XCTest
@testable import Internet_Archive

@MainActor
final class YearCellTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_style_reuseIdentifier() {
        let cell = YearCell(style: .default, reuseIdentifier: "YearCell")
        XCTAssertNotNil(cell)
    }

    func testInit_differentStyles() {
        let defaultCell = YearCell(style: .default, reuseIdentifier: "YearCell")
        let subtitleCell = YearCell(style: .subtitle, reuseIdentifier: "YearCell")
        let value1Cell = YearCell(style: .value1, reuseIdentifier: "YearCell")
        let value2Cell = YearCell(style: .value2, reuseIdentifier: "YearCell")

        XCTAssertNotNil(defaultCell)
        XCTAssertNotNil(subtitleCell)
        XCTAssertNotNil(value1Cell)
        XCTAssertNotNil(value2Cell)
    }

    func testInit_nilReuseIdentifier() {
        let cell = YearCell(style: .default, reuseIdentifier: nil)
        XCTAssertNotNil(cell)
        XCTAssertNil(cell.reuseIdentifier)
    }

    // MARK: - UITableViewCell Properties Tests

    func testIsTableViewCell() {
        // Verify YearCell properly inherits from UITableViewCell
        let cell: UITableViewCell = YearCell(style: .default, reuseIdentifier: "YearCell")
        XCTAssertNotNil(cell)
    }

    func testContentView_exists() {
        let cell = YearCell(style: .default, reuseIdentifier: "YearCell")
        XCTAssertNotNil(cell.contentView)
    }

    func testReuseIdentifier() {
        let cell = YearCell(style: .default, reuseIdentifier: "TestIdentifier")
        XCTAssertEqual(cell.reuseIdentifier, "TestIdentifier")
    }

    // MARK: - Multiple Cells Tests

    func testMultipleCells_areIndependent() {
        let cell1 = YearCell(style: .default, reuseIdentifier: "Cell1")
        let cell2 = YearCell(style: .subtitle, reuseIdentifier: "Cell2")

        XCTAssertNotEqual(cell1.reuseIdentifier, cell2.reuseIdentifier)
    }

    // MARK: - Selection Style Tests

    func testSelectionStyle_canBeSet() {
        let cell = YearCell(style: .default, reuseIdentifier: "YearCell")

        cell.selectionStyle = .none
        XCTAssertEqual(cell.selectionStyle, .none)

        cell.selectionStyle = .default
        XCTAssertEqual(cell.selectionStyle, .default)
    }
}
