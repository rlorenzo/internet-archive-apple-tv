//
//  VideoHomeView.swift
//  Internet Archive
//
//  Home screen for browsing video content
//

import SwiftUI

/// The main video browsing screen displaying video collections from Internet Archive.
///
/// A thin wrapper around `MediaHomeView` configured for video:
/// - Continue Watching section for resuming playback
/// - Featured video collections grid
struct VideoHomeView: View {
    @StateObject private var viewModel = VideoViewModel(collectionService: DefaultCollectionService())

    var body: some View {
        MediaHomeView(configuration: .video, viewModel: viewModel)
    }
}

// MARK: - Video Configuration

extension MediaHomeConfiguration {
    /// Configuration for the video home screen
    @MainActor static let video = MediaHomeConfiguration(
        mediaType: .video,
        continueFilter: .video,
        continueTitle: "Continue Watching",
        continueAccessibilityLabel: { "Continue watching section with \($0) videos" },
        featuredTitle: { _ in "Featured Videos" },
        hidesHeaderUntilTitleLoads: false,
        featuredAccessibilityLabel: { "Featured videos section with \($0.items.count) items" },
        emptyCollectionName: "videos",
        skeletonColumns: 4,
        gridSpacing: 48,
        loadingSpacing: 50
    )
}

// MARK: - Preview

#Preview {
    VideoHomeView()
        .environmentObject(AppState())
}
