//
//  MusicHomeView.swift
//  Internet Archive
//
//  Home screen for browsing music content
//

import SwiftUI

/// The main music browsing screen displaying audio collections from Internet Archive.
///
/// This view shows:
/// - Continue Listening section for resuming playback
/// - Featured live music collections grid
struct MusicHomeView: View {
    // MARK: - Environment & State

    @StateObject private var viewModel = MusicViewModel(collectionService: DefaultCollectionService())

    @Environment(\.isCompactLayout) private var isCompactLayout

    /// Continue listening items from PlaybackProgressManager
    @State private var continueListeningItems: [PlaybackProgress] = []

    /// Navigation path for programmatic navigation control
    @State private var navigationPath = NavigationPath()

    /// Selected sort order for the featured music grid
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
                        mediaType: .music,
                        navigationPath: $navigationPath
                    )
                } else {
                    ItemDetailView(item: item, mediaType: .music)
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
            refreshContinueListening()
        }
        .onChange(of: selectedSort) { _, newValue in
            Task { await viewModel.setSortOption(newValue) }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isCompactLayout == true ? 24 : 60) {
                continueListeningSection
                featuredMusicSection
            }
            .padding(.horizontal, PlatformMetrics.horizontalPadding(compact: isCompactLayout))
            .padding(.vertical, isCompactLayout == true ? 16 : 40)
        }
    }

    // MARK: - Continue Listening Section

    @ViewBuilder
    private var continueListeningSection: some View {
        if !continueListeningItems.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader("Continue Listening")
                    .accessibilityAddTraits(.isHeader)

                ContinueWatchingSection(
                    items: continueListeningItems,
                    mediaType: .audio
                ) { progress in
                    handleContinueListeningTap(progress)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Continue listening section with \(continueListeningItems.count) items")
        }
    }

    // MARK: - Featured Music Section

    private var featuredMusicSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Only show title after load attempt to avoid flash
            HStack {
                Text(viewModel.state.displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                sortPicker
            }
            .opacity(viewModel.state.hasTitleLoadAttempted ? 1 : 0)

            if viewModel.state.isLoading && !viewModel.state.hasItems {
                SkeletonGrid(cardType: .music, columns: 6, rows: 3)
            } else if viewModel.state.hasItems {
                LazyVGrid(
                    columns: SearchResultsGridHelpers.gridColumns(for: .music, compact: isCompactLayout),
                    spacing: isCompactLayout == true ? 16 : 40
                ) {
                    ForEach(viewModel.state.items) { item in
                        Button {
                            navigationPath.append(item)
                        } label: {
                            SearchResultCard(item: item, mediaType: .music, stretches: isCompactLayout == true)
                        }
                        .tvCardStyle()
                        .onAppear {
                            Task { await viewModel.loadNextPageIfNeeded(currentItem: item) }
                        }
                    }

                    if viewModel.state.isLoadingMore {
                        ForEach(0..<SearchResultsGridHelpers.skeletonCardCount(for: .music), id: \.self) { _ in
                            SkeletonCard.music
                        }
                    }
                }

                if !viewModel.state.hasMore && viewModel.state.hasLoaded {
                    noMoreContentView
                }
            } else if viewModel.state.hasLoaded {
                EmptyContentView.emptyCollection(collectionName: "music")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(viewModel.state.displayTitle) section with \(viewModel.state.items.count) items")
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
            VStack(alignment: .leading, spacing: 60) {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader("Continue Listening")
                    SkeletonRow(cardType: .music, count: 4)
                }
                .padding(.horizontal, PlatformMetrics.horizontalPadding(compact: isCompactLayout))

                VStack(alignment: .leading, spacing: 20) {
                    // Keep title hidden until load attempt to avoid flash
                    SectionHeader(viewModel.state.displayTitle)
                        .opacity(viewModel.state.hasTitleLoadAttempted ? 1 : 0)
                    SkeletonGrid(cardType: .music, columns: 6, rows: 3)
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

    private func refreshContinueListening() {
        continueListeningItems = PlaybackProgressManager.shared.getContinueListeningItems()
    }

    // MARK: - Helpers

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

    private func handleContinueListeningTap(_ progress: PlaybackProgress) {
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
    MusicHomeView()
        .environmentObject(AppState())
}
