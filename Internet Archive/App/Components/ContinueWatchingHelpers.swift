//
//  ContinueWatchingHelpers.swift
//  Internet Archive
//
//  Testable helper functions for ContinueWatchingCard and ContinueWatchingSection
//

import SwiftUI

/// Helper functions for Continue Watching functionality
/// Extracted from views to enable comprehensive unit testing
enum ContinueWatchingHelpers {

    // MARK: - Filtering and Sorting

    /// Filters playback progress items based on completion status and media type
    /// - Parameters:
    ///   - items: All progress items to filter
    ///   - mediaType: Optional filter for video or audio (nil = all types)
    /// - Returns: Filtered and sorted items (most recent first, excluding completed items)
    static func filterProgressItems(
        _ items: [PlaybackProgress],
        mediaType: ContinueWatchingSection.MediaFilter?
    ) -> [PlaybackProgress] {
        items
            .filter { !$0.isComplete } // Exclude completed items (>95%)
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

    // MARK: - Card Sizing

    /// Returns the card width based on media type filter
    /// - Parameter mediaType: The media type filter
    /// - Returns: Width in points for the card
    static func cardWidth(for mediaType: ContinueWatchingSection.MediaFilter?) -> CGFloat {
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

    /// Returns the aspect ratio for a card based on whether it's video or audio
    /// - Parameter isVideo: Whether the content is video
    /// - Returns: The aspect ratio (width/height)
    static func aspectRatio(isVideo: Bool) -> CGFloat {
        isVideo ? 16.0 / 9.0 : 1.0
    }

    // MARK: - Accessibility

    /// Generates the accessibility label for a continue watching card
    /// - Parameter progress: The playback progress
    /// - Returns: A descriptive accessibility label
    static func accessibilityLabel(for progress: PlaybackProgress) -> String {
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

    /// Generates the accessibility label for a section
    /// - Parameters:
    ///   - mediaType: The section's media type filter
    ///   - itemCount: Number of items in the section
    /// - Returns: A descriptive section accessibility label
    static func sectionAccessibilityLabel(
        mediaType: ContinueWatchingSection.MediaFilter?,
        itemCount: Int
    ) -> String {
        let typeLabel = switch mediaType {
        case .video: "Continue watching"
        case .audio: "Continue listening"
        case nil: "Continue playing"
        }
        return "\(typeLabel) section with \(itemCount) items"
    }

    // MARK: - Thumbnail URL

    /// Generates the thumbnail URL for an item
    /// - Parameter identifier: The item's identifier
    /// - Returns: URL for the Archive.org thumbnail service
    static func thumbnailURL(for identifier: String) -> URL? {
        URL(string: "https://archive.org/services/img/\(identifier)")
    }
}
