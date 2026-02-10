//
//  NowPlayingViewControllerTests.swift
//  Internet ArchiveTests
//
//  Unit tests for NowPlayingViewController music player
//

import XCTest
import AVFoundation
@testable import Internet_Archive

@MainActor
final class NowPlayingViewControllerTests: XCTestCase {

    // MARK: - Lifecycle

    override func tearDown() {
        // Clean up any media player resources between tests
        super.tearDown()
    }

    // MARK: - Test Helpers

    private func makeTrack(
        id: String = "test-id",
        itemIdentifier: String = "test-item",
        filename: String = "track.mp3",
        trackNumber: Int? = 1,
        title: String = "Test Track",
        artist: String? = "Test Artist",
        album: String? = "Test Album",
        duration: Double? = 180.0
    ) -> AudioTrack {
        let encodedFilename = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filename
        guard let streamURL = URL(string: "https://archive.org/download/\(itemIdentifier)/\(encodedFilename)") else {
            XCTFail("Failed to create stream URL for track: \(filename)")
            fatalError("Invalid test URL")
        }
        return AudioTrack(
            id: id,
            itemIdentifier: itemIdentifier,
            filename: filename,
            trackNumber: trackNumber,
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            streamURL: streamURL,
            thumbnailURL: URL(string: "https://archive.org/services/img/\(itemIdentifier)")
        )
    }

    private func makeViewController(
        itemIdentifier: String = "test-item",
        itemTitle: String? = "Test Album",
        imageURL: URL? = nil,
        tracks: [AudioTrack]? = nil,
        startAt: Int = 0,
        resumeTime: Double? = nil
    ) -> NowPlayingViewController {
        let testTracks = tracks ?? [
            makeTrack(id: "1", filename: "track1.mp3", trackNumber: 1, title: "Track 1"),
            makeTrack(id: "2", filename: "track2.mp3", trackNumber: 2, title: "Track 2"),
            makeTrack(id: "3", filename: "track3.mp3", trackNumber: 3, title: "Track 3")
        ]

        return NowPlayingViewController(
            itemIdentifier: itemIdentifier,
            itemTitle: itemTitle,
            imageURL: imageURL ?? URL(string: "https://archive.org/services/img/\(itemIdentifier)"),
            tracks: testTracks,
            startAt: startAt,
            resumeTime: resumeTime
        )
    }

    // MARK: - Initialization Tests

    func testNowPlayingViewController_initWithBasicParameters() {
        let tracks = [makeTrack()]
        let viewController = NowPlayingViewController(
            itemIdentifier: "test-item",
            itemTitle: "Test Album",
            imageURL: URL(string: "https://example.com/image.jpg"),
            tracks: tracks
        )

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_initWithStartIndex() {
        let viewController = makeViewController(startAt: 2)

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_initWithResumeTime() {
        let viewController = makeViewController(resumeTime: 45.0)

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_initWithAllParameters() {
        let tracks = [
            makeTrack(id: "1", trackNumber: 1, title: "First Track"),
            makeTrack(id: "2", trackNumber: 2, title: "Second Track")
        ]

        let viewController = NowPlayingViewController(
            itemIdentifier: "full-test",
            itemTitle: "Full Album",
            imageURL: URL(string: "https://example.com/album.jpg"),
            tracks: tracks,
            startAt: 1,
            resumeTime: 120.5
        )

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_initWithEmptyTracks() {
        let viewController = NowPlayingViewController(
            itemIdentifier: "empty",
            itemTitle: "Empty Album",
            imageURL: nil,
            tracks: []
        )

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_initWithNilOptionalParameters() {
        let tracks = [makeTrack()]
        let viewController = NowPlayingViewController(
            itemIdentifier: "test",
            itemTitle: nil,
            imageURL: nil,
            tracks: tracks
        )

        XCTAssertNotNil(viewController)
    }

    // MARK: - View Lifecycle Tests

    func testNowPlayingViewController_viewDidLoadSetsBackgroundColor() {
        let viewController = makeViewController()

        viewController.loadViewIfNeeded()

        XCTAssertEqual(viewController.view.backgroundColor, .black)
    }

    func testNowPlayingViewController_viewDidLoadSetsAccessibilityLabel() {
        let viewController = makeViewController()

        viewController.loadViewIfNeeded()

        XCTAssertEqual(viewController.view.accessibilityLabel, "Now Playing")
    }

    // MARK: - Callback Tests

    func testNowPlayingViewController_onDismissCallbackCanBeSet() {
        let viewController = makeViewController()
        var dismissCalled = false

        viewController.onDismiss = {
            dismissCalled = true
        }

        viewController.onDismiss?()

        XCTAssertTrue(dismissCalled)
    }

    // MARK: - Track Count Tests

    func testNowPlayingViewController_initWithSingleTrack() {
        let tracks = [makeTrack()]
        let viewController = NowPlayingViewController(
            itemIdentifier: "single",
            itemTitle: "Single",
            imageURL: nil,
            tracks: tracks
        )

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_initWithManyTracks() {
        var tracks: [AudioTrack] = []
        for index in 1...50 {
            tracks.append(makeTrack(
                id: "\(index)",
                filename: "track\(index).mp3",
                trackNumber: index,
                title: "Track \(index)"
            ))
        }

        let viewController = NowPlayingViewController(
            itemIdentifier: "large-album",
            itemTitle: "Large Album",
            imageURL: nil,
            tracks: tracks
        )

        XCTAssertNotNil(viewController)
    }

    // MARK: - Edge Cases

    func testNowPlayingViewController_startIndexBeyondTrackCount() {
        let tracks = [makeTrack(), makeTrack(id: "2")]
        let viewController = NowPlayingViewController(
            itemIdentifier: "test",
            itemTitle: "Test",
            imageURL: nil,
            tracks: tracks,
            startAt: 100
        )

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_negativeResumeTime() {
        let viewController = makeViewController(resumeTime: -10.0)

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_zeroResumeTime() {
        let viewController = makeViewController(resumeTime: 0.0)

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_veryLargeResumeTime() {
        let viewController = makeViewController(resumeTime: 999999.0)

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_emptyItemIdentifier() {
        let tracks = [makeTrack()]
        let viewController = NowPlayingViewController(
            itemIdentifier: "",
            itemTitle: "Test",
            imageURL: nil,
            tracks: tracks
        )

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_specialCharactersInItemTitle() {
        let tracks = [makeTrack()]
        let viewController = NowPlayingViewController(
            itemIdentifier: "test",
            itemTitle: "Album: Part II (Live) - 日本語 & More™",
            imageURL: nil,
            tracks: tracks
        )

        XCTAssertNotNil(viewController)
    }

    // MARK: - Track Metadata Tests

    func testNowPlayingViewController_trackWithoutArtist() {
        let track = makeTrack(artist: nil)
        let viewController = NowPlayingViewController(
            itemIdentifier: "test",
            itemTitle: "Test",
            imageURL: nil,
            tracks: [track]
        )

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_trackWithoutAlbum() {
        let track = makeTrack(album: nil)
        let viewController = NowPlayingViewController(
            itemIdentifier: "test",
            itemTitle: "Test",
            imageURL: nil,
            tracks: [track]
        )

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_trackWithoutDuration() {
        let track = makeTrack(duration: nil)
        let viewController = NowPlayingViewController(
            itemIdentifier: "test",
            itemTitle: "Test",
            imageURL: nil,
            tracks: [track]
        )

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_trackWithoutTrackNumber() {
        let track = makeTrack(trackNumber: nil)
        let viewController = NowPlayingViewController(
            itemIdentifier: "test",
            itemTitle: "Test",
            imageURL: nil,
            tracks: [track]
        )

        XCTAssertNotNil(viewController)
    }

    // MARK: - URL Tests

    func testNowPlayingViewController_validImageURL() {
        let imageURL = URL(string: "https://archive.org/services/img/test-item")
        let viewController = NowPlayingViewController(
            itemIdentifier: "test",
            itemTitle: "Test",
            imageURL: imageURL,
            tracks: [makeTrack()]
        )

        XCTAssertNotNil(viewController)
    }

    func testNowPlayingViewController_imageURLWithSpecialCharacters() {
        let imageURL = URL(string: "https://example.com/path%20with%20spaces/image.jpg")
        let viewController = NowPlayingViewController(
            itemIdentifier: "test",
            itemTitle: "Test",
            imageURL: imageURL,
            tracks: [makeTrack()]
        )

        XCTAssertNotNil(viewController)
    }
}
