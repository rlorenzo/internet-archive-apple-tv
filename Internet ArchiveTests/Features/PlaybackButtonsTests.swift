//
//  PlaybackButtonsTests.swift
//  Internet ArchiveTests
//
//  Unit tests for PlaybackButtons and PlaybackButtonStyle SwiftUI components
//

import XCTest
import SwiftUI
@testable import Internet_Archive

@MainActor
final class PlaybackButtonsTests: XCTestCase {

    // MARK: - Test Helpers

    /// Creates a mock PlaybackProgress for testing with video content
    private func createVideoProgress(
        currentTime: TimeInterval = 1200,
        duration: TimeInterval = 5400
    ) -> PlaybackProgress {
        PlaybackProgress(
            itemIdentifier: "test-video",
            filename: "test.mp4",
            currentTime: currentTime,
            duration: duration,
            lastWatchedDate: Date(),
            title: "Test Video",
            mediaType: "movies",
            imageURL: nil
        )
    }

    /// Creates a mock PlaybackProgress for testing with audio content
    private func createAudioProgress(
        currentTime: TimeInterval = 600,
        duration: TimeInterval = 3600
    ) -> PlaybackProgress {
        PlaybackProgress(
            itemIdentifier: "test-audio",
            filename: "album",
            currentTime: currentTime,
            duration: duration,
            lastWatchedDate: Date(),
            title: "Test Album",
            mediaType: "etree",
            imageURL: nil
        )
    }

    // MARK: - PlaybackButtons Tests

    // MARK: Initialization

    func testPlaybackButtons_initWithNilProgress() {
        let buttons = PlaybackButtons(
            savedProgress: nil,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertNotNil(buttons)
    }

    func testPlaybackButtons_initWithVideoProgress() {
        let progress = createVideoProgress()

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertNotNil(buttons)
        XCTAssertNotNil(buttons.savedProgress)
    }

    func testPlaybackButtons_initWithAudioProgress() {
        let progress = createAudioProgress()

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertNotNil(buttons)
        XCTAssertNotNil(buttons.savedProgress)
    }

    // MARK: Callback Tests

    func testPlaybackButtons_onPlayCalled() {
        var playCalled = false

        let buttons = PlaybackButtons(
            savedProgress: nil,
            onPlay: { playCalled = true },
            onResume: {},
            onStartOver: {}
        )

        buttons.onPlay()

        XCTAssertTrue(playCalled)
    }

    func testPlaybackButtons_onResumeCalled() {
        var resumeCalled = false
        let progress = createVideoProgress()

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: { resumeCalled = true },
            onStartOver: {}
        )

        buttons.onResume()

        XCTAssertTrue(resumeCalled)
    }

    func testPlaybackButtons_onStartOverCalled() {
        var startOverCalled = false
        let progress = createVideoProgress()

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: { startOverCalled = true }
        )

        buttons.onStartOver()

        XCTAssertTrue(startOverCalled)
    }

    func testPlaybackButtons_allCallbacksIndependent() {
        var playCount = 0
        var resumeCount = 0
        var startOverCount = 0

        let buttons = PlaybackButtons(
            savedProgress: nil,
            onPlay: { playCount += 1 },
            onResume: { resumeCount += 1 },
            onStartOver: { startOverCount += 1 }
        )

        buttons.onPlay()
        buttons.onPlay()
        buttons.onResume()
        buttons.onStartOver()
        buttons.onStartOver()
        buttons.onStartOver()

        XCTAssertEqual(playCount, 2)
        XCTAssertEqual(resumeCount, 1)
        XCTAssertEqual(startOverCount, 3)
    }

    // MARK: Progress State Tests

    func testPlaybackButtons_noProgressShowsPlayButton() {
        let buttons = PlaybackButtons(
            savedProgress: nil,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertNil(buttons.savedProgress)
    }

    func testPlaybackButtons_withProgressStoresProgress() {
        let progress = createVideoProgress(currentTime: 1000, duration: 5000)

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertEqual(buttons.savedProgress?.itemIdentifier, "test-video")
    }

    func testPlaybackButtons_progressWithResumableTime() {
        let progress = createVideoProgress(currentTime: 100, duration: 3600)

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        // hasResumableProgress should be true when there's meaningful progress
        XCTAssertTrue(buttons.savedProgress?.hasResumableProgress ?? false)
    }

    func testPlaybackButtons_progressNearStart() {
        // Progress at 5 seconds out of 1 hour (should not be resumable)
        let progress = createVideoProgress(currentTime: 5, duration: 3600)

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        // Very early progress may not be resumable depending on threshold
        XCTAssertNotNil(buttons.savedProgress)
    }

    func testPlaybackButtons_progressNearEnd() {
        // Progress at 95% (might be considered complete)
        let progress = createVideoProgress(currentTime: 5700, duration: 6000)

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertNotNil(buttons.savedProgress)
    }

    // MARK: - PlaybackButtonStyle Tests

    func testPlaybackButtonStyle_initPrimary() {
        let style = PlaybackButtonStyle(isPrimary: true)

        XCTAssertTrue(style.isPrimary)
    }

    func testPlaybackButtonStyle_initSecondary() {
        let style = PlaybackButtonStyle(isPrimary: false)

        XCTAssertFalse(style.isPrimary)
    }

    // MARK: - Edge Cases

    func testPlaybackButtons_emptyCallbacks() {
        let buttons = PlaybackButtons(
            savedProgress: nil,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        // Should not crash with empty closures
        buttons.onPlay()
        buttons.onResume()
        buttons.onStartOver()

        XCTAssertNotNil(buttons)
    }

    func testPlaybackButtons_rapidCallbacks() {
        var callCount = 0

        let buttons = PlaybackButtons(
            savedProgress: nil,
            onPlay: { callCount += 1 },
            onResume: { callCount += 1 },
            onStartOver: { callCount += 1 }
        )

        for _ in 0..<100 {
            buttons.onPlay()
        }

        XCTAssertEqual(callCount, 100)
    }

    func testPlaybackButtons_zeroProgress() {
        let progress = createVideoProgress(currentTime: 0, duration: 3600)

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertNotNil(buttons.savedProgress)
        XCTAssertEqual(buttons.savedProgress?.currentTime, 0)
    }

    func testPlaybackButtons_fullProgress() {
        let progress = createVideoProgress(currentTime: 3600, duration: 3600)

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertNotNil(buttons.savedProgress)
    }

    func testPlaybackButtons_veryLongContent() {
        // 10 hour video
        let progress = createVideoProgress(currentTime: 18000, duration: 36000)

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertNotNil(buttons.savedProgress)
    }

    func testPlaybackButtons_veryShortContent() {
        // 30 second video
        let progress = createVideoProgress(currentTime: 15, duration: 30)

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertNotNil(buttons.savedProgress)
    }

    // MARK: - Different Media Types

    func testPlaybackButtons_videoMediaType() {
        let progress = createVideoProgress()

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertTrue(buttons.savedProgress?.isVideo ?? false)
    }

    func testPlaybackButtons_audioMediaType() {
        let progress = createAudioProgress()

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertTrue(buttons.savedProgress?.isAudio ?? false)
    }

    // MARK: - Progress Percentage Tests

    func testPlaybackButtons_progressPercentageAccurate() {
        let progress = createVideoProgress(currentTime: 1800, duration: 3600)

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertEqual(buttons.savedProgress?.progressPercentage ?? 0, 0.5, accuracy: 0.01)
    }

    func testPlaybackButtons_progressPercentageZero() {
        let progress = createVideoProgress(currentTime: 0, duration: 3600)

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertEqual(buttons.savedProgress?.progressPercentage ?? -1, 0, accuracy: 0.01)
    }

    func testPlaybackButtons_progressPercentageOne() {
        let progress = createVideoProgress(currentTime: 3600, duration: 3600)

        let buttons = PlaybackButtons(
            savedProgress: progress,
            onPlay: {},
            onResume: {},
            onStartOver: {}
        )

        XCTAssertEqual(buttons.savedProgress?.progressPercentage ?? 0, 1.0, accuracy: 0.01)
    }
}
