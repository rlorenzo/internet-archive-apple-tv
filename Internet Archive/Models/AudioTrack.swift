//
//  AudioTrack.swift
//  Internet Archive
//
//  Model representing an audio track in a playlist
//

import Foundation

/// Represents an audio track in a playlist with metadata from the Internet Archive API
struct AudioTrack: Hashable, Identifiable, Sendable {

    // MARK: - Constants

    /// Base URL for Internet Archive downloads (static, always valid)
    private static let downloadBaseURL = URL(string: "https://archive.org/download")

    // MARK: - Properties

    /// Unique identifier combining item identifier and filename
    let id: String

    /// Internet Archive item identifier
    let itemIdentifier: String

    /// Audio filename
    let filename: String

    /// Track number (parsed from API, may be nil for unnumbered tracks)
    let trackNumber: Int?

    /// Track title (from API or derived from filename)
    let title: String

    /// Artist name (from track-level creator field)
    let artist: String?

    /// Album name (from track-level album field or item title)
    let album: String?

    /// Duration in seconds
    let duration: Double?

    /// URL to stream the audio file
    let streamURL: URL

    /// Thumbnail URL for album art
    let thumbnailURL: URL?

    // MARK: - Initialization

    /// Initialize from a FileInfo and item metadata
    /// - Parameters:
    ///   - fileInfo: File metadata from the API
    ///   - itemIdentifier: Internet Archive item identifier
    ///   - itemTitle: Item-level title (used as album fallback)
    ///   - imageURL: Item thumbnail URL
    init(fileInfo: FileInfo, itemIdentifier: String, itemTitle: String?, imageURL: URL?) {
        self.id = "\(itemIdentifier)/\(fileInfo.name)"
        self.itemIdentifier = itemIdentifier
        self.filename = fileInfo.name
        self.trackNumber = fileInfo.trackNumber
        self.title = fileInfo.displayTitle
        self.artist = fileInfo.creator
        self.album = fileInfo.album ?? itemTitle
        self.duration = fileInfo.durationInSeconds

        // Build stream URL using Internet Archive download endpoint
        if let baseURL = Self.downloadBaseURL {
            self.streamURL = baseURL
                .appendingPathComponent(itemIdentifier)
                .appendingPathComponent(fileInfo.name)
        } else {
            // Fallback: construct URL directly (should never happen with valid constant)
            self.streamURL = URL(string: "https://archive.org/download/\(itemIdentifier)/\(fileInfo.name)")
                ?? URL(fileURLWithPath: "/")
        }

        self.thumbnailURL = imageURL
    }

    /// Memberwise initializer for testing
    init(
        id: String,
        itemIdentifier: String,
        filename: String,
        trackNumber: Int?,
        title: String,
        artist: String?,
        album: String?,
        duration: Double?,
        streamURL: URL,
        thumbnailURL: URL?
    ) {
        self.id = id
        self.itemIdentifier = itemIdentifier
        self.filename = filename
        self.trackNumber = trackNumber
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.streamURL = streamURL
        self.thumbnailURL = thumbnailURL
    }

    // MARK: - Formatting

    /// Formatted duration string (e.g., "5:12" or "1:23:45")
    var formattedDuration: String {
        guard let duration = duration else { return "--:--" }
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Formatted track number with leading zero (e.g., "01", "02")
    var formattedTrackNumber: String {
        guard let number = trackNumber else { return "" }
        return String(format: "%02d", number)
    }

    /// Display string combining artist and album
    var artistAlbumDisplay: String {
        if let artist = artist, let album = album {
            return "\(artist) - \(album)"
        } else if let artist = artist {
            return artist
        } else if let album = album {
            return album
        }
        return ""
    }

    // MARK: - Hashable

    static func == (lhs: AudioTrack, rhs: AudioTrack) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sorting

extension AudioTrack {
    /// Sort tracks by track number, with unnumbered tracks at the end
    static func sortByTrackNumber(_ lhs: AudioTrack, _ rhs: AudioTrack) -> Bool {
        switch (lhs.trackNumber, rhs.trackNumber) {
        case let (lhsTrack?, rhsTrack?):
            return lhsTrack < rhsTrack
        case (nil, _):
            return false
        case (_, nil):
            return true
        }
    }
}
