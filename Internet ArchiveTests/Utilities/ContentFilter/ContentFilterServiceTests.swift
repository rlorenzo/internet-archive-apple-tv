//
//  ContentFilterServiceTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ContentFilterService
//

import XCTest
@testable import Internet_Archive

@MainActor
final class ContentFilterServiceTests: XCTestCase {

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()
        // Reset to defaults before each test
        ContentFilterService.shared.resetToDefaults()
        ContentFilterService.shared.resetStatistics()
    }

    override func tearDown() async throws {
        // Reset after tests
        ContentFilterService.shared.resetToDefaults()
        try await super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstance_exists() {
        let service = ContentFilterService.shared
        XCTAssertNotNil(service)
    }

    func testSharedInstance_isSingleton() {
        let service1 = ContentFilterService.shared
        let service2 = ContentFilterService.shared
        XCTAssertTrue(service1 === service2)
    }

    // MARK: - Default State Tests

    func testDefaultState_filteringEnabled() {
        let service = ContentFilterService.shared
        XCTAssertTrue(service.isFilteringEnabled, "Filtering should be enabled by default for App Store compliance")
    }

    func testDefaultState_licenseFilteringDisabled() {
        let service = ContentFilterService.shared
        XCTAssertFalse(service.isLicenseFilteringEnabled, "License filtering should be disabled by default")
    }

    // MARK: - Collection Filtering Tests

    func testShouldFilter_blockedCollection_noPreview() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Test Item",
            collection: ["no-preview", "movies"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        XCTAssertTrue(filterResult.isFiltered, "Items in no-preview collection should be filtered")
        if case .blockedCollection(let collection) = filterResult.reason {
            XCTAssertEqual(collection, "no-preview")
        } else {
            XCTFail("Expected blockedCollection reason")
        }
    }

    func testShouldFilter_blockedCollection_hentai() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Test Item",
            collection: ["hentai"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        XCTAssertTrue(filterResult.isFiltered, "Items in hentai collection should be filtered")
    }

    func testShouldFilter_blockedCollection_adultcdroms() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Test Item",
            collection: ["adultcdroms"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        XCTAssertTrue(filterResult.isFiltered, "Items in adultcdroms collection should be filtered")
    }

    func testShouldFilter_allowedCollection() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Test Documentary",
            collection: ["movies", "documentary"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        XCTAssertFalse(filterResult.isFiltered, "Items in normal collections should not be filtered")
    }

    func testShouldFilter_caseInsensitive() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Test Item",
            collection: ["HENTAI"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        XCTAssertTrue(filterResult.isFiltered, "Collection filtering should be case-insensitive")
    }

    // MARK: - Keyword Filtering Tests

    func testShouldFilter_blockedKeyword_xxx() {
        let result = SearchResult(
            identifier: "test-item",
            title: "XXX Video",
            collection: ["movies"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        XCTAssertTrue(filterResult.isFiltered, "Items with xxx in title should be filtered")
    }

    func testShouldFilter_blockedKeyword_porn() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Some porn content",
            collection: ["movies"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        XCTAssertTrue(filterResult.isFiltered, "Items with porn in title should be filtered")
    }

    func testShouldFilter_safeTitle() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Educational Documentary",
            collection: ["movies"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        XCTAssertFalse(filterResult.isFiltered, "Items with safe titles should not be filtered")
    }

    // MARK: - License Filtering Tests

    func testIsOpenLicense_creativeCommonsPublicDomain() {
        let service = ContentFilterService.shared

        XCTAssertTrue(service.isOpenLicense("https://creativecommons.org/publicdomain/zero/1.0/"))
        XCTAssertTrue(service.isOpenLicense("http://creativecommons.org/publicdomain/mark/1.0/"))
    }

    func testIsOpenLicense_creativeCommonsBy() {
        let service = ContentFilterService.shared

        XCTAssertTrue(service.isOpenLicense("https://creativecommons.org/licenses/by/4.0/"))
        XCTAssertTrue(service.isOpenLicense("https://creativecommons.org/licenses/by-sa/4.0/"))
        XCTAssertTrue(service.isOpenLicense("https://creativecommons.org/licenses/by-nc/4.0/"))
        XCTAssertTrue(service.isOpenLicense("https://creativecommons.org/licenses/by-nc-sa/4.0/"))
        XCTAssertTrue(service.isOpenLicense("https://creativecommons.org/licenses/by-nd/4.0/"))
        XCTAssertTrue(service.isOpenLicense("https://creativecommons.org/licenses/by-nc-nd/4.0/"))
    }

    func testIsOpenLicense_unknownLicense() {
        let service = ContentFilterService.shared

        XCTAssertFalse(service.isOpenLicense("https://example.com/license"))
        XCTAssertFalse(service.isOpenLicense("all rights reserved"))
    }

    func testGetLicenseType_publicDomain() {
        let service = ContentFilterService.shared

        XCTAssertEqual(service.getLicenseType("https://creativecommons.org/publicdomain/zero/1.0/"), "CC0 (Public Domain)")
        XCTAssertEqual(service.getLicenseType("https://creativecommons.org/publicdomain/mark/1.0/"), "Public Domain")
    }

    func testGetLicenseType_creativeCommons() {
        let service = ContentFilterService.shared

        XCTAssertEqual(service.getLicenseType("https://creativecommons.org/licenses/by/4.0/"), "CC BY")
        XCTAssertEqual(service.getLicenseType("https://creativecommons.org/licenses/by-sa/4.0/"), "CC BY-SA")
        XCTAssertEqual(service.getLicenseType("https://creativecommons.org/licenses/by-nc/4.0/"), "CC BY-NC")
        XCTAssertEqual(service.getLicenseType("https://creativecommons.org/licenses/by-nc-sa/4.0/"), "CC BY-NC-SA")
    }

    func testShouldFilter_licenseFiltering_enabled() {
        let service = ContentFilterService.shared
        service.setLicenseFilteringEnabled(true)

        let resultWithLicense = SearchResult(
            identifier: "test-item",
            title: "Test Item",
            collection: ["movies"],
            licenseurl: "https://creativecommons.org/licenses/by/4.0/"
        )

        let resultWithoutLicense = SearchResult(
            identifier: "test-item-2",
            title: "Test Item 2",
            collection: ["movies"],
            licenseurl: nil
        )

        let resultWithRestrictedLicense = SearchResult(
            identifier: "test-item-3",
            title: "Test Item 3",
            collection: ["movies"],
            licenseurl: "https://example.com/all-rights-reserved"
        )

        XCTAssertFalse(service.shouldFilter(resultWithLicense).isFiltered, "Items with open license should pass")
        XCTAssertTrue(service.shouldFilter(resultWithoutLicense).isFiltered, "Items without license should be filtered when license filtering is enabled")
        XCTAssertTrue(service.shouldFilter(resultWithRestrictedLicense).isFiltered, "Items with restricted license should be filtered")
    }

    // MARK: - Filter Array Tests

    func testFilter_removesBlockedItems() {
        let results = [
            SearchResult(identifier: "1", title: "Safe Movie", collection: ["movies"]),
            SearchResult(identifier: "2", title: "Adult Content", collection: ["hentai"]),
            SearchResult(identifier: "3", title: "Another Safe Movie", collection: ["documentary"])
        ]

        let filtered = ContentFilterService.shared.filter(results)
        XCTAssertEqual(filtered.count, 2, "Should filter out blocked items")
        XCTAssertTrue(filtered.allSatisfy { $0.identifier != "2" }, "Blocked item should be removed")
    }

    // MARK: - Collection Blocking Tests

    func testIsCollectionBlocked() {
        let service = ContentFilterService.shared

        XCTAssertTrue(service.isCollectionBlocked("no-preview"))
        XCTAssertTrue(service.isCollectionBlocked("hentai"))
        XCTAssertTrue(service.isCollectionBlocked("adultcdroms"))
        XCTAssertTrue(service.isCollectionBlocked("NO-PREVIEW"))  // Case insensitive
        XCTAssertFalse(service.isCollectionBlocked("movies"))
        XCTAssertFalse(service.isCollectionBlocked("documentary"))
    }

    func testHasContentWarning() {
        let service = ContentFilterService.shared

        XCTAssertTrue(service.hasContentWarning(["movies", "no-preview"]))
        XCTAssertTrue(service.hasContentWarning(["No-Preview"]))  // Case insensitive
        XCTAssertFalse(service.hasContentWarning(["movies", "documentary"]))
    }

    // MARK: - Custom Blocking Tests

    func testAddBlockedCollection() {
        let service = ContentFilterService.shared

        service.addBlockedCollection("custom-adult-collection")

        let result = SearchResult(
            identifier: "test",
            title: "Test",
            collection: ["custom-adult-collection"]
        )

        XCTAssertTrue(service.shouldFilter(result).isFiltered, "Custom blocked collection should be filtered")
    }

    func testRemoveBlockedCollection() {
        let service = ContentFilterService.shared

        service.addBlockedCollection("custom-collection")
        service.removeBlockedCollection("custom-collection")

        let result = SearchResult(
            identifier: "test",
            title: "Test",
            collection: ["custom-collection"]
        )

        XCTAssertFalse(service.shouldFilter(result).isFiltered, "Removed collection should not be filtered")
    }

    func testAddBlockedKeyword() {
        let service = ContentFilterService.shared

        service.addBlockedKeyword("custom-bad-word")

        let result = SearchResult(
            identifier: "test",
            title: "This has custom-bad-word in it",
            collection: ["movies"]
        )

        XCTAssertTrue(service.shouldFilter(result).isFiltered, "Custom blocked keyword should be filtered")
    }

    // MARK: - Filtering Disabled Tests

    func testShouldFilter_whenDisabled_allowsEverything() {
        let service = ContentFilterService.shared
        service.setFilteringEnabled(false)

        let result = SearchResult(
            identifier: "test",
            title: "XXX Porn Content",
            collection: ["hentai", "no-preview"]
        )

        let filterResult = service.shouldFilter(result)
        XCTAssertFalse(filterResult.isFiltered, "Nothing should be filtered when filtering is disabled")
    }

    // MARK: - Query Building Tests

    func testBuildExclusionQuery() {
        let service = ContentFilterService.shared
        let query = service.buildExclusionQuery()

        XCTAssertTrue(query.contains("-collection:(no-preview)"), "Exclusion query should include no-preview")
        XCTAssertTrue(query.contains("-collection:(hentai)"), "Exclusion query should include hentai")
    }

    func testBuildExclusionQuery_whenDisabled() {
        let service = ContentFilterService.shared
        service.setFilteringEnabled(false)

        let query = service.buildExclusionQuery()
        XCTAssertTrue(query.isEmpty, "Exclusion query should be empty when filtering is disabled")
    }

    func testBuildLicenseQuery() {
        let service = ContentFilterService.shared
        service.setLicenseFilteringEnabled(true)

        let query = service.buildLicenseQuery()
        XCTAssertTrue(query.contains("licenseurl:*creativecommons*"), "License query should filter for CC licenses")
    }

    func testBuildLicenseQuery_whenDisabled() {
        let service = ContentFilterService.shared
        service.setLicenseFilteringEnabled(false)

        let query = service.buildLicenseQuery()
        XCTAssertTrue(query.isEmpty, "License query should be empty when license filtering is disabled")
    }

    // MARK: - Statistics Tests

    func testFilterStatistics() {
        let service = ContentFilterService.shared

        // Filter some items
        let results = [
            SearchResult(identifier: "1", title: "Safe Movie", collection: ["movies"]),
            SearchResult(identifier: "2", title: "Adult Content", collection: ["hentai"]),
            SearchResult(identifier: "3", title: "XXX Video", collection: ["movies"])
        ]

        _ = service.filter(results)

        let stats = service.filterStatistics
        XCTAssertEqual(stats.totalItemsChecked, 3)
        XCTAssertEqual(stats.totalItemsFiltered, 2)
        XCTAssertTrue(stats.filterPercentage > 60 && stats.filterPercentage < 70)
    }

    func testResetStatistics() {
        let service = ContentFilterService.shared

        // Generate some stats
        let result = SearchResult(identifier: "1", title: "Test", collection: ["hentai"])
        _ = service.shouldFilter(result)

        // Reset
        service.resetStatistics()

        let stats = service.filterStatistics
        XCTAssertEqual(stats.totalItemsChecked, 0)
        XCTAssertEqual(stats.totalItemsFiltered, 0)
    }

    // MARK: - PIN Tests

    func testPIN_notEnabledByDefault() {
        let service = ContentFilterService.shared
        XCTAssertFalse(service.isPINProtectionEnabled)
    }

    func testPIN_setAndVerify() {
        let service = ContentFilterService.shared

        service.setPIN("1234")
        XCTAssertTrue(service.isPINProtectionEnabled)
        XCTAssertTrue(service.verifyPIN("1234"))
        XCTAssertFalse(service.verifyPIN("0000"))
    }

    func testPIN_remove() {
        let service = ContentFilterService.shared

        service.setPIN("1234")
        service.removePIN()

        XCTAssertFalse(service.isPINProtectionEnabled)
        XCTAssertTrue(service.verifyPIN("anything"))  // Should always pass when no PIN
    }

    // MARK: - Preferences Tests

    func testResetToDefaults() {
        let service = ContentFilterService.shared

        // Modify settings
        service.setFilteringEnabled(false)
        service.setLicenseFilteringEnabled(true)
        service.addBlockedCollection("custom")
        service.setPIN("1234")

        // Reset
        service.resetToDefaults()

        XCTAssertTrue(service.isFilteringEnabled)
        XCTAssertFalse(service.isLicenseFilteringEnabled)
        XCTAssertFalse(service.isPINProtectionEnabled)
    }
}
