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
}

/// ViewModel state for collection browsing
struct CollectionViewState: Sendable {
    var isLoading: Bool = false
    var items: [SearchResult] = []
    var errorMessage: String?
    var collectionName: String = ""

    static let initial = CollectionViewState()
}

/// ViewModel for collection browsing - handles all business logic
@MainActor
final class CollectionViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var state = CollectionViewState.initial

    // MARK: - Dependencies

    private let collectionService: CollectionServiceProtocol

    // MARK: - Initialization

    init(collectionService: CollectionServiceProtocol) {
        self.collectionService = collectionService
    }

    // MARK: - Public Methods

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

    /// Filter items by media type
    func filterItems(by mediaType: String) -> [SearchResult] {
        if mediaType.isEmpty {
            return state.items
        }
        return state.items.filter { $0.mediatype == mediaType }
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
        if let networkError = error as? NetworkError {
            return ErrorPresenter.shared.userFriendlyMessage(for: networkError)
        }
        return "An unexpected error occurred. Please try again."
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

/// Default implementation using APIManager
struct DefaultCollectionService: CollectionServiceProtocol {

    @MainActor
    func getCollections(collection: String, resultType: String, limit: Int?) async throws -> (collection: String, results: [SearchResult]) {
        try await APIManager.sharedManager.getCollectionsTyped(
            collection: collection,
            resultType: resultType,
            limit: limit
        )
    }

    @MainActor
    func getMetadata(identifier: String) async throws -> ItemMetadataResponse {
        try await APIManager.sharedManager.getMetaDataTyped(identifier: identifier)
    }
}
