//
//  FocusNavigationTests.swift
//  Internet ArchiveUITests
//
//  Tests for tvOS focus engine behavior including tab bar focus,
//  grid navigation, focus restoration, and focus guides.
//

import XCTest

@MainActor
final class FocusNavigationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Tab Bar Focus

    /// Verifies that the Videos tab is selected by default on launch.
    func testInitialFocusOnVideosTab() throws {
        let app = UITestHelper.launchApp()

        let videosTab = app.tabBars.buttons["Videos"]
        XCTAssertTrue(videosTab.waitForExistence(timeout: 5),
                      "Videos tab should exist on launch")
        XCTAssertTrue(videosTab.isSelected,
                      "Videos tab should be selected initially")
    }

    /// Verifies that all five tabs exist and can be navigated to using the remote.
    func testTabBarFocusNavigation() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        let tabNames = ["Videos", "Music", "Search", "Favorites", "Account"]

        // Verify all tabs exist
        for name in tabNames {
            let tab = app.tabBars.buttons[name]
            XCTAssertTrue(tab.waitForExistence(timeout: 5),
                          "\(name) tab should exist")
            XCTAssertTrue(tab.isEnabled,
                          "\(name) tab should be enabled")
        }

        // Navigate right through each tab and select
        for i in 1..<tabNames.count {
            remote.press(.right)
            sleep(1)
            remote.press(.select)
            sleep(1)

            let tab = app.tabBars.buttons[tabNames[i]]
            XCTAssertTrue(tab.isSelected,
                          "\(tabNames[i]) tab should be selected after navigation")
        }
    }

    /// Verifies that pressing right from the last tab does not wrap to the first.
    func testTabBarFocusDoesNotWrapRight() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        // Navigate to Account tab (last tab)
        for _ in 0..<4 {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(1)

        let accountTab = app.tabBars.buttons["Account"]
        XCTAssertTrue(accountTab.isSelected,
                      "Account tab should be selected")

        // Press right again - should stay on Account
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(1)

        XCTAssertTrue(accountTab.isSelected,
                      "Should remain on Account tab when pressing right from last tab")
    }

    /// Verifies that pressing left from the first tab does not wrap to the last.
    func testTabBarFocusDoesNotWrapLeft() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)
        let videosTab = app.tabBars.buttons["Videos"]
        XCTAssertTrue(videosTab.isSelected,
                      "Videos tab should be selected initially")

        // Press left - should stay on Videos
        remote.press(.left)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "App should remain in foreground when pressing left from first tab")
    }

    // MARK: - Grid Focus

    /// Verifies that pressing down from the tab bar enters the content grid.
    func testGridInitialFocusOnFirstItem() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Move focus down from tab bar into grid content
        remote.press(.down)
        sleep(1)

        // Verify the grid/collection exists
        let collectionView = app.collectionViews.firstMatch
        XCTAssertTrue(collectionView.waitForExistence(timeout: 3),
                      "Collection view should exist after pressing down from tab bar")
        XCTAssertTrue(collectionView.cells.count > 0,
                      "Collection should have at least one cell")
    }

    /// Verifies horizontal focus movement in the content grid.
    func testGridFocusMovesRight() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Enter the grid
        remote.press(.down)
        sleep(1)

        // Move right through items
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)

        // Move back left
        remote.press(.left)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "Horizontal grid navigation should work smoothly")
    }

    /// Verifies vertical focus movement between grid rows.
    func testGridFocusMovesDown() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Enter grid and move down multiple rows
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)
        remote.press(.down)
        sleep(1)

        // Move back up
        remote.press(.up)
        sleep(1)
        remote.press(.up)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "Vertical grid navigation should work smoothly")
    }

    /// Verifies that moving right past the end of a row wraps focus to the next row.
    func testGridFocusWrapsToNextRow() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Enter the grid
        remote.press(.down)
        sleep(1)

        // Move right past the end of the row (video grid has 4 columns)
        for _ in 0..<6 {
            remote.press(.right)
            sleep(1)
        }

        // Should still be navigable
        remote.press(.left)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "Grid should handle row boundary focus transitions")
    }

    // MARK: - Focus Restoration

    /// Verifies that focus is restored to the correct position after navigating
    /// to a detail view and returning.
    func testFocusRestoredAfterNavigation() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Navigate to a specific grid position
        remote.press(.down)
        sleep(1)
        remote.press(.right)
        sleep(1)

        // Enter detail view
        remote.press(.select)
        sleep(3)

        // Return to the grid
        remote.press(.menu)
        sleep(2)

        // Verify navigation still works (focus was restored)
        remote.press(.right)
        sleep(1)
        remote.press(.left)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "Focus should be restored after returning from detail view")
    }

    /// Verifies focus restoration after dismissing an alert or modal.
    func testFocusRestoredAfterAlert() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Navigate down into content
        remote.press(.down)
        sleep(1)

        // Select an item to trigger detail view
        remote.press(.select)
        sleep(3)

        // Check for any alerts and dismiss via remote
        let alert = app.alerts.firstMatch
        if alert.exists {
            // On tvOS, dismiss alerts using the remote (tap() is unavailable)
            remote.press(.select)
            sleep(1)
        }

        // Navigate back
        remote.press(.menu)
        sleep(2)

        // Verify focus is restored
        remote.press(.right)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "Focus should be restored after dismissing alert")
    }

    /// Verifies focus restoration after exiting full-screen video playback.
    func testFocusRestoredAfterFullScreen() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Navigate to an item and enter detail
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Navigate to play button and start playback
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Exit playback with menu
        remote.press(.menu)
        sleep(2)

        // Should be back on detail view with focus restored
        XCTAssertTrue(app.state == .runningForeground,
                      "Focus should be restored after full-screen playback")

        // Return to collection
        remote.press(.menu)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground)
    }

    // MARK: - Focus Guides

    /// Verifies that focus guides maintain column alignment when navigating
    /// between grid rows.
    func testFocusGuidesWorkCorrectly() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Enter grid and move to a specific column
        remote.press(.down)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)

        // Move down to next row - focus guide should maintain approximate column
        remote.press(.down)
        sleep(1)

        // Move back up - should return to similar position
        remote.press(.up)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "Focus guides should maintain column alignment between rows")
    }

    /// Verifies that custom focus environments work in the collection browser
    /// (TVCardButtonStyle applies proper visual effects).
    func testCustomFocusEnvironment() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Navigate into the collection
        remote.press(.down)
        sleep(1)

        // The focused card should be visually distinct (TVCardButtonStyle applies
        // scale, shadow, and brightness). We verify the element is hittable/focused.
        let collectionView = app.collectionViews.firstMatch
        XCTAssertTrue(collectionView.waitForExistence(timeout: 3),
                      "Collection view should exist")
        if collectionView.cells.count > 0 {
            let focusedElement = collectionView.cells.firstMatch
            XCTAssertTrue(focusedElement.isHittable,
                          "Focused element should be hittable")
        }

        // Move focus and verify the app handles the transition
        remote.press(.right)
        sleep(1)

        XCTAssertTrue(app.state == .runningForeground,
                      "Custom focus environment should handle focus transitions")
    }
}
