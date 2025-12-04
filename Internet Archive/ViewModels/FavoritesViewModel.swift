//
//  FavoritesViewModel.swift
//  Internet Archive
//
//  ViewModel for favorites management with testable business logic
//

import Foundation

/// Protocol for favorites operations - enables dependency injection for testing
protocol FavoritesServiceProtocol: Sendable {
    func getFavoriteItems(username: String) async throws -> FavoritesResponse
}

/// ViewModel state for favorites
struct FavoritesViewState: Sendable {
    var isLoading: Bool = false
    var allItems: [FavoriteItem] = []
    var movieItems: [FavoriteItem] = []
    var musicItems: [FavoriteItem] = []
    var errorMessage: String?

    // Extended state for FavoriteVC - stores SearchResult details
    var movieResults: [SearchResult] = []
    var musicResults: [SearchResult] = []
    var peopleResults: [SearchResult] = []

    static let initial = FavoritesViewState()

    /// Check if there are any results to display
    var hasResults: Bool {
        !movieResults.isEmpty || !musicResults.isEmpty || !peopleResults.isEmpty
    }
}

/// ViewModel for favorites screen - handles all business logic
@MainActor
final class FavoritesViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var state = FavoritesViewState.initial

    // MARK: - Dependencies

    private let favoritesService: FavoritesServiceProtocol

    // MARK: - Initialization

    init(favoritesService: FavoritesServiceProtocol) {
        self.favoritesService = favoritesService
    }

    // MARK: - Public Methods

    /// Load favorites for a user
    func loadFavorites(username: String) async {
        guard !username.isEmpty else {
            state.errorMessage = "Please log in to view favorites"
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        do {
            let response = try await favoritesService.getFavoriteItems(username: username)
            let items = response.members ?? []

            state.allItems = items
            state.movieItems = filterByMediaType(items: items, types: ["movies", "video"])
            state.musicItems = filterByMediaType(items: items, types: ["audio", "etree"])
            state.isLoading = false
        } catch {
            state.errorMessage = mapErrorToMessage(error)
            state.isLoading = false
        }
    }

    /// Check if an item is a favorite
    func isFavorite(identifier: String) -> Bool {
        Global.getFavoriteData()?.contains(identifier) ?? false
    }

    /// Add item to favorites
    func addFavorite(identifier: String) {
        Global.saveFavoriteData(identifier: identifier)
    }

    /// Remove item from favorites
    func removeFavorite(identifier: String) {
        Global.removeFavoriteData(identifier: identifier)
    }

    /// Toggle favorite status
    func toggleFavorite(identifier: String) -> Bool {
        if isFavorite(identifier: identifier) {
            removeFavorite(identifier: identifier)
            return false
        } else {
            addFavorite(identifier: identifier)
            return true
        }
    }

    /// Clear all favorites
    func clearFavorites() {
        Global.resetFavoriteData()
        state = FavoritesViewState.initial
    }

    /// Get count of favorites
    var favoritesCount: Int {
        Global.getFavoriteData()?.count ?? 0
    }

    /// Get count of movie favorites
    var movieFavoritesCount: Int {
        state.movieItems.count
    }

    /// Get count of music favorites
    var musicFavoritesCount: Int {
        state.musicItems.count
    }

    /// Get count of people favorites
    var peopleFavoritesCount: Int {
        state.peopleResults.count
    }

    /// Load favorites with full details (used by FavoriteVC)
    /// This fetches the favorites then loads SearchResult details for each
    func loadFavoritesWithDetails(username: String, searchService: SearchServiceProtocol) async {
        guard !username.isEmpty else {
            state.errorMessage = "Please log in to view favorites"
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        do {
            // First fetch the favorites list
            let favoritesResponse = try await favoritesService.getFavoriteItems(username: username)

            guard let favorites = favoritesResponse.members, !favorites.isEmpty else {
                // Clear existing results when no favorites
                state.movieResults = []
                state.musicResults = []
                state.peopleResults = []
                state.allItems = []
                state.isLoading = false
                return
            }

            // Filter for supported media types
            let identifiers = favorites.compactMap { item -> String? in
                guard let mediaType = item.mediatype,
                      ["movies", "audio", "account"].contains(mediaType) else {
                    return nil
                }
                return item.identifier
            }

            guard !identifiers.isEmpty else {
                // Clear existing results when no supported identifiers
                state.movieResults = []
                state.musicResults = []
                state.peopleResults = []
                state.allItems = []
                state.isLoading = false
                return
            }

            // Fetch full details for each identifier
            let options = [
                "fl[]": "identifier,title,year,downloads,date,creator,description,mediatype",
                "sort[]": "date+desc"
            ]

            let query = "identifier:(\(identifiers.joined(separator: " OR ")))"
            let searchResponse = try await searchService.search(query: query, options: options)

            // Categorize results by media type
            var movies: [SearchResult] = []
            var music: [SearchResult] = []
            var people: [SearchResult] = []

            for item in searchResponse.response.docs {
                switch item.safeMediaType {
                case "movies":
                    movies.append(item)
                case "audio":
                    music.append(item)
                case "account":
                    people.append(item)
                default:
                    break
                }
            }

            state.movieResults = movies
            state.musicResults = music
            state.peopleResults = people
            state.allItems = favorites
            state.isLoading = false

            ErrorLogger.shared.logSuccess(
                operation: .getFavorites,
                info: ["username": username, "count": favorites.count]
            )

        } catch {
            state.errorMessage = mapErrorToMessage(error)
            state.isLoading = false
        }
    }

    // MARK: - Private Methods

    private func filterByMediaType(items: [FavoriteItem], types: [String]) -> [FavoriteItem] {
        items.filter { item in
            guard let mediaType = item.mediatype else { return false }
            return types.contains(mediaType.lowercased())
        }
    }

    private func mapErrorToMessage(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            return ErrorPresenter.shared.userFriendlyMessage(for: networkError)
        }
        return "An unexpected error occurred. Please try again."
    }
}

// MARK: - Default Favorites Service Implementation

/// Default implementation using APIManager.networkService (supports mock data for UI testing)
struct DefaultFavoritesService: FavoritesServiceProtocol {

    @MainActor
    func getFavoriteItems(username: String) async throws -> FavoritesResponse {
        try await APIManager.networkService.getFavoriteItems(username: username)
    }
}
