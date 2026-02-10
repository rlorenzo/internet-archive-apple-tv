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

import Testing
@testable import Internet_Archive

@Suite("KeychainManager Tests", .serialized)
@MainActor
struct KeychainManagerTests {

    private let testEmail = "test@example.com"
    private let testPassword = "testpassword123"
    private let testUsername = "testuser"

    init() {
        // Clean up before each test
        _ = KeychainManager.shared.deleteAll()
    }

    // MARK: - Singleton Tests

    @Test func sharedInstance() {
        let instance1 = KeychainManager.shared
        let instance2 = KeychainManager.shared
        #expect(instance1 === instance2, "Shared instance should be the same object")
    }

    // MARK: - String Storage Tests

    @Test func saveAndGetString() {
        let result = KeychainManager.shared.save(testEmail, forKey: .userEmail)
        #expect(result, "Save should succeed")

        let retrieved = KeychainManager.shared.getString(forKey: .userEmail)
        #expect(retrieved == testEmail)
    }

    @Test func getNonExistentKey() {
        let retrieved = KeychainManager.shared.getString(forKey: .userEmail)
        #expect(retrieved == nil, "Non-existent key should return nil")
    }

    @Test func overwriteExistingValue() {
        _ = KeychainManager.shared.save("original@test.com", forKey: .userEmail)
        _ = KeychainManager.shared.save("updated@test.com", forKey: .userEmail)

        let retrieved = KeychainManager.shared.getString(forKey: .userEmail)
        #expect(retrieved == "updated@test.com")
    }

    // MARK: - Boolean Storage Tests

    @Test func saveAndGetBoolTrue() {
        let result = KeychainManager.shared.save(true, forKey: .isLoggedIn)
        #expect(result)

        let retrieved = KeychainManager.shared.getBool(forKey: .isLoggedIn)
        #expect(retrieved)
    }

    @Test func saveAndGetBoolFalse() {
        let result = KeychainManager.shared.save(false, forKey: .isLoggedIn)
        #expect(result)

        let retrieved = KeychainManager.shared.getBool(forKey: .isLoggedIn)
        #expect(!retrieved)
    }

    @Test func getBoolNonExistent() {
        let retrieved = KeychainManager.shared.getBool(forKey: .isLoggedIn)
        #expect(!retrieved, "Non-existent bool key should return false")
    }

    // MARK: - Delete Tests

    @Test func deleteExistingValue() {
        _ = KeychainManager.shared.save(testEmail, forKey: .userEmail)
        let deleteResult = KeychainManager.shared.delete(forKey: .userEmail)
        #expect(deleteResult)

        let retrieved = KeychainManager.shared.getString(forKey: .userEmail)
        #expect(retrieved == nil)
    }

    @Test func deleteNonExistentValue() {
        let deleteResult = KeychainManager.shared.delete(forKey: .userEmail)
        #expect(deleteResult, "Deleting non-existent key should succeed (returns errSecItemNotFound)")
    }

    @Test func deleteAll() {
        _ = KeychainManager.shared.save(testEmail, forKey: .userEmail)
        _ = KeychainManager.shared.save(testPassword, forKey: .userPassword)
        _ = KeychainManager.shared.save(testUsername, forKey: .username)

        let deleteResult = KeychainManager.shared.deleteAll()
        #expect(deleteResult)

        #expect(KeychainManager.shared.getString(forKey: .userEmail) == nil)
        #expect(KeychainManager.shared.getString(forKey: .userPassword) == nil)
        #expect(KeychainManager.shared.getString(forKey: .username) == nil)
    }

    // MARK: - User Credentials Tests

    @Test func saveUserCredentials() {
        let result = KeychainManager.shared.saveUserCredentials(
            email: testEmail,
            password: testPassword,
            username: testUsername
        )
        #expect(result)

        #expect(KeychainManager.shared.userEmail == testEmail)
        #expect(KeychainManager.shared.userPassword == testPassword)
        #expect(KeychainManager.shared.username == testUsername)
        #expect(KeychainManager.shared.isLoggedIn)
    }

    @Test func clearUserCredentials() {
        // First save some credentials
        _ = KeychainManager.shared.saveUserCredentials(
            email: testEmail,
            password: testPassword,
            username: testUsername
        )

        // Then clear them
        let clearResult = KeychainManager.shared.clearUserCredentials()
        #expect(clearResult)

        #expect(KeychainManager.shared.userEmail == nil)
        #expect(KeychainManager.shared.userPassword == nil)
        #expect(KeychainManager.shared.username == nil)
        #expect(!KeychainManager.shared.isLoggedIn)
    }

    // MARK: - Computed Properties Tests

    @Test func userEmailProperty() {
        _ = KeychainManager.shared.save(testEmail, forKey: .userEmail)
        #expect(KeychainManager.shared.userEmail == testEmail)
    }

    @Test func userPasswordProperty() {
        _ = KeychainManager.shared.save(testPassword, forKey: .userPassword)
        #expect(KeychainManager.shared.userPassword == testPassword)
    }

    @Test func usernameProperty() {
        _ = KeychainManager.shared.save(testUsername, forKey: .username)
        #expect(KeychainManager.shared.username == testUsername)
    }

    @Test func isLoggedInProperty() {
        #expect(!KeychainManager.shared.isLoggedIn)

        _ = KeychainManager.shared.save(true, forKey: .isLoggedIn)
        #expect(KeychainManager.shared.isLoggedIn)
    }

    // MARK: - KeychainKey Enum Tests

    @Test func keychainKeyRawValues() {
        #expect(KeychainManager.KeychainKey.userEmail.rawValue == "user_email")
        #expect(KeychainManager.KeychainKey.userPassword.rawValue == "user_password")
        #expect(KeychainManager.KeychainKey.username.rawValue == "username")
        #expect(KeychainManager.KeychainKey.isLoggedIn.rawValue == "is_logged_in")
    }
}
