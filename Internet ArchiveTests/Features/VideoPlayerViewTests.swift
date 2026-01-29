//
//  VideoPlayerViewTests.swift
//  Internet ArchiveTests
//
//  Tests for VideoPlayerView - video format selection, URL building, coordinator
//

import XCTest
@testable import Internet_Archive

// MARK: - VideoPlayerView Tests

final class VideoPlayerViewTests: XCTestCase {

    // MARK: - findPlayableVideo Tests

    func testFindPlayableVideo_prefersH264Format() {
        let files = [
            FileInfo(name: "video.ogv", source: "original", format: "Ogg Video"),
            FileInfo(name: "video.mp4", source: "original", format: "h.264"),
            FileInfo(name: "video.webm", source: "original", format: "WebM")
        ]

        let result = VideoPlayerView.findPlayableVideo(in: files)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "video.mp4")
    }

    func testFindPlayableVideo_prefersMp4Extension() {
        let files = [
            FileInfo(name: "video.webm", source: "original", format: "WebM"),
            FileInfo(name: "movie.mp4", source: "original", format: "MPEG4")
        ]

        let result = VideoPlayerView.findPlayableVideo(in: files)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "movie.mp4")
    }

    func testFindPlayableVideo_prefersMovExtension() {
        let files = [
            FileInfo(name: "video.ogv", source: "original", format: "Ogg Video"),
            FileInfo(name: "clip.mov", source: "original", format: "mov")
        ]

        let result = VideoPlayerView.findPlayableVideo(in: files)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "clip.mov")
    }

    func testFindPlayableVideo_prefersM4vExtension() {
        let files = [
            FileInfo(name: "video.webm", source: "original", format: "WebM"),
            FileInfo(name: "movie.m4v", source: "original", format: "m4v")
        ]

        let result = VideoPlayerView.findPlayableVideo(in: files)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "movie.m4v")
    }

    func testFindPlayableVideo_fallsBackToOgv() {
        let files = [
            FileInfo(name: "video.ogv", source: "original", format: "Ogg Video"),
            FileInfo(name: "thumbnail.jpg", source: "derivative", format: "JPEG")
        ]

        let result = VideoPlayerView.findPlayableVideo(in: files)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "video.ogv")
    }

    func testFindPlayableVideo_fallsBackToWebm() {
        let files = [
            FileInfo(name: "video.webm", source: "original", format: "WebM"),
            FileInfo(name: "meta.xml", source: "original", format: "Metadata")
        ]

        let result = VideoPlayerView.findPlayableVideo(in: files)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "video.webm")
    }

    func testFindPlayableVideo_fallsBackToGenericVideoFormat() {
        let files = [
            FileInfo(name: "clip.avi", source: "original", format: "AVI Video"),
            FileInfo(name: "thumbnail.jpg", source: "derivative", format: "JPEG")
        ]

        let result = VideoPlayerView.findPlayableVideo(in: files)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "clip.avi")
    }

    func testFindPlayableVideo_noVideoFiles_returnsNil() {
        let files = [
            FileInfo(name: "track.mp3", source: "original", format: "MP3"),
            FileInfo(name: "thumbnail.jpg", source: "derivative", format: "JPEG"),
            FileInfo(name: "meta.xml", source: "original", format: "Metadata")
        ]

        let result = VideoPlayerView.findPlayableVideo(in: files)

        XCTAssertNil(result)
    }

    func testFindPlayableVideo_emptyFiles_returnsNil() {
        let result = VideoPlayerView.findPlayableVideo(in: [])

        XCTAssertNil(result)
    }

    func testFindPlayableVideo_caseInsensitiveFormat() {
        let files = [
            FileInfo(name: "VIDEO.MP4", source: "original", format: "H.264")
        ]

        let result = VideoPlayerView.findPlayableVideo(in: files)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "VIDEO.MP4")
    }

    func testFindPlayableVideo_priorityOrder() {
        // Tests that H.264/MP4 is chosen over OGV/WebM
        let files = [
            FileInfo(name: "first.ogv", source: "original", format: "ogv"),
            FileInfo(name: "second.webm", source: "original", format: "webm"),
            FileInfo(name: "third.mp4", source: "original", format: "mp4")
        ]

        let result = VideoPlayerView.findPlayableVideo(in: files)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "third.mp4")
    }
}

// MARK: - VideoPlayerView Coordinator Tests

final class VideoPlayerViewCoordinatorTests: XCTestCase {

    func testCoordinator_initWithOnDismiss() {
        var dismissCalled = false
        let coordinator = VideoPlayerView.Coordinator(onDismiss: { dismissCalled = true })

        XCTAssertNotNil(coordinator.onDismiss)
        coordinator.onDismiss?()
        XCTAssertTrue(dismissCalled)
    }

    func testCoordinator_initWithNilOnDismiss() {
        let coordinator = VideoPlayerView.Coordinator(onDismiss: nil)

        XCTAssertNil(coordinator.onDismiss)
    }

    func testCoordinator_viewControllerInitiallyNil() {
        let coordinator = VideoPlayerView.Coordinator(onDismiss: nil)

        XCTAssertNil(coordinator.viewController)
    }
}

// MARK: - VideoPlayerView Initialization Tests

final class VideoPlayerViewInitializationTests: XCTestCase {

    func testInit_setsAllProperties() {
        guard let videoURL = URL(string: "https://archive.org/download/test/video.mp4") else {
            XCTFail("Failed to create URL")
            return
        }

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

        XCTAssertEqual(view.videoURL, videoURL)
        XCTAssertTrue(view.subtitleTracks.isEmpty)
        XCTAssertEqual(view.identifier, "test-id")
        XCTAssertEqual(view.filename, "video.mp4")
        XCTAssertEqual(view.title, "Test Video")
        XCTAssertEqual(view.thumbnailURL, "https://archive.org/services/img/test-id")
        XCTAssertEqual(view.resumeTime, 120.0)
    }

    func testInit_withDefaultValues() {
        guard let videoURL = URL(string: "https://archive.org/download/test/video.mp4") else {
            XCTFail("Failed to create URL")
            return
        }

        let view = VideoPlayerView(videoURL: videoURL)

        XCTAssertEqual(view.videoURL, videoURL)
        XCTAssertTrue(view.subtitleTracks.isEmpty)
        XCTAssertNil(view.identifier)
        XCTAssertNil(view.filename)
        XCTAssertNil(view.title)
        XCTAssertNil(view.thumbnailURL)
        XCTAssertNil(view.resumeTime)
        XCTAssertNil(view.onDismiss)
    }

    func testInit_withSubtitleTracks() {
        guard let videoURL = URL(string: "https://archive.org/download/test/video.mp4") else {
            XCTFail("Failed to create URL")
            return
        }

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

        XCTAssertEqual(view.subtitleTracks.count, 2)
    }
}
