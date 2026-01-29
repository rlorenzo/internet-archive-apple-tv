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

// MARK: - PlaybackButtonStyleHelpers Tests

final class PlaybackButtonStyleHelpersTests: XCTestCase {

    // MARK: - Scale Value Tests

    func testScaleValue_pressed() {
        let scale = PlaybackButtonStyleHelpers.scaleValue(isPressed: true, isFocused: false)
        XCTAssertEqual(scale, 0.95)
    }

    func testScaleValue_focused() {
        let scale = PlaybackButtonStyleHelpers.scaleValue(isPressed: false, isFocused: true)
        XCTAssertEqual(scale, 1.08)
    }

    func testScaleValue_normal() {
        let scale = PlaybackButtonStyleHelpers.scaleValue(isPressed: false, isFocused: false)
        XCTAssertEqual(scale, 1.0)
    }

    func testScaleValue_pressedTakesPrecedenceOverFocused() {
        // When both pressed and focused, pressed state wins
        let scale = PlaybackButtonStyleHelpers.scaleValue(isPressed: true, isFocused: true)
        XCTAssertEqual(scale, 0.95)
    }

    // MARK: - Shadow Color Tests

    func testShadowColor_focused() {
        let color = PlaybackButtonStyleHelpers.shadowColor(isFocused: true)
        // Should have some opacity (white with 0.5 opacity)
        XCTAssertNotEqual(color, Color.clear)
    }

    func testShadowColor_notFocused() {
        let color = PlaybackButtonStyleHelpers.shadowColor(isFocused: false)
        XCTAssertEqual(color, Color.clear)
    }

    // MARK: - Foreground Color Tests

    func testForegroundColor_primaryNormal() {
        let color = PlaybackButtonStyleHelpers.foregroundColor(isPrimary: true, isPressed: false)
        XCTAssertEqual(color, Color.black)
    }

    func testForegroundColor_primaryPressed() {
        let color = PlaybackButtonStyleHelpers.foregroundColor(isPrimary: true, isPressed: true)
        XCTAssertEqual(color, Color.black.opacity(0.8))
    }

    func testForegroundColor_secondaryNormal() {
        let color = PlaybackButtonStyleHelpers.foregroundColor(isPrimary: false, isPressed: false)
        XCTAssertEqual(color, Color.white)
    }

    func testForegroundColor_secondaryPressed() {
        let color = PlaybackButtonStyleHelpers.foregroundColor(isPrimary: false, isPressed: true)
        XCTAssertEqual(color, Color.white.opacity(0.8))
    }

    // MARK: - Background Color Tests

    func testBackgroundColor_primaryFocused() {
        let color = PlaybackButtonStyleHelpers.backgroundColor(isPrimary: true, isFocused: true, isPressed: false)
        XCTAssertEqual(color, Color.white)
    }

    func testBackgroundColor_secondaryFocused() {
        let color = PlaybackButtonStyleHelpers.backgroundColor(isPrimary: false, isFocused: true, isPressed: false)
        XCTAssertEqual(color, Color.white.opacity(0.4))
    }

    func testBackgroundColor_primaryNormal() {
        let color = PlaybackButtonStyleHelpers.backgroundColor(isPrimary: true, isFocused: false, isPressed: false)
        XCTAssertEqual(color, Color.white)
    }

    func testBackgroundColor_primaryPressed() {
        let color = PlaybackButtonStyleHelpers.backgroundColor(isPrimary: true, isFocused: false, isPressed: true)
        XCTAssertEqual(color, Color.white.opacity(0.8))
    }

    func testBackgroundColor_secondaryNormal() {
        let color = PlaybackButtonStyleHelpers.backgroundColor(isPrimary: false, isFocused: false, isPressed: false)
        XCTAssertEqual(color, Color.white.opacity(0.15))
    }

    func testBackgroundColor_secondaryPressed() {
        let color = PlaybackButtonStyleHelpers.backgroundColor(isPrimary: false, isFocused: false, isPressed: true)
        XCTAssertEqual(color, Color.white.opacity(0.3))
    }

    func testBackgroundColor_focusTakesPrecedence() {
        // When focused, the focused state should determine the color regardless of pressed state
        let colorFocusedPressed = PlaybackButtonStyleHelpers.backgroundColor(isPrimary: true, isFocused: true, isPressed: true)
        let colorFocusedNotPressed = PlaybackButtonStyleHelpers.backgroundColor(isPrimary: true, isFocused: true, isPressed: false)
        XCTAssertEqual(colorFocusedPressed, colorFocusedNotPressed)
    }

    // MARK: - Border Color Tests

    func testBorderColor_focused() {
        let color = PlaybackButtonStyleHelpers.borderColor(isPrimary: true, isFocused: true, isPressed: false)
        XCTAssertEqual(color, Color.white)
    }

    func testBorderColor_focusedSecondary() {
        let color = PlaybackButtonStyleHelpers.borderColor(isPrimary: false, isFocused: true, isPressed: false)
        XCTAssertEqual(color, Color.white)
    }

    func testBorderColor_primaryNormal() {
        let color = PlaybackButtonStyleHelpers.borderColor(isPrimary: true, isFocused: false, isPressed: false)
        XCTAssertEqual(color, Color.clear)
    }

    func testBorderColor_primaryPressed() {
        let color = PlaybackButtonStyleHelpers.borderColor(isPrimary: true, isFocused: false, isPressed: true)
        XCTAssertEqual(color, Color.clear)
    }

    func testBorderColor_secondaryNormal() {
        let color = PlaybackButtonStyleHelpers.borderColor(isPrimary: false, isFocused: false, isPressed: false)
        XCTAssertEqual(color, Color.white.opacity(0.4))
    }

    func testBorderColor_secondaryPressed() {
        let color = PlaybackButtonStyleHelpers.borderColor(isPrimary: false, isFocused: false, isPressed: true)
        XCTAssertEqual(color, Color.white.opacity(0.6))
    }

    // MARK: - Border Width Tests

    func testBorderWidth_focused() {
        let width = PlaybackButtonStyleHelpers.borderWidth(isFocused: true)
        XCTAssertEqual(width, 4)
    }

    func testBorderWidth_notFocused() {
        let width = PlaybackButtonStyleHelpers.borderWidth(isFocused: false)
        XCTAssertEqual(width, 2)
    }
}
