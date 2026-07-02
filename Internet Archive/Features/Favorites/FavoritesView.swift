//
//  FavoritesView.swift
//  Internet Archive
//
//  Favorites and followed creators management
//

import SwiftUI

/// The favorites management screen displaying saved items and followed creators.
///
/// This view shows three sections:
/// - Favorite Videos
/// - Favorite Music
/// - Followed Creators/People
///
/// Favorites are merged from two sources by `FavoritesViewModel`:
/// - Device-local favorites saved via the heart button (always shown)
/// - Internet Archive account favorites (when signed in)
struct FavoritesView: View {
    @EnvironmentObject private var appState: AppState

    @Environment(\.isCompactLayout) private var isCompactLayout

    // MARK: - ViewModel

    @StateObject private var viewModel = FavoritesViewModel(
        favoritesService: DefaultFavoritesService()
    )

    // MARK: - Navigation State

    @State private var selectedItem: SearchResult?
    @State private var selectedMediaType: MediaItemCard.MediaType = .video
    @State private var selectedPerson: PersonNavigation?

    // MARK: - Task Management

    @State private var loadTask: Task<Void, Never>?

    /// The `AppState.favoritesVersion` the current results reflect. Used to
    /// reload when a heart was toggled while this tab was not visible.
    @State private var loadedFavoritesVersion: Int?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Favorites")
                .navigationDestination(item: $selectedItem) { item in
                    ItemDetailView(item: item, mediaType: selectedMediaType)
                }
                .navigationDestination(item: $selectedPerson) { person in
                    PeopleDetailView(
                        identifier: person.identifier,
                        name: person.name
                    )
                }
                .task {
                    // Load once per content change: on first appearance, and on
                    // re-appearance only if favorites changed while away or a
                    // previous load was cancelled before finishing.
                    if !viewModel.state.hasLoaded || loadedFavoritesVersion != appState.favoritesVersion {
                        loadedFavoritesVersion = appState.favoritesVersion
                        await loadFavorites()
                    }
                }
                .onChange(of: appState.favoritesVersion) { _, newVersion in
                    loadedFavoritesVersion = newVersion
                    reloadFavorites()
                }
                .onChange(of: appState.isAuthenticated) { _, _ in
                    reloadFavorites()
                }
                .onDisappear {
                    cancelLoadTask()
                }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch FavoritesViewHelpers.authenticatedContentState(
            isLoading: viewModel.state.isLoading,
            hasResults: viewModel.state.hasResults,
            errorMessage: viewModel.state.errorMessage
        ) {
        case .loading:
            loadingContent
        case .error(let message):
            errorContent(message: message)
        case .empty:
            emptyContent
        case .content:
            favoritesContent
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 40) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading Favorites...")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading your favorites")
    }

    private func errorContent(message: String) -> some View {
        ErrorContentView(
            message: message,
            onRetry: {
                reloadFavorites()
            }
        )
    }

    private var emptyContent: some View {
        VStack(spacing: 40) {
            Spacer()
            EmptyContentView.noFavorites()
            if !appState.isAuthenticated {
                signInHint
            }
            Spacer()
        }
    }

    /// Hint shown to signed-out users: local favorites still work, but
    /// account favorites require signing in.
    private var signInHint: some View {
        Text("Sign in from the Account tab to also see your Internet Archive account favorites.")
            .font(.callout)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 600)
            .padding(.horizontal, 40)
    }

    private var favoritesContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 60) {
                // Favorite Videos Section
                if !viewModel.state.movieResults.isEmpty {
                    favoriteSectionView(
                        title: "Favorite Videos",
                        items: viewModel.state.movieResults,
                        mediaType: .video
                    )
                }

                // Favorite Music Section
                if !viewModel.state.musicResults.isEmpty {
                    favoriteSectionView(
                        title: "Favorite Music",
                        items: viewModel.state.musicResults,
                        mediaType: .music
                    )
                }

                // Followed Creators Section
                if !viewModel.state.peopleResults.isEmpty {
                    peopleSection
                }

                if !appState.isAuthenticated {
                    signInHint
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, PlatformMetrics.horizontalPadding(compact: isCompactLayout))
            .padding(.vertical, 40)
        }
        .refreshable {
            await loadFavorites()
        }
    }

    // MARK: - Section Views

    private func favoriteSectionView(
        title: String,
        items: [SearchResult],
        mediaType: MediaItemCard.MediaType
    ) -> some View {
        MediaGridSection(
            title: title,
            items: items,
            mediaType: mediaType
        ) { item in
            selectedMediaType = mediaType
            selectedItem = item
        }
    }

    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader("Followed Creators (\(viewModel.state.peopleResults.count))")
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 40) {
                    ForEach(viewModel.state.peopleResults) { person in
                        Button {
                            selectedPerson = PersonNavigation(
                                identifier: person.identifier,
                                name: person.safeTitle
                            )
                        } label: {
                            PersonCard(
                                identifier: person.identifier,
                                name: person.safeTitle
                            )
                        }
                        .tvCardStyle()
                    }
                }
                .padding(.vertical, 20) // Extra space for focus effects
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Followed Creators section with \(viewModel.state.peopleResults.count) creators")
    }

    // MARK: - Helper Methods

    /// Load favorites. Local favorites are always shown; the username is
    /// passed only when signed in so account favorites merge in.
    private func loadFavorites() async {
        let username = appState.isAuthenticated ? (appState.username ?? "") : ""
        await viewModel.loadFavoritesWithDetails(
            username: username,
            searchService: DefaultSearchService()
        )
    }

    /// Reload from a synchronous context (retry button, onChange handlers).
    private func reloadFavorites() {
        loadTask?.cancel()
        loadTask = Task {
            await loadFavorites()
        }
    }

    private func cancelLoadTask() {
        loadTask?.cancel()
        loadTask = nil
    }
}

// MARK: - Person Card

/// A card component for displaying a followed creator/person.
private struct PersonCard: View {
    let identifier: String
    let name: String

    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .empty:
                    avatarPlaceholder
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    avatarPlaceholder
                @unknown default:
                    avatarPlaceholder
                }
            }
            .frame(width: 150, height: 150)
            .clipShape(Circle())

            // Name
            Text(name)
                .font(.callout)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .frame(width: 180)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Creator: \(name)")
        .accessibilityHint("Double-tap to view content by this creator")
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.placeholderFill)
            Image(systemName: "person.fill")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
        }
    }

    private var avatarURL: URL? {
        FavoritesViewHelpers.avatarURL(for: identifier)
    }
}

// MARK: - Navigation Models

/// Navigation data for person detail view
struct PersonNavigation: Identifiable, Hashable {
    let id = UUID()
    let identifier: String
    let name: String
}

// MARK: - Preview

#Preview("Unauthenticated") {
    FavoritesView()
        .environmentObject(AppState())
}

#Preview("Authenticated") {
    let appState = AppState()
    appState.setLoggedIn(email: "test@example.com", username: "TestUser")
    return FavoritesView()
        .environmentObject(appState)
}
