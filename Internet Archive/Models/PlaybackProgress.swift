//
//  PlaybackProgress.swift
//  Internet Archive
//
//  Model for tracking video and audio playback progress
//

import Foundation

/// Represents saved playback progress for a media item
struct PlaybackProgress: Codable, Sendable, Hashable {

    // MARK: - Static Properties

    // Pre-compiled regex for validating Internet Archive identifiers.
    // Valid identifiers contain only alphanumeric characters, periods, underscores, and hyphens.
    private static let validIdentifierRegex: NSRegularExpression = {
        do {
            return try NSRegularExpression(pattern: "^[a-zA-Z0-9._-]+$", options: [])
        } catch {
            preconditionFailure("Invalid identifier regex: \(error)")
        }
    }()

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

    /// Track index within album queue (audio only)
    let trackIndex: Int?

    /// Actual filename of the track being played (audio only, for display)
    let trackFilename: String?

    /// Current playback position within the track in seconds (audio only, for resume)
    let trackCurrentTime: Double?

    // MARK: - Initialization

    init(
        itemIdentifier: String,
        filename: String,
        currentTime: Double,
        duration: Double,
        lastWatchedDate: Date,
        title: String?,
        mediaType: String,
        imageURL: String?,
        trackIndex: Int? = nil,
        trackFilename: String? = nil,
        trackCurrentTime: Double? = nil
    ) {
        self.itemIdentifier = itemIdentifier
        self.filename = filename
        self.currentTime = currentTime
        self.duration = duration
        self.lastWatchedDate = lastWatchedDate
        self.title = title
        self.mediaType = mediaType
        self.imageURL = imageURL
        self.trackIndex = trackIndex
        self.trackFilename = trackFilename
        self.trackCurrentTime = trackCurrentTime
    }

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

    /// Time remaining in seconds (for video) or percentage points remaining (for audio albums)
    var timeRemaining: Double {
        max(duration - currentTime, 0)
    }

    /// Formatted time remaining (e.g., "12 min remaining" or "45 sec remaining")
    /// For audio albums using normalized progress, shows percentage remaining instead
    var formattedTimeRemaining: String {
        // Audio albums use normalized 0-100 scale, not actual seconds
        // Show percentage remaining for audio to avoid confusing "50 sec remaining" display
        if isAudio && duration == 100.0 {
            let percentRemaining = Int(100.0 - progressPercentage * 100.0)
            return "\(percentRemaining)% remaining"
        }

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

    /// Whether this progress entry has valid data for display
    /// Filters out corrupted entries with empty identifiers or titles
    var isValid: Bool {
        // Must have a non-empty identifier (needed for thumbnail URL)
        guard !itemIdentifier.isEmpty else { return false }

        // Identifier should look like a valid Internet Archive identifier
        // (alphanumeric, hyphens, underscores, periods - no spaces or special chars)
        let range = NSRange(itemIdentifier.startIndex..<itemIdentifier.endIndex, in: itemIdentifier)
        guard Self.validIdentifierRegex.firstMatch(in: itemIdentifier, options: [], range: range) != nil else {
            return false
        }

        // Must have a non-empty title for display (trimmed of whitespace)
        guard let title = title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }

        return true
    }

    /// Whether there is enough progress to offer resume
    /// For video: requires >10 seconds of playback
    /// For audio: requires >10 seconds in the current track (falls back to album progress)
    var hasResumableProgress: Bool {
        if isAudio, let trackTime = trackCurrentTime {
            // For audio, use track-level progress (seconds within current track)
            return trackTime > 10
        }
        // For video, currentTime is in seconds
        return currentTime > 10
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
            imageURL: imageURL,
            trackIndex: trackIndex,
            trackFilename: trackFilename,
            trackCurrentTime: trackCurrentTime
        )
    }

    /// Create a progress entry for video content
    static func video(_ info: MediaProgressInfo) -> PlaybackProgress {
        PlaybackProgress(
            itemIdentifier: info.identifier,
            filename: info.filename,
            currentTime: info.currentTime,
            duration: info.duration,
            lastWatchedDate: Date(),
            title: info.title,
            mediaType: "movies",
            imageURL: info.imageURL,
            trackIndex: nil,
            trackFilename: nil
        )
    }

    /// Create a progress entry for audio content (album-level)
    static func audio(_ info: MediaProgressInfo) -> PlaybackProgress {
        PlaybackProgress(
            itemIdentifier: info.identifier,
            filename: info.filename,
            currentTime: info.currentTime,
            duration: info.duration,
            lastWatchedDate: Date(),
            title: info.title,
            mediaType: "etree",
            imageURL: info.imageURL,
            trackIndex: info.trackIndex,
            trackFilename: info.trackFilename,
            trackCurrentTime: info.trackCurrentTime
        )
    }
}

// MARK: - Supporting Types

/// Parameters for creating a PlaybackProgress entry
struct MediaProgressInfo {
    let identifier: String
    let filename: String
    let currentTime: Double
    let duration: Double
    var title: String?
    var imageURL: String?
    /// Track index within album queue (audio only)
    var trackIndex: Int?
    /// Actual filename of the track being played (audio only)
    var trackFilename: String?
    /// Current playback position within the track in seconds (audio only, for resume)
    var trackCurrentTime: Double?

    init(
        identifier: String,
        filename: String,
        currentTime: Double,
        duration: Double,
        title: String? = nil,
        imageURL: String? = nil,
        trackIndex: Int? = nil,
        trackFilename: String? = nil,
        trackCurrentTime: Double? = nil
    ) {
        self.identifier = identifier
        self.filename = filename
        self.currentTime = currentTime
        self.duration = duration
        self.title = title
        self.imageURL = imageURL
        self.trackIndex = trackIndex
        self.trackFilename = trackFilename
        self.trackCurrentTime = trackCurrentTime
    }
}
