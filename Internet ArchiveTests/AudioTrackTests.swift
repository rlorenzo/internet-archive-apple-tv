//
//  AudioTrackTests.swift
//  Internet ArchiveTests
//
//  Unit tests for AudioTrack model
//

import XCTest
@testable import Internet_Archive

final class AudioTrackTests: XCTestCase {

    // MARK: - Test Helpers

    /// Creates a URL for testing. Uses a static valid URL format.
    private func testURL(_ path: String = "test.mp3") -> URL {
        guard let url = URL(string: "https://example.com/\(path)") else {
            XCTFail("Failed to create test URL for path: \(path)")
            return URL(fileURLWithPath: "/")
        }
        return url
    }

    // MARK: - Initialization Tests

    func testInitFromFileInfo_withFullMetadata() {
        let fileInfo = FileInfo(
            name: "gd89-12-08d1t02.mp3",
            source: "original",
            format: "MP3",
            length: "312.45",
            track: "02",
            title: "Let The Good Times Roll",
            album: "1989-12-08 - Great Western LA Forum",
            creator: "Grateful Dead"
        )

        let track = AudioTrack(
            fileInfo: fileInfo,
            itemIdentifier: "gd89-12-08",
            itemTitle: "Grateful Dead Live",
            imageURL: URL(string: "https://archive.org/services/img/gd89-12-08")
        )

        XCTAssertEqual(track.id, "gd89-12-08/gd89-12-08d1t02.mp3")
        XCTAssertEqual(track.itemIdentifier, "gd89-12-08")
        XCTAssertEqual(track.filename, "gd89-12-08d1t02.mp3")
        XCTAssertEqual(track.trackNumber, 2)
        XCTAssertEqual(track.title, "Let The Good Times Roll")
        XCTAssertEqual(track.artist, "Grateful Dead")
        XCTAssertEqual(track.album, "1989-12-08 - Great Western LA Forum")
        XCTAssertEqual(track.duration, 312.45)
        XCTAssertEqual(track.streamURL.absoluteString, "https://archive.org/download/gd89-12-08/gd89-12-08d1t02.mp3")
        XCTAssertNotNil(track.thumbnailURL)
    }

    func testInitFromFileInfo_withMinimalMetadata() {
        let fileInfo = FileInfo(
            name: "unknown_song.mp3",
            length: "180.0"
        )

        let track = AudioTrack(
            fileInfo: fileInfo,
            itemIdentifier: "test-item",
            itemTitle: "Test Album",
            imageURL: nil
        )

        XCTAssertEqual(track.title, "unknown_song")  // Derived from filename
        XCTAssertNil(track.trackNumber)
        XCTAssertNil(track.artist)
        XCTAssertEqual(track.album, "Test Album")  // Falls back to item title
        XCTAssertNil(track.thumbnailURL)
    }

    func testInitFromFileInfo_albumFallsBackToItemTitle() {
        let fileInfo = FileInfo(
            name: "track.mp3",
            track: "1",
            title: "My Song"
            // No album field
        )

        let track = AudioTrack(
            fileInfo: fileInfo,
            itemIdentifier: "test",
            itemTitle: "Item Title as Album",
            imageURL: nil
        )

        XCTAssertEqual(track.album, "Item Title as Album")
    }

    // MARK: - Track Number Parsing Tests

    func testTrackNumber_parsesSimpleNumber() {
        let fileInfo = FileInfo(name: "track.mp3", track: "5")
        let track = AudioTrack(fileInfo: fileInfo, itemIdentifier: "test", itemTitle: nil, imageURL: nil)

        XCTAssertEqual(track.trackNumber, 5)
    }

    func testTrackNumber_parsesLeadingZero() {
        let fileInfo = FileInfo(name: "track.mp3", track: "03")
        let track = AudioTrack(fileInfo: fileInfo, itemIdentifier: "test", itemTitle: nil, imageURL: nil)

        XCTAssertEqual(track.trackNumber, 3)
    }

    func testTrackNumber_parsesSlashFormat() {
        let fileInfo = FileInfo(name: "track.mp3", track: "07/12")
        let track = AudioTrack(fileInfo: fileInfo, itemIdentifier: "test", itemTitle: nil, imageURL: nil)

        XCTAssertEqual(track.trackNumber, 7)
    }

    func testTrackNumber_handlesWhitespace() {
        let fileInfo = FileInfo(name: "track.mp3", track: " 10 ")
        let track = AudioTrack(fileInfo: fileInfo, itemIdentifier: "test", itemTitle: nil, imageURL: nil)

        XCTAssertEqual(track.trackNumber, 10)
    }

    func testTrackNumber_nilWhenNoTrack() {
        let fileInfo = FileInfo(name: "track.mp3")
        let track = AudioTrack(fileInfo: fileInfo, itemIdentifier: "test", itemTitle: nil, imageURL: nil)

        XCTAssertNil(track.trackNumber)
    }

    // MARK: - Duration Parsing Tests

    func testDuration_parsesSecondsFormat() throws {
        let fileInfo = FileInfo(name: "track.mp3", length: "312.45")
        let track = AudioTrack(fileInfo: fileInfo, itemIdentifier: "test", itemTitle: nil, imageURL: nil)

        let duration = try XCTUnwrap(track.duration)
        XCTAssertEqual(duration, 312.45, accuracy: 0.01)
    }

    func testDuration_parsesMMSSFormat() {
        let fileInfo = FileInfo(name: "track.mp3", length: "06:21")
        let track = AudioTrack(fileInfo: fileInfo, itemIdentifier: "test", itemTitle: nil, imageURL: nil)

        // 6 minutes 21 seconds = 381 seconds
        XCTAssertEqual(track.duration, 381.0)
    }

    func testDuration_parsesHHMMSSFormat() {
        let fileInfo = FileInfo(name: "track.mp3", length: "1:23:45")
        let track = AudioTrack(fileInfo: fileInfo, itemIdentifier: "test", itemTitle: nil, imageURL: nil)

        // 1 hour 23 minutes 45 seconds = 5025 seconds
        XCTAssertEqual(track.duration, 5025.0)
    }

    func testDuration_nilWhenNoLength() {
        let fileInfo = FileInfo(name: "track.mp3")
        let track = AudioTrack(fileInfo: fileInfo, itemIdentifier: "test", itemTitle: nil, imageURL: nil)

        XCTAssertNil(track.duration)
    }

    // MARK: - Display Title Tests

    func testDisplayTitle_usesTrackTitle() {
        let fileInfo = FileInfo(name: "gd89-d1t02.mp3", title: "Shakedown Street")
        let track = AudioTrack(fileInfo: fileInfo, itemIdentifier: "test", itemTitle: nil, imageURL: nil)

        XCTAssertEqual(track.title, "Shakedown Street")
    }

    func testDisplayTitle_derivesFromFilename() {
        let fileInfo = FileInfo(name: "my_song.mp3")
        let track = AudioTrack(fileInfo: fileInfo, itemIdentifier: "test", itemTitle: nil, imageURL: nil)

        XCTAssertEqual(track.title, "my_song")
    }

    func testDisplayTitle_removesMultipleExtensions() {
        let fileInfo = FileInfo(name: "song.flac")
        // Test that displayTitle is derived correctly (FileInfo strips extensions)
        XCTAssertEqual(fileInfo.displayTitle, "song")
    }

    // MARK: - Formatting Tests

    func testFormattedDuration_shortDuration() {
        let track = AudioTrack(
            id: "test",
            itemIdentifier: "test",
            filename: "test.mp3",
            trackNumber: 1,
            title: "Test",
            artist: nil,
            album: nil,
            duration: 185.0,  // 3:05
            streamURL: testURL(),
            thumbnailURL: nil
        )

        XCTAssertEqual(track.formattedDuration, "3:05")
    }

    func testFormattedDuration_longDuration() {
        let track = AudioTrack(
            id: "test",
            itemIdentifier: "test",
            filename: "test.mp3",
            trackNumber: 1,
            title: "Test",
            artist: nil,
            album: nil,
            duration: 4567.0,  // 1:16:07
            streamURL: testURL(),
            thumbnailURL: nil
        )

        XCTAssertEqual(track.formattedDuration, "1:16:07")
    }

    func testFormattedDuration_nilDuration() {
        let track = AudioTrack(
            id: "test",
            itemIdentifier: "test",
            filename: "test.mp3",
            trackNumber: 1,
            title: "Test",
            artist: nil,
            album: nil,
            duration: nil,
            streamURL: testURL(),
            thumbnailURL: nil
        )

        XCTAssertEqual(track.formattedDuration, "--:--")
    }

    func testFormattedTrackNumber_singleDigit() {
        let track = AudioTrack(
            id: "test",
            itemIdentifier: "test",
            filename: "test.mp3",
            trackNumber: 5,
            title: "Test",
            artist: nil,
            album: nil,
            duration: nil,
            streamURL: testURL(),
            thumbnailURL: nil
        )

        XCTAssertEqual(track.formattedTrackNumber, "05")
    }

    func testFormattedTrackNumber_doubleDigit() {
        let track = AudioTrack(
            id: "test",
            itemIdentifier: "test",
            filename: "test.mp3",
            trackNumber: 12,
            title: "Test",
            artist: nil,
            album: nil,
            duration: nil,
            streamURL: testURL(),
            thumbnailURL: nil
        )

        XCTAssertEqual(track.formattedTrackNumber, "12")
    }

    func testFormattedTrackNumber_nilTrackNumber() {
        let track = AudioTrack(
            id: "test",
            itemIdentifier: "test",
            filename: "test.mp3",
            trackNumber: nil,
            title: "Test",
            artist: nil,
            album: nil,
            duration: nil,
            streamURL: testURL(),
            thumbnailURL: nil
        )

        XCTAssertEqual(track.formattedTrackNumber, "")
    }

    // MARK: - Artist Album Display Tests

    func testArtistAlbumDisplay_bothPresent() {
        let track = AudioTrack(
            id: "test",
            itemIdentifier: "test",
            filename: "test.mp3",
            trackNumber: 1,
            title: "Test",
            artist: "The Band",
            album: "Great Album",
            duration: nil,
            streamURL: testURL(),
            thumbnailURL: nil
        )

        XCTAssertEqual(track.artistAlbumDisplay, "The Band - Great Album")
    }

    func testArtistAlbumDisplay_artistOnly() {
        let track = AudioTrack(
            id: "test",
            itemIdentifier: "test",
            filename: "test.mp3",
            trackNumber: 1,
            title: "Test",
            artist: "The Band",
            album: nil,
            duration: nil,
            streamURL: testURL(),
            thumbnailURL: nil
        )

        XCTAssertEqual(track.artistAlbumDisplay, "The Band")
    }

    func testArtistAlbumDisplay_albumOnly() {
        let track = AudioTrack(
            id: "test",
            itemIdentifier: "test",
            filename: "test.mp3",
            trackNumber: 1,
            title: "Test",
            artist: nil,
            album: "Great Album",
            duration: nil,
            streamURL: testURL(),
            thumbnailURL: nil
        )

        XCTAssertEqual(track.artistAlbumDisplay, "Great Album")
    }

    func testArtistAlbumDisplay_neitherPresent() {
        let track = AudioTrack(
            id: "test",
            itemIdentifier: "test",
            filename: "test.mp3",
            trackNumber: 1,
            title: "Test",
            artist: nil,
            album: nil,
            duration: nil,
            streamURL: testURL(),
            thumbnailURL: nil
        )

        XCTAssertEqual(track.artistAlbumDisplay, "")
    }

    // MARK: - Hashable Tests

    func testEquality_sameId() {
        let track1 = AudioTrack(
            id: "test/song.mp3",
            itemIdentifier: "test",
            filename: "song.mp3",
            trackNumber: 1,
            title: "Song",
            artist: nil,
            album: nil,
            duration: nil,
            streamURL: testURL("song.mp3"),
            thumbnailURL: nil
        )

        let track2 = AudioTrack(
            id: "test/song.mp3",
            itemIdentifier: "test",
            filename: "song.mp3",
            trackNumber: 1,
            title: "Song (different)",  // Different title but same ID
            artist: nil,
            album: nil,
            duration: nil,
            streamURL: testURL("song.mp3"),
            thumbnailURL: nil
        )

        XCTAssertEqual(track1, track2)
    }

    func testEquality_differentId() {
        let track1 = AudioTrack(
            id: "test/song1.mp3",
            itemIdentifier: "test",
            filename: "song1.mp3",
            trackNumber: 1,
            title: "Song",
            artist: nil,
            album: nil,
            duration: nil,
            streamURL: testURL("song1.mp3"),
            thumbnailURL: nil
        )

        let track2 = AudioTrack(
            id: "test/song2.mp3",
            itemIdentifier: "test",
            filename: "song2.mp3",
            trackNumber: 2,
            title: "Song",
            artist: nil,
            album: nil,
            duration: nil,
            streamURL: testURL("song2.mp3"),
            thumbnailURL: nil
        )

        XCTAssertNotEqual(track1, track2)
    }

    // MARK: - Sorting Tests

    func testSortByTrackNumber_sortsCorrectly() {
        let track1 = createTrackWithNumber(3)
        let track2 = createTrackWithNumber(1)
        let track3 = createTrackWithNumber(2)
        let trackNil = createTrackWithNumber(nil)

        let sorted = [track1, track2, track3, trackNil].sorted(by: AudioTrack.sortByTrackNumber)

        XCTAssertEqual(sorted[0].trackNumber, 1)
        XCTAssertEqual(sorted[1].trackNumber, 2)
        XCTAssertEqual(sorted[2].trackNumber, 3)
        XCTAssertNil(sorted[3].trackNumber)  // nil tracks go to end
    }

    private func createTrackWithNumber(_ number: Int?) -> AudioTrack {
        AudioTrack(
            id: "test/\(number ?? 0).mp3",
            itemIdentifier: "test",
            filename: "\(number ?? 0).mp3",
            trackNumber: number,
            title: "Track \(number ?? 0)",
            artist: nil,
            album: nil,
            duration: nil,
            streamURL: testURL("\(number ?? 0).mp3"),
            thumbnailURL: nil
        )
    }
}
