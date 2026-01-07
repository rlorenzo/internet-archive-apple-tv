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
/// - Featured music collections
/// - Browse by artist/year options
///
/// ## Future Implementation
/// This placeholder will be replaced with a full implementation using:
/// - `LazyVGrid` for efficient grid layout
/// - Integration with `APIManager.getCollectionsTyped()`
/// - `PlaybackProgressManager` for Continue Listening
/// - `AudioQueueManager` for music playback
struct MusicHomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    // Continue Listening Section (placeholder)
                    SectionHeader("Continue Listening")
                    placeholderGrid()

                    // Featured Collections Section (placeholder)
                    SectionHeader("Featured Collections")
                    placeholderGrid()

                    // Browse Artists Section (placeholder)
                    SectionHeader("Browse Artists")
                    placeholderGrid()
                }
                .padding(.horizontal, 80)
                .padding(.vertical, 40)
            }
            .navigationTitle("Music")
        }
    }

    // MARK: - Helper Views

    private func placeholderGrid() -> some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 200, maximum: 250), spacing: 40)
        ], spacing: 40) {
            ForEach(0..<6, id: \.self) { _ in
                PlaceholderCard.music
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MusicHomeView()
        .environmentObject(AppState())
}
