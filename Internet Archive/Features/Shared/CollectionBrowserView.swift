//
//  CollectionBrowserView.swift
//  Internet Archive
//
//  View for browsing items within a collection
//

import NukeUI
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

    // MARK: - Environment

    @Environment(\.isCompactLayout) private var isCompactLayout

    // MARK: - ViewModel

    /// Collection view model (owns items, loading/error state, and the
    /// load token that discards stale responses after sort changes)
    @StateObject private var viewModel = CollectionViewModel(
        collectionService: DefaultCollectionService()
    )

    // MARK: - State

    /// Sort order for collection items
    @State private var sortOption: CollectionSortOption = .weeklyViews

    /// Navigation path passed from parent for proper back navigation
    @Binding var navigationPath: NavigationPath

    // MARK: - Constants

    private let videoCardWidth: CGFloat = 350
    private let musicCardSize: CGFloat = 200

    // MARK: - ViewModel Accessors

    private var items: [SearchResult] { viewModel.state.items }
    private var isLoading: Bool { viewModel.state.isLoading }
    private var errorMessage: String? { viewModel.state.errorMessage }
    private var collectionMetadata: ItemMetadata? { viewModel.state.collectionMetadata }

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
            .padding(.horizontal, PlatformMetrics.horizontalPadding(compact: isCompactLayout))
            .padding(.vertical, 40)
        }
        .background(Color.libraryCharcoal)
        .task {
            // Only load on first appearance - .task re-runs when returning
            // from item detail, and an unconditional load would reset the
            // grid and the user's focus position
            if !viewModel.state.hasLoaded {
                await loadCollectionItems()
            }
        }
        .onChange(of: sortOption) { _, _ in
            Task { await loadCollectionItems() }
        }
        // Note: NavigationStack handles back navigation automatically on tvOS.
        // Don't use .onExitCommand here as it can interfere with the navigation stack.
    }

    // MARK: - Collection Header

    private var collectionHeader: some View {
        Group {
            if isCompactLayout == true {
                VStack(alignment: .leading, spacing: 20) {
                    headerThumbnail
                    headerMetadata
                }
            } else {
                HStack(alignment: .top, spacing: 40) {
                    headerThumbnail
                    headerMetadata
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.bottom, 20)
    }

    private var headerThumbnail: some View {
        let width: CGFloat = isCompactLayout == true ? 140 : 300
        let height: CGFloat = mediaType == .video ? width * 9 / 16 : width

        return LazyImage(url: thumbnailURL) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholderThumbnail
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
    }

    private var headerMetadata: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(collection.safeTitle)
                .font(.title)
                .fontWeight(.bold)
                .lineLimit(2)
                .accessibilityAddTraits(.isHeader)

            if let creator = collection.creator {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(creator)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Creator: \(creator)")
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
                    .accessibilityLabel("Browse by year")
                    .accessibilityHint("Double-tap to browse this collection organized by year")
                }
            }
        }
    }

    private var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.placeholderFill)
            .overlay(
                Image(systemName: mediaType.placeholderIcon)
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
            )
    }

    private var thumbnailURL: URL? {
        IAURLHelpers.thumbnailURL(for: collection.identifier)
    }

    // MARK: - Items Grid

    private var itemsGrid: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Items")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                if isCompactLayout != true {
                    Text("Sort by")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }

                sortPicker
            }

            LazyVGrid(
                columns: SearchResultsGridHelpers.gridColumns(for: mediaType, compact: isCompactLayout),
                spacing: gridRowSpacing
            ) {
                ForEach(items) { item in
                    Button {
                        navigationPath.append(item)
                    } label: {
                        itemCard(for: item)
                    }
                    .tvCardStyle()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(itemAccessibilityLabel(for: item))
                    .accessibilityHint("Double-tap to view details")
                }
            }
            .tvFocusSection()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Items section with \(items.count) items")
    }

    /// Generate accessibility label for an item
    private func itemAccessibilityLabel(for item: SearchResult) -> String {
        var components = [item.safeTitle]
        if let subtitle = item.creator ?? item.year {
            components.append(subtitle)
        }
        let typeLabel = mediaType == .video ? "Video" : "Music"
        components.append(typeLabel)
        return components.joined(separator: ", ")
    }

    /// Row spacing between grid rows. Compact platforms get a tighter rhythm
    /// to match the smaller card minimums from `SearchResultsGridHelpers`.
    private var gridRowSpacing: CGFloat {
        if isCompactLayout == true { return 16 }
        return mediaType == .video ? 48 : 40
    }

    /// Sort picker. Segmented on TV / regular width (the picker keeps its
    /// information dense across a wide row); menu on compact width so it
    /// collapses to a small affordance instead of overflowing the header.
    @ViewBuilder
    private var sortPicker: some View {
        if isCompactLayout == true {
            Picker("Sort by", selection: $sortOption) {
                ForEach(CollectionSortOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel("Sort order")
        } else {
            Picker("Sort by", selection: $sortOption) {
                ForEach(CollectionSortOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 400)
            .accessibilityLabel("Sort order")
        }
    }

    private func itemCard(for item: SearchResult) -> some View {
        let stretches = isCompactLayout == true

        return VStack(alignment: .leading, spacing: 12) {
            thumbnail(for: item, stretches: stretches)

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
        .modifier(ItemCardWidthModifier(stretches: stretches, fixedWidth: fixedCardWidth))
    }

    @ViewBuilder
    private func thumbnail(for item: SearchResult, stretches: Bool) -> some View {
        if stretches {
            MediaThumbnailView(
                identifier: item.identifier,
                mediaType: mediaType,
                aspectRatio: mediaType == .video ? 16.0 / 9.0 : 1.0
            )
        } else {
            let cardWidth = fixedCardWidth
            let cardHeight = mediaType == .video ? cardWidth * 9 / 16 : cardWidth
            MediaThumbnailView(
                identifier: item.identifier,
                mediaType: mediaType,
                size: CGSize(width: cardWidth, height: cardHeight)
            )
        }
    }

    private var fixedCardWidth: CGFloat {
        mediaType == .video ? videoCardWidth : musicCardSize
    }

    private struct ItemCardWidthModifier: ViewModifier {
        let stretches: Bool
        let fixedWidth: CGFloat

        func body(content: Content) -> some View {
            if stretches {
                content.frame(maxWidth: .infinity, alignment: .leading)
            } else {
                content.frame(width: fixedWidth)
            }
        }
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
        // Music collections use both "etree" and "audio" mediatypes
        let mediaTypeFilter = mediaType == .video ? "movies" : "(etree OR audio)"

        await viewModel.loadCollectionContents(
            identifier: collection.identifier,
            mediaTypeFilter: mediaTypeFilter,
            sort: sortOption.apiSortString
        )
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
