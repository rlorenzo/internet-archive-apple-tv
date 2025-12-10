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

    func testDefaultState_licenseFilteringDisabled() {
        let service = ContentFilterService.shared
        service.resetToDefaults()
        XCTAssertFalse(service.isLicenseFilteringEnabled, "License filtering should be disabled by default (most IA content lacks license metadata)")
    }

    // MARK: - Collection Filtering Tests (Always Active)

    func testShouldFilter_blockedCollection_noPreview() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Test Item",
            collection: ["no-preview", "movies"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        XCTAssertTrue(filterResult.isFiltered, "Items in no-preview collection should always be filtered")
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
        XCTAssertTrue(filterResult.isFiltered, "Items in hentai collection should always be filtered")
    }

    func testShouldFilter_blockedCollection_adultcdroms() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Test Item",
            collection: ["adultcdroms"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        XCTAssertTrue(filterResult.isFiltered, "Items in adultcdroms collection should always be filtered")
    }

    func testShouldFilter_allowedCollection_withLicense() {
        // Need to disable license filtering to test collection-only filtering
        let service = ContentFilterService.shared
        service.setLicenseFilteringEnabled(false)

        let result = SearchResult(
            identifier: "test-item",
            title: "Test Documentary",
            collection: ["movies", "documentary"]
        )

        let filterResult = service.shouldFilter(result)
        XCTAssertFalse(filterResult.isFiltered, "Items in normal collections should not be filtered when license filtering is off")
    }

    func testShouldFilter_allowedCollection_withOpenLicense() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Test Documentary",
            collection: ["movies", "documentary"],
            licenseurl: "https://creativecommons.org/licenses/by/4.0/"
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        XCTAssertFalse(filterResult.isFiltered, "Items with open license should not be filtered")
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

    // MARK: - Keyword Filtering Tests (Always Active)

    func testShouldFilter_blockedKeyword_xxx() {
        let result = SearchResult(
            identifier: "test-item",
            title: "XXX Video",
            collection: ["movies"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        XCTAssertTrue(filterResult.isFiltered, "Items with xxx in title should always be filtered")
    }

    func testShouldFilter_blockedKeyword_porn() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Some porn content",
            collection: ["movies"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        XCTAssertTrue(filterResult.isFiltered, "Items with porn in title should always be filtered")
    }

    func testShouldFilter_safeTitle() {
        // Disable license filtering to test keyword-only filtering
        let service = ContentFilterService.shared
        service.setLicenseFilteringEnabled(false)

        let result = SearchResult(
            identifier: "test-item",
            title: "Educational Documentary",
            collection: ["movies"]
        )

        let filterResult = service.shouldFilter(result)
        XCTAssertFalse(filterResult.isFiltered, "Items with safe titles should not be filtered")
    }

    // MARK: - License Filtering Tests (Optional)

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

    func testShouldFilter_licenseFiltering_disabled() {
        let service = ContentFilterService.shared
        service.setLicenseFilteringEnabled(false)

        let resultWithoutLicense = SearchResult(
            identifier: "test-item",
            title: "Test Item",
            collection: ["movies"],
            licenseurl: nil
        )

        XCTAssertFalse(service.shouldFilter(resultWithoutLicense).isFiltered, "Items without license should pass when license filtering is disabled")
    }

    // MARK: - Filter Array Tests

    func testFilter_removesBlockedItems() {
        // Disable license filtering to test collection filtering only
        let service = ContentFilterService.shared
        service.setLicenseFilteringEnabled(false)

        let results = [
            SearchResult(identifier: "1", title: "Safe Movie", collection: ["movies"]),
            SearchResult(identifier: "2", title: "Adult Content", collection: ["hentai"]),
            SearchResult(identifier: "3", title: "Another Safe Movie", collection: ["documentary"])
        ]

        let filtered = service.filter(results)
        XCTAssertEqual(filtered.count, 2, "Should filter out blocked items")
        XCTAssertTrue(filtered.allSatisfy { $0.identifier != "2" }, "Blocked item should be removed")
    }

    func testFilter_withLicenseFiltering() {
        let service = ContentFilterService.shared
        service.setLicenseFilteringEnabled(true)

        let results = [
            SearchResult(identifier: "1", title: "Licensed Movie", collection: ["movies"], licenseurl: "https://creativecommons.org/licenses/by/4.0/"),
            SearchResult(identifier: "2", title: "Unlicensed Movie", collection: ["movies"], licenseurl: nil),
            SearchResult(identifier: "3", title: "Adult Content", collection: ["hentai"], licenseurl: "https://creativecommons.org/licenses/by/4.0/")
        ]

        let filtered = service.filter(results)
        XCTAssertEqual(filtered.count, 1, "Should only keep licensed, non-adult content")
        XCTAssertEqual(filtered.first?.identifier, "1", "Only the licensed, safe item should remain")
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

    // MARK: - Query Building Tests

    func testBuildExclusionQuery() {
        let service = ContentFilterService.shared
        let query = service.buildExclusionQuery()

        XCTAssertTrue(query.contains("-collection:(no-preview)"), "Exclusion query should include no-preview")
        XCTAssertTrue(query.contains("-collection:(hentai)"), "Exclusion query should include hentai")
    }

    // MARK: - Statistics Tests

    func testFilterStatistics() {
        let service = ContentFilterService.shared
        service.setLicenseFilteringEnabled(false)  // Disable to test collection/keyword filtering only

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

    // MARK: - Preferences Tests

    func testResetToDefaults() {
        let service = ContentFilterService.shared

        // Modify settings
        service.setLicenseFilteringEnabled(true)

        // Reset
        service.resetToDefaults()

        XCTAssertFalse(service.isLicenseFilteringEnabled, "Default should have license filtering OFF")
    }

    func testSetLicenseFilteringEnabled() {
        let service = ContentFilterService.shared

        service.setLicenseFilteringEnabled(true)
        XCTAssertTrue(service.isLicenseFilteringEnabled)

        service.setLicenseFilteringEnabled(false)
        XCTAssertFalse(service.isLicenseFilteringEnabled)
    }
}
