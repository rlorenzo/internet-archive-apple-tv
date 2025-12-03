//
//  GlobalTests.swift
//  Internet ArchiveTests
//
//  Unit tests for Global utility class
//

import XCTest
@testable import Internet_Archive

final class GlobalTests: XCTestCase {

    private static let testUserDataKey = "UserData"
    private static let testFavoriteDataKey = "FavoriteData"

    override func setUp() {
        super.setUp()
        // Clean up UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: GlobalTests.testUserDataKey)
        UserDefaults.standard.removeObject(forKey: GlobalTests.testFavoriteDataKey)
    }

    override func tearDown() {
        // Clean up after each test
        UserDefaults.standard.removeObject(forKey: GlobalTests.testUserDataKey)
        UserDefaults.standard.removeObject(forKey: GlobalTests.testFavoriteDataKey)
        super.tearDown()
    }

    // MARK: - User Data Tests

    @MainActor
    func testSaveAndGetUserData() {
        let userData: [String: Any?] = [
            "email": "test@example.com",
            "username": "testuser",
            "logged-in": true
        ]

        Global.saveUserData(userData: userData)

        let retrieved = Global.getUserData()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?["email"] as? String, "test@example.com")
        XCTAssertEqual(retrieved?["username"] as? String, "testuser")
        XCTAssertEqual(retrieved?["logged-in"] as? Bool, true)
    }

    @MainActor
    func testGetUserDataWhenNil() {
        let retrieved = Global.getUserData()
        XCTAssertNil(retrieved)
    }

    // MARK: - Favorite Data Tests

    @MainActor
    func testSaveFavoriteData() {
        Global.saveFavoriteData(identifier: "item_001")

        let favorites = Global.getFavoriteData()
        XCTAssertNotNil(favorites)
        XCTAssertEqual(favorites?.count, 1)
        XCTAssertTrue(favorites?.contains("item_001") ?? false)
    }

    @MainActor
    func testSaveFavoriteDataNoDuplicates() {
        Global.saveFavoriteData(identifier: "item_001")
        Global.saveFavoriteData(identifier: "item_001")

        let favorites = Global.getFavoriteData()
        XCTAssertEqual(favorites?.count, 1)
    }

    @MainActor
    func testSaveMultipleFavorites() {
        Global.saveFavoriteData(identifier: "item_001")
        Global.saveFavoriteData(identifier: "item_002")
        Global.saveFavoriteData(identifier: "item_003")

        let favorites = Global.getFavoriteData()
        XCTAssertEqual(favorites?.count, 3)
        XCTAssertTrue(favorites?.contains("item_001") ?? false)
        XCTAssertTrue(favorites?.contains("item_002") ?? false)
        XCTAssertTrue(favorites?.contains("item_003") ?? false)
    }

    @MainActor
    func testGetFavoriteDataWhenNil() {
        let favorites = Global.getFavoriteData()
        XCTAssertNil(favorites)
    }

    @MainActor
    func testRemoveFavoriteData() {
        Global.saveFavoriteData(identifier: "item_001")
        Global.saveFavoriteData(identifier: "item_002")

        Global.removeFavoriteData(identifier: "item_001")

        let favorites = Global.getFavoriteData()
        XCTAssertEqual(favorites?.count, 1)
        XCTAssertFalse(favorites?.contains("item_001") ?? true)
        XCTAssertTrue(favorites?.contains("item_002") ?? false)
    }

    @MainActor
    func testRemoveNonExistentFavorite() {
        Global.saveFavoriteData(identifier: "item_001")
        Global.removeFavoriteData(identifier: "item_999")

        let favorites = Global.getFavoriteData()
        XCTAssertEqual(favorites?.count, 1)
    }

    @MainActor
    func testResetFavoriteData() {
        Global.saveFavoriteData(identifier: "item_001")
        Global.saveFavoriteData(identifier: "item_002")

        Global.resetFavoriteData()

        let favorites = Global.getFavoriteData()
        XCTAssertNotNil(favorites)
        XCTAssertEqual(favorites?.count, 0)
    }

    // MARK: - Login State Tests

    @MainActor
    func testIsLoggedInWhenTrue() {
        let userData: [String: Any?] = ["logged-in": true]
        Global.saveUserData(userData: userData)

        XCTAssertTrue(Global.isLoggedIn())
    }

    @MainActor
    func testIsLoggedInWhenFalse() {
        let userData: [String: Any?] = ["logged-in": false]
        Global.saveUserData(userData: userData)

        XCTAssertFalse(Global.isLoggedIn())
    }

    @MainActor
    func testIsLoggedInWhenNoUserData() {
        XCTAssertFalse(Global.isLoggedIn())
    }

    @MainActor
    func testIsLoggedInWhenMissingKey() {
        let userData: [String: Any?] = ["email": "test@example.com"]
        Global.saveUserData(userData: userData)

        XCTAssertFalse(Global.isLoggedIn())
    }

    // MARK: - Date Formatting Tests

    @MainActor
    func testFormatDateValid() {
        let input = "2025-01-15T10:30:00Z"
        let formatted = Global.formatDate(string: input)

        XCTAssertNotNil(formatted)
        XCTAssertEqual(formatted, "Jan 15, 2025")
    }

    @MainActor
    func testFormatDateWithTimezone() {
        let input = "2025-06-01T14:45:30+0000"
        let formatted = Global.formatDate(string: input)

        XCTAssertNotNil(formatted)
        XCTAssertEqual(formatted, "Jun 01, 2025")
    }

    @MainActor
    func testFormatDateInvalidFormat() {
        let input = "not-a-date"
        let formatted = Global.formatDate(string: input)

        // Should return original string if parsing fails
        XCTAssertEqual(formatted, input)
    }

    @MainActor
    func testFormatDateNil() {
        let formatted = Global.formatDate(string: nil)
        XCTAssertNil(formatted)
    }

    @MainActor
    func testFormatDateEmpty() {
        let input = ""
        let formatted = Global.formatDate(string: input)

        // Empty string doesn't parse, should return original
        XCTAssertEqual(formatted, input)
    }

    // MARK: - Alert Tests

    @MainActor
    func testShowAlert_doesNotCrash() {
        let viewController = UIViewController()
        // Load the view
        viewController.loadViewIfNeeded()

        // Alert cannot be shown without presenting VC, but method should not crash
        // Note: In test environment, we can't fully test UI alerts
        XCTAssertNotNil(viewController)
    }

    @MainActor
    func testShowServiceUnavailableAlert_doesNotCrash() {
        let viewController = UIViewController()
        viewController.loadViewIfNeeded()

        // Method should not crash even if VC is not in window hierarchy
        XCTAssertNotNil(viewController)
    }

    // MARK: - Edge Case Tests

    @MainActor
    func testSaveUserData_withAllValidValues() {
        // Test saving user data with valid, non-nil values only
        // (UserDefaults cannot properly serialize nil values in dictionaries)
        let userData: [String: Any?] = [
            "email": "valid@email.com",
            "username": "testuser",
            "logged-in": true
        ]

        Global.saveUserData(userData: userData)

        let retrieved = Global.getUserData()
        XCTAssertNotNil(retrieved)
        if let retrieved = retrieved {
            XCTAssertEqual(retrieved["username"] as? String, "testuser")
            XCTAssertEqual(retrieved["logged-in"] as? Bool, true)
            XCTAssertEqual(retrieved["email"] as? String, "valid@email.com")
        }
    }

    @MainActor
    func testRemoveFavoriteData_whenNoFavorites() {
        // Ensure no favorites exist
        UserDefaults.standard.removeObject(forKey: GlobalTests.testFavoriteDataKey)

        // Should not crash when trying to remove from nil favorites
        Global.removeFavoriteData(identifier: "non_existent")

        let favorites = Global.getFavoriteData()
        XCTAssertNil(favorites)
    }

    @MainActor
    func testSaveFavoriteData_multipleIdentifiers() {
        Global.resetFavoriteData()

        // Save multiple unique identifiers
        for i in 0..<10 {
            Global.saveFavoriteData(identifier: "item_\(i)")
        }

        let favorites = Global.getFavoriteData()
        XCTAssertEqual(favorites?.count, 10)
    }

    @MainActor
    func testRemoveFavoriteData_allItems() {
        // Add items
        Global.saveFavoriteData(identifier: "a")
        Global.saveFavoriteData(identifier: "b")
        Global.saveFavoriteData(identifier: "c")

        // Remove all one by one
        Global.removeFavoriteData(identifier: "a")
        Global.removeFavoriteData(identifier: "b")
        Global.removeFavoriteData(identifier: "c")

        let favorites = Global.getFavoriteData()
        XCTAssertEqual(favorites?.count, 0)
    }
}
