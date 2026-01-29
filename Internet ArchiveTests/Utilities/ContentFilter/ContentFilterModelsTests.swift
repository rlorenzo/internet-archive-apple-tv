//
//  ContentFilterModelsTests.swift
//  Internet ArchiveTests
//
//  Direct unit tests for ContentFilterModels
//

import XCTest
@testable import Internet_Archive

final class ContentFilterModelsTests: XCTestCase {

    // MARK: - ContentFilterReason Tests

    func testContentFilterReason_blockedCollection_description() {
        let reason = ContentFilterReason.blockedCollection("adult-content")
        XCTAssertEqual(reason.description, "Blocked collection: adult-content")
    }

    func testContentFilterReason_blockedKeyword_description() {
        let reason = ContentFilterReason.blockedKeyword("explicit")
        XCTAssertEqual(reason.description, "Contains blocked keyword: explicit")
    }

    func testContentFilterReason_restrictedLicense_description() {
        let reason = ContentFilterReason.restrictedLicense("All Rights Reserved")
        XCTAssertEqual(reason.description, "Restricted license: All Rights Reserved")
    }

    func testContentFilterReason_noLicense_description() {
        let reason = ContentFilterReason.noLicense
        XCTAssertEqual(reason.description, "No open license specified")
    }

    // MARK: - ContentFilterResult Tests

    func testContentFilterResult_allowed() {
        let result = ContentFilterResult.allowed
        XCTAssertFalse(result.isFiltered)
        XCTAssertNil(result.reason)
    }

    func testContentFilterResult_filtered_withBlockedCollection() {
        let result = ContentFilterResult.filtered(reason: .blockedCollection("test"))
        XCTAssertTrue(result.isFiltered)
        if case .blockedCollection(let collection) = result.reason {
            XCTAssertEqual(collection, "test")
        } else {
            XCTFail("Expected blockedCollection reason")
        }
    }

    func testContentFilterResult_filtered_withBlockedKeyword() {
        let result = ContentFilterResult.filtered(reason: .blockedKeyword("keyword"))
        XCTAssertTrue(result.isFiltered)
        if case .blockedKeyword(let keyword) = result.reason {
            XCTAssertEqual(keyword, "keyword")
        } else {
            XCTFail("Expected blockedKeyword reason")
        }
    }

    func testContentFilterResult_filtered_withRestrictedLicense() {
        let result = ContentFilterResult.filtered(reason: .restrictedLicense("restricted"))
        XCTAssertTrue(result.isFiltered)
        if case .restrictedLicense(let license) = result.reason {
            XCTAssertEqual(license, "restricted")
        } else {
            XCTFail("Expected restrictedLicense reason")
        }
    }

    func testContentFilterResult_filtered_withNoLicense() {
        let result = ContentFilterResult.filtered(reason: .noLicense)
        XCTAssertTrue(result.isFiltered)
        if case .noLicense = result.reason {
            // Success
        } else {
            XCTFail("Expected noLicense reason")
        }
    }

    // MARK: - ContentFilterPreferences Tests

    func testContentFilterPreferences_default() {
        let preferences = ContentFilterPreferences.default
        XCTAssertFalse(preferences.requireOpenLicense, "Default should not require open license")
    }

    func testContentFilterPreferences_customInitialization() {
        let preferences = ContentFilterPreferences(requireOpenLicense: true)
        XCTAssertTrue(preferences.requireOpenLicense)
    }

    // MARK: - ContentFilterStats Tests

    func testContentFilterStats_empty() {
        let stats = ContentFilterStats.empty
        XCTAssertEqual(stats.totalItemsChecked, 0)
        XCTAssertEqual(stats.totalItemsFiltered, 0)
        XCTAssertTrue(stats.filterReasons.isEmpty)
    }

    func testContentFilterStats_filterPercentage_zeroItems() {
        let stats = ContentFilterStats.empty
        XCTAssertEqual(stats.filterPercentage, 0, "Should return 0 when no items checked")
    }

    func testContentFilterStats_filterPercentage_halfFiltered() {
        let stats = ContentFilterStats(
            totalItemsChecked: 10,
            totalItemsFiltered: 5,
            filterReasons: [:]
        )
        XCTAssertEqual(stats.filterPercentage, 50.0, accuracy: 0.001)
    }

    func testContentFilterStats_filterPercentage_allFiltered() {
        let stats = ContentFilterStats(
            totalItemsChecked: 10,
            totalItemsFiltered: 10,
            filterReasons: [:]
        )
        XCTAssertEqual(stats.filterPercentage, 100.0, accuracy: 0.001)
    }

    func testContentFilterStats_filterPercentage_noneFiltered() {
        let stats = ContentFilterStats(
            totalItemsChecked: 10,
            totalItemsFiltered: 0,
            filterReasons: [:]
        )
        XCTAssertEqual(stats.filterPercentage, 0.0, accuracy: 0.001)
    }

    func testContentFilterStats_filterPercentage_fractional() {
        let stats = ContentFilterStats(
            totalItemsChecked: 3,
            totalItemsFiltered: 1,
            filterReasons: [:]
        )
        XCTAssertEqual(stats.filterPercentage, 33.333, accuracy: 0.01)
    }

    func testContentFilterStats_withReasons() {
        let stats = ContentFilterStats(
            totalItemsChecked: 100,
            totalItemsFiltered: 25,
            filterReasons: ["blockedCollection": 15, "blockedKeyword": 10]
        )
        XCTAssertEqual(stats.totalItemsChecked, 100)
        XCTAssertEqual(stats.totalItemsFiltered, 25)
        XCTAssertEqual(stats.filterReasons["blockedCollection"], 15)
        XCTAssertEqual(stats.filterReasons["blockedKeyword"], 10)
        XCTAssertEqual(stats.filterPercentage, 25.0, accuracy: 0.001)
    }
}
