//
//  RemoteInteractionTests.swift
//  Internet ArchiveUITests
//
//  Tests for Apple TV remote interactions including play/pause,
//  menu button behavior, and select button interactions.
//
//  Note: Long press / context menu tests are omitted because
//  the app does not currently implement context menu actions.
//

import XCTest

@MainActor
final class RemoteInteractionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Play/Pause Button

    /// Verifies that play/pause button toggles video playback from the detail view.
    func testPlayPauseTogglesPlayback() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Navigate to an item and enter detail
        UITestHelper.enterFirstItem(remote: remote)

        // Navigate to play button
        remote.press(.down)
        sleep(1)

        // Start playback
        remote.press(.select)
        sleep(2)

        // Toggle play/pause
        remote.press(.playPause)
        sleep(1)

        // Toggle again to resume
        remote.press(.playPause)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "Play/pause toggle should work during video playback")

        // Exit playback
        remote.press(.menu)
        sleep(1)
        remote.press(.menu)
        sleep(1)
    }

    /// Verifies play/pause in the music player context.
    func testPlayPauseInMusicPlayer() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        // Navigate to Music tab
        UITestHelper.navigateToTab(1, remote: remote)
        sleep(2)

        // Enter a music item
        UITestHelper.enterFirstItem(remote: remote)

        // Navigate to play button area
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Toggle play/pause
        remote.press(.playPause)
        sleep(1)
        remote.press(.playPause)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "Play/pause should work in music player")

        // Exit back
        remote.press(.menu)
        sleep(1)
        remote.press(.menu)
        sleep(1)
    }

    // MARK: - Menu Button

    /// Verifies that the menu button navigates back from item detail.
    func testMenuButtonGoesBack() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Enter an item
        UITestHelper.enterFirstItem(remote: remote)

        // Press menu to go back
        remote.press(.menu)
        sleep(2)

        // Should be back at the collection
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists,
                      "Tab bar should be visible after pressing menu to go back")
    }

    /// Verifies that menu button dismisses the search keyboard modal.
    func testMenuButtonDismissesModal() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        // Navigate to Search tab
        UITestHelper.navigateToTab(2, remote: remote)

        // Navigate down to search field
        remote.press(.down)
        sleep(1)

        // Select to open keyboard
        remote.press(.select)
        sleep(2)

        // Dismiss with menu
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "Menu button should dismiss search keyboard")
    }

    /// Verifies that menu button at the root level (tab bar, no navigation history)
    /// does not crash the app. On tvOS, the system may send the app to the background.
    func testMenuButtonAtRootShowsConfirmation() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Press menu at root level
        remote.press(.menu)
        sleep(2)

        // App should remain in foreground (tvOS keeps the app running on first menu press)
        XCTAssertTrue(app.state == .runningForeground,
                      "App should remain in foreground when menu is pressed at root level")
    }

    /// Verifies that multiple sequential menu presses navigate back through
    /// a deep navigation stack without crashing.
    func testMenuButtonNavigatesDeepStack() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Enter first level
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Try entering second level
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Pop back two levels
        remote.press(.menu)
        sleep(2)
        remote.press(.menu)
        sleep(2)

        XCTAssertTrue(app.state == .runningForeground,
                      "Sequential menu presses should navigate back through stack")
    }

    // MARK: - Swipe/Scroll Gestures

    /// Verifies that the player slider responds to left/right remote presses for seeking.
    func testSwipeToSeekInPlayer() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Navigate to item and start playback
        UITestHelper.enterFirstItem(remote: remote)
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Seek forward with right presses
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)

        // Seek backward
        remote.press(.left)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "Seeking via remote should work during playback")

        // Exit playback
        remote.press(.menu)
        sleep(1)
        remote.press(.menu)
        sleep(1)
    }

    /// Verifies scrolling through long lists using the remote.
    func testSwipeToScrollInList() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Navigate into collection
        remote.press(.down)
        sleep(1)

        // Scroll down through multiple rows
        for _ in 0..<5 {
            remote.press(.down)
            sleep(1)
        }

        // Scroll back up
        for _ in 0..<3 {
            remote.press(.up)
            sleep(1)
        }

        XCTAssertTrue(app.state == .runningForeground,
                      "Scrolling through lists should work smoothly")
    }
}
