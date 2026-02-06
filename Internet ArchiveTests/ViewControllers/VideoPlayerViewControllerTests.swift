//
//  VideoPlayerViewControllerTests.swift
//  Internet ArchiveTests
//
//  Unit tests for VideoPlayerViewController video player with subtitle support
//

import XCTest
import AVFoundation
import AVKit
@testable import Internet_Archive

@MainActor
final class VideoPlayerViewControllerTests: XCTestCase {

    // MARK: - Lifecycle

    override func tearDown() {
        // Clean up any media player resources between tests
        super.tearDown()
    }

    // MARK: - Test Helpers

    private func makeSubtitleTrack(
        filename: String = "subtitles.vtt",
        format: SubtitleFormat = .vtt,
        languageCode: String? = "en",
        languageDisplayName: String = "English",
        isDefault: Bool = false
    ) -> SubtitleTrack {
        let encodedFilename = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filename
        guard let url = URL(string: "https://archive.org/download/test/\(encodedFilename)") else {
            XCTFail("Failed to create test URL for subtitle track: \(filename)")
            fatalError("Invalid test URL - this should not happen with valid test data")
        }
        return SubtitleTrack(
            filename: filename,
            format: format,
            languageCode: languageCode,
            languageDisplayName: languageDisplayName,
            isDefault: isDefault,
            url: url
        )
    }

    private func makePlayer() -> AVPlayer {
        guard let url = URL(string: "https://archive.org/download/test/video.mp4") else {
            XCTFail("Failed to create test video URL")
            fatalError("Invalid test URL")
        }
        return AVPlayer(url: url)
    }

    private func makeViewController(
        subtitleTracks: [SubtitleTrack] = [],
        identifier: String? = "test-video",
        filename: String? = "video.mp4",
        title: String? = "Test Video",
        thumbnailURL: String? = "https://archive.org/services/img/test",
        resumeFromTime: Double? = nil
    ) -> VideoPlayerViewController {
        VideoPlayerViewController(
            player: makePlayer(),
            subtitleTracks: subtitleTracks,
            identifier: identifier,
            filename: filename,
            title: title,
            thumbnailURL: thumbnailURL,
            resumeFromTime: resumeFromTime
        )
    }

    // MARK: - Initialization Tests

    func testVideoPlayerViewController_initWithBasicParameters() {
        let viewController = VideoPlayerViewController(
            player: makePlayer(),
            subtitleTracks: [],
            identifier: "test"
        )

        XCTAssertNotNil(viewController)
        XCTAssertNotNil(viewController.player)
    }

    func testVideoPlayerViewController_initWithAllParameters() {
        let tracks = [
            makeSubtitleTrack(filename: "en.vtt", languageCode: "en", languageDisplayName: "English"),
            makeSubtitleTrack(filename: "es.vtt", languageCode: "es", languageDisplayName: "Spanish")
        ]

        let viewController = VideoPlayerViewController(
            player: makePlayer(),
            subtitleTracks: tracks,
            identifier: "full-test",
            filename: "movie.mp4",
            title: "Full Movie",
            thumbnailURL: "https://example.com/thumb.jpg",
            resumeFromTime: 120.5
        )

        XCTAssertNotNil(viewController)
        XCTAssertEqual(viewController.subtitleTracks.count, 2)
    }

    func testVideoPlayerViewController_initWithEmptySubtitles() {
        let viewController = makeViewController(subtitleTracks: [])

        XCTAssertNotNil(viewController)
        XCTAssertTrue(viewController.subtitleTracks.isEmpty)
    }

    func testVideoPlayerViewController_initWithMultipleSubtitleTracks() {
        let tracks = [
            makeSubtitleTrack(filename: "en.vtt", languageCode: "en", languageDisplayName: "English"),
            makeSubtitleTrack(filename: "es.srt", format: .srt, languageCode: "es", languageDisplayName: "Spanish"),
            makeSubtitleTrack(filename: "fr.vtt", languageCode: "fr", languageDisplayName: "French"),
            makeSubtitleTrack(filename: "de.vtt", languageCode: "de", languageDisplayName: "German")
        ]

        let viewController = makeViewController(subtitleTracks: tracks)

        XCTAssertEqual(viewController.subtitleTracks.count, 4)
    }

    func testVideoPlayerViewController_initWithNilOptionalParameters() {
        let viewController = VideoPlayerViewController(
            player: makePlayer(),
            subtitleTracks: [],
            identifier: nil,
            filename: nil,
            title: nil,
            thumbnailURL: nil,
            resumeFromTime: nil
        )

        XCTAssertNotNil(viewController)
    }

    // MARK: - Subtitle Track Tests

    func testVideoPlayerViewController_subtitleTracksAreStoredCorrectly() {
        let tracks = [
            makeSubtitleTrack(filename: "en.vtt", languageCode: "en", languageDisplayName: "English"),
            makeSubtitleTrack(filename: "es.vtt", languageCode: "es", languageDisplayName: "Spanish")
        ]

        let viewController = makeViewController(subtitleTracks: tracks)

        XCTAssertEqual(viewController.subtitleTracks.count, 2)
        XCTAssertEqual(viewController.subtitleTracks[0].languageDisplayName, "English")
        XCTAssertEqual(viewController.subtitleTracks[1].languageDisplayName, "Spanish")
    }

    func testVideoPlayerViewController_selectedSubtitleTrackInitiallyNil() {
        let tracks = [makeSubtitleTrack()]
        let viewController = makeViewController(subtitleTracks: tracks)

        XCTAssertNil(viewController.selectedSubtitleTrack)
    }

    func testVideoPlayerViewController_selectSubtitleTrack() {
        let track = makeSubtitleTrack(
            filename: "en.vtt",
            languageCode: "en",
            languageDisplayName: "English"
        )
        let viewController = makeViewController(subtitleTracks: [track])
        viewController.loadViewIfNeeded()

        viewController.selectSubtitleTrack(track)

        XCTAssertNotNil(viewController.selectedSubtitleTrack)
        XCTAssertEqual(viewController.selectedSubtitleTrack?.languageCode, "en")
    }

    func testVideoPlayerViewController_selectSubtitleTrack_nil() {
        let track = makeSubtitleTrack()
        let viewController = makeViewController(subtitleTracks: [track])
        viewController.loadViewIfNeeded()

        viewController.selectSubtitleTrack(track)
        viewController.selectSubtitleTrack(nil)

        XCTAssertNil(viewController.selectedSubtitleTrack)
    }

    // MARK: - Resume Time Tests

    func testVideoPlayerViewController_initWithResumeTime() {
        let viewController = makeViewController(resumeFromTime: 300.0)

        XCTAssertNotNil(viewController)
    }

    func testVideoPlayerViewController_initWithZeroResumeTime() {
        let viewController = makeViewController(resumeFromTime: 0.0)

        XCTAssertNotNil(viewController)
    }

    func testVideoPlayerViewController_initWithNegativeResumeTime() {
        let viewController = makeViewController(resumeFromTime: -50.0)

        XCTAssertNotNil(viewController)
    }

    func testVideoPlayerViewController_initWithVeryLargeResumeTime() {
        let viewController = makeViewController(resumeFromTime: 999999.0)

        XCTAssertNotNil(viewController)
    }

    // MARK: - Callback Tests

    func testVideoPlayerViewController_onDismissCallbackCanBeSet() {
        let viewController = makeViewController()
        var dismissCalled = false

        viewController.onDismiss = {
            dismissCalled = true
        }

        viewController.onDismiss?()

        XCTAssertTrue(dismissCalled)
    }

    // MARK: - View Lifecycle Tests

    func testVideoPlayerViewController_viewDidLoadConfiguresDelegate() {
        let viewController = makeViewController()

        viewController.loadViewIfNeeded()

        XCTAssertNotNil(viewController.delegate)
    }

    // MARK: - Edge Cases

    func testVideoPlayerViewController_emptyIdentifier() {
        let viewController = makeViewController(identifier: "")

        XCTAssertNotNil(viewController)
    }

    func testVideoPlayerViewController_emptyFilename() {
        let viewController = makeViewController(filename: "")

        XCTAssertNotNil(viewController)
    }

    func testVideoPlayerViewController_specialCharactersInTitle() {
        let viewController = makeViewController(title: "Movie: Part II (2024) - Director's Cut™ & More")

        XCTAssertNotNil(viewController)
    }

    func testVideoPlayerViewController_unicodeTitle() {
        let viewController = makeViewController(title: "日本語映画 🎬")

        XCTAssertNotNil(viewController)
    }

    func testVideoPlayerViewController_invalidThumbnailURL() {
        let viewController = makeViewController(thumbnailURL: "not-a-valid-url")

        XCTAssertNotNil(viewController)
    }

    // MARK: - Subtitle Format Tests

    func testVideoPlayerViewController_srtSubtitleTrack() {
        let track = makeSubtitleTrack(filename: "subtitles.srt", format: .srt)
        let viewController = makeViewController(subtitleTracks: [track])

        XCTAssertEqual(viewController.subtitleTracks[0].format, .srt)
        XCTAssertFalse(viewController.subtitleTracks[0].format.isNativelySupported)
    }

    func testVideoPlayerViewController_vttSubtitleTrack() {
        let track = makeSubtitleTrack(filename: "subtitles.vtt", format: .vtt)
        let viewController = makeViewController(subtitleTracks: [track])

        XCTAssertEqual(viewController.subtitleTracks[0].format, .vtt)
        XCTAssertTrue(viewController.subtitleTracks[0].format.isNativelySupported)
    }

    func testVideoPlayerViewController_webvttSubtitleTrack() {
        let track = makeSubtitleTrack(filename: "subtitles.webvtt", format: .webvtt)
        let viewController = makeViewController(subtitleTracks: [track])

        XCTAssertEqual(viewController.subtitleTracks[0].format, .webvtt)
        XCTAssertTrue(viewController.subtitleTracks[0].format.isNativelySupported)
    }

    func testVideoPlayerViewController_mixedSubtitleFormats() {
        let tracks = [
            makeSubtitleTrack(filename: "en.vtt", format: .vtt, languageCode: "en"),
            makeSubtitleTrack(filename: "es.srt", format: .srt, languageCode: "es"),
            makeSubtitleTrack(filename: "fr.webvtt", format: .webvtt, languageCode: "fr")
        ]

        let viewController = makeViewController(subtitleTracks: tracks)

        XCTAssertEqual(viewController.subtitleTracks.count, 3)
    }
}

// MARK: - SubtitleSelectionDelegate Tests

@MainActor
final class VideoPlayerSubtitleDelegateTests: XCTestCase {

    private func makeSubtitleTrack(
        filename: String = "subtitles.vtt",
        languageCode: String = "en",
        languageDisplayName: String = "English"
    ) -> SubtitleTrack {
        SubtitleTrack(
            filename: filename,
            format: .vtt,
            languageCode: languageCode,
            languageDisplayName: languageDisplayName,
            isDefault: false,
            url: URL(string: "https://archive.org/download/test/\(filename)")!
        )
    }

    private func makePlayer() -> AVPlayer {
        AVPlayer(url: URL(string: "https://archive.org/download/test/video.mp4")!)
    }

    func testSubtitleSelection_didSelectTrack() {
        let track = makeSubtitleTrack()
        let viewController = VideoPlayerViewController(
            player: makePlayer(),
            subtitleTracks: [track],
            identifier: "test"
        )
        viewController.loadViewIfNeeded()

        let selectionVC = SubtitleSelectionViewController(tracks: [track], selectedTrack: nil)
        viewController.subtitleSelection(selectionVC, didSelect: track)

        XCTAssertNotNil(viewController.selectedSubtitleTrack)
        XCTAssertEqual(viewController.selectedSubtitleTrack?.languageCode, "en")
    }

    func testSubtitleSelection_didTurnOff() {
        let track = makeSubtitleTrack()
        let viewController = VideoPlayerViewController(
            player: makePlayer(),
            subtitleTracks: [track],
            identifier: "test"
        )
        viewController.loadViewIfNeeded()
        viewController.selectSubtitleTrack(track)

        let selectionVC = SubtitleSelectionViewController(tracks: [track], selectedTrack: track)
        viewController.subtitleSelectionDidTurnOff(selectionVC)

        XCTAssertNil(viewController.selectedSubtitleTrack)
    }
}
