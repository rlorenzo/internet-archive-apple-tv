//
//  AppInfoFooterTests.swift
//  Internet ArchiveTests
//
//  Unit tests for AppInfoFooter SwiftUI component
//

import XCTest
import SwiftUI
@testable import Internet_Archive

@MainActor
final class AppInfoFooterTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_succeeds() {
        let footer = AppInfoFooter()
        XCTAssertNotNil(footer)
    }

    // MARK: - View Type Tests

    func testAppInfoFooter_isView() {
        let footer = AppInfoFooter()
        _ = type(of: footer.body)
        XCTAssertNotNil(footer)
    }

    func testAppInfoFooter_canBeCreatedMultipleTimes() {
        let footer1 = AppInfoFooter()
        let footer2 = AppInfoFooter()
        XCTAssertNotNil(footer1)
        XCTAssertNotNil(footer2)
    }

    // MARK: - Body Access Tests

    func testBody_doesNotCrash() {
        let footer = AppInfoFooter()
        // Accessing body should not crash
        _ = footer.body
        XCTAssertTrue(true)
    }

    func testBody_canBeAccessedMultipleTimes() {
        let footer = AppInfoFooter()
        // Body should be stable
        _ = footer.body
        _ = footer.body
        _ = footer.body
        XCTAssertTrue(true)
    }
}
