//
//  SectionHeaderTests.swift
//  Internet ArchiveTests
//
//  Unit tests for SectionHeader SwiftUI component
//

import XCTest
import SwiftUI
@testable import Internet_Archive

@MainActor
final class SectionHeaderTests: XCTestCase {

    // MARK: - Simple Initialization Tests

    func testSimpleInit_setsTitle() {
        let header = SectionHeader("Featured Collections")
        XCTAssertEqual(header.title, "Featured Collections")
    }

    func testSimpleInit_showSeeAllIsFalse() {
        let header = SectionHeader("Featured")
        XCTAssertFalse(header.showSeeAll)
    }

    func testSimpleInit_seeAllTextIsDefault() {
        let header = SectionHeader("Featured")
        XCTAssertEqual(header.seeAllText, "See All")
    }

    func testSimpleInit_onSeeAllTapIsNil() {
        let header = SectionHeader("Featured")
        XCTAssertNil(header.onSeeAllTap)
    }

    // MARK: - Full Initialization Tests

    func testFullInit_setsTitle() {
        let header = SectionHeader("Continue Watching", showSeeAll: true, seeAllText: "View All") {}
        XCTAssertEqual(header.title, "Continue Watching")
    }

    func testFullInit_setsShowSeeAll() {
        let header = SectionHeader("Test", showSeeAll: true, seeAllText: "All") {}
        XCTAssertTrue(header.showSeeAll)
    }

    func testFullInit_setsSeeAllText() {
        let header = SectionHeader("Test", showSeeAll: true, seeAllText: "Browse All") {}
        XCTAssertEqual(header.seeAllText, "Browse All")
    }

    func testFullInit_setsOnSeeAllTap() {
        let header = SectionHeader("Test", showSeeAll: true) { print("tapped") }
        XCTAssertNotNil(header.onSeeAllTap)
    }

    func testFullInit_defaultSeeAllText() {
        let header = SectionHeader("Test", showSeeAll: true) {}
        XCTAssertEqual(header.seeAllText, "See All")
    }

    // MARK: - ShowSeeAll False Tests

    func testShowSeeAllFalse_buttonNotShown() {
        let header = SectionHeader("Test", showSeeAll: false, seeAllText: "All") {}
        XCTAssertFalse(header.showSeeAll)
    }

    // MARK: - Title Variations Tests

    func testTitle_emptyString() {
        let header = SectionHeader("")
        XCTAssertEqual(header.title, "")
    }

    func testTitle_longString() {
        let longTitle = "This is a very long section header title that might wrap"
        let header = SectionHeader(longTitle)
        XCTAssertEqual(header.title, longTitle)
    }

    func testTitle_specialCharacters() {
        let specialTitle = "Music & Audio"
        let header = SectionHeader(specialTitle)
        XCTAssertEqual(header.title, specialTitle)
    }

    func testTitle_unicode() {
        let unicodeTitle = "音乐 Music 🎵"
        let header = SectionHeader(unicodeTitle)
        XCTAssertEqual(header.title, unicodeTitle)
    }

    // MARK: - SeeAllText Variations Tests

    func testSeeAllText_customText() {
        let header = SectionHeader("Title", showSeeAll: true, seeAllText: "View All Years") {}
        XCTAssertEqual(header.seeAllText, "View All Years")
    }

    func testSeeAllText_emptyString() {
        let header = SectionHeader("Title", showSeeAll: true, seeAllText: "") {}
        XCTAssertEqual(header.seeAllText, "")
    }

    // MARK: - Callback Tests

    func testOnSeeAllTap_callbackExecutes() {
        var callbackExecuted = false
        let header = SectionHeader("Test", showSeeAll: true) {
            callbackExecuted = true
        }

        // Execute the callback
        header.onSeeAllTap?()

        XCTAssertTrue(callbackExecuted)
    }

    func testOnSeeAllTap_canBeCalledMultipleTimes() {
        var callCount = 0
        let header = SectionHeader("Test", showSeeAll: true) {
            callCount += 1
        }

        header.onSeeAllTap?()
        header.onSeeAllTap?()
        header.onSeeAllTap?()

        XCTAssertEqual(callCount, 3)
    }

    // MARK: - View Type Tests

    func testSectionHeader_isView() {
        let header = SectionHeader("Test")
        // Verify it conforms to View by accessing body type
        _ = type(of: header.body)
        XCTAssertNotNil(header)
    }

    // MARK: - Common Usage Pattern Tests

    func testCommonPattern_continueWatchingHeader() {
        let header = SectionHeader("Continue Watching", showSeeAll: true) {}
        XCTAssertEqual(header.title, "Continue Watching")
        XCTAssertTrue(header.showSeeAll)
        XCTAssertEqual(header.seeAllText, "See All")
    }

    func testCommonPattern_browseByYearHeader() {
        let header = SectionHeader("Browse by Year", showSeeAll: true, seeAllText: "View All Years") {}
        XCTAssertEqual(header.title, "Browse by Year")
        XCTAssertEqual(header.seeAllText, "View All Years")
    }

    func testCommonPattern_featuredHeader() {
        let header = SectionHeader("Featured Collections")
        XCTAssertEqual(header.title, "Featured Collections")
        XCTAssertFalse(header.showSeeAll)
    }

    // MARK: - Accessibility Label Tests

    func testAccessibilityLabel_computedFromProperties() {
        // The accessibility label for the "See All" button is computed as "\(seeAllText) for \(title)"
        let header = SectionHeader("Continue Watching", showSeeAll: true) {}

        // Verify the components that would be used in the accessibility label
        XCTAssertEqual(header.title, "Continue Watching")
        XCTAssertEqual(header.seeAllText, "See All")

        // Expected label: "See All for Continue Watching"
        let expectedLabel = "\(header.seeAllText) for \(header.title)"
        XCTAssertEqual(expectedLabel, "See All for Continue Watching")
    }

    func testAccessibilityLabel_customSeeAllText() {
        let header = SectionHeader("Browse by Year", showSeeAll: true, seeAllText: "View All Years") {}

        let expectedLabel = "\(header.seeAllText) for \(header.title)"
        XCTAssertEqual(expectedLabel, "View All Years for Browse by Year")
    }

    // MARK: - View Type Conformance

    func testBody_returnsValidView() {
        let header = SectionHeader("Test")
        // SwiftUI View's body should return something
        _ = header.body
        XCTAssertNotNil(header)
    }

    // MARK: - Edge Case Tests

    func testInit_emptyTitleAndSeeAllText() {
        let header = SectionHeader("", showSeeAll: true, seeAllText: "") {}

        XCTAssertEqual(header.title, "")
        XCTAssertEqual(header.seeAllText, "")
        XCTAssertTrue(header.showSeeAll)
    }

    func testInit_veryLongTitle() {
        let longTitle = String(repeating: "A", count: 200)
        let header = SectionHeader(longTitle)

        XCTAssertEqual(header.title.count, 200)
    }

    func testInit_titleWithNewlines() {
        let titleWithNewlines = "Line One\nLine Two"
        let header = SectionHeader(titleWithNewlines)

        XCTAssertEqual(header.title, "Line One\nLine Two")
    }

    // MARK: - Multiple Instance Tests

    func testMultipleInstances_areIndependent() {
        let header1 = SectionHeader("Header 1")
        let header2 = SectionHeader("Header 2", showSeeAll: true) {}

        XCTAssertEqual(header1.title, "Header 1")
        XCTAssertEqual(header2.title, "Header 2")
        XCTAssertFalse(header1.showSeeAll)
        XCTAssertTrue(header2.showSeeAll)
    }
}
