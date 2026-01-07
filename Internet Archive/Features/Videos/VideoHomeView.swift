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

    /// Selected item for navigation
    @State private var selectedItem: SearchResult?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.state.isLoading && !viewModel.state.hasLoaded {
                    loadingView
                } else if let errorMessage = viewModel.state.errorMessage {
                    MediaHomeErrorView(message: errorMessage, onRetry: loadContent)
                } else {
                    contentView
                }
            }
            .navigationDestination(item: $selectedItem) { item in
                ItemDetailPlaceholderView(item: item, mediaType: .video)
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
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 48) {
                ForEach(items) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            // Thumbnail with fixed aspect ratio
                            AsyncImage(url: URL(string: "https://archive.org/services/img/\(item.identifier)")) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "film")
                                                .font(.system(size: 40))
                                                .foregroundStyle(.secondary)
                                        )
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "film")
                                                .font(.system(size: 40))
                                                .foregroundStyle(.secondary)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: videoCardWidth, height: videoCardWidth * 9 / 16)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Text content
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.safeTitle)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .lineLimit(2)
                                    .foregroundStyle(.primary)

                                if let subtitle = item.creator ?? item.year {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .frame(width: videoCardWidth)
                    }
                    .tvCardStyle()
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
        }
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
        // In Phase 5, this will navigate to the player with resume position
        #if DEBUG
        print("Continue watching tapped: \(progress.itemIdentifier)")
        #endif
    }
}

// MARK: - Preview

#Preview {
    VideoHomeView()
        .environmentObject(AppState())
}
