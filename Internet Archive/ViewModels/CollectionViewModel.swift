//
//  CollectionViewModel.swift
//  Internet Archive
//
//  ViewModel for collection browsing with testable business logic
//

import Foundation

/// Protocol for collection operations - enables dependency injection for testing
protocol CollectionServiceProtocol: Sendable {
    func getCollections(collection: String, resultType: String, limit: Int?) async throws -> (collection: String, results: [SearchResult])
    func getMetadata(identifier: String) async throws -> ItemMetadataResponse

    /// Fetch a single page of collection items using server-side sorting and pagination.
    /// - Parameters:
    ///   - collection: The collection identifier
    ///   - resultType: The mediatype filter (e.g., "collection", "movies", "audio")
    ///   - page: Zero-indexed page number (converted to 1-indexed for the API)
    ///   - pageSize: Number of items per page
    ///   - sort: Solr-style sort expression (e.g., "downloads desc")
    /// - Returns: Raw SearchResponse so callers can read numFound for pagination decisions
    func getCollectionPage(
        collection: String,
        resultType: String,
        page: Int,
        pageSize: Int,
        sort: String
    ) async throws -> SearchResponse
}

/// ViewModel state for collection browsing
struct CollectionViewState: Sendable {
    var isLoading: Bool = false
    /// Whether a load has run to completion (success or failure).
    /// Stays false when a load is cancelled so the view retries on reappear.
    var hasLoaded: Bool = false
    var items: [SearchResult] = []
    var errorMessage: String?
    var collectionName: String = ""
    /// Metadata of the collection itself (description etc.), when available
    var collectionMetadata: ItemMetadata?

    static let initial = CollectionViewState()
}

/// ViewModel for collection browsing - handles all business logic
@MainActor
final class CollectionViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var state = CollectionViewState.initial

    // MARK: - Dependencies

    private let collectionService: CollectionServiceProtocol
    private var currentLoadToken = UUID()

    // MARK: - Initialization

    init(collectionService: CollectionServiceProtocol) {
        self.collectionService = collectionService
    }

    // MARK: - Public Methods

    /// Load the items of a collection with server-side sorting, plus the
    /// collection's own metadata for the description (non-fatal on failure).
    ///
    /// Uses a load token so a stale response (e.g. after a sort change) can't
    /// overwrite newer results.
    ///
    /// - Parameters:
    ///   - identifier: The collection identifier.
    ///   - mediaTypeFilter: mediatype filter, e.g. "movies" or "(etree OR audio)".
    ///   - sort: Solr-style sort expression (e.g. "week desc").
    ///   - rows: Maximum number of items to fetch (default 100).
    func loadCollectionContents(
        identifier: String,
        mediaTypeFilter: String,
        sort: String,
        rows: Int = 100
    ) async {
        let loadToken = UUID()
        currentLoadToken = loadToken

        state.isLoading = true
        state.errorMessage = nil
        state.items = []
        state.collectionName = identifier

        do {
            let response = try await collectionService.getCollectionPage(
                collection: identifier,
                resultType: mediaTypeFilter,
                page: 0,
                pageSize: rows,
                sort: sort
            )

            guard loadToken == currentLoadToken else { return }
            state.items = response.response.docs

            // Also load the collection's own metadata for the description.
            // Non-fatal: the search-result description is a sufficient fallback.
            do {
                let metadata = try await collectionService.getMetadata(identifier: identifier)
                guard loadToken == currentLoadToken else { return }
                state.collectionMetadata = metadata.metadata
            } catch {
                guard loadToken == currentLoadToken else { return }
            }

            state.isLoading = false
            state.hasLoaded = true
        } catch {
            guard loadToken == currentLoadToken else { return }
            state.isLoading = false
            guard !(error is CancellationError), !Task.isCancelled else { return }
            state.errorMessage = mapErrorToMessage(error)
            state.hasLoaded = true
        }
    }

    /// Load items from a collection
    func loadCollection(name: String, mediaType: String) async {
        state.isLoading = true
        state.errorMessage = nil
        state.collectionName = name

        do {
            let result = try await collectionService.getCollections(
                collection: name,
                resultType: mediaType,
                limit: nil
            )

            state.items = result.results
            state.isLoading = false
        } catch {
            state.errorMessage = mapErrorToMessage(error)
            state.isLoading = false
        }
    }

    /// Load metadata for a specific item
    func loadItemMetadata(identifier: String) async -> ItemMetadataResponse? {
        do {
            return try await collectionService.getMetadata(identifier: identifier)
        } catch {
            state.errorMessage = mapErrorToMessage(error)
            return nil
        }
    }

    /// Clear collection items
    func clearItems() {
        state = CollectionViewState.initial
    }

    /// Filter items by media type (case-insensitive)
    func filterItems(by mediaType: String) -> [SearchResult] {
        if mediaType.isEmpty {
            return state.items
        }
        return state.items.filter { $0.mediatype?.lowercased() == mediaType.lowercased() }
    }

    /// Sort items by various criteria
    func sortItems(by criteria: SortCriteria) -> [SearchResult] {
        switch criteria {
        case .title:
            return state.items.sorted { ($0.title ?? "") < ($1.title ?? "") }
        case .date:
            return state.items.sorted { ($0.date ?? "") > ($1.date ?? "") }
        case .downloads:
            return state.items.sorted { ($0.downloads ?? 0) > ($1.downloads ?? 0) }
        case .year:
            return state.items.sorted { ($0.year ?? "") > ($1.year ?? "") }
        }
    }

    // MARK: - Private Methods

    private func mapErrorToMessage(_ error: Error) -> String {
        ErrorMessageMapper.message(for: error)
    }
}

// MARK: - Sort Criteria

enum SortCriteria: String, CaseIterable, Sendable {
    case title = "Title"
    case date = "Date"
    case downloads = "Downloads"
    case year = "Year"
}

// MARK: - Default Collection Service Implementation

/// Default implementation using APIManager.networkService (supports mock data for UI testing)
struct DefaultCollectionService: CollectionServiceProtocol {

    @MainActor
    func getCollections(collection: String, resultType: String, limit: Int?) async throws -> (collection: String, results: [SearchResult]) {
        try await APIManager.networkService.getCollections(
            collection: collection,
            resultType: resultType,
            limit: limit
        )
    }

    @MainActor
    func getMetadata(identifier: String) async throws -> ItemMetadataResponse {
        try await APIManager.networkService.getMetadata(identifier: identifier)
    }

    @MainActor
    func getCollectionPage(
        collection: String,
        resultType: String,
        page: Int,
        pageSize: Int,
        sort: String
    ) async throws -> SearchResponse {
        let options: [String: String] = [
            "rows": "\(pageSize)",
            "page": "\(page + 1)", // API uses 1-indexed pages
            "fl[]": "identifier,title,year,downloads,date,creator,description,mediatype,collection,licenseurl",
            "sort[]": sort
        ]

        return try await APIManager.networkService.search(
            query: "collection:(\(collection)) And mediatype:\(resultType)",
            options: options
        )
    }
}
