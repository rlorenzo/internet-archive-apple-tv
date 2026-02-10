//
//  ContentFilterModelsTests.swift
//  Internet ArchiveTests
//
//  Direct unit tests for ContentFilterModels
//

import Testing
@testable import Internet_Archive

@Suite("ContentFilterModels Tests")
struct ContentFilterModelsTests {

    // MARK: - ContentFilterReason Tests

    @Test func contentFilterReasonBlockedCollectionDescription() {
        let reason = ContentFilterReason.blockedCollection("adult-content")
        #expect(reason.description == "Blocked collection: adult-content")
    }

    @Test func contentFilterReasonBlockedKeywordDescription() {
        let reason = ContentFilterReason.blockedKeyword("explicit")
        #expect(reason.description == "Contains blocked keyword: explicit")
    }

    @Test func contentFilterReasonRestrictedLicenseDescription() {
        let reason = ContentFilterReason.restrictedLicense("All Rights Reserved")
        #expect(reason.description == "Restricted license: All Rights Reserved")
    }

    @Test func contentFilterReasonNoLicenseDescription() {
        let reason = ContentFilterReason.noLicense
        #expect(reason.description == "No open license specified")
    }

    // MARK: - ContentFilterResult Tests

    @Test func contentFilterResultAllowed() {
        let result = ContentFilterResult.allowed
        #expect(!result.isFiltered)
        #expect(result.reason == nil)
    }

    @Test func contentFilterResultFilteredWithBlockedCollection() {
        let result = ContentFilterResult.filtered(reason: .blockedCollection("test"))
        #expect(result.isFiltered)
        if case .blockedCollection(let collection) = result.reason {
            #expect(collection == "test")
        } else {
            Issue.record("Expected blockedCollection reason")
        }
    }

    @Test func contentFilterResultFilteredWithBlockedKeyword() {
        let result = ContentFilterResult.filtered(reason: .blockedKeyword("keyword"))
        #expect(result.isFiltered)
        if case .blockedKeyword(let keyword) = result.reason {
            #expect(keyword == "keyword")
        } else {
            Issue.record("Expected blockedKeyword reason")
        }
    }

    @Test func contentFilterResultFilteredWithRestrictedLicense() {
        let result = ContentFilterResult.filtered(reason: .restrictedLicense("restricted"))
        #expect(result.isFiltered)
        if case .restrictedLicense(let license) = result.reason {
            #expect(license == "restricted")
        } else {
            Issue.record("Expected restrictedLicense reason")
        }
    }

    @Test func contentFilterResultFilteredWithNoLicense() {
        let result = ContentFilterResult.filtered(reason: .noLicense)
        #expect(result.isFiltered)
        if case .noLicense = result.reason {
            // Success
        } else {
            Issue.record("Expected noLicense reason")
        }
    }

    // MARK: - ContentFilterPreferences Tests

    @Test func contentFilterPreferencesDefault() {
        let preferences = ContentFilterPreferences.default
        #expect(!preferences.requireOpenLicense, "Default should not require open license")
    }

    @Test func contentFilterPreferencesCustomInitialization() {
        let preferences = ContentFilterPreferences(requireOpenLicense: true)
        #expect(preferences.requireOpenLicense)
    }

    // MARK: - ContentFilterStats Tests

    @Test func contentFilterStatsEmpty() {
        let stats = ContentFilterStats.empty
        #expect(stats.totalItemsChecked == 0)
        #expect(stats.totalItemsFiltered == 0)
        #expect(stats.filterReasons.isEmpty)
    }

    @Test func contentFilterStatsFilterPercentageZeroItems() {
        let stats = ContentFilterStats.empty
        #expect(stats.filterPercentage == 0, "Should return 0 when no items checked")
    }

    @Test func contentFilterStatsFilterPercentageHalfFiltered() {
        let stats = ContentFilterStats(
            totalItemsChecked: 10,
            totalItemsFiltered: 5,
            filterReasons: [:]
        )
        #expect(abs(stats.filterPercentage - 50.0) < 0.001)
    }

    @Test func contentFilterStatsFilterPercentageAllFiltered() {
        let stats = ContentFilterStats(
            totalItemsChecked: 10,
            totalItemsFiltered: 10,
            filterReasons: [:]
        )
        #expect(abs(stats.filterPercentage - 100.0) < 0.001)
    }

    @Test func contentFilterStatsFilterPercentageNoneFiltered() {
        let stats = ContentFilterStats(
            totalItemsChecked: 10,
            totalItemsFiltered: 0,
            filterReasons: [:]
        )
        #expect(abs(stats.filterPercentage - 0.0) < 0.001)
    }

    @Test func contentFilterStatsFilterPercentageFractional() {
        let stats = ContentFilterStats(
            totalItemsChecked: 3,
            totalItemsFiltered: 1,
            filterReasons: [:]
        )
        #expect(abs(stats.filterPercentage - 33.333) < 0.01)
    }

    @Test func contentFilterStatsWithReasons() {
        let stats = ContentFilterStats(
            totalItemsChecked: 100,
            totalItemsFiltered: 25,
            filterReasons: ["blockedCollection": 15, "blockedKeyword": 10]
        )
        #expect(stats.totalItemsChecked == 100)
        #expect(stats.totalItemsFiltered == 25)
        #expect(stats.filterReasons["blockedCollection"] == 15)
        #expect(stats.filterReasons["blockedKeyword"] == 10)
        #expect(abs(stats.filterPercentage - 25.0) < 0.001)
    }
}
