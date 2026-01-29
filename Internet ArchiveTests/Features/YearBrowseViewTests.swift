//
//  YearBrowseViewTests.swift
//  Internet ArchiveTests
//
//  Tests for YearBrowseView-specific types
//  Note: YearsViewState tests are in YearsViewModelTests.swift
//  Note: MediaType.gridColumns tests are in MediaItemCardTests.swift
//

import XCTest
@testable import Internet_Archive

// MARK: - YearBrowseDestination Tests

/// Tests for YearBrowseDestination navigation type
final class YearBrowseDestinationTests: XCTestCase {

    func testYearBrowseDestination_isHashable() {
        let item = TestFixtures.movieSearchResult
        let destination1 = YearBrowseDestination(collection: item, mediaType: .video)
        let destination2 = YearBrowseDestination(collection: item, mediaType: .video)

        XCTAssertEqual(destination1, destination2)
    }

    func testYearBrowseDestination_differentMediaTypes_notEqual() {
        let item = TestFixtures.movieSearchResult
        let videoDestination = YearBrowseDestination(collection: item, mediaType: .video)
        let musicDestination = YearBrowseDestination(collection: item, mediaType: .music)

        XCTAssertNotEqual(videoDestination, musicDestination)
    }

    func testYearBrowseDestination_canBeUsedInSet() {
        let item = TestFixtures.movieSearchResult
        let destination = YearBrowseDestination(collection: item, mediaType: .video)

        var set: Set<YearBrowseDestination> = []
        set.insert(destination)

        XCTAssertEqual(set.count, 1)
        XCTAssertTrue(set.contains(destination))
    }

    func testYearBrowseDestination_differentCollections_notEqual() {
        let item1 = TestFixtures.makeSearchResult(identifier: "item1")
        let item2 = TestFixtures.makeSearchResult(identifier: "item2")
        let destination1 = YearBrowseDestination(collection: item1, mediaType: .video)
        let destination2 = YearBrowseDestination(collection: item2, mediaType: .video)

        XCTAssertNotEqual(destination1, destination2)
    }

    func testYearBrowseDestination_accessesCollection() {
        let item = TestFixtures.makeSearchResult(identifier: "test_collection", title: "Test Collection")
        let destination = YearBrowseDestination(collection: item, mediaType: .video)

        XCTAssertEqual(destination.collection.identifier, "test_collection")
        XCTAssertEqual(destination.mediaType, .video)
    }

    func testYearBrowseDestination_hashValue_consistency() {
        let item = TestFixtures.makeSearchResult(identifier: "hash_test")
        let destination = YearBrowseDestination(collection: item, mediaType: .video)

        // Same destination should have consistent hash
        let hash1 = destination.hashValue
        let hash2 = destination.hashValue
        XCTAssertEqual(hash1, hash2)
    }
}
