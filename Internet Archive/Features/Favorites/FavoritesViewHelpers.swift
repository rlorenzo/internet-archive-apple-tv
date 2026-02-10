//
//  FavoritesViewHelpers.swift
//  Internet Archive
//
//  Testable helper functions for FavoritesView
//

import SwiftUI

/// Pure functions for FavoritesView logic
/// Extracted from view to enable comprehensive unit testing
enum FavoritesViewHelpers {

    // MARK: - Content State

    /// Determines which content state to show for the authenticated view
    /// - Parameters:
    ///   - isLoading: Whether the view model is loading
    ///   - hasResults: Whether results have been loaded
    ///   - errorMessage: Optional error message
    /// - Returns: The content state to display
    static func authenticatedContentState(
        isLoading: Bool,
        hasResults: Bool,
        errorMessage: String?
    ) -> AuthenticatedContentState {
        if isLoading && !hasResults {
            return .loading
        } else if let error = errorMessage {
            return .error(error)
        } else if !hasResults {
            return .empty
        } else {
            return .content
        }
    }

    /// Possible states for authenticated content
    enum AuthenticatedContentState: Equatable {
        case loading
        case error(String)
        case empty
        case content
    }

    // MARK: - Avatar URL

    /// Generates the avatar URL for a creator/person
    /// - Parameter identifier: The person's identifier
    /// - Returns: URL for the Archive.org thumbnail service
    static func avatarURL(for identifier: String) -> URL? {
        let encoded = identifier.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? identifier
        return URL(string: "https://archive.org/services/img/\(encoded)")
    }

    // MARK: - Section Visibility

    /// Whether the video favorites section should be visible
    /// - Parameter movieResults: The movie search results
    /// - Returns: True if there are movies to display
    static func shouldShowVideoSection(movieResults: [SearchResult]) -> Bool {
        !movieResults.isEmpty
    }

    /// Whether the music favorites section should be visible
    /// - Parameter musicResults: The music search results
    /// - Returns: True if there are music items to display
    static func shouldShowMusicSection(musicResults: [SearchResult]) -> Bool {
        !musicResults.isEmpty
    }

    /// Whether the people section should be visible
    /// - Parameter peopleResults: The people search results
    /// - Returns: True if there are followed creators to display
    static func shouldShowPeopleSection(peopleResults: [SearchResult]) -> Bool {
        !peopleResults.isEmpty
    }

    // MARK: - Accessibility

    /// Generates accessibility label for the people section
    /// - Parameter count: Number of followed creators
    /// - Returns: Descriptive accessibility label
    static func peopleSectionAccessibilityLabel(count: Int) -> String {
        "Followed Creators section with \(count) \(count == 1 ? "creator" : "creators")"
    }

    /// Generates accessibility label for the unauthenticated state
    static var unauthenticatedAccessibilityLabel: String {
        "Sign in required to view favorites. Go to the Account tab to sign in."
    }

    // MARK: - Section Title

    /// Returns the section header text for people section
    /// - Parameter count: Number of followed creators
    /// - Returns: Formatted section header string
    static func peopleSectionTitle(count: Int) -> String {
        "Followed Creators (\(count))"
    }
}
