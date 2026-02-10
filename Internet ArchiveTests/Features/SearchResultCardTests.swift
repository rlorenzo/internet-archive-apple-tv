//
//  SearchResultCardTests.swift
//  Internet ArchiveTests
//
//  Unit tests for SearchResultCard SwiftUI component
//

import XCTest
import SwiftUI
@testable import Internet_Archive

@MainActor
final class SearchResultCardTests: XCTestCase {

    // MARK: - Initialization Tests

    func testSearchResultCard_initWithVideoType() {
        let item = SearchResult(
            identifier: "test-video",
            title: "Test Video Title"
        )

        let card = SearchResultCard(item: item, mediaType: .video)

        XCTAssertEqual(card.item.identifier, "test-video")
    }

    func testSearchResultCard_initWithMusicType() {
        let item = SearchResult(
            identifier: "test-music",
            title: "Test Music Title"
        )

        let card = SearchResultCard(item: item, mediaType: .music)

        XCTAssertEqual(card.item.identifier, "test-music")
    }

    // MARK: - Item Property Tests

    func testSearchResultCard_itemTitleStored() {
        let item = SearchResult(
            identifier: "id",
            title: "My Video Title"
        )

        let card = SearchResultCard(item: item, mediaType: .video)

        XCTAssertEqual(card.item.safeTitle, "My Video Title")
    }

    func testSearchResultCard_itemCreatorStored() {
        let item = SearchResult(
            identifier: "id",
            title: "Title",
            creator: "Artist Name"
        )

        let card = SearchResultCard(item: item, mediaType: .music)

        XCTAssertEqual(card.item.creator, "Artist Name")
    }

    func testSearchResultCard_itemYearStored() {
        let item = SearchResult(
            identifier: "id",
            title: "Title",
            year: "2024"
        )

        let card = SearchResultCard(item: item, mediaType: .video)

        XCTAssertEqual(card.item.year, "2024")
    }

    func testSearchResultCard_itemWithAllFields() {
        let item = SearchResult(
            identifier: "full-id",
            title: "Full Title",
            creator: "Full Creator",
            year: "1999"
        )

        let card = SearchResultCard(item: item, mediaType: .video)

        XCTAssertEqual(card.item.identifier, "full-id")
        XCTAssertEqual(card.item.safeTitle, "Full Title")
        XCTAssertEqual(card.item.creator, "Full Creator")
        XCTAssertEqual(card.item.year, "1999")
    }

    // MARK: - Media Type Tests

    func testSearchResultCard_videoMediaType() {
        let item = SearchResult(identifier: "id", title: "Title")
        let card = SearchResultCard(item: item, mediaType: .video)

        switch card.mediaType {
        case .video:
            XCTAssertTrue(true)
        case .music:
            XCTFail("Expected video media type")
        }
    }

    func testSearchResultCard_musicMediaType() {
        let item = SearchResult(identifier: "id", title: "Title")
        let card = SearchResultCard(item: item, mediaType: .music)

        switch card.mediaType {
        case .video:
            XCTFail("Expected music media type")
        case .music:
            XCTAssertTrue(true)
        }
    }

    // MARK: - Nil Value Tests

    func testSearchResultCard_nilCreator() {
        let item = SearchResult(
            identifier: "id",
            title: "Title"
        )

        let card = SearchResultCard(item: item, mediaType: .video)

        XCTAssertNil(card.item.creator)
    }

    func testSearchResultCard_nilYear() {
        let item = SearchResult(
            identifier: "id",
            title: "Title"
        )

        let card = SearchResultCard(item: item, mediaType: .video)

        XCTAssertNil(card.item.year)
    }

    func testSearchResultCard_creatorButNoYear() {
        let item = SearchResult(
            identifier: "id",
            title: "Title",
            creator: "Creator"
        )

        let card = SearchResultCard(item: item, mediaType: .music)

        XCTAssertEqual(card.item.creator, "Creator")
        XCTAssertNil(card.item.year)
    }

    func testSearchResultCard_yearButNoCreator() {
        let item = SearchResult(
            identifier: "id",
            title: "Title",
            year: "2000"
        )

        let card = SearchResultCard(item: item, mediaType: .music)

        XCTAssertNil(card.item.creator)
        XCTAssertEqual(card.item.year, "2000")
    }

    // MARK: - Edge Cases

    func testSearchResultCard_emptyIdentifier() {
        let item = SearchResult(
            identifier: "",
            title: "Title"
        )

        let card = SearchResultCard(item: item, mediaType: .video)

        XCTAssertEqual(card.item.identifier, "")
    }

    func testSearchResultCard_emptyTitle() {
        let item = SearchResult(
            identifier: "id",
            title: ""
        )

        let card = SearchResultCard(item: item, mediaType: .video)

        XCTAssertNotNil(card)
    }

    func testSearchResultCard_veryLongTitle() {
        let longTitle = String(repeating: "Very Long Title ", count: 50)
        let item = SearchResult(
            identifier: "id",
            title: longTitle
        )

        let card = SearchResultCard(item: item, mediaType: .video)

        XCTAssertEqual(card.item.safeTitle, longTitle)
    }

    func testSearchResultCard_specialCharactersInTitle() {
        let item = SearchResult(
            identifier: "id",
            title: "Title: Part II (2024) - Director's Cut™ & More"
        )

        let card = SearchResultCard(item: item, mediaType: .video)

        XCTAssertEqual(card.item.safeTitle, "Title: Part II (2024) - Director's Cut™ & More")
    }

    func testSearchResultCard_unicodeTitle() {
        let item = SearchResult(
            identifier: "id",
            title: "日本語タイトル 🎬"
        )

        let card = SearchResultCard(item: item, mediaType: .video)

        XCTAssertEqual(card.item.safeTitle, "日本語タイトル 🎬")
    }

    func testSearchResultCard_unicodeCreator() {
        let item = SearchResult(
            identifier: "id",
            title: "Title",
            creator: "アーティスト名"
        )

        let card = SearchResultCard(item: item, mediaType: .music)

        XCTAssertEqual(card.item.creator, "アーティスト名")
    }

    func testSearchResultCard_longIdentifier() {
        let longId = String(repeating: "long-id-", count: 20)
        let item = SearchResult(
            identifier: longId,
            title: "Title"
        )

        let card = SearchResultCard(item: item, mediaType: .video)

        XCTAssertEqual(card.item.identifier, longId)
    }

    // MARK: - Multiple Cards Tests

    func testSearchResultCard_multipleVideoCards() {
        let items = [
            SearchResult(identifier: "v1", title: "Video 1"),
            SearchResult(identifier: "v2", title: "Video 2"),
            SearchResult(identifier: "v3", title: "Video 3")
        ]

        let cards = items.map { SearchResultCard(item: $0, mediaType: .video) }

        XCTAssertEqual(cards.count, 3)
        XCTAssertEqual(cards[0].item.identifier, "v1")
        XCTAssertEqual(cards[1].item.identifier, "v2")
        XCTAssertEqual(cards[2].item.identifier, "v3")
    }

    func testSearchResultCard_multipleMusicCards() {
        let items = [
            SearchResult(identifier: "m1", title: "Music 1"),
            SearchResult(identifier: "m2", title: "Music 2")
        ]

        let cards = items.map { SearchResultCard(item: $0, mediaType: .music) }

        XCTAssertEqual(cards.count, 2)
    }

    func testSearchResultCard_mixedMediaTypes() {
        let videoItem = SearchResult(identifier: "v1", title: "Video")
        let musicItem = SearchResult(identifier: "m1", title: "Music")

        let videoCard = SearchResultCard(item: videoItem, mediaType: .video)
        let musicCard = SearchResultCard(item: musicItem, mediaType: .music)

        switch videoCard.mediaType {
        case .video: XCTAssertTrue(true)
        case .music: XCTFail("Expected video")
        }

        switch musicCard.mediaType {
        case .video: XCTFail("Expected music")
        case .music: XCTAssertTrue(true)
        }
    }
}
