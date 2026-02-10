//
//  NowPlayingView.swift
//  Internet Archive
//
//  SwiftUI wrapper for NowPlayingViewController for music/audio playback
//

import SwiftUI

/// SwiftUI wrapper for the Now Playing audio player.
///
/// This view wraps the existing `NowPlayingViewController` to provide
/// full-screen music playback with album art, track list, and transport controls.
///
/// ## Features
/// - Album art display with reflection effect
/// - Track list with "Up Next" queue
/// - Transport controls (play/pause, next, previous, shuffle, repeat)
/// - Progress tracking for Continue Listening
/// - Resume playback support at track level
///
/// ## Usage
/// ```swift
/// NowPlayingView(
///     itemIdentifier: "album-id",
///     itemTitle: "Album Title",
///     imageURL: albumArtURL,
///     tracks: audioTracks,
///     startAt: 0,
///     resumeTime: 45.0
/// )
/// ```
struct NowPlayingView: UIViewControllerRepresentable {
    // MARK: - Properties

    /// Internet Archive item identifier
    let itemIdentifier: String

    /// Item/album title for display
    let itemTitle: String?

    /// Album art image URL
    let imageURL: URL?

    /// Audio tracks to play
    let tracks: [AudioTrack]

    /// Index of track to start playing (0-based)
    let startAt: Int

    /// Time to resume playback from within the starting track (in seconds)
    let resumeTime: Double?

    /// Callback when the player is dismissed
    var onDismiss: (() -> Void)?

    // MARK: - Initialization

    /// Create a Now Playing view.
    /// - Parameters:
    ///   - itemIdentifier: Internet Archive item identifier
    ///   - itemTitle: Item/album title for display
    ///   - imageURL: Album art image URL
    ///   - tracks: Audio tracks to play
    ///   - startAt: Index of track to start playing (default: 0)
    ///   - resumeTime: Time to resume from within the starting track (in seconds)
    ///   - onDismiss: Callback when player is dismissed
    init(
        itemIdentifier: String,
        itemTitle: String? = nil,
        imageURL: URL? = nil,
        tracks: [AudioTrack],
        startAt: Int = 0,
        resumeTime: Double? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.itemIdentifier = itemIdentifier
        self.itemTitle = itemTitle
        self.imageURL = imageURL
        self.tracks = tracks
        self.startAt = startAt
        self.resumeTime = resumeTime
        self.onDismiss = onDismiss
    }

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> NowPlayingViewController {
        let viewController = NowPlayingViewController(
            itemIdentifier: itemIdentifier,
            itemTitle: itemTitle,
            imageURL: imageURL,
            tracks: tracks,
            startAt: startAt,
            resumeTime: resumeTime
        )

        viewController.onDismiss = onDismiss
        context.coordinator.viewController = viewController

        return viewController
    }

    func updateUIViewController(_ uiViewController: NowPlayingViewController, context: Context) {
        // Updates are not needed after initial setup
        // The NowPlayingViewController manages its own state
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        weak var viewController: NowPlayingViewController?
        var onDismiss: (() -> Void)?

        init(onDismiss: (() -> Void)?) {
            self.onDismiss = onDismiss
        }
    }
}

// MARK: - Convenience Initializer

extension NowPlayingView {
    /// Create a Now Playing view from item metadata.
    /// - Parameters:
    ///   - item: The search result item
    ///   - metadata: Item metadata response containing audio files
    ///   - savedProgress: Optional saved playback progress for resume
    ///   - onDismiss: Callback when player is dismissed
    /// - Returns: NowPlayingView if playable audio files are found, nil otherwise
    static func fromMetadata(
        item: SearchResult,
        metadata: ItemMetadataResponse,
        savedProgress: PlaybackProgress? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> NowPlayingView? {
        guard let files = metadata.files else { return nil }

        // Filter for audio files and sort by track number
        let audioFiles = files.filter { file in
            let audioFormats = ["mp3", "flac", "ogg", "wav", "aac", "m4a", "vbr mp3"]
            let format = file.format?.lowercased() ?? ""
            let name = file.name.lowercased()

            return audioFormats.contains(format) ||
                   audioFormats.contains { name.hasSuffix(".\($0)") }
        }

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
        var startIndex = 0
        var trackResumeTime: Double?

        if let progress = savedProgress {
            // Find the track to resume from
            if let savedIndex = progress.trackIndex, savedIndex < tracks.count {
                startIndex = savedIndex
                trackResumeTime = progress.trackCurrentTime
            } else if let savedFilename = progress.trackFilename {
                // Fall back to matching by filename
                if let matchIndex = tracks.firstIndex(where: { $0.filename == savedFilename }) {
                    startIndex = matchIndex
                    trackResumeTime = progress.trackCurrentTime
                }
            }
        }

        return NowPlayingView(
            itemIdentifier: item.identifier,
            itemTitle: item.safeTitle,
            imageURL: thumbnailURL,
            tracks: tracks,
            startAt: startIndex,
            resumeTime: trackResumeTime,
            onDismiss: onDismiss
        )
    }
}

// MARK: - Preview

private enum PreviewURLs {
    static let track1 = URL(string: "https://archive.org/download/example/track01.mp3")
    static let track2 = URL(string: "https://archive.org/download/example/track02.mp3")
}

#Preview {
    if let track1URL = PreviewURLs.track1,
       let track2URL = PreviewURLs.track2 {
        NowPlayingView(
            itemIdentifier: "example-album",
            itemTitle: "Example Album",
            imageURL: nil,
            tracks: [
                AudioTrack(
                    id: "example-album/track01.mp3",
                    itemIdentifier: "example-album",
                    filename: "track01.mp3",
                    trackNumber: 1,
                    title: "First Track",
                    artist: "Artist Name",
                    album: "Example Album",
                    duration: 180,
                    streamURL: track1URL,
                    thumbnailURL: nil
                ),
                AudioTrack(
                    id: "example-album/track02.mp3",
                    itemIdentifier: "example-album",
                    filename: "track02.mp3",
                    trackNumber: 2,
                    title: "Second Track",
                    artist: "Artist Name",
                    album: "Example Album",
                    duration: 240,
                    streamURL: track2URL,
                    thumbnailURL: nil
                )
            ],
            startAt: 0,
            resumeTime: nil
        )
    }
}
