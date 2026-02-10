//
//  NowPlayingHelpers.swift
//  Internet Archive
//
//  Testable helper functions extracted from NowPlayingViewController
//

import Foundation

/// Pure helper functions for Now Playing screen logic
/// Extracted from NowPlayingViewController for unit testing
enum NowPlayingHelpers {

    // MARK: - Time Formatting

    /// Format a time value in seconds to a display string
    /// Supports negative values (for countdown display)
    /// - Parameter time: Time in seconds (can be negative for countdown)
    /// - Returns: Formatted string like "1:23:45", "-3:21", or "0:00"
    static func formatTime(_ time: Double) -> String {
        let sign = time < 0 ? -1.0 : 1.0
        let absTime = abs(time)
        let hours = Int(absTime) / 3600
        let minutes = (Int(absTime) % 3600) / 60
        let seconds = Int(absTime) % 60

        let prefix = sign < 0 ? "-" : ""

        if hours > 0 {
            return prefix + String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return prefix + String(format: "%d:%02d", minutes, seconds)
        }
    }

    // MARK: - Accessibility

    /// Build accessibility value for the playback slider
    /// - Parameters:
    ///   - currentTime: Current playback position in seconds
    ///   - duration: Total duration in seconds
    /// - Returns: Formatted accessibility value like "1:23 of 4:56"
    static func sliderAccessibilityValue(currentTime: Double, duration: Double) -> String {
        let currentFormatted = formatTime(currentTime)
        let durationFormatted = formatTime(duration)
        return "\(currentFormatted) of \(durationFormatted)"
    }

    // MARK: - Track Position

    /// Build the track position display text
    /// - Parameters:
    ///   - currentPosition: 1-based track position
    ///   - trackCount: Total number of tracks
    /// - Returns: Formatted string like "Track 3 of 12"
    static func trackPositionText(currentPosition: Int, trackCount: Int) -> String {
        "Track \(currentPosition) of \(trackCount)"
    }

    // MARK: - Progress Calculation

    /// Check if progress should be saved (validates minimum thresholds)
    /// - Parameters:
    ///   - currentTime: Current playback time in seconds
    ///   - trackDuration: Duration of current track in seconds
    /// - Returns: true if progress meets minimum thresholds for saving
    static func shouldSaveProgress(currentTime: Double, trackDuration: Double) -> Bool {
        currentTime >= 10 && trackDuration > 0
    }

    /// Build the progress title for Continue Listening display
    /// - Parameters:
    ///   - artist: Track artist (optional)
    ///   - itemTitle: Album/item title (optional)
    ///   - trackTitle: Current track title
    /// - Returns: Formatted display title like "Artist: Track Title"
    static func progressTitle(artist: String?, itemTitle: String?, trackTitle: String) -> String {
        "\(artist ?? itemTitle ?? ""): \(trackTitle)"
    }

    /// Calculate album-level progress from track position
    /// Uses a normalized 0-100 scale for consistent progress bar display
    /// - Parameters:
    ///   - currentIndex: 0-based index of current track
    ///   - trackProgressPercentage: Progress within current track (0.0 to 1.0)
    ///   - trackCount: Total number of tracks in the album
    /// - Returns: Tuple of (currentTime, duration) on a normalized 0-100 scale
    static func calculateAlbumProgress(
        currentIndex: Int,
        trackProgressPercentage: Double,
        trackCount: Int
    ) -> (currentTime: Double, duration: Double) {
        guard trackCount > 0 else { return (0, 100) }
        let albumProgress = (Double(currentIndex) + trackProgressPercentage) / Double(trackCount)
        return (currentTime: albumProgress * 100.0, duration: 100.0)
    }
}
