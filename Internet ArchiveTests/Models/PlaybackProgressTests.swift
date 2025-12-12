//
//  PlaybackProgressTests.swift
//  Internet ArchiveTests
//
//  Tests for PlaybackProgress model
//

import XCTest
@testable import Internet_Archive

final class PlaybackProgressTests: XCTestCase {

    // MARK: - Computed Properties Tests

    func testProgressPercentageWithValidDuration() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 30,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertEqual(progress.progressPercentage, 0.3, accuracy: 0.001)
    }

    func testProgressPercentageWithZeroDuration() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 30,
            duration: 0,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertEqual(progress.progressPercentage, 0)
    }

    func testProgressPercentageCapsAtOne() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 150,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertEqual(progress.progressPercentage, 1.0)
    }

    func testIsCompleteAt95Percent() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 95,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertTrue(progress.isComplete)
    }

    func testIsNotCompleteAt94Percent() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 94,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertFalse(progress.isComplete)
    }

    func testTimeRemaining() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 30,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertEqual(progress.timeRemaining, 70, accuracy: 0.001)
    }

    func testTimeRemainingNeverNegative() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 150,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertEqual(progress.timeRemaining, 0)
    }

    // MARK: - Formatted Time Remaining Tests

    func testFormattedTimeRemainingSeconds() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 55,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertEqual(progress.formattedTimeRemaining, "45 sec remaining")
    }

    func testFormattedTimeRemainingMinutes() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 0,
            duration: 720,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertEqual(progress.formattedTimeRemaining, "12 min remaining")
    }

    func testFormattedTimeRemainingHours() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 0,
            duration: 3600,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertEqual(progress.formattedTimeRemaining, "1 hr remaining")
    }

    func testFormattedTimeRemainingHoursAndMinutes() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 0,
            duration: 5400, // 1 hr 30 min
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertEqual(progress.formattedTimeRemaining, "1 hr 30 min remaining")
    }

    // MARK: - Formatted Time Tests

    func testFormattedCurrentTimeMinutesSeconds() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 185, // 3:05
            duration: 600,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertEqual(progress.formattedCurrentTime, "3:05")
    }

    func testFormattedCurrentTimeWithHours() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 5025, // 1:23:45
            duration: 7200,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertEqual(progress.formattedCurrentTime, "1:23:45")
    }

    func testFormattedDuration() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 0,
            duration: 7325, // 2:02:05
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertEqual(progress.formattedDuration, "2:02:05")
    }

    // MARK: - Media Type Tests

    func testIsVideo() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 30,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertTrue(progress.isVideo)
        XCTAssertFalse(progress.isAudio)
    }

    func testIsAudio() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "track.mp3",
            currentTime: 30,
            duration: 300,
            lastWatchedDate: Date(),
            title: "Test Track",
            mediaType: "etree",
            imageURL: nil
        )

        XCTAssertTrue(progress.isAudio)
        XCTAssertFalse(progress.isVideo)
    }

    // MARK: - Thumbnail URL Tests

    func testThumbnailURLWithValidURL() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 30,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: "https://archive.org/services/img/test-item"
        )

        XCTAssertNotNil(progress.thumbnailURL)
        XCTAssertEqual(progress.thumbnailURL?.absoluteString, "https://archive.org/services/img/test-item")
    }

    func testThumbnailURLWithNilURL() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 30,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertNil(progress.thumbnailURL)
    }

    // MARK: - Hashable Tests

    func testEqualityByIdentifierAndFilename() {
        let progress1 = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 30,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        let progress2 = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 60,
            duration: 100,
            lastWatchedDate: Date().addingTimeInterval(3600),
            title: "Different Title",
            mediaType: "movies",
            imageURL: "https://example.com/img"
        )

        // Same identifier and filename = equal
        XCTAssertEqual(progress1, progress2)
    }

    func testInequalityWithDifferentFilename() {
        let progress1 = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video1.mp4",
            currentTime: 30,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        let progress2 = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video2.mp4",
            currentTime: 30,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertNotEqual(progress1, progress2)
    }

    func testInequalityWithDifferentIdentifier() {
        let progress1 = PlaybackProgress(
            itemIdentifier: "item-1",
            filename: "video.mp4",
            currentTime: 30,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        let progress2 = PlaybackProgress(
            itemIdentifier: "item-2",
            filename: "video.mp4",
            currentTime: 30,
            duration: 100,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertNotEqual(progress1, progress2)
    }

    // MARK: - Factory Methods Tests

    func testVideoFactoryMethod() {
        let progress = PlaybackProgress.video(
            identifier: "test-video",
            filename: "movie.mp4",
            currentTime: 120,
            duration: 3600,
            title: "My Movie",
            imageURL: "https://example.com/img"
        )

        XCTAssertEqual(progress.itemIdentifier, "test-video")
        XCTAssertEqual(progress.filename, "movie.mp4")
        XCTAssertEqual(progress.currentTime, 120)
        XCTAssertEqual(progress.duration, 3600)
        XCTAssertEqual(progress.title, "My Movie")
        XCTAssertEqual(progress.mediaType, "movies")
        XCTAssertTrue(progress.isVideo)
        XCTAssertFalse(progress.isAudio)
    }

    func testAudioFactoryMethod() {
        let progress = PlaybackProgress.audio(
            identifier: "test-audio",
            filename: "track.mp3",
            currentTime: 60,
            duration: 300,
            title: "My Track",
            imageURL: nil
        )

        XCTAssertEqual(progress.itemIdentifier, "test-audio")
        XCTAssertEqual(progress.filename, "track.mp3")
        XCTAssertEqual(progress.currentTime, 60)
        XCTAssertEqual(progress.duration, 300)
        XCTAssertEqual(progress.title, "My Track")
        XCTAssertEqual(progress.mediaType, "etree")
        XCTAssertTrue(progress.isAudio)
        XCTAssertFalse(progress.isVideo)
    }

    func testWithUpdatedTime() {
        let original = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 30,
            duration: 100,
            lastWatchedDate: Date().addingTimeInterval(-3600),
            title: "Test Video",
            mediaType: "movies",
            imageURL: "https://example.com/img"
        )

        let updated = original.withUpdatedTime(60)

        XCTAssertEqual(updated.itemIdentifier, original.itemIdentifier)
        XCTAssertEqual(updated.filename, original.filename)
        XCTAssertEqual(updated.currentTime, 60)
        XCTAssertEqual(updated.duration, original.duration)
        XCTAssertEqual(updated.title, original.title)
        XCTAssertEqual(updated.mediaType, original.mediaType)
        XCTAssertEqual(updated.imageURL, original.imageURL)
        // Date should be updated (more recent)
        XCTAssertGreaterThan(updated.lastWatchedDate, original.lastWatchedDate)
    }

    // MARK: - Codable Tests

    func testCodableEncodeAndDecode() throws {
        let original = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 123.456,
            duration: 7200.789,
            lastWatchedDate: Date(timeIntervalSince1970: 1700000000),
            title: "Test Video",
            mediaType: "movies",
            imageURL: "https://archive.org/services/img/test-item"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PlaybackProgress.self, from: data)

        XCTAssertEqual(decoded.itemIdentifier, original.itemIdentifier)
        XCTAssertEqual(decoded.filename, original.filename)
        XCTAssertEqual(decoded.currentTime, original.currentTime, accuracy: 0.001)
        XCTAssertEqual(decoded.duration, original.duration, accuracy: 0.001)
        XCTAssertEqual(decoded.lastWatchedDate, original.lastWatchedDate)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.mediaType, original.mediaType)
        XCTAssertEqual(decoded.imageURL, original.imageURL)
    }

    func testCodableWithNilOptionalFields() throws {
        let original = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 30,
            duration: 100,
            lastWatchedDate: Date(),
            title: nil,
            mediaType: "movies",
            imageURL: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PlaybackProgress.self, from: data)

        XCTAssertNil(decoded.title)
        XCTAssertNil(decoded.imageURL)
    }

    func testCodableArrayEncodeAndDecode() throws {
        let items = [
            PlaybackProgress.video(
                identifier: "video-1",
                filename: "movie.mp4",
                currentTime: 100,
                duration: 3600,
                title: "Movie 1",
                imageURL: nil
            ),
            PlaybackProgress.audio(
                identifier: "audio-1",
                filename: "track.mp3",
                currentTime: 60,
                duration: 300,
                title: "Track 1",
                imageURL: nil
            )
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(items)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode([PlaybackProgress].self, from: data)

        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].itemIdentifier, "video-1")
        XCTAssertEqual(decoded[1].itemIdentifier, "audio-1")
    }
}
