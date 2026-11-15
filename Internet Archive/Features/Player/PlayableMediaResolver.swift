//
//  PlayableMediaResolver.swift
//  Internet Archive
//
//  Shared resolution of playable media from item metadata.
//  Single source of truth for video file selection, media URL building,
//  subtitle extraction, audio format filtering, track building, and
//  resume logic - used by both the UIKit presenters and the SwiftUI
//  fromMetadata factories.
//

import Foundation

// MARK: - Resolved Configurations

/// Everything needed to start video playback for an item.
struct ResolvedVideo: Sendable {
    /// Stream URL for the selected video file
    let url: URL

    /// Available subtitle tracks for the video
    let subtitleTracks: [SubtitleTrack]

    /// Item identifier for progress tracking
    let identifier: String

    /// Selected video filename for progress tracking
    let filename: String

    /// Display title for Continue Watching
    let title: String

    /// Thumbnail URL string for Continue Watching display
    let thumbnailURL: String
}

/// One playable episode of a multi-video item.
struct VideoEpisode: Sendable, Equatable, Identifiable {
    /// Filename of the streamable rendition (also the progress-tracking key)
    let filename: String

    /// Display title: the file's `title` metadata, else its filename
    let title: String

    /// Running time in seconds, when IA reports one
    let duration: Double?

    var id: String { filename }
}

/// Everything needed to start audio playback for an item.
struct ResolvedAudioQueue: Sendable {
    /// Internet Archive item identifier
    let itemIdentifier: String

    /// Item/album title for display
    let itemTitle: String

    /// Album art image URL
    let imageURL: URL?

    /// Audio tracks sorted by track number
    let tracks: [AudioTrack]

    /// Index of the track to start playing (0-based)
    let startIndex: Int

    /// Time to resume playback from within the starting track (in seconds)
    let resumeTime: Double?
}

// MARK: - Resolver

/// Pure resolution helpers shared by `VideoPlayerPresenter`,
/// `NowPlayingPresenter`, `VideoPlayerView.fromMetadata`, and
/// `NowPlayingView.fromMetadata`.
enum PlayableMediaResolver {

    // MARK: - Audio Formats

    /// Audio formats recognized for playback (single source of truth).
    /// Matched case-insensitively against the file's format field and
    /// filename extension.
    static let audioFormats = ["mp3", "flac", "ogg", "wav", "aac", "m4a", "vbr mp3"]

    // MARK: - Video Resolution

    /// Resolve the playable video configuration for an item.
    ///
    /// Selects the best playable video file, builds the stream URL
    /// (https://archive.org/download/{identifier}/{filename}), extracts
    /// subtitle tracks, and builds the thumbnail URL.
    /// - Parameters:
    ///   - item: The search result item
    ///   - metadata: Item metadata response containing files and server info
    /// - Returns: ResolvedVideo if a playable video file is found, nil otherwise
    ///   - filename: Episode to play (from `resolveEpisodes`). When nil or not
    ///     found, falls back to the item's best playable video.
    @MainActor
    static func resolveVideo(
        item: SearchResult,
        metadata: ItemMetadataResponse,
        filename: String? = nil
    ) -> ResolvedVideo? {
        let files = metadata.files ?? []
        let requested = filename.flatMap { name in files.first { $0.name == name } }
        // Find the requested episode, else the best playable video file
        guard let videoFile = requested ?? findPlayableVideo(in: files) else {
            return nil
        }

        // Build the video URL: https://archive.org/download/{identifier}/{filename}
        guard let downloadBaseURL = URL(string: "https://archive.org/download") else {
            return nil
        }

        let url = downloadBaseURL
            .appendingPathComponent(item.identifier)
            .appendingPathComponent(videoFile.name)

        // Extract subtitle tracks
        let subtitleTracks = SubtitleManager.shared.extractSubtitleTracks(
            from: metadata.files ?? [],
            identifier: item.identifier
        )

        // Build thumbnail URL
        let thumbnailURL = "https://archive.org/services/img/\(item.identifier)"

        return ResolvedVideo(
            url: url,
            subtitleTracks: subtitleTracks,
            identifier: item.identifier,
            filename: videoFile.name,
            title: displayTitle(item: item, filename: videoFile.name, files: files),
            thumbnailURL: thumbnailURL
        )
    }

    /// Find the best playable video file from the files list.
    /// Prefers H.264 format, then falls back to other video formats.
    static func findPlayableVideo(in files: [FileInfo]) -> FileInfo? {
        let videoFormats = ["h.264", "mp4", "mpeg4", "mov", "m4v"]
        let lowerPriorityFormats = ["ogv", "webm"]

        // First try H.264 / MP4 formats (best compatibility)
        for format in videoFormats {
            if let file = files.first(where: {
                $0.format?.lowercased() == format ||
                $0.name.lowercased().hasSuffix(".\(format)")
            }) {
                return file
            }
        }

        // Fall back to other video formats
        for format in lowerPriorityFormats {
            if let file = files.first(where: {
                $0.format?.lowercased() == format ||
                $0.name.lowercased().hasSuffix(".\(format)")
            }) {
                return file
            }
        }

        // Last resort: any file with "video" in its format
        return files.first { $0.format?.lowercased().contains("video") == true }
    }

    // MARK: - Episodes

    /// Formats AVPlayer can stream, in order of preference.
    static let streamableVideoFormats = ["h.264", "mp4", "mpeg4", "mov", "m4v"]

    /// Resolve every playable episode in a multi-video item (e.g. a
    /// "Complete Series" upload with one file per episode).
    ///
    /// Internet Archive stores each episode as an original plus derivative
    /// renditions whose `original` field names the source file. Files are
    /// grouped by that source so each episode appears once, the most
    /// streamable rendition is chosen (H.264/MP4 first; Ogg, MPEG-1 and AVI
    /// are skipped because AVPlayer can't play them), and episodes are
    /// sorted naturally by source path ("Season 2" before "Season 10").
    ///
    /// Returns an empty array when nothing is streamable; a single-video
    /// item yields one episode.
    static func resolveEpisodes(in files: [FileInfo]) -> [VideoEpisode] {
        var best: [String: (file: FileInfo, rank: Int)] = [:]
        for file in files {
            guard let rank = streamableRank(of: file) else { continue }
            let key = episodeKey(for: file)
            if let current = best[key], current.rank <= rank { continue }
            best[key] = (file, rank)
        }

        return best
            .sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
            .map { key, entry in
                VideoEpisode(
                    filename: entry.file.name,
                    title: episodeTitle(for: entry.file, key: key),
                    duration: parseDuration(entry.file.length)
                )
            }
    }

    /// The episode that follows `filename`, or nil for the last episode or a
    /// single-video item.
    static func nextEpisode(after filename: String, in files: [FileInfo]) -> VideoEpisode? {
        let episodes = resolveEpisodes(in: files)
        guard let index = episodes.firstIndex(where: { $0.filename == filename }),
              episodes.indices.contains(index + 1) else { return nil }
        return episodes[index + 1]
    }

    /// "Series – Episode" for multi-episode items so Continue Watching and
    /// the transport bar show which episode is playing; the item title
    /// otherwise.
    private static func displayTitle(item: SearchResult, filename: String, files: [FileInfo]) -> String {
        let episodes = resolveEpisodes(in: files)
        guard episodes.count > 1,
              let episode = episodes.first(where: { $0.filename == filename }) else {
            return item.safeTitle
        }
        return "\(item.safeTitle) – \(episode.title)"
    }

    /// Lower is better; nil when AVPlayer can't stream the file.
    private static func streamableRank(of file: FileInfo) -> Int? {
        let format = file.format?.lowercased() ?? ""
        let name = file.name.lowercased()
        return streamableVideoFormats.firstIndex { format == $0 || name.hasSuffix(".\($0)") }
    }

    /// The source file an episode rendition was derived from.
    private static func episodeKey(for file: FileInfo) -> String {
        if file.source == "derivative", let original = file.original, !original.isEmpty {
            return original
        }
        return file.name
    }

    private static func episodeTitle(for file: FileInfo, key: String) -> String {
        if let title = file.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }
        let lastComponent = (key as NSString).lastPathComponent
        return (lastComponent as NSString).deletingPathExtension
    }

    /// IA reports `length` as seconds ("1520.14") or as "MM:SS" / "HH:MM:SS".
    static func parseDuration(_ length: String?) -> Double? {
        guard let length, !length.isEmpty else { return nil }
        if let seconds = Double(length) { return seconds > 0 ? seconds : nil }
        let parts = length.split(separator: ":").map { Double($0) }
        guard parts.count <= 3, parts.allSatisfy({ $0 != nil }) else { return nil }
        let total = parts.compactMap { $0 }.reduce(0) { $0 * 60 + $1 }
        return total > 0 ? total : nil
    }

    // MARK: - Audio Resolution

    /// Resolve the playable audio queue configuration for an item.
    ///
    /// Filters for audio files (preferring originals over derivatives to
    /// avoid duplicates - the API returns both original MP3 and derivative
    /// formats like Ogg Vorbis), builds the sorted track list, and resolves
    /// the resume position from saved progress.
    /// - Parameters:
    ///   - item: The search result item
    ///   - metadata: Item metadata response containing audio files
    ///   - savedProgress: Optional saved playback progress for resume
    /// - Returns: ResolvedAudioQueue if playable audio files are found, nil otherwise
    static func resolveAudioQueue(
        item: SearchResult,
        metadata: ItemMetadataResponse,
        savedProgress: PlaybackProgress? = nil
    ) -> ResolvedAudioQueue? {
        guard let files = metadata.files else { return nil }

        // Filter for audio files, preferring originals to avoid duplicates
        let allAudioFiles = files.filter { isAudioFile($0) }

        let originals = allAudioFiles.filter { $0.source == "original" }
        let audioFiles = originals.isEmpty ? allAudioFiles : originals

        guard !audioFiles.isEmpty else { return nil }

        // Convert to AudioTrack models
        let thumbnailURL = URL(string: "https://archive.org/services/img/\(item.identifier)")
        let tracks = audioFiles.map { file in
            AudioTrack(
                fileInfo: file,
                itemIdentifier: item.identifier,
                itemTitle: item.safeTitle,
                imageURL: thumbnailURL
            )
        }.sorted { AudioTrack.sortByTrackNumber($0, $1) }

        // Determine starting track and resume time from saved progress
        // (filename match first, saved index as fallback)
        var startIndex = 0
        var trackResumeTime: Double?

        if let progress = savedProgress,
           let resumeIndex = NowPlayingHelpers.resumeStartIndex(
               trackFilename: progress.trackFilename,
               trackIndex: progress.trackIndex,
               tracks: tracks
           ) {
            startIndex = resumeIndex
            trackResumeTime = progress.trackCurrentTime
        }

        return ResolvedAudioQueue(
            itemIdentifier: item.identifier,
            itemTitle: item.safeTitle,
            imageURL: thumbnailURL,
            tracks: tracks,
            startIndex: startIndex,
            resumeTime: trackResumeTime
        )
    }

    /// Check whether a file is a recognized audio file, matching the
    /// format field or filename extension case-insensitively.
    static func isAudioFile(_ file: FileInfo) -> Bool {
        let format = file.format?.lowercased() ?? ""
        let name = file.name.lowercased()

        return audioFormats.contains(format) ||
               audioFormats.contains { name.hasSuffix(".\($0)") }
    }
}
