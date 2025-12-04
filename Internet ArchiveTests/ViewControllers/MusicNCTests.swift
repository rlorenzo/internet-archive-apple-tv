//
//  MusicNCTests.swift
//  Internet ArchiveTests
//
//  Unit tests for MusicNC navigation controller
//

import XCTest
@testable import Internet_Archive

@MainActor
final class MusicNCTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit() {
        let navController = MusicNC()
        XCTAssertNotNil(navController)
    }

    func testIsUINavigationController() {
        let navController: UINavigationController = MusicNC()
        XCTAssertNotNil(navController)
    }

    func testInheritsFromBaseNC() {
        let navController = MusicNC()
        XCTAssertTrue(navController is BaseNC)
    }

    // MARK: - View Lifecycle Tests

    func testViewDidLoad_doesNotCrash() {
        let navController = MusicNC()
        navController.loadViewIfNeeded()
        XCTAssertNotNil(navController.view)
    }

    func testViewDidLoad_setsUpNavigationBar() {
        let navController = MusicNC()
        navController.loadViewIfNeeded()
        XCTAssertNotNil(navController.navigationBar)
    }

    // MARK: - Navigation Stack Tests

    func testViewControllers_initiallyEmpty() {
        let navController = MusicNC()
        XCTAssertTrue(navController.viewControllers.isEmpty)
    }

    func testGotoMusicVC_withoutStoryboard_handlesGracefully() {
        let navController = MusicNC()
        // Without storyboard, gotoMusicVC should fail gracefully (guard returns)
        navController.gotoMusicVC()
        // Should not crash and viewControllers should still be empty
        XCTAssertTrue(navController.viewControllers.isEmpty)
    }

    // MARK: - Multiple Instances Tests

    func testMultipleInstances_areIndependent() {
        let nav1 = MusicNC()
        let nav2 = MusicNC()
        XCTAssertFalse(nav1 === nav2)
    }

    // MARK: - Navigation Bar Properties

    func testNavigationBar_isVisible() {
        let navController = MusicNC()
        navController.loadViewIfNeeded()
        XCTAssertFalse(navController.isNavigationBarHidden)
    }
}
