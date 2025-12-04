//
//  VideoViewModel.swift
//  Internet Archive
//
//  ViewModel for video collections with testable business logic
//

import Foundation

// Note: Uses CollectionServiceProtocol defined in CollectionViewModel.swift

/// ViewModel state for video collection
struct VideoViewState: Sendable {
    var isLoading: Bool = false
    var collection: String = "movies"
    var items: [SearchResult] = []
    var errorMessage: String?

    static let initial = VideoViewState()

    /// Check if there are items to display
    var hasItems: Bool {
        !items.isEmpty
    }

    /// Get item count
    var itemCount: Int {
        items.count
    }
}

/// ViewModel for video screen - handles all business logic
@MainActor
final class VideoViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var state = VideoViewState.initial

    // MARK: - Dependencies

    private let collectionService: CollectionServiceProtocol

    // MARK: - Initialization

    init(collectionService: CollectionServiceProtocol) {
        self.collectionService = collectionService
    }

    /// Initialize with a specific collection
    convenience init(collectionService: CollectionServiceProtocol, collection: String) {
        self.init(collectionService: collectionService)
        state.collection = collection
    }

    // MARK: - Public Methods

    /// Set the collection to load
    func setCollection(_ collection: String) {
        state.collection = collection
    }

    /// Load collection data
    func loadCollection() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let result = try await RetryMechanism.execute(config: .standard) {
                try await self.collectionService.getCollections(
                    collection: self.state.collection,
                    resultType: "collection",
                    limit: nil
                )
            }

            // Update collection name from response
            state.collection = result.collection

            // Sort by downloads
            state.items = sortByDownloads(result.results)
            state.isLoading = false

            ErrorLogger.shared.logSuccess(
                operation: .getCollections,
                info: ["collection": state.collection, "count": state.items.count]
            )

        } catch {
            state.isLoading = false
            state.errorMessage = mapErrorToMessage(error)

            ErrorLogger.shared.log(
                error: error,
                context: ErrorContext(
                    operation: .getCollections,
                    userFacingTitle: "Unable to Load Videos",
                    additionalInfo: ["collection": state.collection]
                )
            )
        }
    }

    /// Sort items by download count (highest first)
    func sortByDownloads(_ items: [SearchResult]) -> [SearchResult] {
        items.sorted { item1, item2 in
            (item1.downloads ?? 0) > (item2.downloads ?? 0)
        }
    }

    /// Get item at index
    func item(at index: Int) -> SearchResult? {
        guard index >= 0 && index < state.items.count else { return nil }
        return state.items[index]
    }

    /// Get navigation data for an item
    func navigationData(for index: Int) -> (collection: String, name: String, identifier: String)? {
        guard let item = item(at: index) else { return nil }
        return (
            collection: state.collection,
            name: item.title ?? item.identifier,
            identifier: item.identifier
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

// Note: Uses DefaultCollectionService defined in CollectionViewModel.swift
