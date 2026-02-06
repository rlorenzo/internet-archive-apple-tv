//
//  FavoritesViewTests.swift
//  Internet ArchiveTests
//
//  Tests for FavoritesView types, helpers, and navigation
//  Migrated to Swift Testing for Sprint 2
//

import Testing
import Foundation
@testable import Internet_Archive

// MARK: - PersonNavigation Tests

@Suite("PersonNavigation Tests")
struct PersonNavigationTests {

    @Test("Has unique UUID id per instance")
    func hasUniqueId() {
        let nav1 = PersonNavigation(identifier: "user1", name: "User One")
        let nav2 = PersonNavigation(identifier: "user1", name: "User One")
        #expect(nav1.id != nav2.id)
    }

    @Test("Same instance equals itself")
    func sameInstanceIsEqual() {
        let nav = PersonNavigation(identifier: "user1", name: "User One")
        #expect(nav == nav)
    }

    @Test("Can be used in Set")
    func canBeUsedInSet() {
        let nav = PersonNavigation(identifier: "user1", name: "User One")
        var set: Set<PersonNavigation> = []
        set.insert(nav)
        #expect(set.count == 1)
        #expect(set.contains(nav))
    }

    @Test("Properties accessible")
    func accessesProperties() {
        let nav = PersonNavigation(identifier: "user123", name: "Test User")
        #expect(nav.identifier == "user123")
        #expect(nav.name == "Test User")
    }

    @Test("Is Identifiable with non-nil id")
    func isIdentifiable() {
        let nav = PersonNavigation(identifier: "user1", name: "User One")
        #expect(nav.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    @Test("Different instances with same data are not equal (UUID-based)")
    func differentInstancesNotEqual() {
        let nav1 = PersonNavigation(identifier: "user1", name: "User One")
        let nav2 = PersonNavigation(identifier: "user1", name: "User One")
        #expect(nav1 != nav2)
    }

    @Test("Conforms to Hashable")
    func isHashable() {
        let nav1 = PersonNavigation(identifier: "user1", name: "User One")
        let nav2 = PersonNavigation(identifier: "user2", name: "User Two")
        #expect(nav1.hashValue != nav2.hashValue)
    }
}

// MARK: - FavoritesViewHelpers Tests

@Suite("FavoritesViewHelpers Tests")
struct FavoritesViewHelpersTests {

    // MARK: - Content State

    @Test("Loading state when isLoading and no results")
    func contentStateLoading() {
        let state = FavoritesViewHelpers.authenticatedContentState(
            isLoading: true, hasResults: false, errorMessage: nil
        )
        #expect(state == .loading)
    }

    @Test("Error state when error message present")
    func contentStateError() {
        let state = FavoritesViewHelpers.authenticatedContentState(
            isLoading: false, hasResults: false, errorMessage: "Network error"
        )
        #expect(state == .error("Network error"))
    }

    @Test("Empty state when not loading and no results")
    func contentStateEmpty() {
        let state = FavoritesViewHelpers.authenticatedContentState(
            isLoading: false, hasResults: false, errorMessage: nil
        )
        #expect(state == .empty)
    }

    @Test("Content state when results available")
    func contentStateContent() {
        let state = FavoritesViewHelpers.authenticatedContentState(
            isLoading: false, hasResults: true, errorMessage: nil
        )
        #expect(state == .content)
    }

    @Test("Loading with results shows content, not loading")
    func contentStateLoadingWithResults() {
        let state = FavoritesViewHelpers.authenticatedContentState(
            isLoading: true, hasResults: true, errorMessage: nil
        )
        #expect(state == .content)
    }

    @Test("Error takes priority over empty state")
    func contentStateErrorPriority() {
        let state = FavoritesViewHelpers.authenticatedContentState(
            isLoading: false, hasResults: false, errorMessage: "Server error"
        )
        #expect(state == .error("Server error"))
    }

    @Test("Loading takes priority over error when no results")
    func contentStateLoadingPriorityOverError() {
        let state = FavoritesViewHelpers.authenticatedContentState(
            isLoading: true, hasResults: false, errorMessage: "Network error"
        )
        #expect(state == .loading)
    }

    // MARK: - Avatar URL

    @Test("Avatar URL generated correctly")
    func avatarURL() {
        let url = FavoritesViewHelpers.avatarURL(for: "user123")
        #expect(url?.absoluteString == "https://archive.org/services/img/user123")
    }

    @Test("Avatar URL with hyphenated identifier")
    func avatarURLHyphenated() {
        let url = FavoritesViewHelpers.avatarURL(for: "some-user-name")
        #expect(url?.absoluteString == "https://archive.org/services/img/some-user-name")
    }

    @Test("Avatar URL percent-encodes spaces in identifier")
    func avatarURLWithSpaces() {
        let url = FavoritesViewHelpers.avatarURL(for: "user with spaces")
        #expect(url?.absoluteString == "https://archive.org/services/img/user%20with%20spaces")
    }

    // MARK: - Section Visibility

    @Test("Shows video section when movies exist")
    func showsVideoSection() {
        let movies = TestFixtures.makeVideoResults(count: 3)
        #expect(FavoritesViewHelpers.shouldShowVideoSection(movieResults: movies))
    }

    @Test("Hides video section when empty")
    func hidesVideoSection() {
        #expect(!FavoritesViewHelpers.shouldShowVideoSection(movieResults: []))
    }

    @Test("Shows music section when music exists")
    func showsMusicSection() {
        let music = TestFixtures.makeMusicResults(count: 2)
        #expect(FavoritesViewHelpers.shouldShowMusicSection(musicResults: music))
    }

    @Test("Hides music section when empty")
    func hidesMusicSection() {
        #expect(!FavoritesViewHelpers.shouldShowMusicSection(musicResults: []))
    }

    @Test("Shows people section when people exist")
    func showsPeopleSection() {
        let people = [TestFixtures.makeSearchResult(identifier: "creator1", mediatype: "account")]
        #expect(FavoritesViewHelpers.shouldShowPeopleSection(peopleResults: people))
    }

    @Test("Hides people section when empty")
    func hidesPeopleSection() {
        #expect(!FavoritesViewHelpers.shouldShowPeopleSection(peopleResults: []))
    }

    // MARK: - Accessibility Labels

    @Test("People section accessibility label with count",
          arguments: [(0, "0 creators"), (1, "1 creator"), (5, "5 creators")])
    func peopleSectionAccessibility(count: Int, expectedSuffix: String) {
        let label = FavoritesViewHelpers.peopleSectionAccessibilityLabel(count: count)
        #expect(label.contains("Followed Creators"))
        #expect(label.contains(expectedSuffix))
    }

    @Test("Unauthenticated accessibility label")
    func unauthenticatedAccessibility() {
        let label = FavoritesViewHelpers.unauthenticatedAccessibilityLabel
        #expect(label.contains("Sign in required"))
        #expect(label.contains("Account tab"))
    }

    // MARK: - Section Title

    @Test("People section title includes count",
          arguments: [(0, "(0)"), (1, "(1)"), (15, "(15)")])
    func peopleSectionTitle(count: Int, expectedCount: String) {
        let title = FavoritesViewHelpers.peopleSectionTitle(count: count)
        #expect(title.contains("Followed Creators"))
        #expect(title.contains(expectedCount))
    }
}
