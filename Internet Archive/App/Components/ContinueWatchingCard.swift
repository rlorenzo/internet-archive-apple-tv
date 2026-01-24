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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Double-tap to resume playback")
    }

    // MARK: - Accessibility

    /// Combined accessibility label describing the continue watching item
    private var accessibilityLabelText: String {
        var components: [String] = []

        // Title
        components.append(progress.title ?? progress.itemIdentifier)

        // Media type
        components.append(progress.isVideo ? "Video" : "Music")

        // Progress info
        let percentage = Int(progress.progressPercentage * 100)
        components.append("\(percentage)% complete")

        // Time remaining
        components.append(progress.formattedTimeRemaining)

        return components.joined(separator: ", ")
    }

    // MARK: - Subviews

    private var thumbnailWithProgress: some View {
        ZStack(alignment: .bottom) {
            // Container with fixed aspect ratio
            Color.clear
                .aspectRatio(aspectRatio, contentMode: .fit)
                .overlay {
                    // Thumbnail - always use archive.org thumbnail service for consistency
                    // This avoids issues with corrupted/invalid stored imageURLs
                    AsyncImage(url: archiveThumbnailURL) { phase in
                        switch phase {
                        case .empty:
                            placeholderContent
                        case .success(let image):
                            // Internet Archive audio items often return waveform visualizations
                            // as thumbnails instead of album art. These waveforms are typically
                            // very wide and short (e.g., 180x45 pixels) - appearing as a horizontal
                            // audio waveform strip rather than a proper thumbnail.
                            //
                            // Heuristic to detect waveform thumbnails:
                            // - Height < 100px: Too short to be proper album art
                            // - Width > 3x height: Panoramic aspect ratio typical of waveforms
                            //
                            // When detected, we show a placeholder with a music icon instead.
                            if progress.isAudio, let cgImage = ImageRenderer(content: image).cgImage,
                               cgImage.height < 100 && cgImage.width > cgImage.height * 3 {
                                placeholderContent
                            } else {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }
                        case .failure:
                            placeholderContent
                        @unknown default:
                            placeholderContent
                        }
                    }
                }
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Progress bar
            progressOverlay
        }
    }

    /// Thumbnail URL using Internet Archive's thumbnail service
    /// Always uses the item identifier to ensure consistent, valid thumbnails
    private var archiveThumbnailURL: URL? {
        URL(string: "https://archive.org/services/img/\(progress.itemIdentifier)")
    }

    /// Placeholder content without aspect ratio (used inside fixed container)
    private var placeholderContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))

            Image(systemName: progress.isVideo ? "film" : "music.note")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
        }
    }

    /// Placeholder view with aspect ratio (for standalone use)
    private var placeholderView: some View {
        placeholderContent
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
                .padding(.vertical, 50)
            }
            .scrollClipDisabled()
            .accessibilityElement(children: .contain)
            .accessibilityLabel(sectionAccessibilityLabel)
        }
    }

    // MARK: - Accessibility

    /// Accessibility label for the section
    private var sectionAccessibilityLabel: String {
        let typeLabel = mediaType == .video ? "Continue watching" :
                        mediaType == .audio ? "Continue listening" :
                        "Continue playing"
        return "\(typeLabel) section with \(filteredItems.count) items"
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
