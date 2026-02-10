//
//  YearBrowseViewTests.swift
//  Internet ArchiveTests
//
//  Tests for YearBrowseView-specific types and state logic
//  Migrated from XCTest to Swift Testing
//  Note: YearsViewState tests are in YearsViewModelTests.swift
//  Note: MediaType.gridColumns tests are in MediaItemCardTests.swift
//

import Testing
@testable import Internet_Archive

// MARK: - YearBrowseDestination Tests

/// Tests for YearBrowseDestination navigation type
@Suite("YearBrowseDestination Tests")
struct YearBrowseDestinationTests {

    @Test func isHashable() {
        let item = TestFixtures.movieSearchResult
        let destination1 = YearBrowseDestination(collection: item, mediaType: .video)
        let destination2 = YearBrowseDestination(collection: item, mediaType: .video)

        #expect(destination1 == destination2)
    }

    @Test func differentMediaTypesNotEqual() {
        let item = TestFixtures.movieSearchResult
        let videoDestination = YearBrowseDestination(collection: item, mediaType: .video)
        let musicDestination = YearBrowseDestination(collection: item, mediaType: .music)

        #expect(videoDestination != musicDestination)
    }

    @Test func canBeUsedInSet() {
        let item = TestFixtures.movieSearchResult
        let destination = YearBrowseDestination(collection: item, mediaType: .video)

        var set: Set<YearBrowseDestination> = []
        set.insert(destination)

        #expect(set.count == 1)
        #expect(set.contains(destination))
    }

    @Test func differentCollectionsNotEqual() {
        let item1 = TestFixtures.makeSearchResult(identifier: "item1")
        let item2 = TestFixtures.makeSearchResult(identifier: "item2")
        let destination1 = YearBrowseDestination(collection: item1, mediaType: .video)
        let destination2 = YearBrowseDestination(collection: item2, mediaType: .video)

        #expect(destination1 != destination2)
    }

    @Test func accessesCollection() {
        let item = TestFixtures.makeSearchResult(identifier: "test_collection", title: "Test Collection")
        let destination = YearBrowseDestination(collection: item, mediaType: .video)

        #expect(destination.collection.identifier == "test_collection")
        #expect(destination.mediaType == .video)
    }

    @Test func hashValueConsistency() {
        let item = TestFixtures.makeSearchResult(identifier: "hash_test")
        let destination = YearBrowseDestination(collection: item, mediaType: .video)

        // Same destination should have consistent hash
        let hash1 = destination.hashValue
        let hash2 = destination.hashValue
        #expect(hash1 == hash2)
    }

    @Test func duplicateInsertIntoSetIgnored() {
        let item = TestFixtures.movieSearchResult
        let destination1 = YearBrowseDestination(collection: item, mediaType: .video)
        let destination2 = YearBrowseDestination(collection: item, mediaType: .video)

        var set: Set<YearBrowseDestination> = []
        set.insert(destination1)
        set.insert(destination2)

        #expect(set.count == 1)
    }

    @Test func distinctDestinationsInSet() {
        let item1 = TestFixtures.makeSearchResult(identifier: "item_a")
        let item2 = TestFixtures.makeSearchResult(identifier: "item_b")
        let destination1 = YearBrowseDestination(collection: item1, mediaType: .video)
        let destination2 = YearBrowseDestination(collection: item2, mediaType: .music)

        var set: Set<YearBrowseDestination> = []
        set.insert(destination1)
        set.insert(destination2)

        #expect(set.count == 2)
    }

    @Test func accessesMediaType() {
        let item = TestFixtures.movieSearchResult
        let videoDestination = YearBrowseDestination(collection: item, mediaType: .video)
        let musicDestination = YearBrowseDestination(collection: item, mediaType: .music)

        #expect(videoDestination.mediaType == .video)
        #expect(musicDestination.mediaType == .music)
    }
}

// MARK: - YearsViewState Driven Tests

/// Tests for YearsViewState computed properties and state transitions
/// that are relevant to YearBrowseView rendering logic
@Suite("YearsViewState Rendering Logic Tests")
struct YearsViewStateRenderingTests {

    @Test func initialStateShowsLoading() {
        var state = YearsViewState.initial
        state.isLoading = true

        #expect(state.isLoading)
        #expect(!state.hasYears)
        #expect(state.errorMessage == nil)
    }

    @Test func loadedStateWithYears() {
        var state = YearsViewState.initial
        state.sortedKeys = ["2024", "2023", "2022"]
        state.sortedData = [
            "2024": [TestFixtures.makeSearchResult(identifier: "a", year: "2024")],
            "2023": [TestFixtures.makeSearchResult(identifier: "b", year: "2023")],
            "2022": [TestFixtures.makeSearchResult(identifier: "c", year: "2022")]
        ]

        #expect(state.hasYears)
        #expect(state.yearsCount == 3)
        #expect(!state.isLoading)
    }

    @Test func errorStateHasMessage() {
        var state = YearsViewState.initial
        state.errorMessage = "Network error occurred"

        #expect(state.errorMessage != nil)
        #expect(state.errorMessage == "Network error occurred")
        #expect(!state.hasYears)
    }

    @Test func emptyStateHasNoYears() {
        let state = YearsViewState.initial

        #expect(!state.hasYears)
        #expect(state.yearsCount == 0)
        #expect(state.selectedYear == nil)
        #expect(state.selectedYearItems.isEmpty)
        #expect(state.selectedYearItemCount == 0)
    }

    @Test func selectedYearReturnsCorrectYear() {
        var state = YearsViewState.initial
        state.sortedKeys = ["2024", "2023", "2022"]
        state.selectedYearIndex = 0

        #expect(state.selectedYear == "2024")

        state.selectedYearIndex = 2
        #expect(state.selectedYear == "2022")
    }

    @Test func selectedYearOutOfBoundsReturnsNil() {
        var state = YearsViewState.initial
        state.sortedKeys = ["2024"]
        state.selectedYearIndex = 5

        #expect(state.selectedYear == nil)
    }

    @Test func selectedYearItemsReturnsItemsForSelectedYear() {
        let items2024 = [
            TestFixtures.makeSearchResult(identifier: "item1", year: "2024"),
            TestFixtures.makeSearchResult(identifier: "item2", year: "2024")
        ]
        let items2023 = [
            TestFixtures.makeSearchResult(identifier: "item3", year: "2023")
        ]

        var state = YearsViewState.initial
        state.sortedKeys = ["2024", "2023"]
        state.sortedData = ["2024": items2024, "2023": items2023]
        state.selectedYearIndex = 0

        #expect(state.selectedYearItems.count == 2)
        #expect(state.selectedYearItemCount == 2)

        state.selectedYearIndex = 1
        #expect(state.selectedYearItems.count == 1)
        #expect(state.selectedYearItemCount == 1)
    }

    @Test func configureStateUpdatesFields() {
        var state = YearsViewState.initial
        state.name = "Grateful Dead"
        state.identifier = "GratefulDead"
        state.collection = "etree"

        #expect(state.name == "Grateful Dead")
        #expect(state.identifier == "GratefulDead")
        #expect(state.collection == "etree")
    }

    @Test func stateTransitionFromLoadingToLoaded() {
        var state = YearsViewState.initial
        state.isLoading = true
        #expect(state.isLoading)

        // Simulate load completion
        state.isLoading = false
        state.sortedKeys = ["2024", "2023"]
        state.sortedData = [
            "2024": [TestFixtures.makeSearchResult(identifier: "a", year: "2024")],
            "2023": [TestFixtures.makeSearchResult(identifier: "b", year: "2023")]
        ]
        state.selectedYearIndex = 0

        #expect(!state.isLoading)
        #expect(state.hasYears)
        #expect(state.selectedYear == "2024")
    }

    @Test func stateTransitionFromLoadingToError() {
        var state = YearsViewState.initial
        state.isLoading = true
        #expect(state.isLoading)

        // Simulate error
        state.isLoading = false
        state.errorMessage = "Connection timed out"

        #expect(!state.isLoading)
        #expect(!state.hasYears)
        #expect(state.errorMessage == "Connection timed out")
    }

    @Test func clearErrorResetsErrorMessage() {
        var state = YearsViewState.initial
        state.errorMessage = "Some error"
        #expect(state.errorMessage != nil)

        state.errorMessage = nil
        #expect(state.errorMessage == nil)
    }

    @Test func undatedItemsGroupedCorrectly() {
        var state = YearsViewState.initial
        state.sortedKeys = ["2024", "Undated"]
        state.sortedData = [
            "2024": [TestFixtures.makeSearchResult(identifier: "dated", year: "2024")],
            "Undated": [
                TestFixtures.makeSearchResult(identifier: "undated1", year: nil),
                TestFixtures.makeSearchResult(identifier: "undated2", year: nil)
            ]
        ]
        state.selectedYearIndex = 1

        #expect(state.selectedYear == "Undated")
        #expect(state.selectedYearItems.count == 2)
    }
}
