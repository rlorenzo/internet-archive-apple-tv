//
//  MediaCollectionViewModel.swift
//  Internet Archive
//
//  Shared ViewModel for the video and music home screens with testable
//  business logic. VideoViewModel and MusicViewModel are thin, configured
//  subclasses of this class.
//

import Foundation

// Note: Uses CollectionServiceProtocol and DefaultCollectionService defined in CollectionViewModel.swift

// MARK: - Configuration

/// Per-media configuration for `MediaCollectionViewModel`.
struct MediaCollectionConfiguration: Sendable {
    /// Collection identifier loaded by default
    let defaultCollection: String

    /// Server-side page size for paginated loads
    let pageSize: Int

    /// Fallback display title when no collection title has been fetched
    let titleFallback: String

    /// Whether to fetch the collection's display title from metadata after loads
    let fetchesCollectionTitle: Bool

    /// User-facing title used when logging load failures (nil uses the logger default)
    let loadErrorTitle: String?

    /// Configuration for the video home screen
    static let video = MediaCollectionConfiguration(
        defaultCollection: "movies",
        pageSize: 24,
        titleFallback: "Videos",
        fetchesCollectionTitle: false,
        loadErrorTitle: "Unable to Load Videos"
    )

    /// Configuration for the music home screen
    static let music = MediaCollectionConfiguration(
        defaultCollection: "etree",
        pageSize: 30,
        titleFallback: "Music",
        fetchesCollectionTitle: true,
        loadErrorTitle: nil
    )
}

// MARK: - State

/// ViewModel state shared by the video and music collection screens
struct MediaCollectionViewState: Sendable {
    var isLoading: Bool = false
    var hasLoaded: Bool = false
    var collection: String
    /// Collection title fetched from metadata (only populated when the
    /// configuration fetches titles, i.e. the music screen)
    var collectionTitle: String?
    var items: [SearchResult] = []
    var errorMessage: String?
    var sortOption: CollectionSortOption = .weeklyViews

    // Pagination state
    var currentPage: Int = 0
    var isLoadingMore: Bool = false
    var hasMore: Bool = true
    var totalFound: Int = 0
    let pageSize: Int

    /// Fallback display title when no collection title is available
    let titleFallback: String

    /// Whether we've attempted to load the title (success or failure)
    var hasTitleLoadAttempted: Bool = false

    init(configuration: MediaCollectionConfiguration) {
        self.collection = configuration.defaultCollection
        self.pageSize = configuration.pageSize
        self.titleFallback = configuration.titleFallback
    }

    /// Initial state for the video home screen
    static let video = MediaCollectionViewState(configuration: .video)

    /// Initial state for the music home screen
    static let music = MediaCollectionViewState(configuration: .music)

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
        collectionTitle ?? titleFallback
    }
}

// MARK: - ViewModel

/// Shared ViewModel for the media home screens - handles all business logic.
///
/// Parameterized by `MediaCollectionConfiguration` so the video and music
/// screens share one implementation while keeping their own default
/// collection, page size, and display-title behavior.
@MainActor
class MediaCollectionViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var state: MediaCollectionViewState

    // MARK: - Dependencies

    private let collectionService: CollectionServiceProtocol
    private let configuration: MediaCollectionConfiguration
    private var currentLoadToken = UUID()

    // MARK: - Initialization

    init(collectionService: CollectionServiceProtocol, configuration: MediaCollectionConfiguration) {
        self.collectionService = collectionService
        self.configuration = configuration
        self.state = MediaCollectionViewState(configuration: configuration)
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
    /// Uses the currently selected server-side sort option from `state.sortOption`,
    /// so no client-side sorting is needed.
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
            if configuration.fetchesCollectionTitle {
                await loadCollectionTitle(loadToken: loadToken)
            }

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
            handleLoadFailure(error)
            if configuration.fetchesCollectionTitle {
                // Reveal the header even on failure so the user can still see the
                // fallback title and the sort picker to retry with a different sort.
                state.hasTitleLoadAttempted = true
            }
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
            // De-duplicate: IA sort orders shift between pages, so page N+1
            // can re-contain page-N items (duplicate ForEach IDs break focus)
            SearchResultDeduplicator.appendUnique(response.response.docs, to: &state.items)
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
        let loadToken = UUID()
        currentLoadToken = loadToken

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

            // A stale response (a newer load started meanwhile) must not
            // overwrite the newer load's state
            guard loadToken == currentLoadToken else { return }

            // Update collection name from response
            state.collection = result.collection

            // Sort by downloads
            state.items = sortByDownloads(result.results)
            state.isLoading = false
            state.hasLoaded = true

            // Fetch collection metadata for the display title, passing the
            // token captured at the start so a stale title is discarded
            if configuration.fetchesCollectionTitle {
                await loadCollectionTitle(loadToken: loadToken)
            }

            ErrorLogger.shared.logSuccess(
                operation: .getCollections,
                info: ["collection": state.collection, "count": state.items.count]
            )

        } catch {
            guard loadToken == currentLoadToken else { return }
            handleLoadFailure(error)
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

    /// Load the collection's display title from metadata.
    ///
    /// Guards against stale responses: if `setCollection` + a new load ran
    /// while this metadata request was in flight, the outdated title is
    /// discarded instead of overwriting the newer collection's title.
    private func loadCollectionTitle(loadToken: UUID) async {
        do {
            let metadata = try await collectionService.getMetadata(identifier: state.collection)
            guard loadToken == currentLoadToken else { return }
            state.collectionTitle = metadata.metadata?.title
        } catch {
            guard loadToken == currentLoadToken else { return }
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

    /// Shared failure bookkeeping for `loadInitialPage`/`loadCollection`:
    /// finishes the load, surfaces a user-facing message, and logs the error.
    private func handleLoadFailure(_ error: Error) {
        state.isLoading = false
        state.hasLoaded = true
        state.errorMessage = mapErrorToMessage(error)

        ErrorLogger.shared.log(
            error: error,
            context: ErrorContext(
                operation: .getCollections,
                userFacingTitle: configuration.loadErrorTitle ?? "Error",
                additionalInfo: ["collection": state.collection]
            )
        )
    }

    private func mapErrorToMessage(_ error: Error) -> String {
        ErrorMessageMapper.message(for: error)
    }
}
