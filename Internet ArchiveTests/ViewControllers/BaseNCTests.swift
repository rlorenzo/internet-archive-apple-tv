//
//  BaseNCTests.swift
//  Internet ArchiveTests
//
//  Unit tests for BaseNC navigation controller
//

import XCTest
@testable import Internet_Archive

@MainActor
final class BaseNCTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit() {
        let navController = BaseNC()
        XCTAssertNotNil(navController)
    }

    func testIsUINavigationController() {
        let navController: UINavigationController = BaseNC()
        XCTAssertNotNil(navController)
    }

    // MARK: - View Lifecycle Tests

    func testViewDidLoad_doesNotCrash() {
        let navController = BaseNC()
        navController.loadViewIfNeeded()
        XCTAssertNotNil(navController.view)
    }

    func testViewDidLoad_setsUpNavigationBar() {
        let navController = BaseNC()
        navController.loadViewIfNeeded()
        XCTAssertNotNil(navController.navigationBar)
    }

    // MARK: - Navigation Bar Properties

    func testNavigationBar_exists() {
        let navController = BaseNC()
        XCTAssertNotNil(navController.navigationBar)
    }

    func testNavigationBar_isVisible() {
        let navController = BaseNC()
        navController.loadViewIfNeeded()
        XCTAssertFalse(navController.isNavigationBarHidden)
    }

    // MARK: - Multiple Instances Tests

    func testMultipleInstances_areIndependent() {
        let nav1 = BaseNC()
        let nav2 = BaseNC()
        XCTAssertFalse(nav1 === nav2)
    }

    // MARK: - Subclass Tests

    func testVideoNC_isSubclass() {
        let videoNC = VideoNC()
        XCTAssertTrue(videoNC is BaseNC)
    }

    func testMusicNC_isSubclass() {
        let musicNC = MusicNC()
        XCTAssertTrue(musicNC is BaseNC)
    }

    func testFavoriteNC_isSubclass() {
        let favoriteNC = FavoriteNC()
        XCTAssertTrue(favoriteNC is BaseNC)
    }
}
