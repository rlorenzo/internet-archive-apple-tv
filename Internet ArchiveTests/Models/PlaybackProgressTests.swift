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

    // MARK: - hasResumableProgress Tests

    func testHasResumableProgress_videoOver10Seconds() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 15,
            duration: 3600,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertTrue(progress.hasResumableProgress)
    }

    func testHasResumableProgress_videoUnder10Seconds() {
        let progress = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video.mp4",
            currentTime: 5,
            duration: 3600,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertFalse(progress.hasResumableProgress)
    }

    func testHasResumableProgress_audioWithTrackTimeOver10Seconds() {
        // Audio album: currentTime is album percentage, trackCurrentTime is actual seconds
        let progress = PlaybackProgress(
            itemIdentifier: "album-123",
            filename: "__album__",
            currentTime: 5.0, // Only 5% through album (would fail old threshold)
            duration: 100.0,
            lastWatchedDate: Date(),
            title: "Artist: Track 1",
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 0,
            trackFilename: "track01.mp3",
            trackCurrentTime: 30.0 // 30 seconds into track (passes new threshold)
        )

        XCTAssertTrue(progress.hasResumableProgress)
    }

    func testHasResumableProgress_audioWithTrackTimeUnder10Seconds() {
        let progress = PlaybackProgress(
            itemIdentifier: "album-123",
            filename: "__album__",
            currentTime: 1.0, // 1% through album
            duration: 100.0,
            lastWatchedDate: Date(),
            title: "Artist: Track 1",
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 0,
            trackFilename: "track01.mp3",
            trackCurrentTime: 5.0 // Only 5 seconds (should not resume)
        )

        XCTAssertFalse(progress.hasResumableProgress)
    }

    func testHasResumableProgress_audioFallsBackToCurrentTime() {
        // Audio without trackCurrentTime falls back to currentTime
        let progress = PlaybackProgress(
            itemIdentifier: "album-123",
            filename: "__album__",
            currentTime: 15.0, // 15% through album
            duration: 100.0,
            lastWatchedDate: Date(),
            title: "Artist: Track 2",
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 1,
            trackFilename: "track02.mp3",
            trackCurrentTime: nil // No track time recorded
        )

        XCTAssertTrue(progress.hasResumableProgress)
    }

    func testHasResumableProgress_audioWithoutTrackTimeFallsBackUnder10() {
        // Audio without trackCurrentTime, and currentTime < 10
        let progress = PlaybackProgress(
            itemIdentifier: "album-123",
            filename: "__album__",
            currentTime: 5.0,
            duration: 100.0,
            lastWatchedDate: Date(),
            title: "Artist: Track 1",
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 0,
            trackFilename: "track01.mp3",
            trackCurrentTime: nil
        )

        XCTAssertFalse(progress.hasResumableProgress)
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
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-video",
            filename: "movie.mp4",
            currentTime: 120,
            duration: 3600,
            title: "My Movie",
            imageURL: "https://example.com/img"
        ))

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
        let progress = PlaybackProgress.audio(MediaProgressInfo(
            identifier: "test-audio",
            filename: "track.mp3",
            currentTime: 60,
            duration: 300,
            title: "My Track"
        ))

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
            PlaybackProgress.video(MediaProgressInfo(
                identifier: "video-1",
                filename: "movie.mp4",
                currentTime: 100,
                duration: 3600,
                title: "Movie 1"
            )),
            PlaybackProgress.audio(MediaProgressInfo(
                identifier: "audio-1",
                filename: "track.mp3",
                currentTime: 60,
                duration: 300,
                title: "Track 1"
            ))
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

// MARK: - MediaProgressInfo Tests

final class MediaProgressInfoTests: XCTestCase {

    func testInit_withAllParameters() {
        let info = MediaProgressInfo(
            identifier: "test-id",
            filename: "video.mp4",
            currentTime: 120.5,
            duration: 3600.0,
            title: "Test Title",
            imageURL: "https://example.com/image.jpg"
        )

        XCTAssertEqual(info.identifier, "test-id")
        XCTAssertEqual(info.filename, "video.mp4")
        XCTAssertEqual(info.currentTime, 120.5)
        XCTAssertEqual(info.duration, 3600.0)
        XCTAssertEqual(info.title, "Test Title")
        XCTAssertEqual(info.imageURL, "https://example.com/image.jpg")
    }

    func testInit_withRequiredParametersOnly() {
        let info = MediaProgressInfo(
            identifier: "test-id",
            filename: "audio.mp3",
            currentTime: 60.0,
            duration: 300.0
        )

        XCTAssertEqual(info.identifier, "test-id")
        XCTAssertEqual(info.filename, "audio.mp3")
        XCTAssertEqual(info.currentTime, 60.0)
        XCTAssertEqual(info.duration, 300.0)
        XCTAssertNil(info.title)
        XCTAssertNil(info.imageURL)
    }

    func testInit_withTitleOnly() {
        let info = MediaProgressInfo(
            identifier: "test-id",
            filename: "video.mp4",
            currentTime: 0,
            duration: 100,
            title: "My Video"
        )

        XCTAssertEqual(info.title, "My Video")
        XCTAssertNil(info.imageURL)
    }

    func testInit_withImageURLOnly() {
        let info = MediaProgressInfo(
            identifier: "test-id",
            filename: "video.mp4",
            currentTime: 0,
            duration: 100,
            imageURL: "https://example.com/thumb.png"
        )

        XCTAssertNil(info.title)
        XCTAssertEqual(info.imageURL, "https://example.com/thumb.png")
    }

    func testVideoFactoryMethod_usesMediaProgressInfo() {
        let info = MediaProgressInfo(
            identifier: "video-123",
            filename: "movie.mp4",
            currentTime: 500,
            duration: 7200,
            title: "Epic Movie",
            imageURL: "https://archive.org/image.jpg"
        )

        let progress = PlaybackProgress.video(info)

        XCTAssertEqual(progress.itemIdentifier, "video-123")
        XCTAssertEqual(progress.filename, "movie.mp4")
        XCTAssertEqual(progress.currentTime, 500)
        XCTAssertEqual(progress.duration, 7200)
        XCTAssertEqual(progress.title, "Epic Movie")
        XCTAssertEqual(progress.imageURL, "https://archive.org/image.jpg")
        XCTAssertEqual(progress.mediaType, "movies")
    }

    func testAudioFactoryMethod_usesMediaProgressInfo() {
        let info = MediaProgressInfo(
            identifier: "audio-456",
            filename: "track.mp3",
            currentTime: 90,
            duration: 240,
            title: "Great Song"
        )

        let progress = PlaybackProgress.audio(info)

        XCTAssertEqual(progress.itemIdentifier, "audio-456")
        XCTAssertEqual(progress.filename, "track.mp3")
        XCTAssertEqual(progress.currentTime, 90)
        XCTAssertEqual(progress.duration, 240)
        XCTAssertEqual(progress.title, "Great Song")
        XCTAssertNil(progress.imageURL)
        XCTAssertEqual(progress.mediaType, "etree")
    }

    func testMediaProgressInfo_mutableProperties() {
        var info = MediaProgressInfo(
            identifier: "test",
            filename: "file.mp4",
            currentTime: 0,
            duration: 100
        )

        // Title and imageURL are mutable (var)
        info.title = "Updated Title"
        info.imageURL = "https://new-url.com/image.jpg"

        XCTAssertEqual(info.title, "Updated Title")
        XCTAssertEqual(info.imageURL, "https://new-url.com/image.jpg")
    }

    func testMediaProgressInfo_withZeroValues() {
        let info = MediaProgressInfo(
            identifier: "empty",
            filename: "empty.mp4",
            currentTime: 0,
            duration: 0
        )

        XCTAssertEqual(info.currentTime, 0)
        XCTAssertEqual(info.duration, 0)
    }

    func testMediaProgressInfo_withLargeValues() {
        let info = MediaProgressInfo(
            identifier: "long-video",
            filename: "documentary.mp4",
            currentTime: 36000, // 10 hours in seconds
            duration: 72000    // 20 hours in seconds
        )

        XCTAssertEqual(info.currentTime, 36000)
        XCTAssertEqual(info.duration, 72000)
    }

    // MARK: - Track-Level Progress Tests (Audio Albums)

    func testMediaProgressInfo_withTrackIndex() {
        let info = MediaProgressInfo(
            identifier: "album-123",
            filename: "__album__",
            currentTime: 25.0, // Album progress percentage
            duration: 100.0,
            title: "Artist: Track 3",
            trackIndex: 2,
            trackFilename: "track03.mp3"
        )

        XCTAssertEqual(info.trackIndex, 2)
        XCTAssertEqual(info.trackFilename, "track03.mp3")
    }

    func testMediaProgressInfo_withTrackCurrentTime() {
        let info = MediaProgressInfo(
            identifier: "album-123",
            filename: "__album__",
            currentTime: 30.0, // Album progress (30% through album)
            duration: 100.0,
            title: "Artist: Track 3",
            trackIndex: 2,
            trackFilename: "track03.mp3",
            trackCurrentTime: 125.5 // Actual position in track
        )

        XCTAssertEqual(info.trackCurrentTime, 125.5)
    }

    func testAudioFactoryMethod_preservesTrackCurrentTime() {
        let info = MediaProgressInfo(
            identifier: "album-456",
            filename: "__album__",
            currentTime: 50.0,
            duration: 100.0,
            title: "Artist: Track 5",
            trackIndex: 4,
            trackFilename: "track05.mp3",
            trackCurrentTime: 200.0
        )

        let progress = PlaybackProgress.audio(info)

        XCTAssertEqual(progress.trackIndex, 4)
        XCTAssertEqual(progress.trackFilename, "track05.mp3")
        XCTAssertEqual(progress.trackCurrentTime, 200.0)
    }

    func testPlaybackProgress_trackCurrentTimeForAudioResume() {
        // Simulates album-level progress where currentTime is album percentage
        // but trackCurrentTime is the actual position for resume
        let progress = PlaybackProgress(
            itemIdentifier: "album-789",
            filename: "__album__",
            currentTime: 40.0, // 40% through 10-track album (track 4)
            duration: 100.0,
            lastWatchedDate: Date(),
            title: "Artist: Track 4",
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 3,
            trackFilename: "track04.mp3",
            trackCurrentTime: 180.5 // 3:00.5 into track 4
        )

        // currentTime is album-level progress (for completion check)
        XCTAssertEqual(progress.currentTime, 40.0)
        XCTAssertFalse(progress.isComplete) // 40% < 95%

        // trackCurrentTime is actual position for resume
        XCTAssertEqual(progress.trackCurrentTime, 180.5)
        XCTAssertEqual(progress.trackIndex, 3)
    }

    func testPlaybackProgress_albumCompletesOnlyOnLastTrack() {
        // Album at 95% means last track is 95% done
        let almostComplete = PlaybackProgress(
            itemIdentifier: "album-final",
            filename: "__album__",
            currentTime: 95.0,
            duration: 100.0,
            lastWatchedDate: Date(),
            title: "Artist: Track 10",
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 9, // Last track (0-indexed)
            trackFilename: "track10.mp3",
            trackCurrentTime: 285.0 // Near end of final track
        )

        XCTAssertTrue(almostComplete.isComplete)
    }

    func testFormattedTimeRemaining_audioAlbumShowsPercentage() {
        // Audio albums use normalized 0-100 scale, should show percentage not fake time
        let progress = PlaybackProgress(
            itemIdentifier: "album-123",
            filename: "__album__",
            currentTime: 50.0, // 50% through album
            duration: 100.0,
            lastWatchedDate: Date(),
            title: "Artist: Track 5",
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 4,
            trackFilename: "track05.mp3",
            trackCurrentTime: 120.0
        )

        XCTAssertEqual(progress.formattedTimeRemaining, "50% remaining")
    }

    func testFormattedTimeRemaining_videoShowsActualTime() {
        // Video uses actual seconds, should show time remaining
        let progress = PlaybackProgress(
            itemIdentifier: "video-123",
            filename: "movie.mp4",
            currentTime: 1800, // 30 minutes in
            duration: 3600, // 1 hour total
            lastWatchedDate: Date(),
            title: "Test Movie",
            mediaType: "movies",
            imageURL: nil
        )

        XCTAssertEqual(progress.formattedTimeRemaining, "30 min remaining")
    }

}
