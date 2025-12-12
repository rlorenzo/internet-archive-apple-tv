//
//  PlaybackProgress.swift
//  Internet Archive
//
//  Model for tracking video and audio playback progress
//

import Foundation

/// Represents saved playback progress for a media item
struct PlaybackProgress: Codable, Sendable, Hashable {

    // MARK: - Properties

    /// Internet Archive item identifier
    let itemIdentifier: String

    /// Specific media filename within the item
    let filename: String

    /// Current playback position in seconds
    let currentTime: Double

    /// Total duration in seconds
    let duration: Double

    /// When the item was last watched/listened
    let lastWatchedDate: Date

    /// Display title for Continue Watching/Listening UI
    let title: String?

    /// Media type: "movies" for video, "etree" for audio
    let mediaType: String

    /// Thumbnail URL for Continue Watching/Listening cells
    let imageURL: String?

    // MARK: - Computed Properties

    /// Progress as a percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard duration > 0 else { return 0 }
        return min(currentTime / duration, 1.0)
    }

    /// Whether the item is considered complete (>95% watched)
    var isComplete: Bool {
        progressPercentage >= 0.95
    }

    /// Time remaining in seconds
    var timeRemaining: Double {
        max(duration - currentTime, 0)
    }

    /// Formatted time remaining (e.g., "12 min remaining" or "45 sec remaining")
    var formattedTimeRemaining: String {
        let remaining = timeRemaining
        if remaining >= 3600 {
            let hours = Int(remaining / 3600)
            let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
            if minutes > 0 {
                return "\(hours) hr \(minutes) min remaining"
            }
            return "\(hours) hr remaining"
        } else if remaining >= 60 {
            let minutes = Int(remaining / 60)
            return "\(minutes) min remaining"
        } else {
            let seconds = Int(remaining)
            return "\(seconds) sec remaining"
        }
    }

    /// Formatted current position (e.g., "1:23:45" or "23:45")
    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    /// Formatted duration (e.g., "1:23:45" or "23:45")
    var formattedDuration: String {
        formatTime(duration)
    }

    /// Whether this is video content
    var isVideo: Bool {
        mediaType == "movies"
    }

    /// Whether this is audio content
    var isAudio: Bool {
        mediaType == "etree"
    }

    /// URL for the thumbnail image
    var thumbnailURL: URL? {
        guard let urlString = imageURL else { return nil }
        return URL(string: urlString)
    }

    // MARK: - Hashable

    static func == (lhs: PlaybackProgress, rhs: PlaybackProgress) -> Bool {
        lhs.itemIdentifier == rhs.itemIdentifier && lhs.filename == rhs.filename
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(itemIdentifier)
        hasher.combine(filename)
    }

    // MARK: - Private Helpers

    private func formatTime(_ time: Double) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Factory Methods

extension PlaybackProgress {

    /// Create a new progress entry with updated time
    /// - Parameter newTime: The new current time
    /// - Returns: Updated PlaybackProgress with new time and date
    func withUpdatedTime(_ newTime: Double) -> PlaybackProgress {
        PlaybackProgress(
            itemIdentifier: itemIdentifier,
            filename: filename,
            currentTime: newTime,
            duration: duration,
            lastWatchedDate: Date(),
            title: title,
            mediaType: mediaType,
            imageURL: imageURL
        )
    }

    /// Create a progress entry for video content
    static func video(
        identifier: String,
        filename: String,
        currentTime: Double,
        duration: Double,
        title: String?,
        imageURL: String?
    ) -> PlaybackProgress {
        PlaybackProgress(
            itemIdentifier: identifier,
            filename: filename,
            currentTime: currentTime,
            duration: duration,
            lastWatchedDate: Date(),
            title: title,
            mediaType: "movies",
            imageURL: imageURL
        )
    }

    /// Create a progress entry for audio content
    static func audio(
        identifier: String,
        filename: String,
        currentTime: Double,
        duration: Double,
        title: String?,
        imageURL: String?
    ) -> PlaybackProgress {
        PlaybackProgress(
            itemIdentifier: identifier,
            filename: filename,
            currentTime: currentTime,
            duration: duration,
            lastWatchedDate: Date(),
            title: title,
            mediaType: "etree",
            imageURL: imageURL
        )
    }
}
