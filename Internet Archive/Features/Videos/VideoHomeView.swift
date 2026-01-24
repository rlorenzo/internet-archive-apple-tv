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

    /// Binding to expose navigation depth to parent for exit command handling
    @Binding var hasNavigationHistory: Bool

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
        .onChange(of: navigationPath.count) { _, newCount in
            // Sync navigation state with parent
            hasNavigationHistory = newCount > 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .popVideoNavigation)) { _ in
            // Handle pop request from parent (when Menu pressed on tab bar)
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
            }
        }
        .task {
            await loadContent()
        }
        .onAppear {
            refreshContinueWatching()
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

                ContinueWatchingSection(
                    items: continueWatchingItems,
                    mediaType: .video
                ) { progress in
                    handleContinueWatchingTap(progress)
                }
            }
        }
    }

    // MARK: - Featured Videos Section

    /// Card width for video items (determines height via 16:9 aspect ratio)
    private let videoCardWidth: CGFloat = 380

    private var featuredVideosSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader("Featured Videos")

            if viewModel.state.hasItems {
                // Use horizontal scroll rows for proper aspect ratio support
                VStack(alignment: .leading, spacing: 48) {
                    videoRow(items: Array(viewModel.state.items.prefix(4)))
                    videoRow(items: Array(viewModel.state.items.dropFirst(4).prefix(4)))
                    videoRow(items: Array(viewModel.state.items.dropFirst(8).prefix(4)))
                }
            } else {
                EmptyContentView.emptyCollection(collectionName: "videos")
            }
        }
    }

    private func videoRow(items: [SearchResult]) -> some View {
        HStack(alignment: .top, spacing: 48) {
            ForEach(items) { item in
                Button {
                    navigationPath.append(item)
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        // Thumbnail with fixed aspect ratio
                        MediaThumbnailView(
                            identifier: item.identifier,
                            mediaType: .video,
                            size: CGSize(width: videoCardWidth, height: videoCardWidth * 9 / 16)
                        )

                        // Text content - fixed height for consistent alignment
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.safeTitle)
                                .font(.callout)
                                .fontWeight(.medium)
                                .lineLimit(2)
                                .foregroundStyle(.primary)
                                .frame(height: 56, alignment: .bottomLeading)

                            Text(item.creator ?? item.year ?? " ")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(width: videoCardWidth)
                }
                .tvCardStyle()
            }
        }
        .padding(.vertical, 50)
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
                    SkeletonGrid(cardType: .video, columns: 4, rows: 2)
                }
                .padding(.horizontal, 80)
            }
            .padding(.vertical, 40)
        }
    }

    // MARK: - Data Loading

    private func loadContent() async {
        await viewModel.loadCollection()
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
    VideoHomeView(hasNavigationHistory: .constant(false))
        .environmentObject(AppState())
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when parent requests video navigation to pop back
    static let popVideoNavigation = Notification.Name("popVideoNavigation")
}
