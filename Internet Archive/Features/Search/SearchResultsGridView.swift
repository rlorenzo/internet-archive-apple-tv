//
//  SearchResultsGridView.swift
//  Internet Archive
//
//  Full grid view for search results of a single media type
//

import SwiftUI

/// A full-screen grid view showing all search results for a specific media type.
///
/// This view is navigated to from the "See All" button in search results sections.
/// It displays results in a grid layout with pagination support.
struct SearchResultsGridView: View {
    let title: String
    let query: String
    let mediaType: MediaItemCard.MediaType
    @Binding var navigationPath: NavigationPath

    @State private var results: [SearchResult] = []
    @State private var isLoading = true
    @State private var isLoadingMore = false
    @State private var hasMore = false
    @State private var currentPage = 0
    @State private var errorMessage: String?
    @State private var loadTask: Task<Void, Never>?

    private let pageSize = 30

    var body: some View {
        Group {
            if isLoading && results.isEmpty {
                loadingView
            } else if let error = errorMessage, results.isEmpty {
                errorView(message: error)
            } else if results.isEmpty {
                emptyView
            } else {
                gridView
            }
        }
        .onAppear {
            if results.isEmpty {
                loadResults(page: 0)
            }
        }
        .onDisappear {
            loadTask?.cancel()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ScrollView {
            SkeletonGrid(
                cardType: mediaType == .video ? .video : .music,
                columns: mediaType == .video ? 4 : 6,
                rows: 3
            )
            .padding(80)
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack {
            Spacer()
            ErrorContentView.loadingFailed(contentType: "results") {
                loadResults(page: 0)
            }
            Spacer()
        }
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack {
            Spacer()
            EmptyContentView.noSearchResults()
            Spacer()
        }
    }

    // MARK: - Grid View

    private var gridView: some View {
        ScrollView {
            LazyVGrid(
                columns: gridColumns,
                spacing: 48
            ) {
                ForEach(results) { item in
                    Button {
                        navigationPath.append(item)
                    } label: {
                        SearchResultCard(item: item, mediaType: mediaType)
                    }
                    .tvCardStyle()
                    .onAppear {
                        checkLoadMore(item: item)
                    }
                }

                if isLoadingMore {
                    ForEach(0..<skeletonCardCount, id: \.self) { _ in
                        if mediaType == .video {
                            SkeletonCard.video
                        } else {
                            SkeletonCard.music
                        }
                    }
                }
            }
            .padding(80)
        }
    }

    private var gridColumns: [GridItem] {
        if mediaType == .video {
            return [GridItem(.adaptive(minimum: 340, maximum: 420), spacing: 48)]
        } else {
            return [GridItem(.adaptive(minimum: 200, maximum: 240), spacing: 40)]
        }
    }

    private var skeletonCardCount: Int {
        mediaType == .video ? 4 : 6
    }

    // MARK: - Data Loading

    private func loadResults(page: Int) {
        loadTask?.cancel()

        if page == 0 {
            isLoading = true
            errorMessage = nil
        } else {
            isLoadingMore = true
        }

        loadTask = Task { @MainActor in
            do {
                let apiMediaType = mediaType == .video
                    ? SearchView.ContentFilter.videos.apiMediaType
                    : SearchView.ContentFilter.music.apiMediaType

                let options: [String: String] = [
                    "rows": "\(pageSize)",
                    "page": "\(page + 1)",
                    "fl[]": "identifier,title,mediatype,creator,description,date,year,downloads",
                    "sort[]": "downloads desc"
                ]

                let fullQuery = "\(query) AND mediatype:(\(apiMediaType))"
                let response = try await APIManager.networkService.search(
                    query: fullQuery,
                    options: options
                )

                guard !Task.isCancelled else { return }

                if page == 0 {
                    results = response.response.docs
                } else {
                    results.append(contentsOf: response.response.docs)
                }

                currentPage = page
                hasMore = response.response.docs.count == pageSize &&
                    (page + 1) * pageSize < response.response.numFound

                isLoading = false
                isLoadingMore = false
            } catch {
                guard !Task.isCancelled else { return }

                isLoading = false
                isLoadingMore = false

                if let networkError = error as? NetworkError {
                    errorMessage = ErrorPresenter.shared.userFriendlyMessage(for: networkError)
                } else {
                    errorMessage = "Failed to load results. Please try again."
                }
            }
        }
    }

    private func checkLoadMore(item: SearchResult) {
        guard hasMore,
              !isLoadingMore,
              let index = results.firstIndex(of: item),
              index >= results.count - 6 else { return }

        loadResults(page: currentPage + 1)
    }
}

// MARK: - Navigation Value

/// A hashable struct for navigating to the search results grid
struct SearchResultsDestination: Hashable {
    let title: String
    let query: String
    let mediaType: MediaItemCard.MediaType
}

// MARK: - Preview

#Preview {
    @Previewable @State var path = NavigationPath()
    NavigationStack(path: $path) {
        SearchResultsGridView(
            title: "Videos",
            query: "nature",
            mediaType: .video,
            navigationPath: $path
        )
    }
}
