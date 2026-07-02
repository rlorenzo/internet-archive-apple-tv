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
    /// Whether a load has run to completion (success or failure).
    /// Stays false when a load is cancelled so the view retries on reappear.
    var hasLoaded: Bool = false
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

    // MARK: - Constants

    /// Media types supported for favorites display (case-insensitive matching)
    static let supportedMediaTypes = ["movies", "video", "audio", "etree", "account"]

    /// Maximum identifiers per details request. Keeps the
    /// `identifier:(a OR b OR ...)` query comfortably within URL length limits.
    static let detailsChunkSize = 50

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

    /// Load favorites with full details for display in the Favorites tab.
    ///
    /// Merges the account favorites (the server-side `fav-{username}` list,
    /// fetched when a username is provided) with the device-local favorites
    /// saved via the heart button (`Global.saveFavoriteData`) so locally
    /// favorited items always appear. Pass an empty username when logged out
    /// to show local favorites only.
    func loadFavoritesWithDetails(username: String, searchService: SearchServiceProtocol) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            // Account favorites are only available when logged in
            var members: [FavoriteItem] = []
            if !username.isEmpty {
                let favoritesResponse = try await favoritesService.getFavoriteItems(username: username)
                guard !Task.isCancelled else {
                    state.isLoading = false
                    return
                }
                members = favoritesResponse.members ?? []
            }

            // Filter account favorites for supported media types
            // (case-insensitive to match loadFavorites behavior)
            var identifiers = members.compactMap { item -> String? in
                guard let mediaType = item.mediatype?.lowercased(),
                      Self.supportedMediaTypes.contains(mediaType) else {
                    return nil
                }
                return item.identifier
            }

            // Merge device-local favorites (heart button), de-duplicated.
            // Their media types aren't stored locally, so they're categorized
            // from the details response below like everything else.
            var seenIdentifiers = Set(identifiers)
            for localIdentifier in Global.getFavoriteData() ?? []
            where seenIdentifiers.insert(localIdentifier).inserted {
                identifiers.append(localIdentifier)
            }

            guard !identifiers.isEmpty else {
                // Clear existing results when there is nothing to show
                state.movieResults = []
                state.musicResults = []
                state.peopleResults = []
                state.allItems = members
                state.isLoading = false
                state.hasLoaded = true
                return
            }

            // Fetch full details for the merged identifier list
            let docs = try await fetchFavoriteDetails(identifiers: identifiers, searchService: searchService)

            guard !Task.isCancelled else {
                state.isLoading = false
                return
            }

            // Categorize results by media type (case-insensitive)
            var movies: [SearchResult] = []
            var music: [SearchResult] = []
            var people: [SearchResult] = []

            for item in docs {
                switch item.safeMediaType.lowercased() {
                case "movies", "video":
                    movies.append(item)
                case "audio", "etree":
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
            state.allItems = members
            state.isLoading = false
            state.hasLoaded = true

            ErrorLogger.shared.logSuccess(
                operation: .getFavorites,
                info: ["username": username, "count": identifiers.count]
            )

        } catch is CancellationError {
            // A newer load superseded this one - don't surface an error
            state.isLoading = false
        } catch {
            state.isLoading = false
            guard !Task.isCancelled else { return }
            state.errorMessage = mapErrorToMessage(error)
            state.hasLoaded = true
        }
    }

    // MARK: - Private Methods

    /// Fetch SearchResult details for the given identifiers, chunking the
    /// `identifier:(a OR b OR ...)` query so large favorite lists don't
    /// exceed URL length limits. Results are de-duplicated by identifier.
    private func fetchFavoriteDetails(
        identifiers: [String],
        searchService: SearchServiceProtocol
    ) async throws -> [SearchResult] {
        let options = [
            "rows": "\(Self.detailsChunkSize)",
            "fl[]": "identifier,title,year,downloads,date,creator,description,mediatype",
            "sort[]": "date desc"
        ]

        var docs: [SearchResult] = []
        var seenIdentifiers = Set<String>()
        for chunkStart in stride(from: 0, to: identifiers.count, by: Self.detailsChunkSize) {
            let chunkEnd = min(chunkStart + Self.detailsChunkSize, identifiers.count)
            let chunk = identifiers[chunkStart..<chunkEnd]
            let query = "identifier:(\(chunk.joined(separator: " OR ")))"
            let response = try await searchService.search(query: query, options: options)
            for doc in response.response.docs where seenIdentifiers.insert(doc.identifier).inserted {
                docs.append(doc)
            }
        }
        return docs
    }

    private func filterByMediaType(items: [FavoriteItem], types: [String]) -> [FavoriteItem] {
        items.filter { item in
            guard let mediaType = item.mediatype else { return false }
            return types.contains(mediaType.lowercased())
        }
    }

    private func mapErrorToMessage(_ error: Error) -> String {
        ErrorMessageMapper.message(for: error)
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
