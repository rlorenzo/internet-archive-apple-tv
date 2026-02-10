//
//  PeopleDetailView.swift
//  Internet Archive
//
//  Detail view for browsing a creator's/person's content
//

import SwiftUI

/// Detail view for browsing content by a specific creator/person.
///
/// This view displays:
/// - Creator avatar and name
/// - Videos by this creator
/// - Music by this creator
///
/// Uses `PeopleViewModel` for data loading and state management.
struct PeopleDetailView: View {
    // MARK: - Properties

    /// The Internet Archive identifier for the person (usually @username)
    let identifier: String

    /// Display name for the person
    let name: String

    // MARK: - ViewModel

    @StateObject private var viewModel = PeopleViewModel(
        favoritesService: DefaultPeopleFavoritesService()
    )

    // MARK: - Navigation State

    @State private var selectedItem: SearchResult?
    @State private var selectedMediaType: MediaItemCard.MediaType = .video

    // MARK: - Task Management

    @State private var loadTask: Task<Void, Never>?

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.state.isLoading && !viewModel.state.hasItems {
                loadingContent
            } else if let errorMessage = viewModel.state.errorMessage {
                errorContent(message: errorMessage)
            } else if !viewModel.state.hasItems {
                emptyContent
            } else {
                contentView
            }
        }
        .navigationTitle(name)
        .navigationDestination(item: $selectedItem) { item in
            ItemDetailView(item: item, mediaType: selectedMediaType)
        }
        .onAppear {
            configureAndLoad()
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }

    // MARK: - Loading Content

    private var loadingContent: some View {
        VStack(spacing: 40) {
            Spacer()

            // Avatar placeholder
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 150, height: 150)
                .overlay {
                    ProgressView()
                }

            Text("Loading content by \(name)...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading content by \(name)")
    }

    // MARK: - Error Content

    private func errorContent(message: String) -> some View {
        VStack(spacing: 40) {
            Spacer()

            creatorHeader

            ErrorContentView(
                message: message,
                onRetry: {
                    Task {
                        await viewModel.loadFavorites()
                    }
                }
            )

            Spacer()
        }
    }

    // MARK: - Empty Content

    private var emptyContent: some View {
        VStack(spacing: 40) {
            Spacer()

            creatorHeader

            EmptyContentView(
                icon: "person.crop.circle.badge.questionmark",
                title: "No Content Found",
                message: "\(name) hasn't added any videos or music to their favorites yet."
            )

            Spacer()
        }
    }

    // MARK: - Main Content

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 60) {
                // Creator header
                creatorHeader
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 20)

                // Videos section
                if !viewModel.state.movieItems.isEmpty {
                    contentSection(
                        title: "Videos",
                        items: viewModel.state.movieItems,
                        mediaType: .video
                    )
                }

                // Music section
                if !viewModel.state.musicItems.isEmpty {
                    contentSection(
                        title: "Music",
                        items: viewModel.state.musicItems,
                        mediaType: .music
                    )
                }
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 40)
        }
    }

    // MARK: - Creator Header

    private var creatorHeader: some View {
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
            .frame(width: 180, height: 180)
            .clipShape(Circle())

            // Name
            Text(name)
                .font(.title2)
                .fontWeight(.semibold)

            // Content count
            Text("\(viewModel.state.totalItemCount) items")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(viewModel.state.totalItemCount) items")
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
            Image(systemName: "person.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Content Section

    private func contentSection(
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

    // MARK: - Helper Methods

    private var avatarURL: URL? {
        URL(string: "https://archive.org/services/img/\(identifier)")
    }

    private func configureAndLoad() {
        viewModel.configure(identifier: identifier, name: name)

        // Cancel any existing load task
        loadTask?.cancel()

        loadTask = Task {
            await viewModel.loadFavorites()
        }
    }
}

// MARK: - Preview

#Preview("People Detail") {
    NavigationStack {
        PeopleDetailView(
            identifier: "@brewster",
            name: "Brewster Kahle"
        )
    }
}

#Preview("Empty State") {
    NavigationStack {
        PeopleDetailView(
            identifier: "@unknown_user",
            name: "Unknown User"
        )
    }
}
