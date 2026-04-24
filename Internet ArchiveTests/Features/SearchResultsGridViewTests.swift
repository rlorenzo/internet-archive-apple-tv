//
//  SearchResultsGridViewTests.swift
//  Internet ArchiveTests
//
//  Tests for SearchResultsDestination navigation type used by SearchResultsGridView.
//  View logic (pagination, grid layout, loading state) is tested in SearchResultsHelpersTests.
//

import Testing
@testable import Internet_Archive

// MARK: - SearchResultsGridView Tests

@Suite("SearchResultsGridView Tests")
struct SearchResultsGridViewTests {

    // MARK: - SearchResultsDestination Equality

    @Test func destinationStoresProperties() {
        let destination = SearchResultsDestination(query: "nature", mediaType: .video)
        #expect(destination.query == "nature")
        #expect(destination.mediaType == .video)
    }

    @Test func destinationEqualityWithSameValues() {
        let destination1 = SearchResultsDestination(query: "nature", mediaType: .video)
        let destination2 = SearchResultsDestination(query: "nature", mediaType: .video)
        #expect(destination1 == destination2)
    }

    @Test func destinationInequalityWithDifferentQuery() {
        let destination1 = SearchResultsDestination(query: "nature", mediaType: .video)
        let destination2 = SearchResultsDestination(query: "science", mediaType: .video)
        #expect(destination1 != destination2)
    }

    @Test func destinationInequalityWithDifferentMediaType() {
        let destination1 = SearchResultsDestination(query: "nature", mediaType: .video)
        let destination2 = SearchResultsDestination(query: "nature", mediaType: .music)
        #expect(destination1 != destination2)
    }

    @Test func destinationCanBeUsedAsDictionaryKey() {
        let destination = SearchResultsDestination(query: "nature", mediaType: .video)
        var dict: [SearchResultsDestination: Int] = [:]
        dict[destination] = 42
        #expect(dict[destination] == 42)
    }

    @Test func destinationCanBeUsedInSet() {
        let destination1 = SearchResultsDestination(query: "nature", mediaType: .video)
        let destination2 = SearchResultsDestination(query: "jazz", mediaType: .music)

        var set: Set<SearchResultsDestination> = []
        set.insert(destination1)
        set.insert(destination2)

        #expect(set.count == 2)
        #expect(set.contains(destination1))
        #expect(set.contains(destination2))
    }

    @Test func destinationDuplicateInSetIgnored() {
        let destination1 = SearchResultsDestination(query: "nature", mediaType: .video)
        let destination2 = SearchResultsDestination(query: "nature", mediaType: .video)

        var set: Set<SearchResultsDestination> = []
        set.insert(destination1)
        set.insert(destination2)

        #expect(set.count == 1)
    }

    @Test func destinationHashConsistency() {
        let destination = SearchResultsDestination(query: "nature", mediaType: .video)
        let hash1 = destination.hashValue
        let hash2 = destination.hashValue
        #expect(hash1 == hash2)
    }
}
