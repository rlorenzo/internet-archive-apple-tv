//
//  SharedViewsTests.swift
//  Internet ArchiveTests
//
//  Unit tests for shared feature views (MediaThumbnailView, MediaHomeErrorView, ItemDetailPlaceholderView)
//

import XCTest
import SwiftUI
@testable import Internet_Archive

@MainActor
final class SharedViewsTests: XCTestCase {

    // MARK: - MediaThumbnailView Tests

    // MARK: Initialization

    func testMediaThumbnailView_initWithVideoType() {
        let view = MediaThumbnailView(
            identifier: "test-video",
            mediaType: .video,
            size: CGSize(width: 380, height: 214)
        )

        XCTAssertEqual(view.identifier, "test-video")
        XCTAssertEqual(view.size.width, 380)
        XCTAssertEqual(view.size.height, 214)
    }

    func testMediaThumbnailView_initWithMusicType() {
        let view = MediaThumbnailView(
            identifier: "test-music",
            mediaType: .music,
            size: CGSize(width: 220, height: 220)
        )

        XCTAssertEqual(view.identifier, "test-music")
        XCTAssertEqual(view.size.width, 220)
    }

    func testMediaThumbnailView_defaultCornerRadius() {
        let view = MediaThumbnailView(
            identifier: "test",
            mediaType: .video,
            size: CGSize(width: 100, height: 100)
        )

        XCTAssertEqual(view.cornerRadius, 12)
    }

    func testMediaThumbnailView_customCornerRadius() {
        var view = MediaThumbnailView(
            identifier: "test",
            mediaType: .video,
            size: CGSize(width: 100, height: 100)
        )
        view.cornerRadius = 20

        XCTAssertEqual(view.cornerRadius, 20)
    }

    func testMediaThumbnailView_zeroCornerRadius() {
        var view = MediaThumbnailView(
            identifier: "test",
            mediaType: .video,
            size: CGSize(width: 100, height: 100)
        )
        view.cornerRadius = 0

        XCTAssertEqual(view.cornerRadius, 0)
    }

    // MARK: Size Tests

    func testMediaThumbnailView_squareSize() {
        let view = MediaThumbnailView(
            identifier: "test",
            mediaType: .music,
            size: CGSize(width: 200, height: 200)
        )

        XCTAssertEqual(view.size.width, view.size.height)
    }

    func testMediaThumbnailView_wideSize() {
        let view = MediaThumbnailView(
            identifier: "test",
            mediaType: .video,
            size: CGSize(width: 1920, height: 1080)
        )

        XCTAssertEqual(view.size.width, 1920)
        XCTAssertEqual(view.size.height, 1080)
    }

    func testMediaThumbnailView_smallSize() {
        let view = MediaThumbnailView(
            identifier: "test",
            mediaType: .video,
            size: CGSize(width: 50, height: 30)
        )

        XCTAssertEqual(view.size.width, 50)
        XCTAssertEqual(view.size.height, 30)
    }

    // MARK: Identifier Tests

    func testMediaThumbnailView_emptyIdentifier() {
        let view = MediaThumbnailView(
            identifier: "",
            mediaType: .video,
            size: CGSize(width: 100, height: 100)
        )

        XCTAssertEqual(view.identifier, "")
    }

    func testMediaThumbnailView_specialCharactersInIdentifier() {
        let view = MediaThumbnailView(
            identifier: "test-item_2024.v1",
            mediaType: .video,
            size: CGSize(width: 100, height: 100)
        )

        XCTAssertEqual(view.identifier, "test-item_2024.v1")
    }

    func testMediaThumbnailView_longIdentifier() {
        let longId = String(repeating: "a", count: 200)
        let view = MediaThumbnailView(
            identifier: longId,
            mediaType: .video,
            size: CGSize(width: 100, height: 100)
        )

        XCTAssertEqual(view.identifier, longId)
    }

    // MARK: - MediaHomeErrorView Tests

    // MARK: Initialization

    func testMediaHomeErrorView_init() {
        var retryCount = 0
        let view = MediaHomeErrorView(
            message: "Test error message",
            onRetry: { retryCount += 1 }
        )

        XCTAssertEqual(view.message, "Test error message")
    }

    func testMediaHomeErrorView_emptyMessage() {
        let view = MediaHomeErrorView(
            message: "",
            onRetry: {}
        )

        XCTAssertEqual(view.message, "")
    }

    func testMediaHomeErrorView_longMessage() {
        let longMessage = String(repeating: "Error occurred. ", count: 50)
        let view = MediaHomeErrorView(
            message: longMessage,
            onRetry: {}
        )

        XCTAssertEqual(view.message, longMessage)
    }

    func testMediaHomeErrorView_specialCharactersInMessage() {
        let message = "Error: Unable to load content™ & other items <test>"
        let view = MediaHomeErrorView(
            message: message,
            onRetry: {}
        )

        XCTAssertEqual(view.message, message)
    }

    // MARK: - ItemDetailPlaceholderView Tests

    // MARK: Initialization

    func testItemDetailPlaceholderView_initWithVideoType() {
        let item = SearchResult(
            identifier: "test-id",
            title: "Test Title",
            creator: "Test Creator"
        )

        let view = ItemDetailPlaceholderView(item: item, mediaType: .video)

        XCTAssertNotNil(view)
    }

    func testItemDetailPlaceholderView_initWithMusicType() {
        let item = SearchResult(
            identifier: "test-id",
            title: "Test Title",
            creator: "Test Creator",
            year: "2024"
        )

        let view = ItemDetailPlaceholderView(item: item, mediaType: .music)

        XCTAssertNotNil(view)
    }

    func testItemDetailPlaceholderView_defaultMediaType() {
        let item = SearchResult(
            identifier: "test-id",
            title: "Test Title"
        )

        let view = ItemDetailPlaceholderView(item: item)

        XCTAssertNotNil(view)
    }

    // MARK: SearchResult Item Tests

    func testItemDetailPlaceholderView_itemStored() {
        let item = SearchResult(
            identifier: "my-item",
            title: "My Item Title"
        )

        let view = ItemDetailPlaceholderView(item: item)

        XCTAssertEqual(view.item.identifier, "my-item")
    }

    func testItemDetailPlaceholderView_itemWithCreator() {
        let item = SearchResult(
            identifier: "test",
            title: "Title",
            creator: "Artist Name"
        )

        let view = ItemDetailPlaceholderView(item: item)

        XCTAssertEqual(view.item.creator, "Artist Name")
    }

    func testItemDetailPlaceholderView_itemWithYear() {
        let item = SearchResult(
            identifier: "test",
            title: "Title",
            year: "1985"
        )

        let view = ItemDetailPlaceholderView(item: item, mediaType: .music)

        XCTAssertEqual(view.item.year, "1985")
    }

    func testItemDetailPlaceholderView_itemWithAllFields() {
        let item = SearchResult(
            identifier: "full-item",
            title: "Full Title",
            creator: "Full Creator",
            year: "2024"
        )

        let view = ItemDetailPlaceholderView(item: item, mediaType: .music)

        XCTAssertEqual(view.item.identifier, "full-item")
        XCTAssertEqual(view.item.safeTitle, "Full Title")
        XCTAssertEqual(view.item.creator, "Full Creator")
        XCTAssertEqual(view.item.year, "2024")
    }

    // MARK: Media Type Tests

    func testItemDetailPlaceholderView_mediaTypeVideo() {
        let item = SearchResult(identifier: "test", title: "Title")
        let view = ItemDetailPlaceholderView(item: item, mediaType: .video)

        XCTAssertNotNil(view)
    }

    func testItemDetailPlaceholderView_mediaTypeMusic() {
        let item = SearchResult(identifier: "test", title: "Title")
        let view = ItemDetailPlaceholderView(item: item, mediaType: .music)

        XCTAssertNotNil(view)
    }

    // MARK: - MediaItemCard.MediaType Tests

    func testMediaType_videoCase() {
        let mediaType: MediaItemCard.MediaType = .video
        XCTAssertEqual(mediaType, .video)
    }

    func testMediaType_musicCase() {
        let mediaType: MediaItemCard.MediaType = .music
        XCTAssertEqual(mediaType, .music)
    }

    func testMediaType_videoPlaceholderIcon() {
        let mediaType: MediaItemCard.MediaType = .video

        XCTAssertEqual(mediaType.placeholderIcon, "film")
    }

    func testMediaType_musicPlaceholderIcon() {
        let mediaType: MediaItemCard.MediaType = .music

        XCTAssertEqual(mediaType.placeholderIcon, "music.note")
    }

    // MARK: - Edge Cases

    func testMediaThumbnailView_zeroSize() {
        let view = MediaThumbnailView(
            identifier: "test",
            mediaType: .video,
            size: CGSize.zero
        )

        XCTAssertEqual(view.size, CGSize.zero)
    }

    func testMediaHomeErrorView_unicodeMessage() {
        let message = "エラーが発生しました 🎬"
        let view = MediaHomeErrorView(
            message: message,
            onRetry: {}
        )

        XCTAssertEqual(view.message, message)
    }

    func testItemDetailPlaceholderView_unicodeTitle() {
        let item = SearchResult(
            identifier: "test",
            title: "日本語タイトル"
        )

        let view = ItemDetailPlaceholderView(item: item)

        XCTAssertEqual(view.item.safeTitle, "日本語タイトル")
    }

    func testItemDetailPlaceholderView_nilCreator() {
        let item = SearchResult(
            identifier: "test",
            title: "Title"
        )

        let view = ItemDetailPlaceholderView(item: item)

        XCTAssertNil(view.item.creator)
    }

    func testItemDetailPlaceholderView_nilYear() {
        let item = SearchResult(
            identifier: "test",
            title: "Title"
        )

        let view = ItemDetailPlaceholderView(item: item, mediaType: .music)

        XCTAssertNil(view.item.year)
    }
}
