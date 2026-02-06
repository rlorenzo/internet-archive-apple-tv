//
//  ItemDetailPlaceholderViewTests.swift
//  Internet ArchiveTests
//
//  Tests for ItemDetailPlaceholderView and ItemDetailPlaceholderHelpers
//  Created for Sprint 2 using Swift Testing
//

import Testing
@testable import Internet_Archive

// MARK: - ItemDetailPlaceholderHelpers Tests

@Suite("ItemDetailPlaceholderHelpers Tests")
struct ItemDetailPlaceholderHelpersTests {

    // MARK: - Icon Name

    @Test("Video media type returns film icon")
    func iconNameVideo() {
        #expect(ItemDetailPlaceholderHelpers.iconName(for: .video) == "film")
    }

    @Test("Music media type returns music.note icon")
    func iconNameMusic() {
        #expect(ItemDetailPlaceholderHelpers.iconName(for: .music) == "music.note")
    }

    // MARK: - Year Display Logic

    @Test("Shows year for music with year")
    func shouldShowYearMusicWithYear() {
        #expect(ItemDetailPlaceholderHelpers.shouldShowYear("2024", mediaType: .music))
    }

    @Test("Does not show year for video even with year")
    func shouldNotShowYearVideo() {
        #expect(!ItemDetailPlaceholderHelpers.shouldShowYear("2024", mediaType: .video))
    }

    @Test("Does not show year when year is nil")
    func shouldNotShowYearNil() {
        #expect(!ItemDetailPlaceholderHelpers.shouldShowYear(nil, mediaType: .music))
        #expect(!ItemDetailPlaceholderHelpers.shouldShowYear(nil, mediaType: .video))
    }

    // MARK: - Display Title

    @Test("Display title uses safeTitle with regular title")
    func displayTitleRegular() {
        let item = TestFixtures.makeSearchResult(identifier: "test", title: "My Video")
        #expect(ItemDetailPlaceholderHelpers.displayTitle(for: item) == "My Video")
    }

    @Test("Display title uses safeTitle fallback for nil title")
    func displayTitleNilFallback() {
        let item = TestFixtures.makeSearchResult(identifier: "test", title: nil)
        #expect(ItemDetailPlaceholderHelpers.displayTitle(for: item) == "Untitled")
    }

    @Test("Display title with special characters")
    func displayTitleSpecialChars() {
        let item = TestFixtures.makeSearchResult(
            identifier: "test",
            title: "Movie: Part II (2024) - Director's Cut™"
        )
        #expect(ItemDetailPlaceholderHelpers.displayTitle(for: item) == "Movie: Part II (2024) - Director's Cut™")
    }
}

// MARK: - ItemDetailPlaceholderView Property Tests

@Suite("ItemDetailPlaceholderView Tests")
@MainActor
struct ItemDetailPlaceholderViewPropertyTests {

    @Test("Initializes with video media type")
    func initVideo() {
        let item = TestFixtures.movieSearchResult
        let view = ItemDetailPlaceholderView(item: item, mediaType: .video)
        #expect(view.item.identifier == "test_movie_001")
        #expect(view.mediaType == .video)
    }

    @Test("Initializes with music media type")
    func initMusic() {
        let item = TestFixtures.musicSearchResult
        let view = ItemDetailPlaceholderView(item: item, mediaType: .music)
        #expect(view.item.identifier == "test_music_001")
        #expect(view.mediaType == .music)
    }

    @Test("Default media type is video")
    func defaultMediaType() {
        let item = TestFixtures.movieSearchResult
        let view = ItemDetailPlaceholderView(item: item)
        #expect(view.mediaType == .video)
    }

    @Test("Stores item properties correctly")
    func storesItemProperties() {
        let item = TestFixtures.makeSearchResult(
            identifier: "custom-id",
            title: "Custom Title",
            creator: "Custom Creator",
            year: "2024"
        )
        let view = ItemDetailPlaceholderView(item: item, mediaType: .music)

        #expect(view.item.identifier == "custom-id")
        #expect(view.item.title == "Custom Title")
        #expect(view.item.creator == "Custom Creator")
        #expect(view.item.year == "2024")
    }

    @Test("Item without creator")
    func itemWithoutCreator() {
        let item = TestFixtures.makeSearchResult(
            identifier: "no-creator",
            title: "No Creator Item",
            creator: nil
        )
        let view = ItemDetailPlaceholderView(item: item, mediaType: .video)
        #expect(view.item.creator == nil)
    }

    @Test("Item without year")
    func itemWithoutYear() {
        let item = TestFixtures.makeSearchResult(
            identifier: "no-year",
            title: "No Year Item",
            year: nil
        )
        let view = ItemDetailPlaceholderView(item: item, mediaType: .music)
        #expect(view.item.year == nil)
    }
}
