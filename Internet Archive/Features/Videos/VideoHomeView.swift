//
//  VideoHomeView.swift
//  Internet Archive
//
//  Home screen for browsing video content
//

import SwiftUI

/// The main video browsing screen displaying video collections from Internet Archive.
///
/// This view shows:
/// - Continue Watching section for resuming playback
/// - Featured video collections
/// - Year-based browsing options
///
/// ## Future Implementation
/// This placeholder will be replaced with a full implementation using:
/// - `LazyVGrid` for efficient grid layout
/// - Integration with `APIManager.getCollectionsTyped()`
/// - `PlaybackProgressManager` for Continue Watching
struct VideoHomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    // Continue Watching Section (placeholder)
                    SectionHeader("Continue Watching")
                    placeholderGrid()

                    // Featured Collections Section (placeholder)
                    SectionHeader("Featured Collections")
                    placeholderGrid()

                    // Browse by Year Section (placeholder)
                    SectionHeader("Browse by Year")
                    placeholderGrid()
                }
                .padding(.horizontal, 80)
                .padding(.vertical, 40)
            }
            .navigationTitle("Videos")
        }
    }

    // MARK: - Helper Views

    private func placeholderGrid() -> some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 40)
        ], spacing: 40) {
            ForEach(0..<6, id: \.self) { _ in
                PlaceholderCard.video
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VideoHomeView()
        .environmentObject(AppState())
}
