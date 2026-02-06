//
//  VideoPlayerViewTests.swift
//  Internet ArchiveTests
//
//  Tests for VideoPlayerView - video format selection, URL building, coordinator
//  Migrated to Swift Testing for Sprint 2
//

import Testing
import Foundation
@testable import Internet_Archive

// MARK: - VideoPlayerView findPlayableVideo Tests

@Suite("VideoPlayerView findPlayableVideo Tests")
@MainActor
struct VideoPlayerViewFindPlayableVideoTests {

    @Test("Prefers H.264 format over lower-priority")
    func prefersH264Format() {
        let files = [
            FileInfo(name: "video.ogv", source: "original", format: "Ogg Video"),
            FileInfo(name: "video.mp4", source: "original", format: "h.264"),
            FileInfo(name: "video.webm", source: "original", format: "WebM")
        ]
        let result = VideoPlayerView.findPlayableVideo(in: files)
        #expect(result?.name == "video.mp4")
    }

    @Test("Prefers MP4 extension")
    func prefersMp4Extension() {
        let files = [
            FileInfo(name: "video.webm", source: "original", format: "WebM"),
            FileInfo(name: "movie.mp4", source: "original", format: "MPEG4")
        ]
        let result = VideoPlayerView.findPlayableVideo(in: files)
        #expect(result?.name == "movie.mp4")
    }

    @Test("Prefers MOV extension")
    func prefersMovExtension() {
        let files = [
            FileInfo(name: "video.ogv", source: "original", format: "Ogg Video"),
            FileInfo(name: "clip.mov", source: "original", format: "mov")
        ]
        let result = VideoPlayerView.findPlayableVideo(in: files)
        #expect(result?.name == "clip.mov")
    }

    @Test("Prefers M4V extension")
    func prefersM4vExtension() {
        let files = [
            FileInfo(name: "video.webm", source: "original", format: "WebM"),
            FileInfo(name: "movie.m4v", source: "original", format: "m4v")
        ]
        let result = VideoPlayerView.findPlayableVideo(in: files)
        #expect(result?.name == "movie.m4v")
    }

    @Test("Falls back to OGV when no H.264")
    func fallsBackToOgv() {
        let files = [
            FileInfo(name: "video.ogv", source: "original", format: "Ogg Video"),
            FileInfo(name: "thumbnail.jpg", source: "derivative", format: "JPEG")
        ]
        let result = VideoPlayerView.findPlayableVideo(in: files)
        #expect(result?.name == "video.ogv")
    }

    @Test("Falls back to WebM")
    func fallsBackToWebm() {
        let files = [
            FileInfo(name: "video.webm", source: "original", format: "WebM"),
            FileInfo(name: "meta.xml", source: "original", format: "Metadata")
        ]
        let result = VideoPlayerView.findPlayableVideo(in: files)
        #expect(result?.name == "video.webm")
    }

    @Test("Falls back to generic video format")
    func fallsBackToGenericVideoFormat() {
        let files = [
            FileInfo(name: "clip.avi", source: "original", format: "AVI Video"),
            FileInfo(name: "thumbnail.jpg", source: "derivative", format: "JPEG")
        ]
        let result = VideoPlayerView.findPlayableVideo(in: files)
        #expect(result?.name == "clip.avi")
    }

    @Test("Returns nil when no video files")
    func noVideoFilesReturnsNil() {
        let files = [
            FileInfo(name: "track.mp3", source: "original", format: "MP3"),
            FileInfo(name: "thumbnail.jpg", source: "derivative", format: "JPEG"),
            FileInfo(name: "meta.xml", source: "original", format: "Metadata")
        ]
        #expect(VideoPlayerView.findPlayableVideo(in: files) == nil)
    }

    @Test("Returns nil for empty files")
    func emptyFilesReturnsNil() {
        #expect(VideoPlayerView.findPlayableVideo(in: []) == nil)
    }

    @Test("Case insensitive format matching")
    func caseInsensitiveFormat() {
        let files = [
            FileInfo(name: "VIDEO.MP4", source: "original", format: "H.264")
        ]
        let result = VideoPlayerView.findPlayableVideo(in: files)
        #expect(result?.name == "VIDEO.MP4")
    }

    @Test("Priority order: H.264/MP4 over OGV/WebM")
    func priorityOrder() {
        let files = [
            FileInfo(name: "first.ogv", source: "original", format: "ogv"),
            FileInfo(name: "second.webm", source: "original", format: "webm"),
            FileInfo(name: "third.mp4", source: "original", format: "mp4")
        ]
        let result = VideoPlayerView.findPlayableVideo(in: files)
        #expect(result?.name == "third.mp4")
    }

    @Test("Multiple MP4 files returns first match")
    func multipleMp4ReturnsFirst() {
        let files = [
            FileInfo(name: "low-quality.mp4", source: "derivative", format: "h.264"),
            FileInfo(name: "high-quality.mp4", source: "original", format: "h.264")
        ]
        let result = VideoPlayerView.findPlayableVideo(in: files)
        #expect(result?.name == "low-quality.mp4")
    }

    @Test("Ignores non-video files entirely")
    func ignoresNonVideoFiles() {
        let files = [
            FileInfo(name: "doc.pdf", source: "original", format: "PDF"),
            FileInfo(name: "data.json", source: "original", format: "JSON"),
            FileInfo(name: "image.png", source: "original", format: "PNG")
        ]
        #expect(VideoPlayerView.findPlayableVideo(in: files) == nil)
    }
}

// MARK: - VideoPlayerView Coordinator Tests

@Suite("VideoPlayerView Coordinator Tests")
struct VideoPlayerViewCoordinatorTests {

    @Test("Coordinator init with onDismiss callback")
    func initWithOnDismiss() {
        var dismissCalled = false
        let coordinator = VideoPlayerView.Coordinator(onDismiss: { dismissCalled = true })
        coordinator.onDismiss?()
        #expect(dismissCalled)
    }

    @Test("Coordinator init with nil onDismiss")
    func initWithNilOnDismiss() {
        let coordinator = VideoPlayerView.Coordinator(onDismiss: nil)
        #expect(coordinator.onDismiss == nil)
    }

    @Test("Coordinator viewController initially nil")
    func viewControllerInitiallyNil() {
        let coordinator = VideoPlayerView.Coordinator(onDismiss: nil)
        #expect(coordinator.viewController == nil)
    }
}

// MARK: - VideoPlayerView Initialization Tests

@Suite("VideoPlayerView Initialization Tests")
@MainActor
struct VideoPlayerViewInitializationTests {

    @Test("Sets all properties correctly")
    func setsAllProperties() throws {
        let videoURL = try #require(URL(string: "https://archive.org/download/test/video.mp4"))

        let view = VideoPlayerView(
            videoURL: videoURL,
            subtitleTracks: [],
            identifier: "test-id",
            filename: "video.mp4",
            title: "Test Video",
            thumbnailURL: "https://archive.org/services/img/test-id",
            resumeTime: 120.0,
            onDismiss: nil
        )

        #expect(view.videoURL == videoURL)
        #expect(view.subtitleTracks.isEmpty)
        #expect(view.identifier == "test-id")
        #expect(view.filename == "video.mp4")
        #expect(view.title == "Test Video")
        #expect(view.thumbnailURL == "https://archive.org/services/img/test-id")
        #expect(view.resumeTime == 120.0)
    }

    @Test("Default values are nil")
    func defaultValues() throws {
        let videoURL = try #require(URL(string: "https://archive.org/download/test/video.mp4"))
        let view = VideoPlayerView(videoURL: videoURL)

        #expect(view.videoURL == videoURL)
        #expect(view.subtitleTracks.isEmpty)
        #expect(view.identifier == nil)
        #expect(view.filename == nil)
        #expect(view.title == nil)
        #expect(view.thumbnailURL == nil)
        #expect(view.resumeTime == nil)
        #expect(view.onDismiss == nil)
    }

    @Test("Subtitle tracks stored correctly")
    func subtitleTracksStored() throws {
        let videoURL = try #require(URL(string: "https://archive.org/download/test/video.mp4"))
        let tracks = [
            SubtitleTrack(
                filename: "english.vtt",
                format: .vtt,
                languageCode: "en",
                languageDisplayName: "English",
                isDefault: true,
                url: URL(string: "https://example.com/en.vtt")!
            ),
            SubtitleTrack(
                filename: "spanish.vtt",
                format: .vtt,
                languageCode: "es",
                languageDisplayName: "Spanish",
                isDefault: false,
                url: URL(string: "https://example.com/es.vtt")!
            )
        ]
        let view = VideoPlayerView(videoURL: videoURL, subtitleTracks: tracks)
        #expect(view.subtitleTracks.count == 2)
    }

    @Test("onDismiss callback stored and callable")
    func onDismissCallback() throws {
        let videoURL = try #require(URL(string: "https://archive.org/download/test/video.mp4"))
        var dismissed = false
        let view = VideoPlayerView(videoURL: videoURL, onDismiss: { dismissed = true })
        view.onDismiss?()
        #expect(dismissed)
    }

    @Test("Zero resume time is stored")
    func zeroResumeTime() throws {
        let videoURL = try #require(URL(string: "https://archive.org/download/test/video.mp4"))
        let view = VideoPlayerView(videoURL: videoURL, resumeTime: 0.0)
        #expect(view.resumeTime == 0.0)
    }
}
