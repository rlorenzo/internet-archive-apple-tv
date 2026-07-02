//
//  SearchView.swift
//  Internet Archive
//
//  Search interface for Internet Archive content
//

import SwiftUI

/// The search interface for finding content across Internet Archive collections.
///
/// This view provides:
/// - Text-based search with keyboard input via `.searchable` modifier
/// - Filter options for content type (All/Video/Music)
/// - Dual-section results display (Videos and Music)
/// - Pagination with infinite scroll
///
/// The view is a thin layer over two `SearchViewModel`s (one per section so
/// Videos and Music keep independent pagination); debounce, filter switching,
/// and navigation stay here.
struct SearchView: View {
    // MARK: - State

    @Environment(\.isCompactLayout) private var isCompactLayout

    @State private var searchText = ""
    @State private var selectedFilter: ContentFilter = .all
    @State private var isSearching = false

    /// Search view models - one per section so Videos and Music paginate
    /// independently. Page size matches the shipping UI (20 per page).
    @StateObject private var videoViewModel = SearchViewModel(
        searchService: DefaultSearchService(),
        pageSize: 20
    )
    @StateObject private var musicViewModel = SearchViewModel(
        searchService: DefaultSearchService(),
        pageSize: 20
    )

    /// The trimmed query the current results were fetched with. Pagination
    /// uses this so load-more requests match the page-0 query exactly.
    @State private var activeQuery = ""

    /// Navigation path
    @State private var navigationPath = NavigationPath()

    /// Debounce task for search input
    @State private var debounceTask: Task<Void, Never>?

    /// Active search task (cancelled when new search starts)
    @State private var activeSearchTask: Task<Void, Never>?

    /// Active pagination tasks (cancelled when new search starts)
    @State private var videoPaginationTask: Task<Void, Never>?
    @State private var musicPaginationTask: Task<Void, Never>?

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            contentArea
                .searchable(text: $searchText, prompt: "Search Internet Archive")
                .navigationDestination(for: SearchResult.self) { item in
                    ItemDetailView(
                        item: item,
                        mediaType: item.safeMediaType == ContentFilter.videos.apiMediaType ? .video : .music
                    )
                }
                .navigationDestination(for: SearchResultsDestination.self) { destination in
                    SearchResultsGridView(
                        query: destination.query,
                        mediaType: destination.mediaType,
                        navigationPath: $navigationPath
                    )
                }
        }
        .onChange(of: searchText) { _, newValue in
            handleSearchTextChange(newValue)
        }
        .onChange(of: selectedFilter) { _, _ in
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                performSearch(query: trimmed)
            }
        }
    }

    // MARK: - Results Accessors

    private var videoResults: [SearchResult] {
        videoViewModel.state.results
    }

    private var musicResults: [SearchResult] {
        musicViewModel.state.results
    }

    private var combinedErrorMessage: String? {
        videoViewModel.state.errorMessage ?? musicViewModel.state.errorMessage
    }

    // MARK: - Filter Picker

    private var filterPicker: some View {
        Picker("Content Type", selection: $selectedFilter) {
            ForEach(ContentFilter.allCases) { filter in
                Text(filter.displayName).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, PlatformMetrics.horizontalPadding(compact: isCompactLayout))
        .padding(.top, 20)
        .padding(.bottom, 10)
        .accessibilityLabel("Content type filter")
        .accessibilityHint("Select to filter results by content type")
    }

    // MARK: - Content Area

    /// Which content state to show, via the shared tested helper.
    /// A full-screen error only makes sense when there is nothing to show:
    /// pagination failures with results on screen stay silent (matching the
    /// previous behavior).
    private var contentState: SearchContentState {
        let hasBlockingError = combinedErrorMessage != nil
            && videoResults.isEmpty && musicResults.isEmpty

        return SearchContentState.determine(
            searchText: searchText,
            isSearching: isSearching,
            hasError: hasBlockingError,
            videoResultsCount: videoResults.count,
            musicResultsCount: musicResults.count
        )
    }

    @ViewBuilder
    private var contentArea: some View {
        switch contentState {
        case .empty:
            emptySearchState
        case .loading:
            loadingState
        case .error:
            errorState
        case .noResults:
            noResultsState
        case .results:
            searchResultsView
        }
    }

    // MARK: - Empty Search State

    private var emptySearchState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 80))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)

            Text("Search the Internet Archive")
                .font(.title2)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)

            Text("Find videos, music, and more from the world's largest digital library")
                .font(.body)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 600)

            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Search the Internet Archive. Find videos, music, and more from the world's largest digital library.")
    }

    // MARK: - Loading State

    private var loadingState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                filterPicker

                VStack(alignment: .leading, spacing: 60) {
                    if selectedFilter.includesVideos {
                        SkeletonRow(cardType: .video, count: 4)
                    }

                    if selectedFilter.includesMusic {
                        SkeletonRow(cardType: .music, count: 6)
                    }
                }
                .padding(.horizontal, PlatformMetrics.horizontalPadding(compact: isCompactLayout))
            }
            .padding(.vertical, 40)
        }
    }

    // MARK: - Error State

    private var errorState: some View {
        VStack {
            Spacer()
            ErrorContentView.loadingFailed(contentType: "search results") {
                performSearch(query: activeQuery)
            }
            Spacer()
        }
    }

    // MARK: - No Results State

    private var noResultsState: some View {
        VStack {
            Spacer()
            EmptyContentView.noSearchResults {
                searchText = ""
            }
            Spacer()
        }
    }

    // MARK: - Search Results View

    private var searchResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                filterPicker

                VStack(alignment: .leading, spacing: 60) {
                    if selectedFilter.includesVideos && !videoResults.isEmpty {
                        resultsSection(
                            title: "Videos",
                            results: videoResults,
                            mediaType: .video,
                            isLoadingMore: videoViewModel.state.isLoading && !videoResults.isEmpty,
                            onItemAppear: checkLoadMoreVideos,
                            onSeeAll: {
                                navigationPath.append(SearchResultsDestination(
                                    query: activeQuery,
                                    mediaType: .video
                                ))
                            }
                        )
                        .tvFocusSection()
                    }

                    if selectedFilter.includesMusic && !musicResults.isEmpty {
                        resultsSection(
                            title: "Music",
                            results: musicResults,
                            mediaType: .music,
                            isLoadingMore: musicViewModel.state.isLoading && !musicResults.isEmpty,
                            onItemAppear: checkLoadMoreMusic,
                            onSeeAll: {
                                navigationPath.append(SearchResultsDestination(
                                    query: activeQuery,
                                    mediaType: .music
                                ))
                            }
                        )
                        .tvFocusSection()
                    }
                }
                .padding(.horizontal, PlatformMetrics.horizontalPadding(compact: isCompactLayout))
            }
            .padding(.vertical, 40)
        }
    }

    // MARK: - Results Section (DRY)

    // swiftlint:disable:next function_parameter_count
    private func resultsSection(
        title: String,
        results: [SearchResult],
        mediaType: MediaItemCard.MediaType,
        isLoadingMore: Bool,
        onItemAppear: @escaping (SearchResult) -> Void,
        onSeeAll: @escaping () -> Void
    ) -> some View {
        let spacing: CGFloat = mediaType == .video ? 48 : 40

        return VStack(alignment: .leading, spacing: 20) {
            // "See All" button without section header text
            HStack {
                Spacer()
                Button {
                    onSeeAll()
                } label: {
                    HStack(spacing: 4) {
                        Text("\(results.count) results")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("See all \(results.count) \(title.lowercased()) results")
                .accessibilityHint("Double-tap to view all results in a grid")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: spacing) {
                    ForEach(results) { item in
                        Button {
                            navigationPath.append(item)
                        } label: {
                            SearchResultCard(item: item, mediaType: mediaType)
                        }
                        .tvCardStyle()
                        .onAppear {
                            onItemAppear(item)
                        }
                    }

                    if isLoadingMore {
                        ProgressView()
                            .frame(width: 100)
                            .accessibilityLabel("Loading more results")
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 50)
            }
            .contentMargins(.horizontal, -40, for: .scrollContent)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(title) search results")
        }
    }

    // MARK: - Search Logic

    private func handleSearchTextChange(_ newValue: String) {
        // Cancel debounce and any active search
        debounceTask?.cancel()
        activeSearchTask?.cancel()

        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            clearResults()
            return
        }

        // Debounce search by 500ms
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)

            if !Task.isCancelled {
                performSearch(query: trimmed)
            }
        }
    }

    private func clearResults() {
        cancelAllSearchTasks()
        videoViewModel.clearResults()
        musicViewModel.clearResults()
        activeQuery = ""
        isSearching = false
    }

    private func cancelAllSearchTasks() {
        activeSearchTask?.cancel()
        videoPaginationTask?.cancel()
        musicPaginationTask?.cancel()
    }

    /// Run page-0 searches for the sections included by the current filter.
    /// Excluded sections are cleared so stale results don't reappear when
    /// switching filters back and forth.
    private func performSearch(query: String) {
        guard !query.isEmpty else { return }

        // Cancel any in-flight search/pagination to prevent stale results
        // overwriting newer ones
        cancelAllSearchTasks()

        activeQuery = query
        isSearching = true
        videoViewModel.clearResults()
        musicViewModel.clearResults()

        let filter = selectedFilter

        // Both sections search concurrently (separate main-actor tasks whose
        // network awaits interleave), matching the previous async-let timing.
        let videoTask = Task { @MainActor in
            await searchSection(
                viewModel: videoViewModel,
                include: filter.includesVideos,
                query: query,
                apiMediaType: ContentFilter.videos.apiMediaType
            )
        }
        let musicTask = Task { @MainActor in
            await searchSection(
                viewModel: musicViewModel,
                include: filter.includesMusic,
                query: query,
                apiMediaType: ContentFilter.music.apiMediaType
            )
        }

        activeSearchTask = Task { @MainActor in
            // Forward cancellation to the section tasks (unstructured tasks
            // don't inherit it)
            await withTaskCancellationHandler {
                await videoTask.value
                await musicTask.value
            } onCancel: {
                videoTask.cancel()
                musicTask.cancel()
            }

            guard !Task.isCancelled else { return }
            isSearching = false
        }
    }

    private func searchSection(
        viewModel: SearchViewModel,
        include: Bool,
        query: String,
        apiMediaType: String
    ) async {
        guard include else {
            viewModel.clearResults()
            return
        }
        await viewModel.search(
            query: SearchQueryBuilder.buildQuery(searchText: query, mediaType: apiMediaType)
        )
    }

    // MARK: - Pagination

    private func checkLoadMoreVideos(item: SearchResult) {
        guard videoViewModel.state.hasMoreResults,
              !videoViewModel.state.isLoading,
              let index = videoResults.firstIndex(of: item),
              index >= videoResults.count - 3 else { return }

        loadMoreVideos()
    }

    private func loadMoreVideos() {
        let query = activeQuery
        guard !query.isEmpty else { return }

        videoPaginationTask = Task { @MainActor in
            await videoViewModel.loadNextPage(
                query: SearchQueryBuilder.buildQuery(
                    searchText: query,
                    mediaType: ContentFilter.videos.apiMediaType
                )
            )
        }
    }

    private func checkLoadMoreMusic(item: SearchResult) {
        guard musicViewModel.state.hasMoreResults,
              !musicViewModel.state.isLoading,
              let index = musicResults.firstIndex(of: item),
              index >= musicResults.count - 3 else { return }

        loadMoreMusic()
    }

    private func loadMoreMusic() {
        let query = activeQuery
        guard !query.isEmpty else { return }

        musicPaginationTask = Task { @MainActor in
            await musicViewModel.loadNextPage(
                query: SearchQueryBuilder.buildQuery(
                    searchText: query,
                    mediaType: ContentFilter.music.apiMediaType
                )
            )
        }
    }
}

// MARK: - Content Filter

extension SearchView {
    /// Filter options for search results.
    ///
    /// Alias for the tested `SearchContentFilter` helper in SearchHelpers -
    /// kept as a nested name so call sites keep reading naturally.
    typealias ContentFilter = SearchContentFilter
}

// MARK: - Preview

#Preview {
    SearchView()
        .environmentObject(AppState())
}
