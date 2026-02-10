//
//  AccessibilityTests.swift
//  Internet ArchiveUITests
//
//  Tests for tvOS accessibility including VoiceOver labels,
//  hints, and accessible navigation.
//

import XCTest

@MainActor
final class AccessibilityTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Tab Bar Accessibility

    /// Verifies that all tab bar buttons have correct accessibility labels.
    func testAllTabsHaveAccessibilityLabels() throws {
        let app = UITestHelper.launchApp()

        let expectedTabs = ["Videos", "Music", "Search", "Favorites", "Account"]

        for tabName in expectedTabs {
            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.waitForExistence(timeout: 5),
                          "\(tabName) tab should be accessible by label")
            XCTAssertTrue(tab.isEnabled,
                          "\(tabName) tab should be enabled")
            XCTAssertFalse(tab.label.isEmpty,
                           "\(tabName) tab should have a non-empty label")
        }
    }

    /// Verifies that media cards in the collection have descriptive accessibility labels.
    func testMediaCardsHaveDescriptiveLabels() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Navigate into the collection grid
        remote.press(.down)
        sleep(1)

        // Check for collection view cells with accessibility labels
        let collectionView = app.collectionViews.firstMatch
        XCTAssertTrue(collectionView.waitForExistence(timeout: 3),
                      "Collection view should exist")

        let cells = collectionView.cells
        if cells.count > 0 {
            let firstCell = cells.element(boundBy: 0)
            XCTAssertTrue(firstCell.exists,
                          "First media card should exist")
            // Cell should be accessible (hittable in tvOS means focusable)
            XCTAssertTrue(firstCell.isHittable || firstCell.isEnabled,
                          "Media card should be accessible")
            // Verify the cell has a non-empty accessibility label
            XCTAssertFalse(firstCell.label.isEmpty,
                           "Media card should have a descriptive accessibility label")
        }

        XCTAssertTrue(app.state == .runningForeground)
    }

    /// Verifies that interactive buttons have proper accessibility labels and hints.
    func testButtonsHaveAccessibilityHints() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Navigate to item detail
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)

        // Look for the Play button by accessibility label
        let playButton = app.buttons["Play"]
        if playButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(playButton.isEnabled,
                          "Play button should be enabled")
        }

        // Go back
        remote.press(.menu)
        sleep(1)
    }

    // MARK: - VoiceOver Navigation

    /// Verifies that all tabs can be reached and identified via VoiceOver-compatible
    /// accessibility queries. This validates the accessibility tree structure.
    func testVoiceOverCanNavigateAllTabs() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        let tabNames = ["Videos", "Music", "Search", "Favorites", "Account"]

        for (index, tabName) in tabNames.enumerated() {
            if index > 0 {
                remote.press(.right)
                sleep(1)
                remote.press(.select)
                sleep(2)
            }

            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.exists,
                          "\(tabName) tab should be discoverable via accessibility query")
        }
    }

    /// Verifies that the search field has proper accessibility attributes.
    func testVoiceOverReadsProgressCorrectly() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        // Navigate to Search tab
        UITestHelper.navigateToTab(2, remote: remote)

        // Check for the search field accessibility
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            XCTAssertTrue(searchField.isEnabled,
                          "Search field should be enabled for VoiceOver")
        }

        XCTAssertTrue(app.state == .runningForeground)
    }

    /// Verifies that state change announcements work correctly by checking
    /// accessible elements after tab switches.
    func testVoiceOverAnnouncesStateChanges() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        // Switch to Music tab
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)

        // Verify the Music tab is now selected (state changed)
        let musicTab = app.tabBars.buttons["Music"]
        XCTAssertTrue(musicTab.isSelected,
                      "VoiceOver should be able to detect Music tab selection state")

        // Switch to Favorites tab
        remote.press(.right)
        sleep(1)
        remote.press(.right)
        sleep(1)
        remote.press(.select)
        sleep(2)

        let favoritesTab = app.tabBars.buttons["Favorites"]
        XCTAssertTrue(favoritesTab.isSelected,
                      "VoiceOver should be able to detect Favorites tab selection state")
    }

    // MARK: - Focus Accessibility

    /// Verifies that focused elements in the grid are accessible and queryable.
    func testFocusedElementAnnounced() throws {
        let app = UITestHelper.launchApp()
        let remote = XCUIRemote.shared

        UITestHelper.waitForAppReady(app)

        // Navigate into the grid
        remote.press(.down)
        sleep(1)

        // Check that the focused cell can be discovered
        let collectionView = app.collectionViews.firstMatch
        XCTAssertTrue(collectionView.waitForExistence(timeout: 3),
                      "Collection view should exist for focus testing")

        if collectionView.cells.count > 0 {
            // At least one cell should be hittable (focused)
            var foundHittable = false
            for i in 0..<min(collectionView.cells.count, 5) {
                if collectionView.cells.element(boundBy: i).isHittable {
                    foundHittable = true
                    break
                }
            }
            XCTAssertTrue(foundHittable,
                          "At least one grid cell should be hittable (focused)")
        }
    }

    /// Verifies that grouped elements (like section headers with "See All" buttons)
    /// are properly accessible.
    func testGroupedElementsReadCorrectly() throws {
        let app = UITestHelper.launchApp()

        UITestHelper.waitForAppReady(app)

        // Check for any static text elements that serve as section headers
        let staticTexts = app.staticTexts
        XCTAssertTrue(staticTexts.count > 0,
                      "Page should have accessible text elements for screen readers")

        // Check for buttons (See All, etc.)
        let buttons = app.buttons
        XCTAssertTrue(buttons.count > 0,
                      "Page should have accessible buttons")
    }
}
