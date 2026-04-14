//
//  CollectionSortOptionTests.swift
//  Internet ArchiveTests
//
//  Tests for CollectionSortOption enum
//

import Testing
@testable import Internet_Archive

struct CollectionSortOptionTests {

    @Test func allCases_containsThreeOptions() {
        #expect(CollectionSortOption.allCases.count == 3)
    }

    @Test func displayNames() {
        #expect(CollectionSortOption.weeklyViews.displayName == "Week")
        #expect(CollectionSortOption.monthlyViews.displayName == "Month")
        #expect(CollectionSortOption.allTimeDownloads.displayName == "All Time")
    }

    @Test func apiSortStrings() {
        #expect(CollectionSortOption.weeklyViews.apiSortString == "week desc")
        #expect(CollectionSortOption.monthlyViews.apiSortString == "month desc")
        #expect(CollectionSortOption.allTimeDownloads.apiSortString == "downloads desc")
    }

    @Test func identifiable_uniqueIds() {
        let ids = CollectionSortOption.allCases.map(\.id)
        #expect(Set(ids).count == 3)
    }
}
