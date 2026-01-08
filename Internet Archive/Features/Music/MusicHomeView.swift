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
                    CollectionBrowserView(collection: item, mediaType: .music)
                } else {
                    ItemDetailView(item: item, mediaType: .music)
                }
            }
        }
        .onExitCommand {
            // Handle Menu button - pop navigation if we have history
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
            }
        }
        .onChange(of: navigationPath.count) { _, newCount in
            // Sync navigation state with parent
            hasNavigationHistory = newCount > 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .popMusicNavigation)) { _ in
            // Handle pop request from parent (when Menu pressed on tab bar)
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
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
            // Only show title after load attempt to avoid flash
            SectionHeader(viewModel.state.displayTitle)
                .opacity(viewModel.state.hasTitleLoadAttempted ? 1 : 0)

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
                        navigationPath.append(item)
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            // Square album art thumbnail
                            MediaThumbnailView(
                                identifier: item.identifier,
                                mediaType: .music,
                                size: CGSize(width: musicCardSize, height: musicCardSize)
                            )

                            // Text content
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.safeTitle)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(2)
                                    .foregroundStyle(.primary)

                                // Show subtitle only if different from title
                                if let subtitle = subtitleFor(item) {
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
                    // Keep title hidden until load attempt to avoid flash
                    SectionHeader(viewModel.state.displayTitle)
                        .opacity(viewModel.state.hasTitleLoadAttempted ? 1 : 0)
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

    /// Returns subtitle for item, or nil if it would duplicate the title
    private func subtitleFor(_ item: SearchResult) -> String? {
        // Try creator first, then year
        if let creator = item.creator {
            // Don't show if creator matches title (common for collections)
            if creator.lowercased() != item.safeTitle.lowercased() {
                return creator
            }
        }
        // Fall back to year if no unique creator
        return item.year
    }
}

// MARK: - Preview

#Preview {
    MusicHomeView(hasNavigationHistory: .constant(false))
        .environmentObject(AppState())
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when parent requests music navigation to pop back
    static let popMusicNavigation = Notification.Name("popMusicNavigation")
}
