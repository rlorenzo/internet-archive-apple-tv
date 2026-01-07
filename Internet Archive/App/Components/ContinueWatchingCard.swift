//
//  ContinueWatchingCard.swift
//  Internet Archive
//
//  Card component for Continue Watching/Listening sections
//

import SwiftUI

/// A specialized card for displaying items in Continue Watching/Listening sections.
///
/// This card displays:
/// - Thumbnail with progress bar overlay
/// - Title and time remaining
/// - tvOS focus effects
///
/// ## Usage
/// ```swift
/// ContinueWatchingCard(progress: playbackProgress) {
///     // Navigate to player
/// }
/// ```
struct ContinueWatchingCard: View {
    // MARK: - Properties

    /// The playback progress data for this item
    let progress: PlaybackProgress

    /// Action to perform when the card is tapped
    let onTap: () -> Void

    // MARK: - Initialization

    init(progress: PlaybackProgress, onTap: @escaping () -> Void) {
        self.progress = progress
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                thumbnailWithProgress
                textContent
            }
        }
        .tvCardStyle()
    }

    // MARK: - Subviews

    private var thumbnailWithProgress: some View {
        ZStack(alignment: .bottom) {
            // Thumbnail
            AsyncImage(url: progress.thumbnailURL) { phase in
                switch phase {
                case .empty:
                    placeholderView
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
            .aspectRatio(aspectRatio, contentMode: .fit)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Progress bar
            progressOverlay
        }
    }

    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))

            Image(systemName: progress.isVideo ? "film" : "music.note")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }

    private var progressOverlay: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.black.opacity(0.6))
                        .frame(height: 8)

                    // Progress fill
                    Rectangle()
                        .fill(Color.white)
                        .frame(
                            width: geometry.size.width * min(progress.progressPercentage, 1.0),
                            height: 8
                        )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(progress.title ?? progress.itemIdentifier)
                .font(.callout)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundStyle(.primary)

            Text(progress.formattedTimeRemaining)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Computed Properties

    private var aspectRatio: CGFloat {
        progress.isVideo ? 16.0 / 9.0 : 1.0
    }
}

// MARK: - Continue Watching Section

/// A horizontal scrolling section displaying Continue Watching/Listening items.
///
/// This section:
/// - Displays playback progress items in a horizontal scroll view
/// - Filters out completed items (>95% progress)
/// - Sorts by most recently watched
///
/// ## Usage
/// ```swift
/// ContinueWatchingSection(
///     items: progressItems,
///     mediaType: .video,
///     onItemTap: { progress in
///         // Navigate to player with resume
///     }
/// )
/// ```
struct ContinueWatchingSection: View {
    // MARK: - Properties

    /// The playback progress items to display
    let items: [PlaybackProgress]

    /// Filter to show only video or audio items (nil shows all)
    let mediaType: MediaFilter?

    /// Action when an item is tapped
    let onItemTap: (PlaybackProgress) -> Void

    // MARK: - Media Filter

    enum MediaFilter {
        case video
        case audio
    }

    // MARK: - Initialization

    init(
        items: [PlaybackProgress],
        mediaType: MediaFilter? = nil,
        onItemTap: @escaping (PlaybackProgress) -> Void
    ) {
        self.items = items
        self.mediaType = mediaType
        self.onItemTap = onItemTap
    }

    // MARK: - Body

    var body: some View {
        if filteredItems.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 40) {
                    ForEach(filteredItems, id: \.itemIdentifier) { progress in
                        ContinueWatchingCard(progress: progress) {
                            onItemTap(progress)
                        }
                        .frame(width: cardWidth)
                    }
                }
                .padding(.horizontal, 80)
            }
        }
    }

    // MARK: - Computed Properties

    /// Filtered and sorted items
    private var filteredItems: [PlaybackProgress] {
        items
            .filter { !$0.isComplete } // Exclude completed items
            .filter { item in
                switch mediaType {
                case .video:
                    return item.isVideo
                case .audio:
                    return item.isAudio
                case nil:
                    return true
                }
            }
            .sorted { $0.lastWatchedDate > $1.lastWatchedDate } // Most recent first
    }

    /// Card width based on media type
    private var cardWidth: CGFloat {
        switch mediaType {
        case .video:
            return 350
        case .audio:
            return 200
        case nil:
            // Mixed content - use video width
            return 350
        }
    }
}

// MARK: - Preview

#Preview("Continue Watching Card - Video") {
    let progress = PlaybackProgress(
        itemIdentifier: "example-movie",
        filename: "movie.mp4",
        currentTime: 2700,
        duration: 7200,
        lastWatchedDate: Date(),
        title: "Example Movie Title",
        mediaType: "movies",
        imageURL: nil
    )

    return ContinueWatchingCard(progress: progress) {
        print("Tapped")
    }
    .frame(width: 350)
    .padding()
}

#Preview("Continue Watching Card - Audio") {
    let progress = PlaybackProgress(
        itemIdentifier: "example-album",
        filename: "album",
        currentTime: 45,
        duration: 100,
        lastWatchedDate: Date(),
        title: "Live at Red Rocks 2024",
        mediaType: "etree",
        imageURL: nil,
        trackIndex: 3,
        trackFilename: "track04.mp3",
        trackCurrentTime: 180
    )

    return ContinueWatchingCard(progress: progress) {
        print("Tapped")
    }
    .frame(width: 200)
    .padding()
}
