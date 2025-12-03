//
//  SearchViewModel.swift
//  Internet Archive
//
//  ViewModel for search functionality with testable business logic
//

import Foundation

/// Protocol for search operations - enables dependency injection for testing
protocol SearchServiceProtocol: Sendable {
    func search(query: String, options: [String: String]) async throws -> SearchResponse
}

/// ViewModel state for search results
struct SearchViewState: Sendable {
    var isLoading: Bool = false
    var results: [SearchResult] = []
    var errorMessage: String?
    var totalResults: Int = 0
    var currentPage: Int = 0
    var hasMoreResults: Bool = false

    static let initial = SearchViewState()

    /// Filter results by media type
    func filterByMediaType(_ mediaType: String) -> [SearchResult] {
        results.filter { $0.safeMediaType == mediaType }
    }

    /// Get video results (movies)
    var videoResults: [SearchResult] {
        filterByMediaType("movies")
    }

    /// Get music results (etree/audio)
    var musicResults: [SearchResult] {
        results.filter { $0.safeMediaType == "etree" || $0.safeMediaType == "audio" }
    }
}

/// ViewModel for search screen - handles all business logic
@MainActor
final class SearchViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var state = SearchViewState.initial

    // MARK: - Dependencies

    private let searchService: SearchServiceProtocol
    private let pageSize: Int

    // MARK: - Initialization

    init(searchService: SearchServiceProtocol, pageSize: Int = 50) {
        self.searchService = searchService
        self.pageSize = pageSize
    }

    // MARK: - Public Methods

    /// Perform a new search, resetting pagination
    func search(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state = SearchViewState.initial
            return
        }

        state.isLoading = true
        state.errorMessage = nil
        state.currentPage = 0

        do {
            let options = buildSearchOptions(page: 0)
            let response = try await searchService.search(query: query, options: options)

            state.results = response.response.docs
            state.totalResults = response.response.numFound
            state.hasMoreResults = response.response.docs.count < response.response.numFound
            state.isLoading = false
        } catch {
            state.errorMessage = mapErrorToMessage(error)
            state.isLoading = false
        }
    }

    /// Load the next page of results
    func loadNextPage(query: String) async {
        guard state.hasMoreResults, !state.isLoading else { return }

        state.isLoading = true
        let nextPage = state.currentPage + 1

        do {
            let options = buildSearchOptions(page: nextPage)
            let response = try await searchService.search(query: query, options: options)

            state.results.append(contentsOf: response.response.docs)
            state.currentPage = nextPage
            state.hasMoreResults = state.results.count < state.totalResults
            state.isLoading = false
        } catch {
            state.errorMessage = mapErrorToMessage(error)
            state.isLoading = false
        }
    }

    /// Clear all search results
    func clearResults() {
        state = SearchViewState.initial
    }

    /// Perform a combined search for movies and music
    /// Used by SearchResultVC for multi-category display
    func searchMoviesAndMusic(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state = SearchViewState.initial
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        do {
            let options: [String: String] = [
                "rows": "\(pageSize)",
                "fl[]": "identifier,title,downloads,mediatype"
            ]
            let combinedQuery = "\(query) AND mediatype:(etree OR movies)"

            // Use retry mechanism for resilience against transient network failures
            let response = try await RetryMechanism.execute(config: .standard) {
                try await self.searchService.search(query: combinedQuery, options: options)
            }

            state.results = response.response.docs
            state.totalResults = response.response.numFound
            state.hasMoreResults = false // Single page for this view
            state.isLoading = false

            ErrorLogger.shared.logSuccess(
                operation: .search,
                info: ["query": query, "results": response.response.docs.count]
            )
        } catch {
            state.errorMessage = mapErrorToMessage(error)
            state.isLoading = false
        }
    }

    // MARK: - Private Methods

    private func buildSearchOptions(page: Int) -> [String: String] {
        [
            "rows": "\(pageSize)",
            "page": "\(page + 1)",
            "fl[]": "identifier,title,mediatype,creator,description,date,year,downloads"
        ]
    }

    private func mapErrorToMessage(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            return ErrorPresenter.shared.userFriendlyMessage(for: networkError)
        }
        return "An unexpected error occurred. Please try again."
    }
}

// MARK: - Default Search Service Implementation

/// Default implementation using APIManager.networkService (supports mock data for UI testing)
struct DefaultSearchService: SearchServiceProtocol {

    @MainActor
    func search(query: String, options: [String: String]) async throws -> SearchResponse {
        try await APIManager.networkService.search(query: query, options: options)
    }
}
