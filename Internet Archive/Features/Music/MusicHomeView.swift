//
//  MusicHomeView.swift
//  Internet Archive
//
//  Home screen for browsing music content
//

import SwiftUI

/// The main music browsing screen displaying audio collections from Internet Archive.
///
/// A thin wrapper around `MediaHomeView` configured for music:
/// - Continue Listening section for resuming playback
/// - Featured live music collections grid
struct MusicHomeView: View {
    @StateObject private var viewModel = MusicViewModel(collectionService: DefaultCollectionService())

    var body: some View {
        MediaHomeView(configuration: .music, viewModel: viewModel)
    }
}

// MARK: - Music Configuration

extension MediaHomeConfiguration {
    /// Configuration for the music home screen
    @MainActor static let music = MediaHomeConfiguration(
        mediaType: .music,
        continueFilter: .audio,
        continueTitle: "Continue Listening",
        continueAccessibilityLabel: { "Continue listening section with \($0) items" },
        featuredTitle: { $0.displayTitle },
        hidesHeaderUntilTitleLoads: true,
        featuredAccessibilityLabel: { "\($0.displayTitle) section with \($0.items.count) items" },
        emptyCollectionName: "music",
        skeletonColumns: 6,
        gridSpacing: 40,
        loadingSpacing: 60
    )
}

// MARK: - Preview

#Preview {
    MusicHomeView()
        .environmentObject(AppState())
}
