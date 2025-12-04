//
//  FavoriteNCTests.swift
//  Internet ArchiveTests
//
//  Unit tests for FavoriteNC navigation controller
//

import XCTest
@testable import Internet_Archive

@MainActor
final class FavoriteNCTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit() {
        let navController = FavoriteNC()
        XCTAssertNotNil(navController)
    }

    func testIsUINavigationController() {
        let navController: UINavigationController = FavoriteNC()
        XCTAssertNotNil(navController)
    }

    func testInheritsFromBaseNC() {
        let navController = FavoriteNC()
        XCTAssertTrue(navController is BaseNC)
    }

    // MARK: - View Lifecycle Tests

    func testViewDidLoad_doesNotCrash() {
        let navController = FavoriteNC()
        navController.loadViewIfNeeded()
        XCTAssertNotNil(navController.view)
    }

    func testViewDidLoad_setsUpNavigationBar() {
        let navController = FavoriteNC()
        navController.loadViewIfNeeded()
        XCTAssertNotNil(navController.navigationBar)
    }

    // MARK: - Navigation Stack Tests

    func testViewControllers_initiallyEmpty() {
        let navController = FavoriteNC()
        XCTAssertTrue(navController.viewControllers.isEmpty)
    }

    func testGotoFavoriteVC_withoutStoryboard_handlesGracefully() {
        let navController = FavoriteNC()
        // Without storyboard, gotoFavoriteVC should fail gracefully (guard returns)
        navController.gotoFavoriteVC()
        // Should not crash and viewControllers should still be empty
        XCTAssertTrue(navController.viewControllers.isEmpty)
    }

    // MARK: - Multiple Instances Tests

    func testMultipleInstances_areIndependent() {
        let nav1 = FavoriteNC()
        let nav2 = FavoriteNC()
        XCTAssertFalse(nav1 === nav2)
    }

    // MARK: - Navigation Bar Properties

    func testNavigationBar_isVisible() {
        let navController = FavoriteNC()
        navController.loadViewIfNeeded()
        XCTAssertFalse(navController.isNavigationBarHidden)
    }
}
