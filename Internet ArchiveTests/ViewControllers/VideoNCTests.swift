//
//  VideoNCTests.swift
//  Internet ArchiveTests
//
//  Unit tests for VideoNC navigation controller
//

import XCTest
@testable import Internet_Archive

@MainActor
final class VideoNCTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit() {
        let navController = VideoNC()
        XCTAssertNotNil(navController)
    }

    func testIsUINavigationController() {
        let navController: UINavigationController = VideoNC()
        XCTAssertNotNil(navController)
    }

    func testInheritsFromBaseNC() {
        let navController = VideoNC()
        XCTAssertTrue(navController is BaseNC)
    }

    // MARK: - View Lifecycle Tests

    func testViewDidLoad_doesNotCrash() {
        let navController = VideoNC()
        navController.loadViewIfNeeded()
        XCTAssertNotNil(navController.view)
    }

    func testViewDidLoad_setsUpNavigationBar() {
        let navController = VideoNC()
        navController.loadViewIfNeeded()
        XCTAssertNotNil(navController.navigationBar)
    }

    // MARK: - Navigation Stack Tests

    func testViewControllers_initiallyEmpty() {
        let navController = VideoNC()
        // Before storyboard setup, viewControllers may be empty
        XCTAssertTrue(navController.viewControllers.isEmpty)
    }

    func testGotoVideoVC_withoutStoryboard_handlesGracefully() {
        let navController = VideoNC()
        // Without storyboard, gotoVideoVC should fail gracefully (guard returns)
        navController.gotoVideoVC()
        // Should not crash and viewControllers should still be empty
        XCTAssertTrue(navController.viewControllers.isEmpty)
    }

    // MARK: - Multiple Instances Tests

    func testMultipleInstances_areIndependent() {
        let nav1 = VideoNC()
        let nav2 = VideoNC()
        XCTAssertFalse(nav1 === nav2)
    }

    // MARK: - Navigation Bar Properties

    func testNavigationBar_isVisible() {
        let navController = VideoNC()
        navController.loadViewIfNeeded()
        XCTAssertFalse(navController.isNavigationBarHidden)
    }
}
