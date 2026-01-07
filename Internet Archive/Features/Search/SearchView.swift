//
//  SearchView.swift
//  Internet Archive
//
//  Search interface for Internet Archive content
//

import SwiftUI

/// The search interface for finding content across Internet Archive collections.
///
/// This view provides:
/// - Text-based search with keyboard input
/// - Filter options for content type (All/Video/Music)
/// - Paginated search results
///
/// ## Future Implementation
/// This placeholder will be replaced with a full implementation using:
/// - `.searchable` modifier for tvOS search
/// - Integration with `APIManager.searchTyped()`
/// - Filter picker for content types
/// - Pagination support
struct SearchView: View {
    @EnvironmentObject private var appState: AppState

    @State private var searchText = ""
    @State private var selectedFilter: ContentFilter = .all

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Content Type", selection: $selectedFilter) {
                    ForEach(ContentFilter.allCases) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 80)
                .padding(.top, 20)

                if searchText.isEmpty {
                    // Empty state when no search
                    emptySearchState()
                } else {
                    // Search results (placeholder)
                    searchResultsPlaceholder()
                }
            }
            .navigationTitle("Search")
        }
        .searchable(text: $searchText, prompt: "Search Internet Archive")
    }

    // MARK: - Helper Views

    private func emptySearchState() -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 80))
                .foregroundStyle(.tertiary)

            Text("Search the Internet Archive")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Find videos, music, and more from the world's largest digital library")
                .font(.body)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 600)

            Spacer()
        }
        .padding()
    }

    private func searchResultsPlaceholder() -> some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 280, maximum: 350), spacing: 40)
            ], spacing: 40) {
                ForEach(0..<12, id: \.self) { _ in
                    PlaceholderCard.video
                }
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 40)
        }
    }
}

// MARK: - Content Filter

extension SearchView {
    /// Filter options for search results
    enum ContentFilter: String, CaseIterable, Identifiable {
        case all
        case videos
        case music

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .all: return "All"
            case .videos: return "Videos"
            case .music: return "Music"
            }
        }

        /// The media type parameter for the API
        var mediaType: String? {
            switch self {
            case .all: return nil
            case .videos: return "movies"
            case .music: return "audio"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SearchView()
        .environmentObject(AppState())
}
