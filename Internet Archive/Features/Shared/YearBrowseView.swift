//
//  YearBrowseView.swift
//  Internet Archive
//
//  View for browsing items within a collection organized by year
//

import SwiftUI

/// A view that displays items within a collection organized by year.
///
/// This view shows a tvOS-optimized split layout with:
/// - Left sidebar: Scrollable year list for selection
/// - Right content: Grid of items from the selected year
///
/// ## Usage
/// ```swift
/// YearBrowseView(
///     collection: searchResult,
///     mediaType: .video,
///     navigationPath: $navigationPath
/// )
/// ```
struct YearBrowseView: View {
    // MARK: - Properties

    /// The collection to browse (from search results)
    let collection: SearchResult

    /// Media type for proper formatting
    let mediaType: MediaItemCard.MediaType

    /// Navigation path passed from parent for proper back navigation
    @Binding var navigationPath: NavigationPath

    // MARK: - State

    /// ViewModel for year data management
    @StateObject private var viewModel: YearsViewModel

    /// Currently selected year
    @State private var selectedYear: String?

    // MARK: - Constants

    private let videoCardWidth: CGFloat = 320
    private let musicCardSize: CGFloat = 180
    private let sidebarWidth: CGFloat = 300

    // MARK: - Initialization

    init(
        collection: SearchResult,
        mediaType: MediaItemCard.MediaType,
        navigationPath: Binding<NavigationPath>
    ) {
        self.collection = collection
        self.mediaType = mediaType
        self._navigationPath = navigationPath

        // Initialize the ViewModel with the collection service
        _viewModel = StateObject(wrappedValue: YearsViewModel(
            collectionService: DefaultCollectionService()
        ))
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // Left sidebar: Year list
            yearSidebar
                .frame(width: sidebarWidth)

            // Right content: Items grid
            contentArea
        }
        .background(Color.black.opacity(0.95))
        .task {
            await loadData()
        }
    }

    // MARK: - Year Sidebar

    private var yearSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collection title header
            VStack(alignment: .leading, spacing: 8) {
                Text(collection.safeTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                Text("By Year")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .padding(.bottom, 24)

            Divider()
                .background(Color.gray.opacity(0.3))

            // Year list
            if viewModel.state.isLoading {
                yearListLoading
            } else if viewModel.state.hasYears {
                yearList
            } else if viewModel.state.errorMessage != nil {
                // Error shown in main content area
                EmptyView()
            } else {
                yearListEmpty
            }
        }
        .background(Color.black.opacity(0.5))
    }

    private var yearListLoading: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(0..<10, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 44)
                        .shimmer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    private var yearList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.state.sortedKeys, id: \.self) { year in
                        yearButton(year: year)
                            .id(year)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: selectedYear) { _, newYear in
                if let year = newYear {
                    withAnimation {
                        proxy.scrollTo(year, anchor: .center)
                    }
                }
            }
        }
    }

    private func yearButton(year: String) -> some View {
        let isSelected = selectedYear == year
        let itemCount = viewModel.state.sortedData[year]?.count ?? 0

        return Button {
            selectedYear = year
        } label: {
            HStack {
                Text(year)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)

                Spacer()

                Text("\(itemCount)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(year), \(itemCount) items")
        .accessibilityHint(isSelected ? "Currently selected" : "Double-tap to browse items from \(year)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var yearListEmpty: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text("No years found")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.state.isLoading {
            loadingView
        } else if let errorMessage = viewModel.state.errorMessage {
            errorView(message: errorMessage)
        } else if let year = selectedYear, let items = viewModel.state.sortedData[year] {
            itemsGridView(year: year, items: items)
        } else {
            emptySelectionView
        }
    }

    // MARK: - Items Grid View

    private func itemsGridView(year: String, items: [SearchResult]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Year header
                HStack(alignment: .bottom, spacing: 16) {
                    Text(year)
                        .font(.title)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)

                    Text("\(items.count) items")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 60)
                .padding(.top, 40)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(year), \(items.count) items")

                // Items grid
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
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(itemAccessibilityLabel(for: item))
                        .accessibilityHint("Double-tap to view details")
                    }
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 60)
            }
        }
    }

    /// Generate accessibility label for an item
    private func itemAccessibilityLabel(for item: SearchResult) -> String {
        var components = [item.safeTitle]
        if let creator = item.creator {
            components.append(creator)
        }
        let typeLabel = mediaType == .video ? "Video" : "Music"
        components.append(typeLabel)
        return components.joined(separator: ", ")
    }

    private var gridColumns: [GridItem] {
        let count = mediaType == .video ? 4 : 5
        return Array(repeating: GridItem(.flexible(), spacing: mediaType == .video ? 48 : 40), count: count)
    }

    private func itemCard(for item: SearchResult) -> some View {
        let cardWidth = mediaType == .video ? videoCardWidth : musicCardSize
        let cardHeight = mediaType == .video ? videoCardWidth * 9 / 16 : musicCardSize

        return VStack(alignment: .leading, spacing: 12) {
            // Thumbnail
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

                if let creator = item.creator {
                    Text(creator)
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
            Text("Loading years...")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        ErrorContentView(
            message: message,
            onRetry: {
                Task {
                    await loadData()
                }
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty Selection View

    private var emptySelectionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            Text("Select a year")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Choose a year from the sidebar to browse items")
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadData() async {
        // Map media type to collection type for API query
        let collectionType: String
        switch mediaType {
        case .video:
            collectionType = "movies"
        case .music:
            collectionType = "etree"
        }

        viewModel.configure(
            name: collection.safeTitle,
            identifier: collection.identifier,
            collection: collectionType
        )

        // Load the data
        await viewModel.loadYearsData()

        // Select the first year if available
        if selectedYear == nil, let firstYear = viewModel.state.sortedKeys.first {
            selectedYear = firstYear
        }
    }
}

// MARK: - Year Browse Destination

/// A hashable struct for navigating to the year browse view
struct YearBrowseDestination: Hashable {
    let collection: SearchResult
    let mediaType: MediaItemCard.MediaType
}

// MARK: - Preview

#Preview("Video Years") {
    @Previewable @State var path = NavigationPath()
    NavigationStack(path: $path) {
        YearBrowseView(
            collection: SearchResult(
                identifier: "feature_films",
                title: "Feature Films",
                creator: "Internet Archive"
            ),
            mediaType: .video,
            navigationPath: $path
        )
        .navigationDestination(for: SearchResult.self) { item in
            ItemDetailView(item: item, mediaType: .video)
        }
    }
}

#Preview("Music Years") {
    @Previewable @State var path = NavigationPath()
    NavigationStack(path: $path) {
        YearBrowseView(
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
    }
}
