//
//  MediaHomeView.swift
//  Internet Archive
//
//  Shared home screen for browsing media content. VideoHomeView and
//  MusicHomeView are thin wrappers that supply a configuration and
//  their view model.
//

import SwiftUI

// MARK: - Configuration

/// Per-media configuration for `MediaHomeView`.
struct MediaHomeConfiguration {
    /// Media kind driving cards, grid sizing, skeletons, and navigation destinations
    let mediaType: MediaItemCard.MediaType

    /// Filter (and progress source) for the continue watching/listening shelf
    let continueFilter: ContinueWatchingSection.MediaFilter

    /// Header title of the continue watching/listening shelf
    let continueTitle: String

    /// Accessibility label for the continue shelf, given the item count
    let continueAccessibilityLabel: (Int) -> String

    /// Title for the featured grid header, given the current state
    let featuredTitle: (MediaCollectionViewState) -> String

    /// Hide the featured header row until a title load attempt completes
    /// (used by music, whose title is fetched from collection metadata)
    let hidesHeaderUntilTitleLoads: Bool

    /// Accessibility label for the featured section, given the current state
    let featuredAccessibilityLabel: (MediaCollectionViewState) -> String

    /// Collection name shown in the empty-collection state
    let emptyCollectionName: String

    /// Column count for the loading skeleton grid
    let skeletonColumns: Int

    /// Featured grid spacing on non-compact layouts
    let gridSpacing: CGFloat

    /// Section spacing in the initial loading view
    let loadingSpacing: CGFloat
}

// MARK: - Media Home View

/// The main media browsing screen displaying collections from Internet Archive.
///
/// This view shows:
/// - Continue Watching/Listening section for resuming playback
/// - Featured collections grid
struct MediaHomeView: View {
    // MARK: - Environment & State

    let configuration: MediaHomeConfiguration

    /// View model owned (as @StateObject) by the wrapping home view
    @ObservedObject var viewModel: MediaCollectionViewModel

    @Environment(\.isCompactLayout) private var isCompactLayout

    /// Continue watching/listening items from PlaybackProgressManager
    @State private var continueItems: [PlaybackProgress] = []

    /// Navigation path for programmatic navigation control
    @State private var navigationPath = NavigationPath()

    /// Selected sort order for the featured grid
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
                        mediaType: configuration.mediaType,
                        navigationPath: $navigationPath
                    )
                } else {
                    ItemDetailView(item: item, mediaType: configuration.mediaType)
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
            // Only load on first appearance - .task re-runs every time the
            // tab is revisited and an unconditional load would reset the
            // grid (and the user's scroll/focus position) each time.
            // Sort changes still reload via onChange below.
            if !viewModel.state.hasLoaded {
                await loadContent()
            }
        }
        .onAppear {
            refreshContinueItems()
        }
        .onChange(of: selectedSort) { _, newValue in
            Task { await viewModel.setSortOption(newValue) }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isCompactLayout == true ? 24 : 60) {
                continueSection
                featuredSection
            }
            .padding(.horizontal, PlatformMetrics.horizontalPadding(compact: isCompactLayout))
            .padding(.vertical, isCompactLayout == true ? 16 : 40)
        }
    }

    // MARK: - Continue Watching/Listening Section

    @ViewBuilder
    private var continueSection: some View {
        if !continueItems.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(configuration.continueTitle)
                    .accessibilityAddTraits(.isHeader)

                ContinueWatchingSection(
                    items: continueItems,
                    mediaType: configuration.continueFilter
                ) { progress in
                    handleContinueItemTap(progress)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(configuration.continueAccessibilityLabel(continueItems.count))
        }
    }

    // MARK: - Featured Section

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Only show a dynamic title after the load attempt to avoid flash
            HStack {
                Text(configuration.featuredTitle(viewModel.state))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                sortPicker
            }
            .opacity(headerOpacity)

            if viewModel.state.isLoading && !viewModel.state.hasItems {
                SkeletonGrid(cardType: skeletonGridCardType, columns: configuration.skeletonColumns, rows: 3)
            } else if viewModel.state.hasItems {
                LazyVGrid(
                    columns: SearchResultsGridHelpers.gridColumns(for: configuration.mediaType, compact: isCompactLayout),
                    spacing: isCompactLayout == true ? 16 : configuration.gridSpacing
                ) {
                    ForEach(viewModel.state.items) { item in
                        Button {
                            navigationPath.append(item)
                        } label: {
                            SearchResultCard(item: item, mediaType: configuration.mediaType, stretches: isCompactLayout == true)
                        }
                        .tvCardStyle()
                        .onAppear {
                            Task { await viewModel.loadNextPageIfNeeded(currentItem: item) }
                        }
                    }

                    if viewModel.state.isLoadingMore {
                        ForEach(0..<SearchResultsGridHelpers.skeletonCardCount(for: configuration.mediaType), id: \.self) { _ in
                            loadMoreSkeletonCard
                        }
                    }
                }

                if !viewModel.state.hasMore && viewModel.state.hasLoaded {
                    noMoreContentView
                }
            } else if viewModel.state.hasLoaded {
                EmptyContentView.emptyCollection(collectionName: configuration.emptyCollectionName)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(configuration.featuredAccessibilityLabel(viewModel.state))
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
            VStack(alignment: .leading, spacing: configuration.loadingSpacing) {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader(configuration.continueTitle)
                    SkeletonRow(cardType: skeletonRowCardType, count: 4)
                }
                .padding(.horizontal, PlatformMetrics.horizontalPadding(compact: isCompactLayout))

                VStack(alignment: .leading, spacing: 20) {
                    // Keep a dynamic title hidden until load attempt to avoid flash
                    SectionHeader(configuration.featuredTitle(viewModel.state))
                        .opacity(headerOpacity)
                    SkeletonGrid(cardType: skeletonGridCardType, columns: configuration.skeletonColumns, rows: 3)
                }
                .padding(.horizontal, PlatformMetrics.horizontalPadding(compact: isCompactLayout))
            }
            .padding(.vertical, 40)
        }
    }

    // MARK: - Data Loading

    private func loadContent() async {
        await viewModel.loadInitialPage()
    }

    private func refreshContinueItems() {
        switch configuration.continueFilter {
        case .video:
            continueItems = PlaybackProgressManager.shared.getContinueWatchingItems()
        case .audio:
            continueItems = PlaybackProgressManager.shared.getContinueListeningItems()
        }
    }

    // MARK: - Helpers

    /// Header row opacity: hidden until the title load attempt completes when
    /// the configuration uses a fetched collection title; always visible otherwise.
    private var headerOpacity: Double {
        configuration.hidesHeaderUntilTitleLoads && !viewModel.state.hasTitleLoadAttempted ? 0 : 1
    }

    private var skeletonGridCardType: SkeletonGrid.CardType {
        configuration.mediaType == .video ? .video : .music
    }

    private var skeletonRowCardType: SkeletonRow.CardType {
        configuration.mediaType == .video ? .video : .music
    }

    @ViewBuilder
    private var loadMoreSkeletonCard: some View {
        switch configuration.mediaType {
        case .video:
            SkeletonCard.video
        case .music:
            SkeletonCard.music
        }
    }

    /// Sort picker. Segmented + fixed-width on TV / regular surfaces;
    /// `.menu` style on compact width so the header doesn't overflow the
    /// iPhone screen and crowd out the section title.
    @ViewBuilder
    private var sortPicker: some View {
        if isCompactLayout == true {
            Picker("Sort by", selection: $selectedSort) {
                ForEach(CollectionSortOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Sort order")
        } else {
            Picker("Sort by", selection: $selectedSort) {
                ForEach(CollectionSortOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 400)
            .accessibilityLabel("Sort order")
        }
    }

    private func handleContinueItemTap(_ progress: PlaybackProgress) {
        // Create a SearchResult from the progress data to navigate to ItemDetailView
        let item = SearchResult(
            identifier: progress.itemIdentifier,
            title: progress.title,
            mediatype: progress.mediaType
        )
        navigationPath.append(item)
    }
}
