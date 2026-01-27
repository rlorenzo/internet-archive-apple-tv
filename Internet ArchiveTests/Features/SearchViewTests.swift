//
//  SearchViewTests.swift
//  Internet ArchiveTests
//
//  Unit tests for SearchView and its ContentFilter enum
//

import XCTest
import SwiftUI
@testable import Internet_Archive

/// Tests for SearchView's ContentFilter enum and related functionality.
///
/// Note: Full SwiftUI view testing requires UI automation or specialized tools.
/// These tests focus on the testable business logic extracted from the view.
@MainActor
final class SearchViewContentFilterTests: XCTestCase {

    // MARK: - ContentFilter Enum Tests

    func testContentFilter_allCases() {
        let allCases = SearchView.ContentFilter.allCases

        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.all))
        XCTAssertTrue(allCases.contains(.videos))
        XCTAssertTrue(allCases.contains(.music))
    }

    func testContentFilter_rawValues() {
        XCTAssertEqual(SearchView.ContentFilter.all.rawValue, "all")
        XCTAssertEqual(SearchView.ContentFilter.videos.rawValue, "videos")
        XCTAssertEqual(SearchView.ContentFilter.music.rawValue, "music")
    }

    func testContentFilter_identifiableConformance() {
        // Verify each filter's id matches its rawValue
        XCTAssertEqual(SearchView.ContentFilter.all.id, "all")
        XCTAssertEqual(SearchView.ContentFilter.videos.id, "videos")
        XCTAssertEqual(SearchView.ContentFilter.music.id, "music")
    }

    // MARK: - Display Name Tests

    func testContentFilter_displayName_all() {
        XCTAssertEqual(SearchView.ContentFilter.all.displayName, "All")
    }

    func testContentFilter_displayName_videos() {
        XCTAssertEqual(SearchView.ContentFilter.videos.displayName, "Videos")
    }

    func testContentFilter_displayName_music() {
        XCTAssertEqual(SearchView.ContentFilter.music.displayName, "Music")
    }

    // MARK: - API Media Type Tests

    func testContentFilter_apiMediaType_all() {
        let mediaType = SearchView.ContentFilter.all.apiMediaType

        // "All" should query multiple media types
        XCTAssertTrue(mediaType.contains("movies"))
        XCTAssertTrue(mediaType.contains("etree"))
        XCTAssertTrue(mediaType.contains("audio"))
        XCTAssertTrue(mediaType.contains("OR"))
    }

    func testContentFilter_apiMediaType_videos() {
        let mediaType = SearchView.ContentFilter.videos.apiMediaType

        XCTAssertEqual(mediaType, "movies")
    }

    func testContentFilter_apiMediaType_music() {
        let mediaType = SearchView.ContentFilter.music.apiMediaType

        // Music includes both etree (live music) and audio
        XCTAssertTrue(mediaType.contains("etree"))
        XCTAssertTrue(mediaType.contains("audio"))
        XCTAssertTrue(mediaType.contains("OR"))
    }

    // MARK: - API Media Type Format Tests

    func testContentFilter_apiMediaType_canBeUsedInQuery() {
        // Verify the apiMediaType values can be inserted into API queries
        for filter in SearchView.ContentFilter.allCases {
            let query = "test AND mediatype:(\(filter.apiMediaType))"

            // Should be a valid query string (no syntax issues)
            XCTAssertFalse(query.isEmpty)
            XCTAssertTrue(query.contains("mediatype:"))
        }
    }

    // MARK: - Equatable/Hashable Tests

    func testContentFilter_equality() {
        XCTAssertEqual(SearchView.ContentFilter.all, SearchView.ContentFilter.all)
        XCTAssertNotEqual(SearchView.ContentFilter.all, SearchView.ContentFilter.videos)
        XCTAssertNotEqual(SearchView.ContentFilter.videos, SearchView.ContentFilter.music)
    }

    func testContentFilter_hashable_canBeUsedInSet() {
        var filterSet: Set<SearchView.ContentFilter> = []

        filterSet.insert(.all)
        filterSet.insert(.videos)
        filterSet.insert(.all) // Duplicate

        XCTAssertEqual(filterSet.count, 2)
    }

    func testContentFilter_hashable_canBeUsedAsDictionaryKey() {
        var dict: [SearchView.ContentFilter: String] = [:]

        dict[.all] = "All Content"
        dict[.videos] = "Video Content"
        dict[.music] = "Music Content"

        XCTAssertEqual(dict[.all], "All Content")
        XCTAssertEqual(dict[.videos], "Video Content")
        XCTAssertEqual(dict[.music], "Music Content")
    }
}

// MARK: - SearchResultsDestination Tests

/// Tests for SearchResultsDestination navigation model.
final class SearchResultsDestinationTests: XCTestCase {

    func testInit_setsAllProperties() {
        let destination = SearchResultsDestination(
            title: "Videos",
            query: "test query",
            mediaType: .video
        )

        XCTAssertEqual(destination.title, "Videos")
        XCTAssertEqual(destination.query, "test query")
        XCTAssertEqual(destination.mediaType, .video)
    }

    func testInit_withMusicMediaType() {
        let destination = SearchResultsDestination(
            title: "Music",
            query: "concert",
            mediaType: .music
        )

        XCTAssertEqual(destination.mediaType, .music)
    }

    func testHashable_conformance() {
        let destination1 = SearchResultsDestination(title: "Test", query: "q", mediaType: .video)
        let destination2 = SearchResultsDestination(title: "Test", query: "q", mediaType: .video)
        let destination3 = SearchResultsDestination(title: "Different", query: "q", mediaType: .video)

        XCTAssertEqual(destination1, destination2)
        XCTAssertNotEqual(destination1, destination3)
    }

    func testHashable_canBeUsedInNavigationPath() {
        var destinations: Set<SearchResultsDestination> = []

        destinations.insert(SearchResultsDestination(title: "A", query: "1", mediaType: .video))
        destinations.insert(SearchResultsDestination(title: "B", query: "2", mediaType: .music))

        XCTAssertEqual(destinations.count, 2)
    }
}

// MARK: - Notification Name Tests

/// Tests for SearchView-related notification names.
@MainActor
final class SearchNotificationTests: XCTestCase {

    func testPopSearchNavigation_notificationExists() {
        let notification = Notification.Name.popSearchNavigation

        XCTAssertEqual(notification.rawValue, "popSearchNavigation")
    }

    func testPopSearchNavigation_canBePosted() {
        let expectation = self.expectation(description: "Notification received")

        let observer = NotificationCenter.default.addObserver(
            forName: .popSearchNavigation,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        NotificationCenter.default.post(name: .popSearchNavigation, object: nil)

        waitForExpectations(timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
}
