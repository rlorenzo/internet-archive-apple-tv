//
//  SearchResultsHelpers.swift
//  Internet Archive
//
//  Testable helper functions for SearchResultsGridView
//

import SwiftUI

/// Pure functions for SearchResultsGridView computations
/// Extracted from SearchResultsGridView for comprehensive unit testing
enum SearchResultsGridHelpers {

    // MARK: - Pagination Constants

    /// Default page size for results
    static let defaultPageSize = 30

    /// Number of items from the end to trigger load more
    static let loadMoreThreshold = 6

    // MARK: - Grid Layout

    /// Get grid columns for the given media type
    /// - Parameter mediaType: The media type
    /// - Returns: Array of GridItem definitions
    static func gridColumns(for mediaType: MediaItemCard.MediaType) -> [GridItem] {
        switch mediaType {
        case .video:
            return [GridItem(.adaptive(minimum: 340, maximum: 420), spacing: 48)]
        case .music:
            return [GridItem(.adaptive(minimum: 200, maximum: 240), spacing: 40)]
        }
    }

    /// Get the number of skeleton cards to show while loading more
    /// - Parameter mediaType: The media type
    /// - Returns: Number of skeleton cards
    static func skeletonCardCount(for mediaType: MediaItemCard.MediaType) -> Int {
        switch mediaType {
        case .video:
            return 4
        case .music:
            return 6
        }
    }

    /// Get the skeleton grid columns for loading state
    /// - Parameter mediaType: The media type
    /// - Returns: Number of columns
    static func skeletonColumns(for mediaType: MediaItemCard.MediaType) -> Int {
        switch mediaType {
        case .video:
            return 4
        case .music:
            return 6
        }
    }

    // MARK: - Pagination Logic

    /// Determine if more results should be loaded based on the current item
    /// - Parameters:
    ///   - itemIndex: Index of the item being displayed
    ///   - totalItems: Total number of items currently loaded
    ///   - hasMore: Whether there are more items available
    ///   - isLoadingMore: Whether we're already loading more
    /// - Returns: Whether to trigger load more
    static func shouldLoadMore(
        itemIndex: Int,
        totalItems: Int,
        hasMore: Bool,
        isLoadingMore: Bool
    ) -> Bool {
        guard hasMore, !isLoadingMore else { return false }
        return itemIndex >= totalItems - loadMoreThreshold
    }

    /// Determine if there are more pages based on response
    /// - Parameters:
    ///   - currentPage: The page that was just loaded (0-indexed)
    ///   - pageSize: Number of items per page
    ///   - itemsLoaded: Number of items actually loaded in this page
    ///   - totalFound: Total number of items available
    /// - Returns: Whether there are more pages to load
    static func hasMorePages(
        currentPage: Int,
        pageSize: Int,
        itemsLoaded: Int,
        totalFound: Int
    ) -> Bool {
        return itemsLoaded == pageSize &&
            (currentPage + 1) * pageSize < totalFound
    }

    // MARK: - API Query Building

    /// Build a media type filter query
    /// - Parameters:
    ///   - baseQuery: The base search query
    ///   - apiMediaType: The media type for filtering
    /// - Returns: The combined query string
    static func buildMediaTypeQuery(baseQuery: String, apiMediaType: String) -> String {
        "\(baseQuery) AND mediatype:(\(apiMediaType))"
    }

    /// Build the options dictionary for search
    /// - Parameters:
    ///   - pageSize: Number of results per page
    ///   - page: Page number (0-indexed)
    /// - Returns: Options dictionary for the API
    static func buildSearchOptions(pageSize: Int, page: Int) -> [String: String] {
        [
            "rows": "\(pageSize)",
            "page": "\(page + 1)", // API uses 1-indexed pages
            "fl[]": "identifier,title,mediatype,creator,description,date,year,downloads",
            "sort[]": "downloads desc"
        ]
    }

    // MARK: - Loading State

    /// Determine if the initial loading state should be shown
    /// - Parameters:
    ///   - isLoading: Whether data is currently loading
    ///   - resultsCount: Number of results already loaded
    /// - Returns: Whether to show the loading view
    static func shouldShowInitialLoading(isLoading: Bool, resultsCount: Int) -> Bool {
        isLoading && resultsCount == 0
    }

    /// Determine if the error state should be shown
    /// - Parameters:
    ///   - errorMessage: Current error message (if any)
    ///   - resultsCount: Number of results already loaded
    /// - Returns: Whether to show the error view
    static func shouldShowError(errorMessage: String?, resultsCount: Int) -> Bool {
        errorMessage != nil && resultsCount == 0
    }

    /// Determine if the empty state should be shown
    /// - Parameter resultsCount: Number of results
    /// - Returns: Whether to show the empty view
    static func shouldShowEmpty(resultsCount: Int, isLoading: Bool) -> Bool {
        resultsCount == 0 && !isLoading
    }
}
