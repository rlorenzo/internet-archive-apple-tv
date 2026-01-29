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
/// Uses `FavoritesViewModel` for data loading and state management.
struct FavoritesView: View {
    @EnvironmentObject private var appState: AppState

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

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if appState.isAuthenticated {
                    authenticatedContent
                } else {
                    unauthenticatedContent
                }
            }
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
            .onDisappear {
                cancelLoadTask()
            }
        }
    }

    // MARK: - Authenticated Content

    @ViewBuilder
    private var authenticatedContent: some View {
        if viewModel.state.isLoading && !viewModel.state.hasResults {
            loadingContent
        } else if let errorMessage = viewModel.state.errorMessage {
            errorContent(message: errorMessage)
        } else if !viewModel.state.hasResults {
            emptyContent
        } else {
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
        .onAppear {
            loadFavorites()
        }
    }

    private func errorContent(message: String) -> some View {
        ErrorContentView(
            message: message,
            onRetry: {
                loadFavorites()
            }
        )
    }

    private var emptyContent: some View {
        VStack(spacing: 40) {
            Spacer()
            EmptyContentView.noFavorites()
            Spacer()
        }
        .onAppear {
            loadFavorites()
        }
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
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 40)
        }
        .onAppear {
            // Refresh if returning to screen and state might be stale
            if viewModel.state.allItems.isEmpty {
                loadFavorites()
            }
        }
        .refreshable {
            loadFavorites()
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

    // MARK: - Unauthenticated Content

    private var unauthenticatedContent: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.slash")
                .font(.system(size: 80))
                .foregroundStyle(.tertiary)

            Text("Sign In Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Sign in to your Internet Archive account to view and manage your favorites.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            // Note: Users can sign in via the Account tab
            Text("Go to the Account tab to sign in")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .padding(.top, 20)

            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sign in required to view favorites. Go to the Account tab to sign in.")
    }

    // MARK: - Helper Methods

    private func loadFavorites() {
        guard let username = appState.username else { return }

        // Cancel any existing load task
        loadTask?.cancel()

        loadTask = Task {
            await viewModel.loadFavoritesWithDetails(
                username: username,
                searchService: DefaultSearchService()
            )
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
        .accessibilityHint("Double-click to view content by this creator")
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
            Image(systemName: "person.fill")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
        }
    }

    private var avatarURL: URL? {
        // Internet Archive user avatar URL pattern
        URL(string: "https://archive.org/services/img/\(identifier)")
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
