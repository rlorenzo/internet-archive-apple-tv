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

    /// ViewModel for year data management (owns the year selection)
    @StateObject private var viewModel: YearsViewModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Currently selected year, owned by the view model
    private var selectedYear: String? {
        viewModel.state.selectedYear
    }

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
                .frame(minWidth: YearBrowseHelpers.sidebarWidth, idealWidth: 320, maxWidth: 360)

            // Right content: Items grid
            contentArea
        }
        .background(Color.libraryCharcoal)
        .task {
            // Only load on first appearance - .task re-runs when returning
            // from item detail, and reloading would reset the selection
            if !viewModel.state.hasYears && viewModel.state.errorMessage == nil {
                await loadData()
            }
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
                .background(Color.surfaceDivider)

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
        .background(Color.libraryCharcoal)
    }

    private var yearListLoading: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(0..<10, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.placeholderFill)
                        .frame(height: 44)
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
                    ForEach(Array(viewModel.state.sortedKeys.enumerated()), id: \.element) { index, year in
                        yearButton(year: year, index: index)
                            .id(year)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: selectedYear) { _, newYear in
                if let year = newYear {
                    if reduceMotion {
                        proxy.scrollTo(year, anchor: .center)
                    } else {
                        withAnimation {
                            proxy.scrollTo(year, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private func yearButton(year: String, index: Int) -> some View {
        let isSelected = selectedYear == year
        let itemCount = viewModel.state.sortedData[year]?.count ?? 0

        return Button {
            viewModel.selectYear(at: index)
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
                    .fill(isSelected ? Color.chromeRest : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(YearBrowseHelpers.yearButtonAccessibilityLabel(year: year, itemCount: itemCount))
        .accessibilityHint(YearBrowseHelpers.yearButtonAccessibilityHint(year: year, isSelected: isSelected))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var yearListEmpty: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40))
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
        } else if let year = selectedYear {
            itemsGridView(year: year, items: viewModel.state.selectedYearItems)
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
                    columns: YearBrowseHelpers.gridColumns(for: mediaType),
                    spacing: YearBrowseHelpers.gridSpacing(for: mediaType)
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
                .tvFocusSection()
            }
        }
    }

    /// Generate accessibility label for an item
    private func itemAccessibilityLabel(for item: SearchResult) -> String {
        YearBrowseHelpers.itemAccessibilityLabel(for: item, mediaType: mediaType)
    }

    private func itemCard(for item: SearchResult) -> some View {
        let cardWidth = YearBrowseHelpers.cardWidth(for: mediaType)
        let cardHeight = YearBrowseHelpers.cardHeight(for: mediaType)

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
                    .font(YearBrowseHelpers.titleFont(for: mediaType))
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                if let creator = item.creator {
                    Text(creator)
                        .font(YearBrowseHelpers.creatorFont(for: mediaType))
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
        viewModel.configure(
            name: collection.safeTitle,
            identifier: collection.identifier,
            collection: YearBrowseHelpers.collectionType(for: mediaType)
        )

        // Load the data; the view model auto-selects the first year
        await viewModel.loadYearsData()
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
