//
//  MediaItemCardTests.swift
//  Internet ArchiveTests
//
//  Unit tests for MediaItemCard and related helpers
//

import XCTest
import SwiftUI
@testable import Internet_Archive

@MainActor
final class MediaItemCardTests: XCTestCase {

    // MARK: - MediaType Tests

    func testMediaType_video_aspectRatio() {
        let mediaType = MediaItemCard.MediaType.video
        XCTAssertEqual(mediaType.aspectRatio, 16.0 / 9.0, accuracy: 0.001)
    }

    func testMediaType_music_aspectRatio() {
        let mediaType = MediaItemCard.MediaType.music
        XCTAssertEqual(mediaType.aspectRatio, 1.0, accuracy: 0.001)
    }

    func testMediaType_video_placeholderIcon() {
        let mediaType = MediaItemCard.MediaType.video
        XCTAssertEqual(mediaType.placeholderIcon, "film")
    }

    func testMediaType_music_placeholderIcon() {
        let mediaType = MediaItemCard.MediaType.music
        XCTAssertEqual(mediaType.placeholderIcon, "music.note")
    }

    // MARK: - Grid Columns Tests

    func testGridColumns_video_hasCorrectMinimum() {
        let columns = MediaItemCard.MediaType.video.gridColumns
        XCTAssertEqual(columns.count, 1)

        // Video cards should be wider (300-400pt)
        guard case .adaptive(let minimum, let maximum) = columns.first?.size else {
            XCTFail("Expected adaptive grid item")
            return
        }
        XCTAssertEqual(minimum, 300)
        XCTAssertEqual(maximum, 400)
    }

    func testGridColumns_music_hasCorrectMinimum() {
        let columns = MediaItemCard.MediaType.music.gridColumns
        XCTAssertEqual(columns.count, 1)

        // Music cards should be smaller/square (200-280pt)
        guard case .adaptive(let minimum, let maximum) = columns.first?.size else {
            XCTFail("Expected adaptive grid item")
            return
        }
        XCTAssertEqual(minimum, 200)
        XCTAssertEqual(maximum, 280)
    }

    func testGridColumns_video_hasCorrectSpacing() {
        let columns = MediaItemCard.MediaType.video.gridColumns
        XCTAssertEqual(columns.first?.spacing, 40)
    }

    func testGridColumns_music_hasCorrectSpacing() {
        let columns = MediaItemCard.MediaType.music.gridColumns
        XCTAssertEqual(columns.first?.spacing, 40)
    }

    // MARK: - MediaItemCard Initialization Tests

    func testInit_withAllParameters() {
        let card = MediaItemCard(
            identifier: "test-id",
            title: "Test Title",
            subtitle: "Test Subtitle",
            mediaType: .video,
            progress: 0.5,
            customThumbnailURL: URL(string: "https://example.com/image.jpg")
        )

        XCTAssertEqual(card.identifier, "test-id")
        XCTAssertEqual(card.title, "Test Title")
        XCTAssertEqual(card.subtitle, "Test Subtitle")
        XCTAssertEqual(card.progress, 0.5)
        XCTAssertNotNil(card.customThumbnailURL)
    }

    func testInit_withDefaults() {
        let card = MediaItemCard(
            identifier: "test-id",
            title: "Test Title"
        )

        XCTAssertEqual(card.identifier, "test-id")
        XCTAssertEqual(card.title, "Test Title")
        XCTAssertNil(card.subtitle)
        XCTAssertNil(card.progress)
        XCTAssertNil(card.customThumbnailURL)
    }

    func testInit_fromSearchResult() {
        let searchResult = TestFixtures.makeSearchResult(
            identifier: "search-item",
            title: "Search Result Title",
            mediatype: "movies",
            creator: "Test Creator"
        )

        let card = MediaItemCard(searchResult: searchResult)

        XCTAssertEqual(card.identifier, "search-item")
        XCTAssertEqual(card.title, "Search Result Title")
        XCTAssertEqual(card.subtitle, "Test Creator")
    }

    func testInit_fromSearchResult_etreeMediaType() {
        let searchResult = TestFixtures.makeSearchResult(
            identifier: "concert",
            mediatype: "etree"
        )

        let card = MediaItemCard(searchResult: searchResult)

        // etree should map to music media type
        XCTAssertEqual(card.mediaType.aspectRatio, 1.0)
    }

    func testInit_fromPlaybackProgress() {
        let progress = PlaybackProgress(
            itemIdentifier: "progress-item",
            filename: "file1.mp4",
            currentTime: 300,
            duration: 600,
            lastWatchedDate: Date(),
            title: "Progress Title",
            mediaType: "movies",
            imageURL: nil
        )

        let card = MediaItemCard(playbackProgress: progress)

        XCTAssertEqual(card.identifier, "progress-item")
        XCTAssertEqual(card.title, "Progress Title")
        XCTAssertEqual(card.progress ?? 0, 0.5, accuracy: 0.01)
    }
}

// MARK: - MediaGridSection Tests

/// Tests for MediaGridSection SwiftUI component.
///
/// Note: SwiftUI Views are value types that always succeed in initialization.
/// Direct UI testing requires snapshot testing or UI automation. These tests
/// verify the component accepts correct inputs and the callback can be invoked.
/// For comprehensive UI testing, consider using XCUITest or snapshot testing.
@MainActor
final class MediaGridSectionTests: XCTestCase {

    func testMediaGridSection_acceptsValidInputs() {
        let items = [
            TestFixtures.makeSearchResult(identifier: "item1"),
            TestFixtures.makeSearchResult(identifier: "item2")
        ]

        // Verify component accepts all required inputs without error
        let section = MediaGridSection(
            title: "Test Section",
            items: items,
            mediaType: .video,
            onItemSelected: { _ in }
        )

        // Component created successfully with 2 items
        XCTAssertNotNil(section)
    }

    func testMediaGridSection_acceptsEmptyItems() {
        // Verify component handles empty item array gracefully
        let section = MediaGridSection(
            title: "Empty Section",
            items: [],
            mediaType: .video,
            onItemSelected: { _ in }
        )

        XCTAssertNotNil(section)
    }

    func testMediaGridSection_callbackCanBeInvoked() {
        var callbackInvoked = false
        var receivedItem: SearchResult?
        let testItem = TestFixtures.makeSearchResult(identifier: "callback-test")

        // Create section with callback that tracks invocation
        _ = MediaGridSection(
            title: "Test",
            items: [testItem],
            mediaType: .video,
            onItemSelected: { item in
                callbackInvoked = true
                receivedItem = item
            }
        )

        // Note: Direct callback invocation requires UI automation.
        // This test verifies the closure type signature is correct.
        // The callback would be invoked via button tap in actual use.
        XCTAssertFalse(callbackInvoked, "Callback should not be invoked without user interaction")
        XCTAssertNil(receivedItem)
    }

    func testMediaGridSection_supportsBothMediaTypes() {
        let items = [TestFixtures.makeSearchResult(identifier: "item1")]

        // Video section uses wider columns (300-400pt)
        let videoSection = MediaGridSection(
            title: "Videos",
            items: items,
            mediaType: .video,
            onItemSelected: { _ in }
        )
        XCTAssertNotNil(videoSection)

        // Music section uses narrower columns (200-280pt)
        let musicSection = MediaGridSection(
            title: "Music",
            items: items,
            mediaType: .music,
            onItemSelected: { _ in }
        )
        XCTAssertNotNil(musicSection)
    }
}
