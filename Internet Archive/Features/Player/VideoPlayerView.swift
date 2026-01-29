//
//  VideoPlayerView.swift
//  Internet Archive
//
//  SwiftUI wrapper for VideoPlayerViewController with subtitle support
//

import AVKit
import SwiftUI
import UIKit

// MARK: - Video Player Presenter

/// Helper to present VideoPlayerViewController from SwiftUI using UIKit modal presentation.
/// This ensures proper tvOS remote control handling including transport bar controls.
enum VideoPlayerPresenter {
    /// Present video player from item metadata.
    /// - Parameters:
    ///   - item: The search result item
    ///   - metadata: Item metadata response containing files and server info
    ///   - resumeTime: Optional time to resume from
    ///   - onDismiss: Callback when player is dismissed
    /// - Returns: true if presentation was successful, false if no playable video found
    @MainActor
    @discardableResult
    static func presentFromMetadata(
        item: SearchResult,
        metadata: ItemMetadataResponse,
        resumeTime: Double? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> Bool {
        // Find the best playable video file
        guard let videoFile = VideoPlayerView.findPlayableVideo(in: metadata.files ?? []) else {
            return false
        }

        // Build the video URL
        guard let downloadBaseURL = URL(string: "https://archive.org/download") else {
            return false
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

        // Find the root view controller to present from
        // Prefer the foreground-active scene and its key window for multi-scene support
        let activeScene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        guard let rootVC = activeScene?.windows
            .first(where: { $0.isKeyWindow })?.rootViewController
            ?? activeScene?.windows.first?.rootViewController else {
            return false
        }

        // Find the topmost presented view controller
        var presentingVC = rootVC
        while let presented = presentingVC.presentedViewController {
            presentingVC = presented
        }

        // Create player
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)

        // Create the video player view controller
        let playerVC = VideoPlayerViewController(
            player: player,
            subtitleTracks: subtitleTracks,
            identifier: item.identifier,
            filename: videoFile.name,
            title: item.safeTitle,
            thumbnailURL: thumbnailURL,
            resumeFromTime: resumeTime
        )

        // Configure for proper tvOS presentation
        playerVC.modalPresentationStyle = .fullScreen
        playerVC.allowsPictureInPicturePlayback = false
        playerVC.showsPlaybackControls = true
        playerVC.onDismiss = onDismiss

        // Present using UIKit - this ensures proper remote control handling
        presentingVC.present(playerVC, animated: true) {
            player.play()
        }

        return true
    }
}

/// SwiftUI wrapper for the video player with subtitle support.
///
/// This view wraps the existing `VideoPlayerViewController` to provide
/// native AVPlayer video playback with custom subtitle overlay support.
///
/// ## Features
/// - Full-screen video playback via AVPlayerViewController
/// - Custom subtitle overlay with WebVTT/SRT support
/// - Progress tracking for Continue Watching
/// - Resume playback support
///
/// ## Usage
/// ```swift
/// VideoPlayerView(
///     videoURL: videoURL,
///     subtitleTracks: tracks,
///     identifier: "item-id",
///     filename: "video.mp4",
///     title: "Video Title",
///     thumbnailURL: thumbnailURL,
///     resumeTime: 120.0
/// )
/// ```
struct VideoPlayerView: UIViewControllerRepresentable {
    // MARK: - Properties

    /// URL of the video to play
    let videoURL: URL

    /// Available subtitle tracks for the video
    let subtitleTracks: [SubtitleTrack]

    /// Item identifier for progress tracking
    let identifier: String?

    /// Video filename for progress tracking
    let filename: String?

    /// Video title for Continue Watching display
    let title: String?

    /// Thumbnail URL for Continue Watching display
    let thumbnailURL: String?

    /// Time to resume playback from (in seconds)
    let resumeTime: Double?

    /// Callback when the player is dismissed
    var onDismiss: (() -> Void)?

    // MARK: - Initialization

    /// Create a video player view.
    /// - Parameters:
    ///   - videoURL: URL of the video to play
    ///   - subtitleTracks: Available subtitle tracks
    ///   - identifier: Item identifier for progress tracking
    ///   - filename: Video filename for progress tracking
    ///   - title: Video title for Continue Watching display
    ///   - thumbnailURL: Thumbnail URL for Continue Watching display
    ///   - resumeTime: Optional time to resume from (in seconds)
    ///   - onDismiss: Callback when player is dismissed
    init(
        videoURL: URL,
        subtitleTracks: [SubtitleTrack] = [],
        identifier: String? = nil,
        filename: String? = nil,
        title: String? = nil,
        thumbnailURL: String? = nil,
        resumeTime: Double? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.videoURL = videoURL
        self.subtitleTracks = subtitleTracks
        self.identifier = identifier
        self.filename = filename
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.resumeTime = resumeTime
        self.onDismiss = onDismiss
    }

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> VideoPlayerViewController {
        // Create player using AVAsset and AVPlayerItem
        let asset = AVAsset(url: videoURL)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)

        let viewController = VideoPlayerViewController(
            player: player,
            subtitleTracks: subtitleTracks,
            identifier: identifier,
            filename: filename,
            title: title,
            thumbnailURL: thumbnailURL,
            resumeFromTime: resumeTime
        )

        // Forward onDismiss callback to view controller
        viewController.onDismiss = onDismiss

        // Configure for full-screen playback with controls
        viewController.modalPresentationStyle = .fullScreen
        viewController.allowsPictureInPicturePlayback = false
        viewController.showsPlaybackControls = true

        // Store coordinator reference for dismiss handling
        context.coordinator.viewController = viewController

        // Delay play() until player is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            player.play()
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: VideoPlayerViewController, context: Context) {
        // Updates are not needed after initial setup
        // The VideoPlayerViewController manages its own state
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        weak var viewController: VideoPlayerViewController?
        var onDismiss: (() -> Void)?

        init(onDismiss: (() -> Void)?) {
            self.onDismiss = onDismiss
        }
    }
}

// MARK: - Convenience Initializer

extension VideoPlayerView {
    /// Create a video player view from item metadata.
    /// - Parameters:
    ///   - item: The search result item
    ///   - metadata: Item metadata response containing files and server info
    ///   - resumeTime: Optional time to resume from
    ///   - onDismiss: Callback when player is dismissed
    /// - Returns: VideoPlayerView if a playable video file is found, nil otherwise
    static func fromMetadata(
        item: SearchResult,
        metadata: ItemMetadataResponse,
        resumeTime: Double? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> VideoPlayerView? {
        // Find the best playable video file
        guard let videoFile = findPlayableVideo(in: metadata.files ?? []) else {
            return nil
        }

        // Build the video URL using the same approach as UIKit ItemVC:
        // https://archive.org/download/{identifier}/{filename}
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

        return VideoPlayerView(
            videoURL: url,
            subtitleTracks: subtitleTracks,
            identifier: item.identifier,
            filename: videoFile.name,
            title: item.safeTitle,
            thumbnailURL: thumbnailURL,
            resumeTime: resumeTime,
            onDismiss: onDismiss
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
}

// MARK: - Preview

private enum VideoPreviewURLs {
    static let video = URL(string: "https://archive.org/download/example/video.mp4")
}

#Preview {
    if let videoURL = VideoPreviewURLs.video {
        VideoPlayerView(
            videoURL: videoURL,
            subtitleTracks: [],
            identifier: "example",
            filename: "video.mp4",
            title: "Example Video",
            thumbnailURL: nil,
            resumeTime: nil
        )
    }
}
