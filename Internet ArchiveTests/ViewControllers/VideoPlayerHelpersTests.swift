//
//  VideoPlayerHelpersTests.swift
//  Internet ArchiveTests
//
//  Tests for VideoPlayerHelpers - subtitle display names, accessibility, cell data
//

import Testing
import Foundation
@testable import Internet_Archive

// MARK: - Duplicate Display Names Tests

@Suite("VideoPlayerHelpers.hasDuplicateDisplayNames Tests")
struct VideoPlayerDuplicateNamesTests {

    private func makeTrack(
        filename: String = "sub.vtt",
        format: SubtitleFormat = .vtt,
        languageDisplayName: String = "English"
    ) -> SubtitleTrack {
        SubtitleTrack(
            filename: filename,
            format: format,
            languageCode: "en",
            languageDisplayName: languageDisplayName,
            isDefault: false,
            url: URL(string: "https://archive.org/download/test/\(filename)")!
        )
    }

    @Test func noDuplicatesWithUniqueNames() {
        let tracks = [
            makeTrack(languageDisplayName: "English"),
            makeTrack(languageDisplayName: "Spanish"),
            makeTrack(languageDisplayName: "French")
        ]
        #expect(!VideoPlayerHelpers.hasDuplicateDisplayNames(tracks))
    }

    @Test func hasDuplicatesWithSameNames() {
        let tracks = [
            makeTrack(filename: "sub_en.srt", format: .srt, languageDisplayName: "English"),
            makeTrack(filename: "sub_en.vtt", format: .vtt, languageDisplayName: "English")
        ]
        #expect(VideoPlayerHelpers.hasDuplicateDisplayNames(tracks))
    }

    @Test func emptyTracksNoDuplicates() {
        #expect(!VideoPlayerHelpers.hasDuplicateDisplayNames([]))
    }

    @Test func singleTrackNoDuplicates() {
        #expect(!VideoPlayerHelpers.hasDuplicateDisplayNames([makeTrack()]))
    }
}

// MARK: - Subtitle Display Name Tests

@Suite("VideoPlayerHelpers.subtitleDisplayName Tests")
struct VideoPlayerSubtitleDisplayNameTests {

    private func makeTrack(
        filename: String = "sub.vtt",
        format: SubtitleFormat = .vtt,
        languageDisplayName: String = "English"
    ) -> SubtitleTrack {
        SubtitleTrack(
            filename: filename,
            format: format,
            languageCode: "en",
            languageDisplayName: languageDisplayName,
            isDefault: false,
            url: URL(string: "https://archive.org/download/test/\(filename)")!
        )
    }

    @Test func displayNameWithoutDuplicates() {
        let track = makeTrack(languageDisplayName: "English")
        #expect(VideoPlayerHelpers.subtitleDisplayName(track: track, hasDuplicateNames: false) == "English")
    }

    @Test func displayNameWithDuplicatesShowsFormat() {
        let track = makeTrack(format: .srt, languageDisplayName: "English")
        #expect(VideoPlayerHelpers.subtitleDisplayName(track: track, hasDuplicateNames: true) == "English (SRT)")
    }

    @Test func displayNameVTTFormat() {
        let track = makeTrack(format: .vtt, languageDisplayName: "Spanish")
        #expect(VideoPlayerHelpers.subtitleDisplayName(track: track, hasDuplicateNames: true) == "Spanish (VTT)")
    }
}

// MARK: - Subtitle Button Accessibility Tests

@Suite("VideoPlayerHelpers.subtitleButtonAccessibilityValue Tests")
struct VideoPlayerSubtitleAccessibilityTests {

    private func makeTrack(languageDisplayName: String = "English") -> SubtitleTrack {
        SubtitleTrack(
            filename: "sub.vtt",
            format: .vtt,
            languageCode: "en",
            languageDisplayName: languageDisplayName,
            isDefault: false,
            url: URL(string: "https://archive.org/download/test/sub.vtt")!
        )
    }

    @Test func accessibilityValueWhenOff() {
        #expect(VideoPlayerHelpers.subtitleButtonAccessibilityValue(selectedTrack: nil) == "Off")
    }

    @Test func accessibilityValueWhenOn() {
        let track = makeTrack(languageDisplayName: "English")
        #expect(VideoPlayerHelpers.subtitleButtonAccessibilityValue(selectedTrack: track) == "On - English")
    }

    @Test func accessibilityValueWithDifferentLanguage() {
        let track = makeTrack(languageDisplayName: "Japanese")
        #expect(VideoPlayerHelpers.subtitleButtonAccessibilityValue(selectedTrack: track) == "On - Japanese")
    }
}

// MARK: - Subtitle Cell Data Tests

@Suite("VideoPlayerHelpers.subtitleCellData Tests")
struct VideoPlayerSubtitleCellDataTests {

    private func makeTrack(
        filename: String = "sub.vtt",
        format: SubtitleFormat = .vtt,
        languageDisplayName: String = "English"
    ) -> SubtitleTrack {
        SubtitleTrack(
            filename: filename,
            format: format,
            languageCode: "en",
            languageDisplayName: languageDisplayName,
            isDefault: false,
            url: URL(string: "https://archive.org/download/test/\(filename)")!
        )
    }

    @Test func offRowWhenNoSelection() {
        let result = VideoPlayerHelpers.subtitleCellData(index: 0, tracks: [], selectedTrack: nil)
        #expect(result.title == "Off")
        #expect(result.subtitle == nil)
        #expect(result.isSelected == true)
        #expect(result.accessibilityHint == "Turn off subtitles")
    }

    @Test func offRowWhenTrackSelected() {
        let track = makeTrack()
        let result = VideoPlayerHelpers.subtitleCellData(index: 0, tracks: [track], selectedTrack: track)
        #expect(result.title == "Off")
        #expect(result.isSelected == false)
    }

    @Test func trackRowWithVTTFormat() {
        let track = makeTrack(format: .vtt, languageDisplayName: "English")
        let result = VideoPlayerHelpers.subtitleCellData(index: 1, tracks: [track], selectedTrack: nil)
        #expect(result.title == "English")
        #expect(result.subtitle == "WebVTT")
        #expect(result.isSelected == false)
        #expect(result.accessibilityHint == "Select English subtitles")
    }

    @Test func trackRowWithSRTFormat() {
        let track = makeTrack(filename: "sub.srt", format: .srt, languageDisplayName: "Spanish")
        let result = VideoPlayerHelpers.subtitleCellData(index: 1, tracks: [track], selectedTrack: nil)
        #expect(result.title == "Spanish")
        #expect(result.subtitle == "SRT")
    }

    @Test func trackRowWhenSelected() {
        let track = makeTrack()
        let result = VideoPlayerHelpers.subtitleCellData(index: 1, tracks: [track], selectedTrack: track)
        #expect(result.isSelected == true)
    }

    @Test func invalidIndexReturnsFallback() {
        let result = VideoPlayerHelpers.subtitleCellData(index: 5, tracks: [], selectedTrack: nil)
        #expect(result.title == "Unknown")
    }
}

// MARK: - Container Height Tests

@Suite("VideoPlayerHelpers.containerHeight Tests")
struct VideoPlayerContainerHeightTests {

    @Test func containerHeightWithNoTracks() {
        // (0 + 1) * 66 + 80 = 146
        #expect(VideoPlayerHelpers.containerHeight(trackCount: 0) == 146)
    }

    @Test func containerHeightWithOneTracks() {
        // (1 + 1) * 66 + 80 = 212
        #expect(VideoPlayerHelpers.containerHeight(trackCount: 1) == 212)
    }

    @Test func containerHeightWithFiveTracks() {
        // (5 + 1) * 66 + 80 = 476
        #expect(VideoPlayerHelpers.containerHeight(trackCount: 5) == 476)
    }

    @Test func containerHeightCapsAt500() {
        // (20 + 1) * 66 + 80 = 1466, capped at 500
        #expect(VideoPlayerHelpers.containerHeight(trackCount: 20) == 500)
    }

    @Test func containerHeightExactlyCap() {
        // Need (count + 1) * 66 + 80 >= 500
        // (6 + 1) * 66 + 80 = 542 → capped at 500
        #expect(VideoPlayerHelpers.containerHeight(trackCount: 6) == 500)
    }
}
