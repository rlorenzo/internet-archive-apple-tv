//
//  MediaCardHelpers.swift
//  Internet Archive
//
//  Helper functions for media card formatting - extracted for testability
//

import Foundation
import CoreGraphics

// MARK: - Media Type Helpers

/// Media type definitions with associated display properties
enum MediaTypeHelpers {
    /// Aspect ratio for video content (16:9)
    static let videoAspectRatio: CGFloat = 16.0 / 9.0

    /// Aspect ratio for music content (1:1 square)
    static let musicAspectRatio: CGFloat = 1.0

    /// SF Symbol for video placeholder
    static let videoPlaceholderIcon = "film"

    /// SF Symbol for music placeholder
    static let musicPlaceholderIcon = "music.note"

    /// Get aspect ratio for a media type string
    static func aspectRatio(for mediaType: String?) -> CGFloat {
        guard let mediaType = mediaType?.lowercased() else {
            return videoAspectRatio  // Default to video
        }

        switch mediaType {
        case "etree", "audio":
            return musicAspectRatio
        default:
            return videoAspectRatio
        }
    }

    /// Get placeholder icon for a media type string
    static func placeholderIcon(for mediaType: String?) -> String {
        guard let mediaType = mediaType?.lowercased() else {
            return videoPlaceholderIcon
        }

        switch mediaType {
        case "etree", "audio":
            return musicPlaceholderIcon
        default:
            return videoPlaceholderIcon
        }
    }

    /// Determine if a media type represents music/audio
    static func isAudioType(_ mediaType: String?) -> Bool {
        guard let mediaType = mediaType?.lowercased() else {
            return false
        }
        return mediaType == "etree" || mediaType == "audio"
    }

    /// Determine if a media type represents video
    static func isVideoType(_ mediaType: String?) -> Bool {
        guard let mediaType = mediaType?.lowercased() else {
            return false
        }
        return mediaType == "movies" || mediaType == "video"
    }
}

// MARK: - Accessibility Helpers

/// Helpers for building accessibility labels and hints
enum AccessibilityHelpers {
    /// Build an accessibility label for a media item
    /// - Parameters:
    ///   - title: Item title
    ///   - subtitle: Optional subtitle (creator, year)
    ///   - isVideo: Whether this is video content
    ///   - progress: Optional playback progress (0.0 to 1.0)
    /// - Returns: Combined accessibility label string
    static func buildMediaItemLabel(
        title: String,
        subtitle: String?,
        isVideo: Bool,
        progress: Double?
    ) -> String {
        var components: [String] = [title]

        if let subtitle = subtitle {
            components.append(subtitle)
        }

        let typeLabel = isVideo ? "Video" : "Music"
        components.append(typeLabel)

        if let progress = progress, progress > 0 {
            let percentage = Int(progress * 100)
            components.append("\(percentage)% complete")
        }

        return components.joined(separator: ", ")
    }

    /// Build an accessibility hint for a media item
    /// - Parameter hasProgress: Whether the item has playback progress
    /// - Returns: Accessibility hint string
    static func buildMediaItemHint(hasProgress: Bool) -> String {
        if hasProgress {
            return "Double-tap to resume playback"
        }
        return "Double-tap to view details"
    }

    /// Format progress percentage for accessibility
    static func formatProgressForAccessibility(_ progress: Double) -> String {
        let percentage = Int(progress * 100)
        return "\(percentage)% complete"
    }
}

// MARK: - Progress Formatting Helpers

/// Helpers for formatting playback progress display
enum ProgressFormattingHelpers {
    /// Calculate progress percentage (0.0 to 1.0) from time values
    static func calculateProgress(currentTime: Double, duration: Double) -> Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0), 1.0)
    }

    /// Format remaining time for display
    /// - Parameters:
    ///   - currentTime: Current playback position in seconds
    ///   - duration: Total duration in seconds
    /// - Returns: Formatted string like "45 min remaining" or "2:30 remaining"
    static func formatTimeRemaining(currentTime: Double, duration: Double) -> String? {
        guard duration > 0, currentTime < duration else { return nil }

        let remainingSeconds = duration - currentTime
        return formatDuration(remainingSeconds) + " remaining"
    }

    /// Format a duration in seconds to human-readable string
    /// - Parameter seconds: Duration in seconds
    /// - Returns: Formatted string like "1:23:45" or "45:30" or "45 sec"
    static func formatDuration(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)

        if totalSeconds < 60 {
            return "\(totalSeconds) sec"
        }

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    /// Check if playback is considered complete (>95%)
    static func isPlaybackComplete(currentTime: Double, duration: Double) -> Bool {
        guard duration > 0 else { return false }
        return currentTime / duration >= 0.95
    }

    /// Check if playback has meaningful progress (>5%)
    static func hasSignificantProgress(currentTime: Double, duration: Double) -> Bool {
        guard duration > 0 else { return false }
        let progress = currentTime / duration
        return progress >= 0.05 && progress < 0.95
    }
}

// MARK: - Grid Layout Helpers

/// Helpers for calculating grid layouts
enum GridLayoutHelpers {
    /// Minimum card width for video items
    static let videoMinWidth: CGFloat = 300

    /// Maximum card width for video items
    static let videoMaxWidth: CGFloat = 400

    /// Minimum card width for music items
    static let musicMinWidth: CGFloat = 200

    /// Maximum card width for music items
    static let musicMaxWidth: CGFloat = 280

    /// Default spacing between grid items
    static let defaultSpacing: CGFloat = 40

    /// Calculate number of columns that fit in a given width
    static func columnsCount(
        forWidth containerWidth: CGFloat,
        minItemWidth: CGFloat,
        spacing: CGFloat = defaultSpacing
    ) -> Int {
        let availableWidth = containerWidth - spacing  // Account for edge padding
        let itemWithSpacing = minItemWidth + spacing
        return max(1, Int(availableWidth / itemWithSpacing))
    }

    /// Calculate item width for a given number of columns
    static func itemWidth(
        forColumns columns: Int,
        containerWidth: CGFloat,
        spacing: CGFloat = defaultSpacing
    ) -> CGFloat {
        let totalSpacing = spacing * CGFloat(columns - 1)
        let availableWidth = containerWidth - totalSpacing
        return availableWidth / CGFloat(columns)
    }
}
