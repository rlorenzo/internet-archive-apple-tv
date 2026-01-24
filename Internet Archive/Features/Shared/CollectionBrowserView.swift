//
//  CollectionBrowserView.swift
//  Internet Archive
//
//  View for browsing items within a collection
//

import SwiftUI

/// A view that displays items within a specific Internet Archive collection.
///
/// This view shows:
/// - Collection header with thumbnail, title, and description
/// - Grid of items within the collection
/// - Navigation to individual item details
///
/// ## Usage
/// ```swift
/// CollectionBrowserView(
///     collection: searchResult,
///     mediaType: .video
/// )
/// ```
struct CollectionBrowserView: View {
    // MARK: - Properties

    /// The collection to browse (from search results)
    let collection: SearchResult

    /// Media type for proper formatting
    let mediaType: MediaItemCard.MediaType

    // MARK: - State

    /// Items in the collection
    @State private var items: [SearchResult] = []

    /// Loading state
    @State private var isLoading = true

    /// Error message
    @State private var errorMessage: String?

    /// Navigation path passed from parent for proper back navigation
    @Binding var navigationPath: NavigationPath

    /// Collection metadata (description, etc.)
    @State private var collectionMetadata: ItemMetadata?

    // MARK: - Constants

    private let videoCardWidth: CGFloat = 350
    private let musicCardSize: CGFloat = 200

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Collection header
                collectionHeader

                // Content grid or loading/error state
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if items.isEmpty {
                    emptyView
                } else {
                    itemsGrid
                }
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 40)
        }
        .background(Color.black.opacity(0.95))
        .task {
            await loadCollectionItems()
        }
        // Note: NavigationStack handles back navigation automatically on tvOS.
        // Don't use .onExitCommand here as it can interfere with the navigation stack.
    }

    // MARK: - Collection Header

    private var collectionHeader: some View {
        HStack(alignment: .top, spacing: 40) {
            // Thumbnail
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case .empty:
                    placeholderThumbnail
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderThumbnail
                @unknown default:
                    placeholderThumbnail
                }
            }
            .frame(width: 300, height: mediaType == .video ? 169 : 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Metadata
            VStack(alignment: .leading, spacing: 16) {
                Text(collection.safeTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .lineLimit(2)

                if let creator = collection.creator {
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)
                        Text(creator)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                if let description = collectionMetadata?.description ?? collection.description {
                    DescriptionView(htmlContent: description, collapsedLineLimit: 3)
                }

                if !isLoading && !items.isEmpty {
                    HStack(spacing: 24) {
                        Text("\(items.count) items")
                            .font(.callout)
                            .foregroundStyle(.tertiary)

                        Button {
                            navigationPath.append(YearBrowseDestination(
                                collection: collection,
                                mediaType: mediaType
                            ))
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                Text("Browse by Year")
                            }
                            .font(.callout)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 20)
    }

    private var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: mediaType.placeholderIcon)
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
            )
    }

    private var thumbnailURL: URL? {
        URL(string: "https://archive.org/services/img/\(collection.identifier)")
    }

    // MARK: - Items Grid

    private var itemsGrid: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader("Items")

            LazyVGrid(
                columns: gridColumns,
                spacing: mediaType == .video ? 48 : 40
            ) {
                ForEach(items) { item in
                    Button {
                        navigationPath.append(item)
                    } label: {
                        itemCard(for: item)
                    }
                    .tvCardStyle()
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        let count = mediaType == .video ? 4 : 6
        return Array(repeating: GridItem(.flexible(), spacing: mediaType == .video ? 48 : 40), count: count)
    }

    private func itemCard(for item: SearchResult) -> some View {
        let cardWidth = mediaType == .video ? videoCardWidth : musicCardSize
        let cardHeight = mediaType == .video ? videoCardWidth * 9 / 16 : musicCardSize

        return VStack(alignment: .leading, spacing: 12) {
            // Thumbnail (reuses MediaThumbnailView for DRY)
            MediaThumbnailView(
                identifier: item.identifier,
                mediaType: mediaType,
                size: CGSize(width: cardWidth, height: cardHeight)
            )

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(item.safeTitle)
                    .font(mediaType == .video ? .callout : .caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                if let subtitle = item.creator ?? item.year {
                    Text(subtitle)
                        .font(mediaType == .video ? .caption : .caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(width: cardWidth)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading items...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        ErrorContentView(
            message: message,
            onRetry: {
                Task {
                    await loadCollectionItems()
                }
            }
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        EmptyContentView.emptyCollection(collectionName: collection.safeTitle)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
    }

    // MARK: - Data Loading

    private func loadCollectionItems() async {
        isLoading = true
        errorMessage = nil

        do {
            // Build search options
            // Music collections use both "etree" and "audio" mediatypes
            let mediaTypeFilter = mediaType == .video ? "movies" : "(etree OR audio)"
            let options: [String: String] = [
                "rows": "100",
                "fl[]": "identifier,title,mediatype,creator,description,date,year,downloads",
                "sort": "downloads desc"
            ]

            // Load items within the collection
            let result = try await APIManager.sharedManager.searchTyped(
                query: "collection:\(collection.identifier) AND mediatype:\(mediaTypeFilter)",
                options: options
            )

            items = result.response.docs

            // Also try to load collection metadata for description
            do {
                let metadata = try await APIManager.sharedManager.getMetaDataTyped(
                    identifier: collection.identifier
                )
                collectionMetadata = metadata.metadata
            } catch {
                // Non-fatal: description from search result is sufficient
            }

            isLoading = false
        } catch let networkError as NetworkError {
            errorMessage = ErrorPresenter.shared.userFriendlyMessage(for: networkError)
            isLoading = false
        } catch {
            errorMessage = "Failed to load collection items. Please try again."
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview("Video Collection") {
    @Previewable @State var path = NavigationPath()
    NavigationStack(path: $path) {
        CollectionBrowserView(
            collection: SearchResult(
                identifier: "feature_films",
                title: "Feature Films",
                creator: "Internet Archive",
                description: "Feature films, shorts, silent films and trailers are available for viewing and downloading."
            ),
            mediaType: .video,
            navigationPath: $path
        )
        .navigationDestination(for: SearchResult.self) { item in
            ItemDetailView(item: item, mediaType: .video)
        }
        .navigationDestination(for: YearBrowseDestination.self) { destination in
            YearBrowseView(
                collection: destination.collection,
                mediaType: destination.mediaType,
                navigationPath: $path
            )
        }
    }
}

#Preview("Music Collection") {
    @Previewable @State var path = NavigationPath()
    NavigationStack(path: $path) {
        CollectionBrowserView(
            collection: SearchResult(
                identifier: "GratefulDead",
                title: "Grateful Dead",
                creator: "Live Music Archive"
            ),
            mediaType: .music,
            navigationPath: $path
        )
        .navigationDestination(for: SearchResult.self) { item in
            ItemDetailView(item: item, mediaType: .music)
        }
        .navigationDestination(for: YearBrowseDestination.self) { destination in
            YearBrowseView(
                collection: destination.collection,
                mediaType: destination.mediaType,
                navigationPath: $path
            )
        }
    }
}
