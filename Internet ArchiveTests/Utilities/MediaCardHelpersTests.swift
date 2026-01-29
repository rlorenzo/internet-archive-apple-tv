//
//  MediaCardHelpersTests.swift
//  Internet ArchiveTests
//
//  Tests for MediaCardHelpers - media types, accessibility, progress formatting
//

import XCTest
@testable import Internet_Archive

// MARK: - MediaTypeHelpers Tests

final class MediaTypeHelpersTests: XCTestCase {

    // MARK: - Aspect Ratio Tests

    func testAspectRatio_video_returns16by9() {
        XCTAssertEqual(MediaTypeHelpers.videoAspectRatio, 16.0 / 9.0, accuracy: 0.001)
    }

    func testAspectRatio_music_returns1() {
        XCTAssertEqual(MediaTypeHelpers.musicAspectRatio, 1.0, accuracy: 0.001)
    }

    func testAspectRatioFor_movies_returnsVideo() {
        XCTAssertEqual(MediaTypeHelpers.aspectRatio(for: "movies"), 16.0 / 9.0, accuracy: 0.001)
    }

    func testAspectRatioFor_etree_returnsMusic() {
        XCTAssertEqual(MediaTypeHelpers.aspectRatio(for: "etree"), 1.0, accuracy: 0.001)
    }

    func testAspectRatioFor_audio_returnsMusic() {
        XCTAssertEqual(MediaTypeHelpers.aspectRatio(for: "audio"), 1.0, accuracy: 0.001)
    }

    func testAspectRatioFor_nil_returnsVideo() {
        XCTAssertEqual(MediaTypeHelpers.aspectRatio(for: nil), 16.0 / 9.0, accuracy: 0.001)
    }

    func testAspectRatioFor_uppercase_handlesCorrectly() {
        XCTAssertEqual(MediaTypeHelpers.aspectRatio(for: "ETREE"), 1.0, accuracy: 0.001)
        XCTAssertEqual(MediaTypeHelpers.aspectRatio(for: "MOVIES"), 16.0 / 9.0, accuracy: 0.001)
    }

    // MARK: - Placeholder Icon Tests

    func testPlaceholderIcon_video() {
        XCTAssertEqual(MediaTypeHelpers.videoPlaceholderIcon, "film")
    }

    func testPlaceholderIcon_music() {
        XCTAssertEqual(MediaTypeHelpers.musicPlaceholderIcon, "music.note")
    }

    func testPlaceholderIconFor_movies_returnsFilm() {
        XCTAssertEqual(MediaTypeHelpers.placeholderIcon(for: "movies"), "film")
    }

    func testPlaceholderIconFor_etree_returnsMusicNote() {
        XCTAssertEqual(MediaTypeHelpers.placeholderIcon(for: "etree"), "music.note")
    }

    func testPlaceholderIconFor_audio_returnsMusicNote() {
        XCTAssertEqual(MediaTypeHelpers.placeholderIcon(for: "audio"), "music.note")
    }

    func testPlaceholderIconFor_nil_returnsFilm() {
        XCTAssertEqual(MediaTypeHelpers.placeholderIcon(for: nil), "film")
    }

    // MARK: - Type Detection Tests

    func testIsAudioType_etree_returnsTrue() {
        XCTAssertTrue(MediaTypeHelpers.isAudioType("etree"))
    }

    func testIsAudioType_audio_returnsTrue() {
        XCTAssertTrue(MediaTypeHelpers.isAudioType("audio"))
    }

    func testIsAudioType_movies_returnsFalse() {
        XCTAssertFalse(MediaTypeHelpers.isAudioType("movies"))
    }

    func testIsAudioType_nil_returnsFalse() {
        XCTAssertFalse(MediaTypeHelpers.isAudioType(nil))
    }

    func testIsAudioType_caseInsensitive() {
        XCTAssertTrue(MediaTypeHelpers.isAudioType("ETREE"))
        XCTAssertTrue(MediaTypeHelpers.isAudioType("Audio"))
    }

    func testIsVideoType_movies_returnsTrue() {
        XCTAssertTrue(MediaTypeHelpers.isVideoType("movies"))
    }

    func testIsVideoType_video_returnsTrue() {
        XCTAssertTrue(MediaTypeHelpers.isVideoType("video"))
    }

    func testIsVideoType_etree_returnsFalse() {
        XCTAssertFalse(MediaTypeHelpers.isVideoType("etree"))
    }

    func testIsVideoType_nil_returnsFalse() {
        XCTAssertFalse(MediaTypeHelpers.isVideoType(nil))
    }

    func testIsVideoType_caseInsensitive() {
        XCTAssertTrue(MediaTypeHelpers.isVideoType("MOVIES"))
        XCTAssertTrue(MediaTypeHelpers.isVideoType("Video"))
    }
}

// MARK: - AccessibilityHelpers Tests

final class AccessibilityHelpersTests: XCTestCase {

    func testBuildMediaItemLabel_titleOnly() {
        let label = AccessibilityHelpers.buildMediaItemLabel(
            title: "My Movie",
            subtitle: nil,
            isVideo: true,
            progress: nil
        )

        XCTAssertEqual(label, "My Movie, Video")
    }

    func testBuildMediaItemLabel_withSubtitle() {
        let label = AccessibilityHelpers.buildMediaItemLabel(
            title: "My Album",
            subtitle: "Artist Name",
            isVideo: false,
            progress: nil
        )

        XCTAssertEqual(label, "My Album, Artist Name, Music")
    }

    func testBuildMediaItemLabel_withProgress() {
        let label = AccessibilityHelpers.buildMediaItemLabel(
            title: "My Movie",
            subtitle: "Director",
            isVideo: true,
            progress: 0.65
        )

        XCTAssertEqual(label, "My Movie, Director, Video, 65% complete")
    }

    func testBuildMediaItemLabel_zeroProgress_noProgressLabel() {
        let label = AccessibilityHelpers.buildMediaItemLabel(
            title: "My Movie",
            subtitle: nil,
            isVideo: true,
            progress: 0.0
        )

        XCTAssertEqual(label, "My Movie, Video")
        XCTAssertFalse(label.contains("complete"))
    }

    func testBuildMediaItemLabel_fullProgress() {
        let label = AccessibilityHelpers.buildMediaItemLabel(
            title: "My Movie",
            subtitle: nil,
            isVideo: true,
            progress: 1.0
        )

        XCTAssertTrue(label.contains("100% complete"))
    }

    func testBuildMediaItemHint_withProgress() {
        let hint = AccessibilityHelpers.buildMediaItemHint(hasProgress: true)
        XCTAssertEqual(hint, "Double-tap to resume playback")
    }

    func testBuildMediaItemHint_noProgress() {
        let hint = AccessibilityHelpers.buildMediaItemHint(hasProgress: false)
        XCTAssertEqual(hint, "Double-tap to view details")
    }

    func testFormatProgressForAccessibility() {
        XCTAssertEqual(AccessibilityHelpers.formatProgressForAccessibility(0.5), "50% complete")
        XCTAssertEqual(AccessibilityHelpers.formatProgressForAccessibility(0.0), "0% complete")
        XCTAssertEqual(AccessibilityHelpers.formatProgressForAccessibility(1.0), "100% complete")
        XCTAssertEqual(AccessibilityHelpers.formatProgressForAccessibility(0.333), "33% complete")
    }
}

// MARK: - ProgressFormattingHelpers Tests

final class ProgressFormattingHelpersTests: XCTestCase {

    // MARK: - Calculate Progress Tests

    func testCalculateProgress_halfComplete() {
        let progress = ProgressFormattingHelpers.calculateProgress(currentTime: 50, duration: 100)
        XCTAssertEqual(progress, 0.5, accuracy: 0.001)
    }

    func testCalculateProgress_zeroDuration_returnsZero() {
        let progress = ProgressFormattingHelpers.calculateProgress(currentTime: 50, duration: 0)
        XCTAssertEqual(progress, 0.0, accuracy: 0.001)
    }

    func testCalculateProgress_negativeDuration_returnsZero() {
        let progress = ProgressFormattingHelpers.calculateProgress(currentTime: 50, duration: -100)
        XCTAssertEqual(progress, 0.0, accuracy: 0.001)
    }

    func testCalculateProgress_clampedToOne() {
        let progress = ProgressFormattingHelpers.calculateProgress(currentTime: 150, duration: 100)
        XCTAssertEqual(progress, 1.0, accuracy: 0.001)
    }

    func testCalculateProgress_clampedToZero() {
        let progress = ProgressFormattingHelpers.calculateProgress(currentTime: -50, duration: 100)
        XCTAssertEqual(progress, 0.0, accuracy: 0.001)
    }

    // MARK: - Format Time Remaining Tests

    func testFormatTimeRemaining_minutesRemaining() {
        let result = ProgressFormattingHelpers.formatTimeRemaining(
            currentTime: 1800,  // 30 min
            duration: 3600     // 60 min
        )

        XCTAssertEqual(result, "30:00 remaining")
    }

    func testFormatTimeRemaining_hoursRemaining() {
        let result = ProgressFormattingHelpers.formatTimeRemaining(
            currentTime: 0,
            duration: 7200  // 2 hours
        )

        XCTAssertEqual(result, "2:00:00 remaining")
    }

    func testFormatTimeRemaining_secondsOnly() {
        let result = ProgressFormattingHelpers.formatTimeRemaining(
            currentTime: 0,
            duration: 45
        )

        XCTAssertEqual(result, "45 sec remaining")
    }

    func testFormatTimeRemaining_zeroDuration_returnsNil() {
        let result = ProgressFormattingHelpers.formatTimeRemaining(currentTime: 0, duration: 0)
        XCTAssertNil(result)
    }

    func testFormatTimeRemaining_pastDuration_returnsNil() {
        let result = ProgressFormattingHelpers.formatTimeRemaining(currentTime: 100, duration: 50)
        XCTAssertNil(result)
    }

    // MARK: - Format Duration Tests

    func testFormatDuration_seconds() {
        XCTAssertEqual(ProgressFormattingHelpers.formatDuration(45), "45 sec")
    }

    func testFormatDuration_minutes() {
        XCTAssertEqual(ProgressFormattingHelpers.formatDuration(150), "2:30")
    }

    func testFormatDuration_hours() {
        XCTAssertEqual(ProgressFormattingHelpers.formatDuration(5025), "1:23:45")
    }

    func testFormatDuration_zeroSeconds() {
        XCTAssertEqual(ProgressFormattingHelpers.formatDuration(0), "0 sec")
    }

    func testFormatDuration_exactMinute() {
        XCTAssertEqual(ProgressFormattingHelpers.formatDuration(60), "1:00")
    }

    func testFormatDuration_exactHour() {
        XCTAssertEqual(ProgressFormattingHelpers.formatDuration(3600), "1:00:00")
    }

    // MARK: - Completion Detection Tests

    func testIsPlaybackComplete_at95Percent_returnsTrue() {
        XCTAssertTrue(ProgressFormattingHelpers.isPlaybackComplete(currentTime: 95, duration: 100))
    }

    func testIsPlaybackComplete_at100Percent_returnsTrue() {
        XCTAssertTrue(ProgressFormattingHelpers.isPlaybackComplete(currentTime: 100, duration: 100))
    }

    func testIsPlaybackComplete_at94Percent_returnsFalse() {
        XCTAssertFalse(ProgressFormattingHelpers.isPlaybackComplete(currentTime: 94, duration: 100))
    }

    func testIsPlaybackComplete_zeroDuration_returnsFalse() {
        XCTAssertFalse(ProgressFormattingHelpers.isPlaybackComplete(currentTime: 50, duration: 0))
    }

    func testHasSignificantProgress_at50Percent_returnsTrue() {
        XCTAssertTrue(ProgressFormattingHelpers.hasSignificantProgress(currentTime: 50, duration: 100))
    }

    func testHasSignificantProgress_at5Percent_returnsTrue() {
        XCTAssertTrue(ProgressFormattingHelpers.hasSignificantProgress(currentTime: 5, duration: 100))
    }

    func testHasSignificantProgress_at4Percent_returnsFalse() {
        XCTAssertFalse(ProgressFormattingHelpers.hasSignificantProgress(currentTime: 4, duration: 100))
    }

    func testHasSignificantProgress_at95Percent_returnsFalse() {
        XCTAssertFalse(ProgressFormattingHelpers.hasSignificantProgress(currentTime: 95, duration: 100))
    }

    func testHasSignificantProgress_zeroDuration_returnsFalse() {
        XCTAssertFalse(ProgressFormattingHelpers.hasSignificantProgress(currentTime: 50, duration: 0))
    }
}

// MARK: - GridLayoutHelpers Tests

final class GridLayoutHelpersTests: XCTestCase {

    func testConstants_videoWidth() {
        XCTAssertEqual(GridLayoutHelpers.videoMinWidth, 300)
        XCTAssertEqual(GridLayoutHelpers.videoMaxWidth, 400)
    }

    func testConstants_musicWidth() {
        XCTAssertEqual(GridLayoutHelpers.musicMinWidth, 200)
        XCTAssertEqual(GridLayoutHelpers.musicMaxWidth, 280)
    }

    func testConstants_spacing() {
        XCTAssertEqual(GridLayoutHelpers.defaultSpacing, 40)
    }

    func testColumnsCount_fitsMultiple() {
        // 1000px container, 200px min items, 40px spacing
        // (1000 - 40) / (200 + 40) = 960 / 240 = 4
        let columns = GridLayoutHelpers.columnsCount(
            forWidth: 1000,
            minItemWidth: 200,
            spacing: 40
        )

        XCTAssertEqual(columns, 4)
    }

    func testColumnsCount_tooNarrow_returnsOne() {
        let columns = GridLayoutHelpers.columnsCount(
            forWidth: 100,
            minItemWidth: 200,
            spacing: 40
        )

        XCTAssertEqual(columns, 1)
    }

    func testColumnsCount_exactFit() {
        // 680px container, 300px min items, 40px spacing
        // (680 - 40) / (300 + 40) = 640 / 340 = 1.88 -> 1
        let columns = GridLayoutHelpers.columnsCount(
            forWidth: 680,
            minItemWidth: 300,
            spacing: 40
        )

        XCTAssertEqual(columns, 1)
    }

    func testItemWidth_twoColumns() {
        // 2 columns, 500px container, 40px spacing
        // Available: 500 - 40 = 460, per item: 460 / 2 = 230
        let width = GridLayoutHelpers.itemWidth(
            forColumns: 2,
            containerWidth: 500,
            spacing: 40
        )

        XCTAssertEqual(width, 230, accuracy: 0.001)
    }

    func testItemWidth_oneColumn() {
        let width = GridLayoutHelpers.itemWidth(
            forColumns: 1,
            containerWidth: 500,
            spacing: 40
        )

        XCTAssertEqual(width, 500, accuracy: 0.001)
    }

    func testItemWidth_multipleColumns() {
        // 4 columns, 1000px container, 40px spacing
        // Total spacing: 40 * 3 = 120
        // Available: 1000 - 120 = 880, per item: 880 / 4 = 220
        let width = GridLayoutHelpers.itemWidth(
            forColumns: 4,
            containerWidth: 1000,
            spacing: 40
        )

        XCTAssertEqual(width, 220, accuracy: 0.001)
    }
}
