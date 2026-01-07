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

    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = MusicViewModel(collectionService: DefaultCollectionService())

    /// Continue listening items from PlaybackProgressManager
    @State private var continueListeningItems: [PlaybackProgress] = []

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
                ItemDetailPlaceholderView(item: item, mediaType: .music)
            }
        }
        .task {
            await loadContent()
        }
        .onAppear {
            refreshContinueListening()
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 60) {
                continueListeningSection
                featuredMusicSection
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 40)
        }
    }

    // MARK: - Continue Listening Section

    @ViewBuilder
    private var continueListeningSection: some View {
        if !continueListeningItems.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader("Continue Listening")

                ContinueWatchingSection(
                    items: continueListeningItems,
                    mediaType: .audio
                ) { progress in
                    handleContinueListeningTap(progress)
                }
            }
        }
    }

    // MARK: - Featured Music Section

    /// Card size for music items (square album art)
    private let musicCardSize: CGFloat = 220

    private var featuredMusicSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader("Live Music Archive")

            if viewModel.state.hasItems {
                // Use horizontal scroll rows for proper aspect ratio support
                VStack(alignment: .leading, spacing: 48) {
                    musicRow(items: Array(viewModel.state.items.prefix(6)))
                    musicRow(items: Array(viewModel.state.items.dropFirst(6).prefix(6)))
                }
            } else {
                EmptyContentView.emptyCollection(collectionName: "music")
            }
        }
    }

    private func musicRow(items: [SearchResult]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 40) {
                ForEach(items) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            // Square album art thumbnail
                            AsyncImage(url: URL(string: "https://archive.org/services/img/\(item.identifier)")) { phase in
                                switch phase {
                                case .empty:
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "music.note")
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
                                            Image(systemName: "music.note")
                                                .font(.system(size: 40))
                                                .foregroundStyle(.secondary)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: musicCardSize, height: musicCardSize)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // Text content
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.safeTitle)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(2)
                                    .foregroundStyle(.primary)

                                if let subtitle = item.creator ?? item.year {
                                    Text(subtitle)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .frame(width: musicCardSize)
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
            VStack(alignment: .leading, spacing: 60) {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader("Continue Listening")
                    SkeletonRow(cardType: .music, count: 4)
                }

                VStack(alignment: .leading, spacing: 20) {
                    SectionHeader("Live Music Archive")
                    SkeletonGrid(cardType: .music, columns: 6, rows: 2)
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

    private func refreshContinueListening() {
        continueListeningItems = PlaybackProgressManager.shared.getContinueListeningItems()
    }

    // MARK: - Helpers

    private func handleContinueListeningTap(_ progress: PlaybackProgress) {
        // In Phase 5, this will navigate to the player with resume position
        #if DEBUG
        print("Continue listening tapped: \(progress.itemIdentifier)")
        #endif
    }
}

// MARK: - Preview

#Preview {
    MusicHomeView()
        .environmentObject(AppState())
}
