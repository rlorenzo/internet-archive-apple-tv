//
//  NowPlayingViewTests.swift
//  Internet ArchiveTests
//
//  Tests for NowPlayingView - audio format filtering, track organization, resume logic
//

import XCTest
@testable import Internet_Archive

// MARK: - NowPlayingView Initialization Tests

final class NowPlayingViewInitializationTests: XCTestCase {

    func testInit_setsAllProperties() {
        guard let imageURL = URL(string: "https://archive.org/services/img/test-album") else {
            XCTFail("Failed to create URL")
            return
        }

        let tracks = makeTestTracks(count: 3)

        let view = NowPlayingView(
            itemIdentifier: "test-album",
            itemTitle: "Test Album",
            imageURL: imageURL,
            tracks: tracks,
            startAt: 1,
            resumeTime: 45.0,
            onDismiss: nil
        )

        XCTAssertEqual(view.itemIdentifier, "test-album")
        XCTAssertEqual(view.itemTitle, "Test Album")
        XCTAssertEqual(view.imageURL, imageURL)
        XCTAssertEqual(view.tracks.count, 3)
        XCTAssertEqual(view.startAt, 1)
        XCTAssertEqual(view.resumeTime, 45.0)
    }

    func testInit_withDefaultValues() {
        let tracks = makeTestTracks(count: 1)

        let view = NowPlayingView(
            itemIdentifier: "album",
            tracks: tracks
        )

        XCTAssertEqual(view.itemIdentifier, "album")
        XCTAssertNil(view.itemTitle)
        XCTAssertNil(view.imageURL)
        XCTAssertEqual(view.startAt, 0)
        XCTAssertNil(view.resumeTime)
        XCTAssertNil(view.onDismiss)
    }

    // MARK: - Test Helpers

    private func makeTestTracks(count: Int) -> [AudioTrack] {
        guard let streamURL = URL(string: "https://archive.org/download/test/track.mp3") else {
            return []
        }

        return (0..<count).map { index in
            AudioTrack(
                id: "test/track\(index).mp3",
                itemIdentifier: "test",
                filename: "track\(index).mp3",
                trackNumber: index + 1,
                title: "Track \(index + 1)",
                artist: "Artist",
                album: "Album",
                duration: 180,
                streamURL: streamURL,
                thumbnailURL: nil
            )
        }
    }
}

// MARK: - NowPlayingView Coordinator Tests

final class NowPlayingViewCoordinatorTests: XCTestCase {

    func testCoordinator_initWithOnDismiss() {
        var dismissCalled = false
        let coordinator = NowPlayingView.Coordinator(onDismiss: { dismissCalled = true })

        XCTAssertNotNil(coordinator.onDismiss)
        coordinator.onDismiss?()
        XCTAssertTrue(dismissCalled)
    }

    func testCoordinator_initWithNilOnDismiss() {
        let coordinator = NowPlayingView.Coordinator(onDismiss: nil)

        XCTAssertNil(coordinator.onDismiss)
    }

    func testCoordinator_viewControllerInitiallyNil() {
        let coordinator = NowPlayingView.Coordinator(onDismiss: nil)

        XCTAssertNil(coordinator.viewController)
    }
}

// MARK: - NowPlayingView fromMetadata Tests

final class NowPlayingViewFromMetadataTests: XCTestCase {

    func testFromMetadata_filtersAudioFiles() {
        let item = TestFixtures.makeSearchResult(identifier: "test-album", title: "Test Album")
        let files = [
            FileInfo(name: "track01.mp3", source: "original", format: "MP3"),
            FileInfo(name: "track02.mp3", source: "original", format: "MP3"),
            FileInfo(name: "cover.jpg", source: "derivative", format: "JPEG"),
            FileInfo(name: "meta.xml", source: "original", format: "Metadata")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = NowPlayingView.fromMetadata(item: item, metadata: metadata)

        XCTAssertNotNil(view)
        XCTAssertEqual(view?.tracks.count, 2)
    }

    func testFromMetadata_recognizesAllAudioFormats() {
        let item = TestFixtures.makeSearchResult(identifier: "test")
        let files = [
            FileInfo(name: "track1.mp3", source: "original", format: "MP3"),
            FileInfo(name: "track2.flac", source: "original", format: "Flac"),
            FileInfo(name: "track3.ogg", source: "original", format: "Ogg Vorbis"),
            FileInfo(name: "track4.m4a", source: "original", format: "AAC"),
            FileInfo(name: "track5.aac", source: "original", format: "aac"),
            FileInfo(name: "track6.wav", source: "original", format: "WAV")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = NowPlayingView.fromMetadata(item: item, metadata: metadata)

        XCTAssertNotNil(view)
        XCTAssertEqual(view?.tracks.count, 6)
    }

    func testFromMetadata_noAudioFiles_returnsNil() {
        let item = TestFixtures.makeSearchResult(identifier: "test")
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "MPEG4"),
            FileInfo(name: "cover.jpg", source: "derivative", format: "JPEG")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = NowPlayingView.fromMetadata(item: item, metadata: metadata)

        XCTAssertNil(view)
    }

    func testFromMetadata_nilFiles_returnsNil() {
        let item = TestFixtures.makeSearchResult(identifier: "test")
        let metadata = ItemMetadataResponse(files: nil)

        let view = NowPlayingView.fromMetadata(item: item, metadata: metadata)

        XCTAssertNil(view)
    }

    func testFromMetadata_emptyFiles_returnsNil() {
        let item = TestFixtures.makeSearchResult(identifier: "test")
        let metadata = ItemMetadataResponse(files: [])

        let view = NowPlayingView.fromMetadata(item: item, metadata: metadata)

        XCTAssertNil(view)
    }

    func testFromMetadata_setsCorrectThumbnailURL() {
        let item = TestFixtures.makeSearchResult(identifier: "my-album")
        let files = [FileInfo(name: "track.mp3", source: "original", format: "MP3")]
        let metadata = ItemMetadataResponse(files: files)

        let view = NowPlayingView.fromMetadata(item: item, metadata: metadata)

        XCTAssertNotNil(view)
        XCTAssertEqual(view?.imageURL?.absoluteString, "https://archive.org/services/img/my-album")
    }

    func testFromMetadata_withSavedProgress_resumesAtTrackIndex() {
        let item = TestFixtures.makeSearchResult(identifier: "album")
        let files = [
            FileInfo(name: "track01.mp3", source: "original", format: "MP3", track: "1"),
            FileInfo(name: "track02.mp3", source: "original", format: "MP3", track: "2"),
            FileInfo(name: "track03.mp3", source: "original", format: "MP3", track: "3")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let progress = PlaybackProgress(
            itemIdentifier: "album",
            filename: "track02.mp3",
            currentTime: 0,
            duration: 300,
            lastWatchedDate: Date(),
            title: "Album",
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 1,
            trackFilename: "track02.mp3",
            trackCurrentTime: 60.0
        )

        let view = NowPlayingView.fromMetadata(item: item, metadata: metadata, savedProgress: progress)

        XCTAssertNotNil(view)
        XCTAssertEqual(view?.startAt, 1)
        XCTAssertEqual(view?.resumeTime, 60.0)
    }

    func testFromMetadata_withSavedProgress_fallsBackToFilename() {
        let item = TestFixtures.makeSearchResult(identifier: "album")
        let files = [
            FileInfo(name: "track01.mp3", source: "original", format: "MP3"),
            FileInfo(name: "track02.mp3", source: "original", format: "MP3"),
            FileInfo(name: "track03.mp3", source: "original", format: "MP3")
        ]
        let metadata = ItemMetadataResponse(files: files)

        // Progress with trackIndex out of range, but valid filename
        let progress = PlaybackProgress(
            itemIdentifier: "album",
            filename: "track02.mp3",
            currentTime: 0,
            duration: 300,
            lastWatchedDate: Date(),
            title: "Album",
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 100,  // Out of range
            trackFilename: "track02.mp3",
            trackCurrentTime: 30.0
        )

        let view = NowPlayingView.fromMetadata(item: item, metadata: metadata, savedProgress: progress)

        XCTAssertNotNil(view)
        // Should fall back to filename matching and find track02.mp3
        XCTAssertEqual(view?.resumeTime, 30.0)
    }

    func testFromMetadata_caseInsensitiveFormatMatching() {
        let item = TestFixtures.makeSearchResult(identifier: "test")
        let files = [
            FileInfo(name: "TRACK.MP3", source: "original", format: "mp3"),
            FileInfo(name: "audio.FLAC", source: "original", format: "FLAC")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = NowPlayingView.fromMetadata(item: item, metadata: metadata)

        XCTAssertNotNil(view)
        XCTAssertEqual(view?.tracks.count, 2)
    }

    func testFromMetadata_recognizesVbrMp3Format() {
        let item = TestFixtures.makeSearchResult(identifier: "test")
        let files = [
            FileInfo(name: "track.mp3", source: "original", format: "VBR MP3")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = NowPlayingView.fromMetadata(item: item, metadata: metadata)

        XCTAssertNotNil(view)
        XCTAssertEqual(view?.tracks.count, 1)
    }
}
