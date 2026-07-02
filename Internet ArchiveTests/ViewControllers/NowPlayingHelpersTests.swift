//
//  NowPlayingHelpersTests.swift
//  Internet ArchiveTests
//
//  Tests for NowPlayingHelpers - time formatting, progress calculation, accessibility
//

import Testing
import Foundation
@testable import Internet_Archive

// MARK: - FormatTime Tests

@Suite("NowPlayingHelpers.formatTime Tests")
struct NowPlayingFormatTimeTests {

    @Test func formatTimeZeroReturnsZeroColon00() {
        #expect(NowPlayingHelpers.formatTime(0) == "0:00")
    }

    @Test func formatTimePositiveSecondsOnly() {
        #expect(NowPlayingHelpers.formatTime(45) == "0:45")
    }

    @Test func formatTimePositiveMinutesAndSeconds() {
        #expect(NowPlayingHelpers.formatTime(125) == "2:05")
    }

    @Test func formatTimePositiveWithHours() {
        #expect(NowPlayingHelpers.formatTime(3661) == "1:01:01")
    }

    @Test func formatTimeExactlyOneHour() {
        #expect(NowPlayingHelpers.formatTime(3600) == "1:00:00")
    }

    @Test func formatTimeNegativeSecondsOnly() {
        #expect(NowPlayingHelpers.formatTime(-45) == "-0:45")
    }

    @Test func formatTimeNegativeMinutesAndSeconds() {
        #expect(NowPlayingHelpers.formatTime(-125) == "-2:05")
    }

    @Test func formatTimeNegativeWithHours() {
        #expect(NowPlayingHelpers.formatTime(-3661) == "-1:01:01")
    }

    @Test func formatTimeLargeValue() {
        // 10 hours, 30 minutes, 15 seconds
        #expect(NowPlayingHelpers.formatTime(37815) == "10:30:15")
    }

    @Test func formatTimeSmallFraction() {
        // Should truncate to integer seconds
        #expect(NowPlayingHelpers.formatTime(0.5) == "0:00")
    }

    @Test func formatTimeFractionalMinutes() {
        // 1 minute 30.7 seconds → 1:30
        #expect(NowPlayingHelpers.formatTime(90.7) == "1:30")
    }

    @Test func formatTimePadsSeconds() {
        // 1 minute, 5 seconds → "1:05" (padded)
        #expect(NowPlayingHelpers.formatTime(65) == "1:05")
    }

    @Test func formatTimePadsMinutesInHoursFormat() {
        // 1 hour, 2 minutes, 3 seconds → "1:02:03"
        #expect(NowPlayingHelpers.formatTime(3723) == "1:02:03")
    }
}

// MARK: - Slider Accessibility Tests

@Suite("NowPlayingHelpers.sliderAccessibilityValue Tests")
struct NowPlayingSliderAccessibilityTests {

    @Test func sliderAccessibilityBasic() {
        let result = NowPlayingHelpers.sliderAccessibilityValue(currentTime: 65, duration: 180)
        #expect(result == "1:05 of 3:00")
    }

    @Test func sliderAccessibilityAtStart() {
        let result = NowPlayingHelpers.sliderAccessibilityValue(currentTime: 0, duration: 300)
        #expect(result == "0:00 of 5:00")
    }

    @Test func sliderAccessibilityWithHours() {
        let result = NowPlayingHelpers.sliderAccessibilityValue(currentTime: 3700, duration: 7200)
        #expect(result == "1:01:40 of 2:00:00")
    }
}

// MARK: - Track Position Text Tests

@Suite("NowPlayingHelpers.trackPositionText Tests")
struct NowPlayingTrackPositionTests {

    @Test func trackPositionFirstOfMany() {
        #expect(NowPlayingHelpers.trackPositionText(currentPosition: 1, trackCount: 12) == "Track 1 of 12")
    }

    @Test func trackPositionLastTrack() {
        #expect(NowPlayingHelpers.trackPositionText(currentPosition: 10, trackCount: 10) == "Track 10 of 10")
    }

    @Test func trackPositionSingleTrack() {
        #expect(NowPlayingHelpers.trackPositionText(currentPosition: 1, trackCount: 1) == "Track 1 of 1")
    }
}

// MARK: - ShouldSaveProgress Tests

@Suite("NowPlayingHelpers.shouldSaveProgress Tests")
struct NowPlayingShouldSaveProgressTests {

    @Test func shouldSaveProgressValidThresholds() {
        #expect(NowPlayingHelpers.shouldSaveProgress(currentTime: 15, trackDuration: 180))
    }

    @Test func shouldNotSaveProgressBelowMinTime() {
        #expect(!NowPlayingHelpers.shouldSaveProgress(currentTime: 5, trackDuration: 180))
    }

    @Test func shouldNotSaveProgressAtExactMinTime() {
        // 10 seconds is the threshold (>= 10)
        #expect(NowPlayingHelpers.shouldSaveProgress(currentTime: 10, trackDuration: 180))
    }

    @Test func shouldNotSaveProgressZeroDuration() {
        #expect(!NowPlayingHelpers.shouldSaveProgress(currentTime: 30, trackDuration: 0))
    }

    @Test func shouldNotSaveProgressNegativeDuration() {
        #expect(!NowPlayingHelpers.shouldSaveProgress(currentTime: 30, trackDuration: -1))
    }
}

// MARK: - Progress Title Tests

@Suite("NowPlayingHelpers.progressTitle Tests")
struct NowPlayingProgressTitleTests {

    @Test func progressTitleWithArtist() {
        let result = NowPlayingHelpers.progressTitle(artist: "The Beatles", itemTitle: "Abbey Road", trackTitle: "Come Together")
        #expect(result == "The Beatles: Come Together")
    }

    @Test func progressTitleWithoutArtistUsesItemTitle() {
        let result = NowPlayingHelpers.progressTitle(artist: nil, itemTitle: "Abbey Road", trackTitle: "Come Together")
        #expect(result == "Abbey Road: Come Together")
    }

    @Test func progressTitleWithoutArtistOrItemTitle() {
        let result = NowPlayingHelpers.progressTitle(artist: nil, itemTitle: nil, trackTitle: "Track 1")
        #expect(result == ": Track 1")
    }

    @Test func progressTitleArtistTakesPrecedence() {
        let result = NowPlayingHelpers.progressTitle(artist: "Artist", itemTitle: "Album", trackTitle: "Song")
        #expect(result == "Artist: Song")
    }
}

// MARK: - Resume Start Index Tests

@Suite("NowPlayingHelpers.resumeStartIndex Tests")
struct NowPlayingResumeStartIndexTests {

    private func makeTracks(filenames: [String]) -> [AudioTrack] {
        filenames.enumerated().compactMap { index, filename in
            guard let streamURL = URL(string: "https://archive.org/download/test/\(filename)") else {
                return nil
            }
            return AudioTrack(
                id: "test/\(filename)",
                itemIdentifier: "test",
                filename: filename,
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

    @Test func prefersFilenameMatchOverIndex() {
        let tracks = makeTracks(filenames: ["a.mp3", "b.mp3", "c.mp3"])

        // Filename points at index 2; the saved index (from a shuffled
        // queue) points elsewhere - filename must win
        let result = NowPlayingHelpers.resumeStartIndex(
            trackFilename: "c.mp3",
            trackIndex: 0,
            tracks: tracks
        )

        #expect(result == 2)
    }

    @Test func fallsBackToIndexWhenFilenameMissing() {
        let tracks = makeTracks(filenames: ["a.mp3", "b.mp3", "c.mp3"])

        let result = NowPlayingHelpers.resumeStartIndex(
            trackFilename: nil,
            trackIndex: 1,
            tracks: tracks
        )

        #expect(result == 1)
    }

    @Test func fallsBackToIndexWhenFilenameNotFound() {
        let tracks = makeTracks(filenames: ["a.mp3", "b.mp3"])

        let result = NowPlayingHelpers.resumeStartIndex(
            trackFilename: "gone.mp3",
            trackIndex: 1,
            tracks: tracks
        )

        #expect(result == 1)
    }

    @Test func returnsNilWhenIndexOutOfRangeAndNoFilenameMatch() {
        let tracks = makeTracks(filenames: ["a.mp3", "b.mp3"])

        let result = NowPlayingHelpers.resumeStartIndex(
            trackFilename: "gone.mp3",
            trackIndex: 100,
            tracks: tracks
        )

        #expect(result == nil)
    }

    @Test func returnsNilForNegativeIndex() {
        let tracks = makeTracks(filenames: ["a.mp3"])

        let result = NowPlayingHelpers.resumeStartIndex(
            trackFilename: nil,
            trackIndex: -1,
            tracks: tracks
        )

        #expect(result == nil)
    }

    @Test func returnsNilWhenNothingSaved() {
        let tracks = makeTracks(filenames: ["a.mp3"])

        let result = NowPlayingHelpers.resumeStartIndex(
            trackFilename: nil,
            trackIndex: nil,
            tracks: tracks
        )

        #expect(result == nil)
    }
}

// MARK: - Album Progress Tests

@Suite("NowPlayingHelpers.calculateAlbumProgress Tests")
struct NowPlayingAlbumProgressTests {

    @Test func albumProgressAtStart() {
        let result = NowPlayingHelpers.calculateAlbumProgress(currentIndex: 0, trackProgressPercentage: 0, trackCount: 10)
        #expect(result.currentTime == 0.0)
        #expect(result.duration == 100.0)
    }

    @Test func albumProgressMidway() {
        let result = NowPlayingHelpers.calculateAlbumProgress(currentIndex: 4, trackProgressPercentage: 0.5, trackCount: 10)
        // (4 + 0.5) / 10 = 0.45 → 45.0
        #expect(result.currentTime == 45.0)
        #expect(result.duration == 100.0)
    }

    @Test func albumProgressAtEnd() {
        let result = NowPlayingHelpers.calculateAlbumProgress(currentIndex: 9, trackProgressPercentage: 1.0, trackCount: 10)
        // (9 + 1.0) / 10 = 1.0 → 100.0
        #expect(result.currentTime == 100.0)
        #expect(result.duration == 100.0)
    }

    @Test func albumProgressSingleTrack() {
        let result = NowPlayingHelpers.calculateAlbumProgress(currentIndex: 0, trackProgressPercentage: 0.5, trackCount: 1)
        // (0 + 0.5) / 1 = 0.5 → 50.0
        #expect(result.currentTime == 50.0)
    }

    @Test func albumProgressZeroTracks() {
        let result = NowPlayingHelpers.calculateAlbumProgress(currentIndex: 0, trackProgressPercentage: 0.5, trackCount: 0)
        #expect(result.currentTime == 0.0)
        #expect(result.duration == 100.0)
    }
}
