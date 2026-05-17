//
//  TouchSmokeTests.swift
//  Internet ArchiveUITests
//
//  Minimal tap-based smoke tests for iOS / iPadOS / visionOS.
//  Cross-platform parity for the tvOS focus-engine tests in this folder.
//

import XCTest

#if !os(tvOS)
@MainActor
final class TouchSmokeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testLaunchAndShowsTabBar() throws {
        let app = UITestHelper.launchAppCrossPlatform()

        // Tab bar appears on iPhone (bottom), iPad / visionOS (bottom or side).
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 10),
            "Tab bar should appear after launch on iOS / iPadOS / visionOS"
        )
    }

    func testTapSearchTab() throws {
        let app = UITestHelper.launchAppCrossPlatform()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            XCTFail("Tab bar did not appear")
            return
        }

        // Search tab is the 3rd of 5 tabs. Use accessibility label first, then fall
        // back to position so the test survives label changes.
        let searchTab = tabBar.buttons["Search"]
        if searchTab.exists {
            searchTab.tap()
        } else {
            let buttons = tabBar.buttons.allElementsBoundByIndex
            guard buttons.count >= 3 else {
                XCTFail("Expected at least 3 tab buttons")
                return
            }
            buttons[2].tap()
        }

        // Allow time for view transition; assert app still running.
        XCTAssertEqual(app.state, .runningForeground)
    }
}
#endif
