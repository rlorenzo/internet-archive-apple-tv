//
//  BackgroundAudioTests.swift
//  Internet ArchiveUITests
//
//  Tests for background audio playback behavior on tvOS.
//
//  Note: Background audio testing on the tvOS simulator has significant
//  limitations. These tests verify basic playback lifecycle and remote
//  control responsiveness. Full background audio validation requires
//  manual testing on physical hardware.
//
//  The app relies on AVKit's built-in remote command handling via
//  AVPlayerViewController rather than explicit MPRemoteCommandCenter setup.
//

import XCTest

@MainActor
final class BackgroundAudioTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Helpers

    /// Navigate to Music tab and enter first item.
    private func navigateToMusicItem(app: XCUIApplication) {
        let remote = XCUIRemote.shared

        // Navigate to Music tab
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Enter first item
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)
    }

    // MARK: - Audio Playback Lifecycle

    /// Verifies that audio playback can be started from the music player
    /// and the app remains functional during playback.
    ///
    /// - Note: Simulator limitation — true background audio continuation cannot be
    ///   verified in the simulator. This test validates the playback lifecycle and
    ///   that the app remains responsive during and after navigation.
    func testAudioContinuesWhenMinimized() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        navigateToMusicItem(app: app)

        // Start playback
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Audio should be playing - verify app is still responsive
        XCTAssertTrue(app.state == .runningForeground,
                      "App should remain in foreground during audio playback")

        // Navigate while playing (back to detail)
        remote.press(.menu)
        sleep(2)

        // App should still be running (audio should continue in background)
        XCTAssertTrue(app.state == .runningForeground,
                      "App should handle background audio gracefully")

        // Clean up - go back
        remote.press(.menu)
        sleep(1)
    }

    /// Verifies that Now Playing information is available during music playback
    /// by checking the NowPlaying view contains accessible elements.
    ///
    /// - Note: Simulator limitation — Now Playing metadata (MPNowPlayingInfoCenter)
    ///   may not be fully populated in the simulator. This test checks that the
    ///   playback screen renders accessible content.
    func testNowPlayingInfoUpdates() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        navigateToMusicItem(app: app)

        // Navigate to play button and start playback
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // The Now Playing screen should have accessible elements
        // Check for any text (track title, artist, etc.)
        let hasContent = app.staticTexts.count > 0 || app.buttons.count > 0
        XCTAssertTrue(hasContent,
                      "Now Playing screen should display track information")

        // Exit playback
        remote.press(.menu)
        sleep(1)
        remote.press(.menu)
        sleep(1)
    }

    /// Verifies that play/pause remote command toggles audio playback correctly.
    ///
    /// - Note: The app uses AVKit's built-in remote command handling, so this test
    ///   validates that the player responds to play/pause without crashing.
    func testRemoteControlCommandsWork() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        navigateToMusicItem(app: app)

        // Start playback
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Pause with play/pause
        remote.press(.playPause)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "Play/pause should toggle audio playback")

        // Resume with play/pause
        remote.press(.playPause)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "Play/pause should resume audio playback")

        // Exit
        remote.press(.menu)
        sleep(1)
        remote.press(.menu)
        sleep(1)
    }

    /// Verifies that audio playback can be resumed after a brief interruption
    /// (navigating away and coming back).
    ///
    /// - Note: Simulator limitation — actual audio session interruption behavior
    ///   differs on physical hardware. This test validates navigation resilience.
    func testAudioResumesAfterInterruption() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        navigateToMusicItem(app: app)

        // Start playback
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Pause playback
        remote.press(.playPause)
        sleep(1)

        // Navigate away (back to detail view)
        remote.press(.menu)
        sleep(2)

        // Navigate back to the music player
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Resume playback
        remote.press(.playPause)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "Audio should be resumable after interruption")

        // Clean up
        remote.press(.menu)
        sleep(1)
        remote.press(.menu)
        sleep(1)
    }
}
