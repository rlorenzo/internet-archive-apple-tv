//
//  UITestHelper.swift
//  Internet ArchiveUITests
//
//  Shared helpers for tvOS UI tests to reduce duplication across test files.
//

import XCTest

@MainActor
enum UITestHelper {

    /// Launches the app with standard UI testing configuration.
    static func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = ["USE_MOCK_DATA": "true"]
        app.launch()
        return app
    }

    /// Waits for the app's main content to be ready by checking for the tab bar.
    @discardableResult
    static func waitForAppReady(_ app: XCUIApplication, timeout: TimeInterval = 5) -> Bool {
        app.tabBars.firstMatch.waitForExistence(timeout: timeout)
    }

    /// Navigate to a specific tab by pressing right from Videos (default).
    static func navigateToTab(_ tabIndex: Int, remote: XCUIRemote) {
        for _ in 0..<tabIndex {
            remote.press(.right)
            sleep(1)
        }
        remote.press(.select)
        sleep(2)
    }

    /// Navigate into the first content item from a tab's collection.
    static func enterFirstItem(remote: XCUIRemote) {
        remote.press(.down)
        sleep(1)
        remote.press(.select)
        sleep(3)
    }
}
