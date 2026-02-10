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
struct SearchView: View {
    @EnvironmentObject private var appState: AppState

    /// Binding to expose navigation depth to parent for exit command handling
    @Binding var hasNavigationHistory: Bool

    // MARK: - State

    @State private var searchText = ""
    @State private var selectedFilter: ContentFilter = .all
    @State private var isSearching = false

    /// Search results
    @State private var videoResults: [SearchResult] = []
    @State private var musicResults: [SearchResult] = []

    /// Pagination state
    @State private var videoPage = 0
    @State private var musicPage = 0
    @State private var hasMoreVideos = false
    @State private var hasMoreMusic = false
    @State private var isLoadingMoreVideos = false
    @State private var isLoadingMoreMusic = false

    /// Error state
    @State private var errorMessage: String?

    /// Navigation path
    @State private var navigationPath = NavigationPath()

    /// Debounce task for search input
    @State private var debounceTask: Task<Void, Never>?

    /// Active search task (cancelled when new search starts)
    @State private var activeSearchTask: Task<Void, Never>?

    /// Active pagination tasks (cancelled when new search starts)
    @State private var videoPaginationTask: Task<Void, Never>?
    @State private var musicPaginationTask: Task<Void, Never>?

    /// Page size for results
    private let pageSize = 20

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
                        title: destination.title,
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
            if !searchText.isEmpty {
                performSearch(query: searchText, resetResults: true)
            }
        }
        .onChange(of: navigationPath.count) { _, newCount in
            // Sync navigation state with parent
            hasNavigationHistory = newCount > 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .popSearchNavigation)) { _ in
            // Handle pop request from parent (when Menu pressed on tab bar)
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
            }
        }
    }

    // MARK: - Filter Picker

    private var filterPicker: some View {
        Picker("Content Type", selection: $selectedFilter) {
            ForEach(ContentFilter.allCases) { filter in
                Text(filter.displayName).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 80)
        .padding(.top, 20)
        .padding(.bottom, 10)
        .accessibilityLabel("Content type filter")
        .accessibilityHint("Select to filter results by content type")
    }

    // MARK: - Content Area

    /// Computed property to determine which content state to show
    private var contentState: ContentState {
        if searchText.isEmpty {
            return .empty
        } else if isSearching && videoResults.isEmpty && musicResults.isEmpty {
            return .loading
        } else if errorMessage != nil {
            return .error
        } else if videoResults.isEmpty && musicResults.isEmpty {
            return .noResults
        } else {
            return .results
        }
    }

    private enum ContentState {
        case empty, loading, error, noResults, results
    }

    @ViewBuilder
    private var contentArea: some View {
        // Use switch statement for cleaner state handling
        // Each state returns a completely separate view hierarchy
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
                    if selectedFilter != .music {
                        SkeletonRow(cardType: .video, count: 4)
                    }

                    if selectedFilter != .videos {
                        SkeletonRow(cardType: .music, count: 6)
                    }
                }
                .padding(.horizontal, 80)
            }
            .padding(.vertical, 40)
        }
    }

    // MARK: - Error State

    private var errorState: some View {
        VStack {
            Spacer()
            ErrorContentView.loadingFailed(contentType: "search results") {
                performSearch(query: searchText, resetResults: true)
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
                    if selectedFilter != .music && !videoResults.isEmpty {
                        resultsSection(
                            title: "Videos",
                            results: videoResults,
                            mediaType: .video,
                            isLoadingMore: isLoadingMoreVideos,
                            onItemAppear: checkLoadMoreVideos,
                            onSeeAll: {
                                navigationPath.append(SearchResultsDestination(
                                    title: "Videos",
                                    query: searchText,
                                    mediaType: .video
                                ))
                            }
                        )
                    }

                    if selectedFilter != .videos && !musicResults.isEmpty {
                        resultsSection(
                            title: "Music",
                            results: musicResults,
                            mediaType: .music,
                            isLoadingMore: isLoadingMoreMusic,
                            onItemAppear: checkLoadMoreMusic,
                            onSeeAll: {
                                navigationPath.append(SearchResultsDestination(
                                    title: "Music",
                                    query: searchText,
                                    mediaType: .music
                                ))
                            }
                        )
                    }
                }
                .padding(.horizontal, 80)
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
                performSearch(query: trimmed, resetResults: true)
            }
        }
    }

    private func clearResults() {
        cancelAllSearchTasks()
        videoResults = []
        musicResults = []
        videoPage = 0
        musicPage = 0
        hasMoreVideos = false
        hasMoreMusic = false
        errorMessage = nil
        isSearching = false
    }

    private func cancelAllSearchTasks() {
        activeSearchTask?.cancel()
        videoPaginationTask?.cancel()
        musicPaginationTask?.cancel()
    }

    private func performSearch(query: String, resetResults: Bool) {
        guard !query.isEmpty else { return }

        // Cancel any in-flight search/pagination to prevent stale results overwriting newer ones
        cancelAllSearchTasks()

        if resetResults {
            isSearching = true
            errorMessage = nil
            videoResults = []
            musicResults = []
            videoPage = 0
            musicPage = 0
        }

        let currentFilter = selectedFilter

        activeSearchTask = Task { @MainActor in
            do {
                switch currentFilter {
                case .all:
                    async let videosTask = searchMedia(
                        query: query,
                        mediaType: ContentFilter.videos.apiMediaType,
                        page: 0
                    )
                    async let musicTask = searchMedia(
                        query: query,
                        mediaType: ContentFilter.music.apiMediaType,
                        page: 0
                    )

                    let (videos, music) = try await (videosTask, musicTask)

                    // Check if cancelled before updating state
                    guard !Task.isCancelled else { return }

                    videoResults = videos.results
                    hasMoreVideos = videos.hasMore
                    musicResults = music.results
                    hasMoreMusic = music.hasMore

                case .videos:
                    let videos = try await searchMedia(
                        query: query,
                        mediaType: ContentFilter.videos.apiMediaType,
                        page: 0
                    )

                    guard !Task.isCancelled else { return }

                    videoResults = videos.results
                    hasMoreVideos = videos.hasMore

                case .music:
                    let music = try await searchMedia(
                        query: query,
                        mediaType: ContentFilter.music.apiMediaType,
                        page: 0
                    )

                    guard !Task.isCancelled else { return }

                    musicResults = music.results
                    hasMoreMusic = music.hasMore
                }

                isSearching = false
            } catch {
                // Don't update error state if cancelled
                guard !Task.isCancelled else { return }

                isSearching = false
                if let networkError = error as? NetworkError {
                    errorMessage = ErrorPresenter.shared.userFriendlyMessage(for: networkError)
                } else {
                    errorMessage = "An error occurred while searching. Please try again."
                }
            }
        }
    }

    private func searchMedia(
        query: String,
        mediaType: String,
        page: Int
    ) async throws -> (results: [SearchResult], hasMore: Bool) {
        let options: [String: String] = [
            "rows": "\(pageSize)",
            "page": "\(page + 1)",
            "fl[]": "identifier,title,mediatype,creator,description,date,year,downloads",
            "sort[]": "downloads desc"
        ]

        let fullQuery = "\(query) AND mediatype:(\(mediaType))"
        let response = try await APIManager.networkService.search(query: fullQuery, options: options)

        let hasMore = response.response.docs.count == pageSize &&
            (page + 1) * pageSize < response.response.numFound

        return (response.response.docs, hasMore)
    }

    // MARK: - Pagination

    private func checkLoadMoreVideos(item: SearchResult) {
        guard hasMoreVideos,
              !isLoadingMoreVideos,
              let index = videoResults.firstIndex(of: item),
              index >= videoResults.count - 3 else { return }

        loadMoreVideos()
    }

    private func loadMoreVideos() {
        guard !isLoadingMoreVideos, hasMoreVideos else { return }

        isLoadingMoreVideos = true
        let nextPage = videoPage + 1
        let currentQuery = searchText

        videoPaginationTask = Task { @MainActor in
            do {
                let result = try await searchMedia(
                    query: currentQuery,
                    mediaType: ContentFilter.videos.apiMediaType,
                    page: nextPage
                )

                // Don't update if cancelled or query changed
                guard !Task.isCancelled, searchText == currentQuery else {
                    isLoadingMoreVideos = false
                    return
                }

                videoResults.append(contentsOf: result.results)
                videoPage = nextPage
                hasMoreVideos = result.hasMore
            } catch {
                // Silently fail pagination - don't show error for loading more
            }
            isLoadingMoreVideos = false
        }
    }

    private func checkLoadMoreMusic(item: SearchResult) {
        guard hasMoreMusic,
              !isLoadingMoreMusic,
              let index = musicResults.firstIndex(of: item),
              index >= musicResults.count - 3 else { return }

        loadMoreMusic()
    }

    private func loadMoreMusic() {
        guard !isLoadingMoreMusic, hasMoreMusic else { return }

        isLoadingMoreMusic = true
        let nextPage = musicPage + 1
        let currentQuery = searchText

        musicPaginationTask = Task { @MainActor in
            do {
                let result = try await searchMedia(
                    query: currentQuery,
                    mediaType: ContentFilter.music.apiMediaType,
                    page: nextPage
                )

                // Don't update if cancelled or query changed
                guard !Task.isCancelled, searchText == currentQuery else {
                    isLoadingMoreMusic = false
                    return
                }

                musicResults.append(contentsOf: result.results)
                musicPage = nextPage
                hasMoreMusic = result.hasMore
            } catch {
                // Silently fail pagination
            }
            isLoadingMoreMusic = false
        }
    }
}

// MARK: - Content Filter

extension SearchView {
    /// Filter options for search results
    enum ContentFilter: String, CaseIterable, Identifiable {
        case all
        case videos
        case music

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .all: return "All"
            case .videos: return "Videos"
            case .music: return "Music"
            }
        }

        /// The media type query parameter for the API
        var apiMediaType: String {
            switch self {
            case .all: return "movies OR etree OR audio"
            case .videos: return "movies"
            case .music: return "etree OR audio"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SearchView(hasNavigationHistory: .constant(false))
        .environmentObject(AppState())
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when parent requests search navigation to pop back
    static let popSearchNavigation = Notification.Name("popSearchNavigation")
}
