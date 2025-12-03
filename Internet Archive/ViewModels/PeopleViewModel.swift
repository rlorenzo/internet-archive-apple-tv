//
//  PeopleViewModel.swift
//  Internet Archive
//
//  ViewModel for people favorites with testable business logic
//

import Foundation

/// Protocol for people favorites operations - enables dependency injection for testing
protocol PeopleFavoritesServiceProtocol: Sendable {
    func getFavoriteItems(username: String) async throws -> FavoritesResponse
    func search(query: String, options: [String: String]) async throws -> SearchResponse
}

/// ViewModel state for people favorites
struct PeopleViewState: Sendable {
    var isLoading: Bool = false
    var identifier: String = ""
    var name: String = ""
    var movieItems: [SearchResult] = []
    var musicItems: [SearchResult] = []
    var errorMessage: String?

    static let initial = PeopleViewState()

    /// Check if there are any items to display
    var hasItems: Bool {
        !movieItems.isEmpty || !musicItems.isEmpty
    }

    /// Get total item count
    var totalItemCount: Int {
        movieItems.count + musicItems.count
    }

    /// Extract username from identifier (removes @ prefix)
    var username: String {
        guard !identifier.isEmpty else { return "" }
        if identifier.hasPrefix("@") {
            return String(identifier.dropFirst())
        }
        return identifier
    }
}

/// ViewModel for people screen - handles all business logic
@MainActor
final class PeopleViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var state = PeopleViewState.initial

    // MARK: - Dependencies

    private let favoritesService: PeopleFavoritesServiceProtocol

    // MARK: - Initialization

    init(favoritesService: PeopleFavoritesServiceProtocol) {
        self.favoritesService = favoritesService
    }

    // MARK: - Public Methods

    /// Configure the view model with person data
    func configure(identifier: String, name: String) {
        state.identifier = identifier
        state.name = name
    }

    /// Load favorites for this person
    func loadFavorites() async {
        guard !state.identifier.isEmpty else {
            state.errorMessage = "Missing person information"
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        do {
            // Get username from identifier (removes @ prefix if present)
            let username = state.username

            // First, get the favorites list
            let favoritesResponse = try await favoritesService.getFavoriteItems(username: username)

            guard let favorites = favoritesResponse.members, !favorites.isEmpty else {
                state.isLoading = false
                return
            }

            // Filter for supported media types
            let identifiers = filterSupportedIdentifiers(favorites)

            guard !identifiers.isEmpty else {
                state.isLoading = false
                return
            }

            // Search for full details
            let options = [
                "fl[]": "identifier,title,year,downloads,date,creator,description,mediatype",
                "sort[]": "date+desc"
            ]

            let query = "identifier:(\(identifiers.joined(separator: " OR ")))"
            let searchResponse = try await favoritesService.search(query: query, options: options)

            // Categorize results
            let categorized = categorizeByMediaType(searchResponse.response.docs)
            state.movieItems = categorized.movies
            state.musicItems = categorized.music
            state.isLoading = false

            ErrorLogger.shared.logSuccess(
                operation: .getFavorites,
                info: [
                    "username": username,
                    "movies": state.movieItems.count,
                    "music": state.musicItems.count
                ]
            )

        } catch {
            state.isLoading = false
            state.errorMessage = mapErrorToMessage(error)

            ErrorLogger.shared.log(
                error: error,
                context: ErrorContext(
                    operation: .getFavorites,
                    additionalInfo: ["identifier": state.identifier]
                )
            )
        }
    }

    /// Filter favorites for supported media types (movies, audio)
    func filterSupportedIdentifiers(_ favorites: [FavoriteItem]) -> [String] {
        favorites.compactMap { item in
            guard let mediaType = item.mediatype,
                  ["movies", "audio"].contains(mediaType) else {
                return nil
            }
            return item.identifier
        }
    }

    /// Categorize search results by media type
    func categorizeByMediaType(_ items: [SearchResult]) -> (movies: [SearchResult], music: [SearchResult]) {
        var movies: [SearchResult] = []
        var music: [SearchResult] = []

        for item in items {
            switch item.safeMediaType {
            case "movies":
                movies.append(item)
            case "audio":
                music.append(item)
            default:
                break
            }
        }

        return (movies: movies, music: music)
    }

    /// Get movie item at index
    func movieItem(at index: Int) -> SearchResult? {
        guard index >= 0 && index < state.movieItems.count else { return nil }
        return state.movieItems[index]
    }

    /// Get music item at index
    func musicItem(at index: Int) -> SearchResult? {
        guard index >= 0 && index < state.musicItems.count else { return nil }
        return state.musicItems[index]
    }

    /// Build navigation data for item
    func buildItemNavigationData(for item: SearchResult) -> ItemNavigationData {
        ItemNavigationData(
            identifier: item.identifier,
            title: item.title ?? "",
            archivedBy: item.creator ?? "",
            date: item.date ?? "",
            description: item.description ?? "",
            mediaType: item.mediatype ?? "",
            imageURL: URL(string: "https://archive.org/services/get-item-image.php?identifier=\(item.identifier)")
        )
    }

    /// Clear error message
    func clearError() {
        state.errorMessage = nil
    }

    // MARK: - Private Methods

    private func mapErrorToMessage(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            return ErrorPresenter.shared.userFriendlyMessage(for: networkError)
        }
        return "An unexpected error occurred. Please try again."
    }
}

// MARK: - Default People Favorites Service Implementation

/// Default implementation using APIManager
struct DefaultPeopleFavoritesService: PeopleFavoritesServiceProtocol {

    @MainActor
    func getFavoriteItems(username: String) async throws -> FavoritesResponse {
        try await APIManager.sharedManager.getFavoriteItemsTyped(username: username)
    }

    @MainActor
    func search(query: String, options: [String: String]) async throws -> SearchResponse {
        try await APIManager.sharedManager.searchTyped(query: query, options: options)
    }
}
