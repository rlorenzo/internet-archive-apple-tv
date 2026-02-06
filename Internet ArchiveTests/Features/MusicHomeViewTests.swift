//
//  MusicHomeViewTests.swift
//  Internet ArchiveTests
//
//  Tests for MusicHomeView-specific functionality
//  Note: MusicViewModel tests are in MusicViewModelTests.swift
//  Note: Continue listening tests are in PlaybackProgressManagerTests.swift
//

import XCTest
@testable import Internet_Archive

// MARK: - Music Notification Tests

final class MusicNotificationTests: XCTestCase {

    func testPopMusicNavigationNotification_exists() {
        // Verify the notification name is accessible
        let notificationName = Notification.Name.popMusicNavigation
        XCTAssertEqual(notificationName.rawValue, "popMusicNavigation")
    }

    func testPopMusicNavigationNotification_canBePosted() {
        let expectation = XCTestExpectation(description: "Notification received")

        let observer = NotificationCenter.default.addObserver(
            forName: .popMusicNavigation,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        NotificationCenter.default.post(name: .popMusicNavigation, object: nil)

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
}
