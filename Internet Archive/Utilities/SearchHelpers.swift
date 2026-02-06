//
//  SearchHelpers.swift
//  Internet Archive
//
//  Helper types and functions for search functionality - extracted for testability
//

import Foundation

// MARK: - Content Filter

/// Filter options for search results - pure data type for testability
enum SearchContentFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case videos
    case music

    var id: String { rawValue }

    /// Display name shown in the UI filter picker
    var displayName: String {
        switch self {
        case .all: return "All"
        case .videos: return "Videos"
        case .music: return "Music"
        }
    }

    /// The media type query parameter for the Internet Archive API
    var apiMediaType: String {
        switch self {
        case .all: return "movies OR etree OR audio"
        case .videos: return "movies"
        case .music: return "etree OR audio"
        }
    }

    /// Returns true if this filter should show video results
    var includesVideos: Bool {
        self != .music
    }

    /// Returns true if this filter should show music results
    var includesMusic: Bool {
        self != .videos
    }
}

// MARK: - Search State

/// Represents the current state of a search operation
enum SearchContentState: Equatable, Sendable {
    case empty           // No search text entered
    case loading         // Search in progress, no results yet
    case error           // Search failed
    case noResults       // Search completed with no results
    case results         // Search completed with results

    /// Determine content state from search parameters
    static func determine(
        searchText: String,
        isSearching: Bool,
        hasError: Bool,
        videoResultsCount: Int,
        musicResultsCount: Int
    ) -> SearchContentState {
        if searchText.isEmpty {
            return .empty
        } else if isSearching && videoResultsCount == 0 && musicResultsCount == 0 {
            return .loading
        } else if hasError {
            return .error
        } else if videoResultsCount == 0 && musicResultsCount == 0 {
            return .noResults
        } else {
            return .results
        }
    }
}

// MARK: - Search Query Builder

/// Helper for building Internet Archive search queries
enum SearchQueryBuilder {
    /// Build a full search query with media type filter
    static func buildQuery(searchText: String, mediaType: String) -> String {
        "\(searchText) AND mediatype:(\(mediaType))"
    }

    /// Build search options dictionary
    static func buildOptions(
        pageSize: Int,
        page: Int,
        sortField: String = "downloads",
        sortDirection: String = "desc"
    ) -> [String: String] {
        [
            "rows": "\(pageSize)",
            "page": "\(page + 1)",
            "fl[]": "identifier,title,mediatype,creator,description,date,year,downloads",
            "sort[]": "\(sortField) \(sortDirection)"
        ]
    }

    /// Calculate if there are more results to load
    static func hasMoreResults(
        currentResultCount: Int,
        pageSize: Int,
        currentPage: Int,
        totalResults: Int
    ) -> Bool {
        currentResultCount == pageSize && (currentPage + 1) * pageSize < totalResults
    }
}

// MARK: - Pagination Helpers

/// Helper for managing search pagination state
struct PaginationState: Equatable, Sendable {
    var currentPage: Int = 0
    var hasMore: Bool = false
    var isLoading: Bool = false

    /// Reset pagination state for new search
    mutating func reset() {
        currentPage = 0
        hasMore = false
        isLoading = false
    }

    /// Advance to next page
    mutating func advancePage() {
        currentPage += 1
    }

    /// Check if should load more based on item index
    func shouldLoadMore(itemIndex: Int, totalItems: Int, threshold: Int = 3) -> Bool {
        hasMore && !isLoading && itemIndex >= totalItems - threshold
    }
}
