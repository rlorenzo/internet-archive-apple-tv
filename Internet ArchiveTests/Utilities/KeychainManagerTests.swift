//
//  KeychainManagerTests.swift
//  Internet ArchiveTests
//
//  Unit tests for KeychainManager
//
//  Note: Keychain tests may have limitations in CI environments.
//  The keychain is sandboxed and behavior may differ between
//  simulator and device.
//

import XCTest
@testable import Internet_Archive

@MainActor
final class KeychainManagerTests: XCTestCase {

    private let testEmail = "test@example.com"
    private let testPassword = "testpassword123"
    private let testUsername = "testuser"

    override func setUp() {
        super.setUp()
        MainActor.assumeIsolated {
            // Clean up before each test
            _ = KeychainManager.shared.deleteAll()
        }
    }

    override func tearDown() {
        MainActor.assumeIsolated {
            // Clean up after each test
            _ = KeychainManager.shared.deleteAll()
        }
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let instance1 = KeychainManager.shared
        let instance2 = KeychainManager.shared
        XCTAssertTrue(instance1 === instance2, "Shared instance should be the same object")
    }

    // MARK: - String Storage Tests


    func testSaveAndGetString() {
        let result = KeychainManager.shared.save(testEmail, forKey: .userEmail)
        XCTAssertTrue(result, "Save should succeed")

        let retrieved = KeychainManager.shared.getString(forKey: .userEmail)
        XCTAssertEqual(retrieved, testEmail)
    }


    func testGetNonExistentKey() {
        let retrieved = KeychainManager.shared.getString(forKey: .userEmail)
        XCTAssertNil(retrieved, "Non-existent key should return nil")
    }


    func testOverwriteExistingValue() {
        _ = KeychainManager.shared.save("original@test.com", forKey: .userEmail)
        _ = KeychainManager.shared.save("updated@test.com", forKey: .userEmail)

        let retrieved = KeychainManager.shared.getString(forKey: .userEmail)
        XCTAssertEqual(retrieved, "updated@test.com")
    }

    // MARK: - Boolean Storage Tests


    func testSaveAndGetBoolTrue() {
        let result = KeychainManager.shared.save(true, forKey: .isLoggedIn)
        XCTAssertTrue(result)

        let retrieved = KeychainManager.shared.getBool(forKey: .isLoggedIn)
        XCTAssertTrue(retrieved)
    }


    func testSaveAndGetBoolFalse() {
        let result = KeychainManager.shared.save(false, forKey: .isLoggedIn)
        XCTAssertTrue(result)

        let retrieved = KeychainManager.shared.getBool(forKey: .isLoggedIn)
        XCTAssertFalse(retrieved)
    }


    func testGetBoolNonExistent() {
        let retrieved = KeychainManager.shared.getBool(forKey: .isLoggedIn)
        XCTAssertFalse(retrieved, "Non-existent bool key should return false")
    }

    // MARK: - Delete Tests


    func testDeleteExistingValue() {
        _ = KeychainManager.shared.save(testEmail, forKey: .userEmail)
        let deleteResult = KeychainManager.shared.delete(forKey: .userEmail)
        XCTAssertTrue(deleteResult)

        let retrieved = KeychainManager.shared.getString(forKey: .userEmail)
        XCTAssertNil(retrieved)
    }


    func testDeleteNonExistentValue() {
        let deleteResult = KeychainManager.shared.delete(forKey: .userEmail)
        XCTAssertTrue(deleteResult, "Deleting non-existent key should succeed (returns errSecItemNotFound)")
    }


    func testDeleteAll() {
        _ = KeychainManager.shared.save(testEmail, forKey: .userEmail)
        _ = KeychainManager.shared.save(testPassword, forKey: .userPassword)
        _ = KeychainManager.shared.save(testUsername, forKey: .username)

        let deleteResult = KeychainManager.shared.deleteAll()
        XCTAssertTrue(deleteResult)

        XCTAssertNil(KeychainManager.shared.getString(forKey: .userEmail))
        XCTAssertNil(KeychainManager.shared.getString(forKey: .userPassword))
        XCTAssertNil(KeychainManager.shared.getString(forKey: .username))
    }

    // MARK: - User Credentials Tests


    func testSaveUserCredentials() {
        let result = KeychainManager.shared.saveUserCredentials(
            email: testEmail,
            password: testPassword,
            username: testUsername
        )
        XCTAssertTrue(result)

        XCTAssertEqual(KeychainManager.shared.userEmail, testEmail)
        XCTAssertEqual(KeychainManager.shared.userPassword, testPassword)
        XCTAssertEqual(KeychainManager.shared.username, testUsername)
        XCTAssertTrue(KeychainManager.shared.isLoggedIn)
    }


    func testClearUserCredentials() {
        // First save some credentials
        _ = KeychainManager.shared.saveUserCredentials(
            email: testEmail,
            password: testPassword,
            username: testUsername
        )

        // Then clear them
        let clearResult = KeychainManager.shared.clearUserCredentials()
        XCTAssertTrue(clearResult)

        XCTAssertNil(KeychainManager.shared.userEmail)
        XCTAssertNil(KeychainManager.shared.userPassword)
        XCTAssertNil(KeychainManager.shared.username)
        XCTAssertFalse(KeychainManager.shared.isLoggedIn)
    }

    // MARK: - Computed Properties Tests


    func testUserEmailProperty() {
        _ = KeychainManager.shared.save(testEmail, forKey: .userEmail)
        XCTAssertEqual(KeychainManager.shared.userEmail, testEmail)
    }


    func testUserPasswordProperty() {
        _ = KeychainManager.shared.save(testPassword, forKey: .userPassword)
        XCTAssertEqual(KeychainManager.shared.userPassword, testPassword)
    }


    func testUsernameProperty() {
        _ = KeychainManager.shared.save(testUsername, forKey: .username)
        XCTAssertEqual(KeychainManager.shared.username, testUsername)
    }


    func testIsLoggedInProperty() {
        XCTAssertFalse(KeychainManager.shared.isLoggedIn)

        _ = KeychainManager.shared.save(true, forKey: .isLoggedIn)
        XCTAssertTrue(KeychainManager.shared.isLoggedIn)
    }

    // MARK: - KeychainKey Enum Tests

    func testKeychainKeyRawValues() {
        XCTAssertEqual(KeychainManager.KeychainKey.userEmail.rawValue, "user_email")
        XCTAssertEqual(KeychainManager.KeychainKey.userPassword.rawValue, "user_password")
        XCTAssertEqual(KeychainManager.KeychainKey.username.rawValue, "username")
        XCTAssertEqual(KeychainManager.KeychainKey.isLoggedIn.rawValue, "is_logged_in")
    }
}
