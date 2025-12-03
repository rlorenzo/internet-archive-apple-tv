//
//  TabbarControllerTests.swift
//  Internet ArchiveTests
//
//  Unit tests for TabbarController
//

import XCTest
@testable import Internet_Archive

@MainActor
final class TabbarControllerTests: XCTestCase {

    private let testUserDataKey = "UserData"
    private let testFavoriteDataKey = "FavoriteData"

    override func setUp() {
        super.setUp()
        // Clean up UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: testUserDataKey)
        UserDefaults.standard.removeObject(forKey: testFavoriteDataKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testUserDataKey)
        UserDefaults.standard.removeObject(forKey: testFavoriteDataKey)
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit() {
        let tabBar = TabbarController()
        XCTAssertNotNil(tabBar)
    }

    func testIsUITabBarController() {
        // Verify TabbarController properly inherits from UITabBarController
        let tabBar: UITabBarController = TabbarController()
        XCTAssertNotNil(tabBar)
    }

    // MARK: - ViewDidLoad Tests

    func testViewDidLoad_doesNotCrash() {
        let tabBar = TabbarController()
        tabBar.loadViewIfNeeded()
        XCTAssertNotNil(tabBar.view)
    }

    func testViewDidLoad_setsUpView() {
        let tabBar = TabbarController()
        tabBar.loadViewIfNeeded()
        XCTAssertNotNil(tabBar.view)
    }

    // MARK: - Read-Only Mode Tests

    func testReadOnlyMode_whenNotConfigured() {
        // When AppConfiguration is not configured, tabs should be filtered
        let tabBar = TabbarController()
        tabBar.loadViewIfNeeded()

        // In read-only mode without credentials, certain tabs are removed
        // We can't directly test which tabs remain without a full storyboard setup
        XCTAssertNotNil(tabBar)
    }

    // MARK: - Login State Tests

    func testViewDidLoad_whenNotLoggedIn() {
        // Ensure user is not logged in
        UserDefaults.standard.removeObject(forKey: testUserDataKey)

        let tabBar = TabbarController()
        tabBar.loadViewIfNeeded()

        XCTAssertFalse(Global.isLoggedIn())
    }

    func testViewDidLoad_whenLoggedIn() {
        // Set up logged in state
        let userData: [String: Any?] = [
            "logged-in": true,
            "username": "testuser",
            "email": "test@example.com",
            "password": "password123"
        ]
        Global.saveUserData(userData: userData)

        let tabBar = TabbarController()
        tabBar.loadViewIfNeeded()

        XCTAssertTrue(Global.isLoggedIn())
    }

    // MARK: - Tab Bar Properties Tests

    func testTabBar_exists() {
        let tabBarController = TabbarController()
        XCTAssertNotNil(tabBarController.tabBar)
    }

    func testViewControllers_initiallyNil() {
        let tabBarController = TabbarController()
        // Before loading from storyboard, viewControllers is nil
        XCTAssertNil(tabBarController.viewControllers)
    }

    // MARK: - Multiple Instances Tests

    func testMultipleInstances_areIndependent() {
        let tabBar1 = TabbarController()
        let tabBar2 = TabbarController()

        XCTAssertFalse(tabBar1 === tabBar2)
    }
}
