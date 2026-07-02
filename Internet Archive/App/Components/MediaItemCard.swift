//
//  MediaItemCard.swift
//  Internet Archive
//
//  Reusable card component for displaying media items in grids
//

import SwiftUI

/// A card component displaying a media item with thumbnail, title, and optional progress.
///
/// This component is designed for tvOS grid layouts and supports:
/// - Async image loading with placeholder
/// - Video (16:9) and music (square) aspect ratios
/// - Progress bar for Continue Watching/Listening
/// - tvOS focus effects via `TVCardButtonStyle`
///
/// ## Usage
/// ```swift
/// // Video item
/// MediaItemCard(
///     identifier: "my-video",
///     title: "Movie Title",
///     subtitle: "Director Name",
///     mediaType: .video
/// )
///
/// // Music item with progress
/// MediaItemCard(
///     identifier: "my-album",
///     title: "Album Title",
///     subtitle: "Artist Name",
///     mediaType: .music,
///     progress: 0.65
/// )
/// ```
struct MediaItemCard: View {
    // MARK: - Properties

    /// Internet Archive item identifier (used to construct thumbnail URL)
    let identifier: String

    /// Primary title displayed below the thumbnail
    let title: String

    /// Secondary text (creator, year, etc.)
    let subtitle: String?

    /// Media type determines aspect ratio and thumbnail style
    let mediaType: MediaType

    /// Optional playback progress (0.0 to 1.0)
    let progress: Double?

    /// Optional custom thumbnail URL (overrides default IA thumbnail)
    let customThumbnailURL: URL?

    // MARK: - Media Type

    enum MediaType {
        case video
        case music

        var aspectRatio: CGFloat {
            switch self {
            case .video: return 16.0 / 9.0
            case .music: return 1.0
            }
        }

        var placeholderIcon: String {
            switch self {
            case .video: return "film"
            case .music: return "music.note"
            }
        }
    }

    // MARK: - Initialization

    init(
        identifier: String,
        title: String,
        subtitle: String? = nil,
        mediaType: MediaType = .video,
        progress: Double? = nil,
        customThumbnailURL: URL? = nil
    ) {
        self.identifier = identifier
        self.title = title
        self.subtitle = subtitle
        self.mediaType = mediaType
        self.progress = progress
        self.customThumbnailURL = customThumbnailURL
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            thumbnailView
            textContent
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
    }

    // MARK: - Accessibility

    /// Combined accessibility label describing the media item
    private var accessibilityLabelText: String {
        AccessibilityHelpers.buildMediaItemLabel(
            title: title,
            subtitle: subtitle,
            isVideo: mediaType == .video,
            progress: progress
        )
    }

    /// Accessibility hint for VoiceOver
    private var accessibilityHintText: String {
        AccessibilityHelpers.buildMediaItemHint(hasProgress: (progress ?? 0) > 0)
    }

    // MARK: - Subviews

    private var thumbnailView: some View {
        ZStack(alignment: .bottom) {
            // Thumbnail
            AsyncImage(url: thumbnailURL) { phase in
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
            .aspectRatio(mediaType.aspectRatio, contentMode: .fit)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Progress bar overlay
            if let progress = progress, progress > 0 {
                progressOverlay
            }
        }
    }

    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.placeholderFill)

            Image(systemName: mediaType.placeholderIcon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
        }
        .aspectRatio(mediaType.aspectRatio, contentMode: .fit)
    }

    private var progressOverlay: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.surfaceOverlayDim)
                        .frame(height: 8)
                    Rectangle()
                        .fill(Color.white)
                        .frame(
                            width: geometry.size.width * min(progress ?? 0, 1.0),
                            height: 8
                        )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.callout)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundStyle(.primary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Computed Properties

    private var thumbnailURL: URL? {
        if let customURL = customThumbnailURL {
            return customURL
        }
        // Internet Archive thumbnail URL pattern (percent-encoded)
        return IAURLHelpers.thumbnailURL(for: identifier)
    }
}

// MARK: - Convenience Initializers

extension MediaItemCard {
    /// Create a MediaItemCard from a SearchResult.
    ///
    /// - Parameters:
    ///   - searchResult: The item to display.
    ///   - mediaType: Explicit card type. Pass the section's media type when
    ///     known. When nil, the type is derived from the item's `mediatype`
    ///     via `MediaTypeHelpers` so both "audio" and "etree" render as
    ///     square music cards.
    ///   - progress: Optional playback progress (0.0 to 1.0).
    init(searchResult: SearchResult, mediaType: MediaType? = nil, progress: Double? = nil) {
        let resolvedType = mediaType
            ?? (MediaTypeHelpers.isAudioType(searchResult.mediatype) ? .music : .video)

        self.init(
            identifier: searchResult.identifier,
            title: searchResult.safeTitle,
            subtitle: searchResult.creator ?? searchResult.year,
            mediaType: resolvedType,
            progress: progress
        )
    }

    /// Create a MediaItemCard from a PlaybackProgress
    init(playbackProgress: PlaybackProgress) {
        let mediaType: MediaType = playbackProgress.isAudio ? .music : .video

        self.init(
            identifier: playbackProgress.itemIdentifier,
            title: playbackProgress.title ?? playbackProgress.itemIdentifier,
            subtitle: playbackProgress.formattedTimeRemaining,
            mediaType: mediaType,
            progress: playbackProgress.progressPercentage,
            customThumbnailURL: playbackProgress.thumbnailURL
        )
    }
}

// MARK: - Identifiable Extension for SearchResult

extension SearchResult: Identifiable {
    public var id: String { identifier }
}

// MARK: - Media Grid Section

/// A reusable section component for displaying media items in a grid layout.
///
/// This component provides:
/// - Section header with item count
/// - Lazy grid layout appropriate for the media type (size-class aware)
/// - tvOS card button styling
/// - Accessibility support
///
/// ## Usage
/// ```swift
/// MediaGridSection(
///     title: "Favorite Videos",
///     items: viewModel.state.movieResults,
///     mediaType: .video
/// ) { item in
///     selectedItem = item
/// }
/// ```
struct MediaGridSection: View {
    let title: String
    let items: [SearchResult]
    let mediaType: MediaItemCard.MediaType
    let onItemSelected: (SearchResult) -> Void

    @Environment(\.isCompactLayout) private var isCompactLayout

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader("\(title) (\(items.count))")
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(
                columns: SearchResultsGridHelpers.gridColumns(for: mediaType, compact: isCompactLayout),
                spacing: isCompactLayout == true ? 16 : 40
            ) {
                ForEach(items) { item in
                    Button {
                        onItemSelected(item)
                    } label: {
                        MediaItemCard(searchResult: item, mediaType: mediaType)
                    }
                    .tvCardStyle()
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title) section with \(items.count) items")
    }
}

// MARK: - Preview

#Preview("Video Card") {
    MediaItemCard(
        identifier: "example-movie",
        title: "Example Movie Title That Might Be Long",
        subtitle: "2024 • Director Name",
        mediaType: .video
    )
    .frame(width: 350)
    .padding()
}

#Preview("Music Card") {
    MediaItemCard(
        identifier: "example-album",
        title: "Album Title",
        subtitle: "Artist Name",
        mediaType: .music
    )
    .frame(width: 200)
    .padding()
}

#Preview("Card with Progress") {
    MediaItemCard(
        identifier: "example-video",
        title: "Continue Watching",
        subtitle: "45 min remaining",
        mediaType: .video,
        progress: 0.35
    )
    .frame(width: 350)
    .padding()
}
