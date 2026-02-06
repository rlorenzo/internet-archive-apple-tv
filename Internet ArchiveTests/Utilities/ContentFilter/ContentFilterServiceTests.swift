//
//  ContentFilterServiceTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ContentFilterService
//

import Testing
@testable import Internet_Archive

@Suite("ContentFilterService Tests", .serialized)
@MainActor
struct ContentFilterServiceTests {

    init() {
        // Reset to defaults before each test
        ContentFilterService.shared.resetToDefaults()
        ContentFilterService.shared.resetStatistics()
    }

    // MARK: - Singleton Tests

    @Test func sharedInstanceExists() {
        let service = ContentFilterService.shared
        #expect(service != nil)
    }

    @Test func sharedInstanceIsSingleton() {
        let service1 = ContentFilterService.shared
        let service2 = ContentFilterService.shared
        #expect(service1 === service2)
    }

    // MARK: - Default State Tests

    @Test func defaultStateLicenseFilteringDisabled() {
        let service = ContentFilterService.shared
        service.resetToDefaults()
        #expect(!service.isLicenseFilteringEnabled, "License filtering should be disabled by default (most IA content lacks license metadata)")
    }

    // MARK: - Collection Filtering Tests (Always Active)

    @Test func shouldFilterBlockedCollectionNoPreview() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Test Item",
            collection: ["no-preview", "movies"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        #expect(filterResult.isFiltered, "Items in no-preview collection should always be filtered")
        if case .blockedCollection(let collection) = filterResult.reason {
            #expect(collection == "no-preview")
        } else {
            Issue.record("Expected blockedCollection reason")
        }
    }

    @Test func shouldFilterBlockedCollectionHentai() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Test Item",
            collection: ["hentai"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        #expect(filterResult.isFiltered, "Items in hentai collection should always be filtered")
    }

    @Test func shouldFilterBlockedCollectionAdultcdroms() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Test Item",
            collection: ["adultcdroms"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        #expect(filterResult.isFiltered, "Items in adultcdroms collection should always be filtered")
    }

    @Test func shouldFilterAllowedCollectionWithLicense() {
        // Need to disable license filtering to test collection-only filtering
        let service = ContentFilterService.shared
        service.setLicenseFilteringEnabled(false)

        let result = SearchResult(
            identifier: "test-item",
            title: "Test Documentary",
            collection: ["movies", "documentary"]
        )

        let filterResult = service.shouldFilter(result)
        #expect(!filterResult.isFiltered, "Items in normal collections should not be filtered when license filtering is off")
    }

    @Test func shouldFilterAllowedCollectionWithOpenLicense() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Test Documentary",
            collection: ["movies", "documentary"],
            licenseurl: "https://creativecommons.org/licenses/by/4.0/"
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        #expect(!filterResult.isFiltered, "Items with open license should not be filtered")
    }

    @Test func shouldFilterCaseInsensitive() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Test Item",
            collection: ["HENTAI"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        #expect(filterResult.isFiltered, "Collection filtering should be case-insensitive")
    }

    // MARK: - Keyword Filtering Tests (Always Active)

    @Test func shouldFilterBlockedKeywordXxx() {
        let result = SearchResult(
            identifier: "test-item",
            title: "XXX Video",
            collection: ["movies"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        #expect(filterResult.isFiltered, "Items with xxx in title should always be filtered")
    }

    @Test func shouldFilterBlockedKeywordPorn() {
        let result = SearchResult(
            identifier: "test-item",
            title: "Some porn content",
            collection: ["movies"]
        )

        let filterResult = ContentFilterService.shared.shouldFilter(result)
        #expect(filterResult.isFiltered, "Items with porn in title should always be filtered")
    }

    @Test func shouldFilterSafeTitle() {
        // Disable license filtering to test keyword-only filtering
        let service = ContentFilterService.shared
        service.setLicenseFilteringEnabled(false)

        let result = SearchResult(
            identifier: "test-item",
            title: "Educational Documentary",
            collection: ["movies"]
        )

        let filterResult = service.shouldFilter(result)
        #expect(!filterResult.isFiltered, "Items with safe titles should not be filtered")
    }

    // MARK: - License Filtering Tests (Optional)

    @Test func isOpenLicenseCreativeCommonsPublicDomain() {
        let service = ContentFilterService.shared

        #expect(service.isOpenLicense("https://creativecommons.org/publicdomain/zero/1.0/"))
        #expect(service.isOpenLicense("http://creativecommons.org/publicdomain/mark/1.0/"))
        // Legacy public domain URL format used by older Internet Archive items
        #expect(service.isOpenLicense("http://creativecommons.org/licenses/publicdomain/"))
    }

    @Test func isOpenLicenseCreativeCommonsBy() {
        let service = ContentFilterService.shared

        #expect(service.isOpenLicense("https://creativecommons.org/licenses/by/4.0/"))
        #expect(service.isOpenLicense("https://creativecommons.org/licenses/by-sa/4.0/"))
        #expect(service.isOpenLicense("https://creativecommons.org/licenses/by-nc/4.0/"))
        #expect(service.isOpenLicense("https://creativecommons.org/licenses/by-nc-sa/4.0/"))
        #expect(service.isOpenLicense("https://creativecommons.org/licenses/by-nd/4.0/"))
        #expect(service.isOpenLicense("https://creativecommons.org/licenses/by-nc-nd/4.0/"))
    }

    @Test func isOpenLicenseUnknownLicense() {
        let service = ContentFilterService.shared

        #expect(!service.isOpenLicense("https://example.com/license"))
        #expect(!service.isOpenLicense("all rights reserved"))
    }

    @Test func getLicenseTypePublicDomain() {
        let service = ContentFilterService.shared

        #expect(service.getLicenseType("https://creativecommons.org/publicdomain/zero/1.0/") == "CC0 (Public Domain)")
        #expect(service.getLicenseType("https://creativecommons.org/publicdomain/mark/1.0/") == "Public Domain")
        // Legacy public domain URL format used by older Internet Archive items
        #expect(service.getLicenseType("http://creativecommons.org/licenses/publicdomain/") == "Public Domain")
    }

    @Test func getLicenseTypeCreativeCommons() {
        let service = ContentFilterService.shared

        #expect(service.getLicenseType("https://creativecommons.org/licenses/by/4.0/") == "CC BY")
        #expect(service.getLicenseType("https://creativecommons.org/licenses/by-sa/4.0/") == "CC BY-SA")
        #expect(service.getLicenseType("https://creativecommons.org/licenses/by-nc/4.0/") == "CC BY-NC")
        #expect(service.getLicenseType("https://creativecommons.org/licenses/by-nc-sa/4.0/") == "CC BY-NC-SA")
    }

    @Test func shouldFilterLicenseFilteringEnabled() {
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

        #expect(!service.shouldFilter(resultWithLicense).isFiltered, "Items with open license should pass")
        #expect(service.shouldFilter(resultWithoutLicense).isFiltered, "Items without license should be filtered when license filtering is enabled")
        #expect(service.shouldFilter(resultWithRestrictedLicense).isFiltered, "Items with restricted license should be filtered")
    }

    @Test func shouldFilterLicenseFilteringDisabled() {
        let service = ContentFilterService.shared
        service.setLicenseFilteringEnabled(false)

        let resultWithoutLicense = SearchResult(
            identifier: "test-item",
            title: "Test Item",
            collection: ["movies"],
            licenseurl: nil
        )

        #expect(!service.shouldFilter(resultWithoutLicense).isFiltered, "Items without license should pass when license filtering is disabled")
    }

    // MARK: - Filter Array Tests

    @Test func filterRemovesBlockedItems() {
        // Disable license filtering to test collection filtering only
        let service = ContentFilterService.shared
        service.setLicenseFilteringEnabled(false)

        let results = [
            SearchResult(identifier: "1", title: "Safe Movie", collection: ["movies"]),
            SearchResult(identifier: "2", title: "Adult Content", collection: ["hentai"]),
            SearchResult(identifier: "3", title: "Another Safe Movie", collection: ["documentary"])
        ]

        let filtered = service.filter(results)
        #expect(filtered.count == 2, "Should filter out blocked items")
        #expect(filtered.allSatisfy { $0.identifier != "2" }, "Blocked item should be removed")
    }

    @Test func filterWithLicenseFiltering() {
        let service = ContentFilterService.shared
        service.setLicenseFilteringEnabled(true)

        let results = [
            SearchResult(identifier: "1", title: "Licensed Movie", collection: ["movies"], licenseurl: "https://creativecommons.org/licenses/by/4.0/"),
            SearchResult(identifier: "2", title: "Unlicensed Movie", collection: ["movies"], licenseurl: nil),
            SearchResult(identifier: "3", title: "Adult Content", collection: ["hentai"], licenseurl: "https://creativecommons.org/licenses/by/4.0/")
        ]

        let filtered = service.filter(results)
        #expect(filtered.count == 1, "Should only keep licensed, non-adult content")
        #expect(filtered.first?.identifier == "1", "Only the licensed, safe item should remain")
    }

    // MARK: - Collection Blocking Tests

    @Test func isCollectionBlocked() {
        let service = ContentFilterService.shared

        #expect(service.isCollectionBlocked("no-preview"))
        #expect(service.isCollectionBlocked("hentai"))
        #expect(service.isCollectionBlocked("adultcdroms"))
        #expect(service.isCollectionBlocked("NO-PREVIEW"))  // Case insensitive
        #expect(!service.isCollectionBlocked("movies"))
        #expect(!service.isCollectionBlocked("documentary"))
    }

    @Test func hasContentWarning() {
        let service = ContentFilterService.shared

        #expect(service.hasContentWarning(["movies", "no-preview"]))
        #expect(service.hasContentWarning(["No-Preview"]))  // Case insensitive
        #expect(!service.hasContentWarning(["movies", "documentary"]))
    }

    // MARK: - Query Building Tests

    @Test func buildExclusionQuery() {
        let service = ContentFilterService.shared
        let query = service.buildExclusionQuery()

        #expect(query.contains("-collection:(no-preview)"), "Exclusion query should include no-preview")
        #expect(query.contains("-collection:(hentai)"), "Exclusion query should include hentai")
    }

    // MARK: - Statistics Tests

    @Test func filterStatistics() {
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
        #expect(stats.totalItemsChecked == 3)
        #expect(stats.totalItemsFiltered == 2)
        #expect(stats.filterPercentage > 60 && stats.filterPercentage < 70)
    }

    @Test func resetStatistics() {
        let service = ContentFilterService.shared

        // Generate some stats
        let result = SearchResult(identifier: "1", title: "Test", collection: ["hentai"])
        _ = service.shouldFilter(result)

        // Reset
        service.resetStatistics()

        let stats = service.filterStatistics
        #expect(stats.totalItemsChecked == 0)
        #expect(stats.totalItemsFiltered == 0)
    }

    // MARK: - Preferences Tests

    @Test func resetToDefaults() {
        let service = ContentFilterService.shared

        // Modify settings
        service.setLicenseFilteringEnabled(true)

        // Reset
        service.resetToDefaults()

        #expect(!service.isLicenseFilteringEnabled, "Default should have license filtering OFF")
    }

    @Test func setLicenseFilteringEnabled() {
        let service = ContentFilterService.shared

        service.setLicenseFilteringEnabled(true)
        #expect(service.isLicenseFilteringEnabled)

        service.setLicenseFilteringEnabled(false)
        #expect(!service.isLicenseFilteringEnabled)
    }
}
