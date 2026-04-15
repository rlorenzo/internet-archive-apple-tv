//
//  MusicViewModel.swift
//  Internet Archive
//
//  ViewModel for music collections with testable business logic
//

import Foundation

// Note: Uses CollectionServiceProtocol defined in CollectionViewModel.swift

/// ViewModel state for music collection
struct MusicViewState: Sendable {
    var isLoading: Bool = false
    var hasLoaded: Bool = false
    var collection: String = "etree"
    var collectionTitle: String?
    var items: [SearchResult] = []
    var errorMessage: String?
    var sortOption: CollectionSortOption = .weeklyViews

    // Pagination state
    var currentPage: Int = 0
    var isLoadingMore: Bool = false
    var hasMore: Bool = true
    var totalFound: Int = 0
    let pageSize: Int = 30

    static let initial = MusicViewState()

    /// Check if there are items to display
    var hasItems: Bool {
        !items.isEmpty
    }

    /// Get item count
    var itemCount: Int {
        items.count
    }

    /// Display title for the collection (fetched from API or fallback)
    var displayTitle: String {
        collectionTitle ?? "Music"
    }

    /// Whether we've attempted to load the title (success or failure)
    var hasTitleLoadAttempted: Bool = false
}

/// ViewModel for music screen - handles all business logic
@MainActor
final class MusicViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var state = MusicViewState.initial

    // MARK: - Dependencies

    private let collectionService: CollectionServiceProtocol
    private var currentLoadToken = UUID()

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

    /// Update the sort order and reload content from the beginning.
    func setSortOption(_ option: CollectionSortOption) async {
        guard option != state.sortOption else { return }
        state.sortOption = option
        await loadInitialPage()
    }

    /// Load the first page of content, resetting all pagination state.
    /// Uses the currently selected server-side sort option from `state.sortOption`, so no client-side sort is needed.
    func loadInitialPage() async {
        let loadToken = UUID()
        currentLoadToken = loadToken

        state.isLoading = true
        state.isLoadingMore = false
        state.errorMessage = nil
        state.currentPage = 0
        state.items = []
        state.hasMore = true
        state.totalFound = 0

        do {
            let response = try await RetryMechanism.execute(config: .standard) {
                try await self.collectionService.getCollectionPage(
                    collection: self.state.collection,
                    resultType: "collection",
                    page: 0,
                    pageSize: self.state.pageSize,
                    sort: self.state.sortOption.apiSortString
                )
            }

            guard loadToken == currentLoadToken else { return }
            state.items = response.response.docs
            state.totalFound = response.response.numFound
            state.hasMore = SearchResultsGridHelpers.hasMorePages(
                currentPage: 0,
                pageSize: state.pageSize,
                itemsLoaded: response.response.docs.count,
                totalFound: response.response.numFound
            )
            state.isLoading = false
            state.hasLoaded = true

            // Fetch the collection display title (non-fatal on error)
            await loadCollectionTitle()

            ErrorLogger.shared.logSuccess(
                operation: .getCollections,
                info: [
                    "collection": state.collection,
                    "page": 0,
                    "count": state.items.count,
                    "totalFound": state.totalFound
                ]
            )
        } catch {
            guard loadToken == currentLoadToken else { return }
            state.isLoading = false
            state.hasLoaded = true
            state.errorMessage = mapErrorToMessage(error)
            // Reveal the header even on failure so the user can still see the
            // fallback title and the sort picker to retry with a different sort.
            state.hasTitleLoadAttempted = true

            ErrorLogger.shared.log(
                error: error,
                context: ErrorContext(
                    operation: .getCollections,
                    additionalInfo: ["collection": state.collection]
                )
            )
        }
    }

    /// Load the next page if the given item is near the end of the loaded list.
    /// Called from onAppear on each grid item.
    func loadNextPageIfNeeded(currentItem: SearchResult) async {
        guard let index = state.items.firstIndex(where: { $0.identifier == currentItem.identifier }) else {
            return
        }

        guard SearchResultsGridHelpers.shouldLoadMore(
            itemIndex: index,
            totalItems: state.items.count,
            hasMore: state.hasMore,
            isLoadingMore: state.isLoadingMore
        ) else {
            return
        }

        await loadNextPage()
    }

    /// Fetch the next page and append results. Silent failure on load-more
    /// errors so scrolling remains responsive; user can scroll back to retry.
    private func loadNextPage() async {
        let loadToken = currentLoadToken
        let nextPage = state.currentPage + 1
        state.isLoadingMore = true

        do {
            let response = try await collectionService.getCollectionPage(
                collection: state.collection,
                resultType: "collection",
                page: nextPage,
                pageSize: state.pageSize,
                sort: self.state.sortOption.apiSortString
            )

            guard loadToken == currentLoadToken else { return }
            state.items.append(contentsOf: response.response.docs)
            state.currentPage = nextPage
            state.totalFound = response.response.numFound
            state.hasMore = SearchResultsGridHelpers.hasMorePages(
                currentPage: nextPage,
                pageSize: state.pageSize,
                itemsLoaded: response.response.docs.count,
                totalFound: response.response.numFound
            )
            state.isLoadingMore = false
        } catch {
            guard loadToken == currentLoadToken else { return }
            state.isLoadingMore = false
            ErrorLogger.shared.log(
                error: error,
                context: ErrorContext(
                    operation: .getCollections,
                    additionalInfo: [
                        "collection": state.collection,
                        "page": nextPage,
                        "loadMore": true
                    ]
                )
            )
        }
    }

    /// Load collection data (legacy non-paginated method; retained for compatibility)
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
            state.hasLoaded = true

            // Fetch collection metadata for the display title
            await loadCollectionTitle()

            ErrorLogger.shared.logSuccess(
                operation: .getCollections,
                info: ["collection": state.collection, "count": state.items.count]
            )

        } catch {
            state.isLoading = false
            state.hasLoaded = true
            state.errorMessage = mapErrorToMessage(error)

            ErrorLogger.shared.log(
                error: error,
                context: ErrorContext(
                    operation: .getCollections,
                    additionalInfo: ["collection": state.collection]
                )
            )
        }
    }

    /// Load the collection's display title from metadata
    private func loadCollectionTitle() async {
        do {
            let metadata = try await collectionService.getMetadata(identifier: state.collection)
            state.collectionTitle = metadata.metadata?.title
        } catch {
            // Non-fatal: use fallback title, but log for debugging
            ErrorLogger.shared.log(
                error: error,
                context: ErrorContext(
                    operation: .getMetadata,
                    additionalInfo: ["collection": state.collection]
                )
            )
        }
        // Mark as attempted regardless of success/failure so header shows
        state.hasTitleLoadAttempted = true
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
