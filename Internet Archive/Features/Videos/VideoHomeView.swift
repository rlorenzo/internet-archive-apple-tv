//
//  VideoHomeView.swift
//  Internet Archive
//
//  Home screen for browsing video content
//

import SwiftUI

/// The main video browsing screen displaying video collections from Internet Archive.
///
/// This view shows:
/// - Continue Watching section for resuming playback
/// - Featured video collections grid
struct VideoHomeView: View {
    // MARK: - Environment & State

    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = VideoViewModel(collectionService: DefaultCollectionService())

    /// Continue watching items from PlaybackProgressManager
    @State private var continueWatchingItems: [PlaybackProgress] = []

    /// Navigation path for programmatic navigation control
    @State private var navigationPath = NavigationPath()

    /// Selected sort order for the featured videos grid
    @State private var selectedSort: CollectionSortOption = .weeklyViews

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.state.isLoading && !viewModel.state.hasLoaded {
                    loadingView
                } else if let errorMessage = viewModel.state.errorMessage {
                    MediaHomeErrorView(message: errorMessage, onRetry: loadContent)
                } else {
                    contentView
                }
            }
            .navigationDestination(for: SearchResult.self) { item in
                // Collections navigate to browser, individual items to detail
                if item.mediatype == "collection" {
                    CollectionBrowserView(
                        collection: item,
                        mediaType: .video,
                        navigationPath: $navigationPath
                    )
                } else {
                    ItemDetailView(item: item, mediaType: .video)
                }
            }
            .navigationDestination(for: YearBrowseDestination.self) { destination in
                YearBrowseView(
                    collection: destination.collection,
                    mediaType: destination.mediaType,
                    navigationPath: $navigationPath
                )
            }
        }
        .task {
            await loadContent()
        }
        .onAppear {
            refreshContinueWatching()
        }
        .onChange(of: selectedSort) { _, newValue in
            Task { await viewModel.setSortOption(newValue) }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 60) {
                continueWatchingSection
                featuredVideosSection
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 40)
        }
    }

    // MARK: - Continue Watching Section

    @ViewBuilder
    private var continueWatchingSection: some View {
        if !continueWatchingItems.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader("Continue Watching")
                    .accessibilityAddTraits(.isHeader)

                ContinueWatchingSection(
                    items: continueWatchingItems,
                    mediaType: .video
                ) { progress in
                    handleContinueWatchingTap(progress)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Continue watching section with \(continueWatchingItems.count) videos")
        }
    }

    // MARK: - Featured Videos Section

    private var featuredVideosSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Featured Videos")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Picker("Sort by", selection: $selectedSort) {
                    ForEach(CollectionSortOption.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 400)
                .accessibilityLabel("Sort order")
            }

            if viewModel.state.isLoading && !viewModel.state.hasItems {
                SkeletonGrid(cardType: .video, columns: 4, rows: 3)
            } else if viewModel.state.hasItems {
                LazyVGrid(
                    columns: SearchResultsGridHelpers.gridColumns(for: .video),
                    spacing: 48
                ) {
                    ForEach(viewModel.state.items) { item in
                        Button {
                            navigationPath.append(item)
                        } label: {
                            SearchResultCard(item: item, mediaType: .video)
                        }
                        .tvCardStyle()
                        .onAppear {
                            Task { await viewModel.loadNextPageIfNeeded(currentItem: item) }
                        }
                    }

                    if viewModel.state.isLoadingMore {
                        ForEach(0..<SearchResultsGridHelpers.skeletonCardCount(for: .video), id: \.self) { _ in
                            SkeletonCard.video
                        }
                    }
                }

                if !viewModel.state.hasMore && viewModel.state.hasLoaded {
                    noMoreContentView
                }
            } else if viewModel.state.hasLoaded {
                EmptyContentView.emptyCollection(collectionName: "videos")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Featured videos section with \(viewModel.state.items.count) items")
    }

    private var noMoreContentView: some View {
        Text("No More Content")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 50) {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader("Continue Watching")
                    SkeletonRow(cardType: .video, count: 4)
                }

                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader("Featured Videos")
                    SkeletonGrid(cardType: .video, columns: 4, rows: 3)
                }
                .padding(.horizontal, 80)
            }
            .padding(.vertical, 40)
        }
    }

    // MARK: - Data Loading

    private func loadContent() async {
        await viewModel.loadInitialPage()
    }

    private func refreshContinueWatching() {
        continueWatchingItems = PlaybackProgressManager.shared.getContinueWatchingItems()
    }

    // MARK: - Helpers

    private func handleContinueWatchingTap(_ progress: PlaybackProgress) {
        // Create a SearchResult from the progress data to navigate to ItemDetailView
        let item = SearchResult(
            identifier: progress.itemIdentifier,
            title: progress.title,
            mediatype: progress.mediaType
        )
        navigationPath.append(item)
    }
}

// MARK: - Preview

#Preview {
    VideoHomeView()
        .environmentObject(AppState())
}
