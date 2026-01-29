//
//  ContentViewTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ContentView Tab enum
//

import XCTest
@testable import Internet_Archive

final class ContentViewTabTests: XCTestCase {

    // MARK: - Tab Raw Values Tests

    func testTab_videosRawValue() {
        XCTAssertEqual(ContentView.Tab.videos.rawValue, "videos")
    }

    func testTab_musicRawValue() {
        XCTAssertEqual(ContentView.Tab.music.rawValue, "music")
    }

    func testTab_searchRawValue() {
        XCTAssertEqual(ContentView.Tab.search.rawValue, "search")
    }

    func testTab_favoritesRawValue() {
        XCTAssertEqual(ContentView.Tab.favorites.rawValue, "favorites")
    }

    func testTab_accountRawValue() {
        XCTAssertEqual(ContentView.Tab.account.rawValue, "account")
    }

    // MARK: - Tab Accessibility Label Tests

    func testTab_videosAccessibilityLabel() {
        XCTAssertEqual(ContentView.Tab.videos.accessibilityLabel, "Videos tab")
    }

    func testTab_musicAccessibilityLabel() {
        XCTAssertEqual(ContentView.Tab.music.accessibilityLabel, "Music tab")
    }

    func testTab_searchAccessibilityLabel() {
        XCTAssertEqual(ContentView.Tab.search.accessibilityLabel, "Search tab")
    }

    func testTab_favoritesAccessibilityLabel() {
        XCTAssertEqual(ContentView.Tab.favorites.accessibilityLabel, "Favorites tab")
    }

    func testTab_accountAccessibilityLabel() {
        XCTAssertEqual(ContentView.Tab.account.accessibilityLabel, "Account tab")
    }

    // MARK: - Tab Accessibility Hint Tests

    func testTab_videosAccessibilityHint() {
        XCTAssertEqual(ContentView.Tab.videos.accessibilityHint, "Browse and watch video content")
    }

    func testTab_musicAccessibilityHint() {
        XCTAssertEqual(ContentView.Tab.music.accessibilityHint, "Browse and listen to music")
    }

    func testTab_searchAccessibilityHint() {
        XCTAssertEqual(ContentView.Tab.search.accessibilityHint, "Search the Internet Archive")
    }

    func testTab_favoritesAccessibilityHint() {
        XCTAssertEqual(ContentView.Tab.favorites.accessibilityHint, "View your saved favorites")
    }

    func testTab_accountAccessibilityHint() {
        XCTAssertEqual(ContentView.Tab.account.accessibilityHint, "Manage your account settings")
    }

    // MARK: - Tab Hashable Tests

    func testTab_isHashable() {
        var set: Set<ContentView.Tab> = []
        set.insert(.videos)
        set.insert(.music)
        set.insert(.search)
        set.insert(.favorites)
        set.insert(.account)
        XCTAssertEqual(set.count, 5)
    }

    func testTab_duplicatesNotAdded() {
        var set: Set<ContentView.Tab> = []
        set.insert(.videos)
        set.insert(.videos)
        set.insert(.videos)
        XCTAssertEqual(set.count, 1)
    }

    func testTab_hashValue() {
        let tab1 = ContentView.Tab.videos
        let tab2 = ContentView.Tab.videos
        XCTAssertEqual(tab1.hashValue, tab2.hashValue)
    }

    // MARK: - Tab Equatable Tests

    func testTab_equality() {
        let tab1 = ContentView.Tab.music
        let tab2 = ContentView.Tab.music
        XCTAssertEqual(tab1, tab2)
    }

    func testTab_inequality() {
        let tab1 = ContentView.Tab.videos
        let tab2 = ContentView.Tab.music
        XCTAssertNotEqual(tab1, tab2)
    }

    // MARK: - Tab Init From Raw Value Tests

    func testTab_initFromValidRawValue() {
        let tab = ContentView.Tab(rawValue: "videos")
        XCTAssertEqual(tab, .videos)
    }

    func testTab_initFromInvalidRawValue() {
        let tab = ContentView.Tab(rawValue: "invalid")
        XCTAssertNil(tab)
    }

    func testTab_initAllRawValues() {
        XCTAssertNotNil(ContentView.Tab(rawValue: "videos"))
        XCTAssertNotNil(ContentView.Tab(rawValue: "music"))
        XCTAssertNotNil(ContentView.Tab(rawValue: "search"))
        XCTAssertNotNil(ContentView.Tab(rawValue: "favorites"))
        XCTAssertNotNil(ContentView.Tab(rawValue: "account"))
    }

    // MARK: - Tab As Dictionary Key Tests

    func testTab_asDictionaryKey() {
        var dict: [ContentView.Tab: String] = [:]
        dict[.videos] = "Video Content"
        dict[.music] = "Audio Content"
        dict[.search] = "Search"
        dict[.favorites] = "Saved Items"
        dict[.account] = "User Settings"

        XCTAssertEqual(dict.count, 5)
        XCTAssertEqual(dict[.videos], "Video Content")
        XCTAssertEqual(dict[.account], "User Settings")
    }

    // MARK: - All Tabs Have Labels

    func testAllTabs_haveAccessibilityLabels() {
        let tabs: [ContentView.Tab] = [.videos, .music, .search, .favorites, .account]
        for tab in tabs {
            XCTAssertFalse(tab.accessibilityLabel.isEmpty, "\(tab) should have accessibility label")
        }
    }

    func testAllTabs_haveAccessibilityHints() {
        let tabs: [ContentView.Tab] = [.videos, .music, .search, .favorites, .account]
        for tab in tabs {
            XCTAssertFalse(tab.accessibilityHint.isEmpty, "\(tab) should have accessibility hint")
        }
    }

    func testAllTabs_labelsContainTabWord() {
        let tabs: [ContentView.Tab] = [.videos, .music, .search, .favorites, .account]
        for tab in tabs {
            XCTAssertTrue(
                tab.accessibilityLabel.lowercased().contains("tab"),
                "\(tab) accessibility label should contain 'tab'"
            )
        }
    }
}
