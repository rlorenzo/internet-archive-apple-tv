//
//  Internet_ArchiveUITestsLaunchTests.swift
//  Internet ArchiveUITests
//
//  Created by Rex Victor Lorenzo on 11/21/25.
//  Copyright © 2025 mac-admin. All rights reserved.
//

import XCTest

final class Internet_ArchiveUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        // Disabled to prevent flaky parallel test runs in CI
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
