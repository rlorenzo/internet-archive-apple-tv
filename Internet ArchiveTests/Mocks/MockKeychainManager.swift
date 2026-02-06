//
//  MockKeychainManager.swift
//  Internet ArchiveTests
//
//  In-memory mock for KeychainManager, avoiding real Keychain access in tests.
//

import Foundation
@testable import Internet_Archive

/// In-memory mock that mirrors `KeychainManager`'s public API.
///
/// Uses a simple dictionary instead of the iOS Keychain for fast,
/// deterministic, side-effect-free tests.
///
/// ## Usage Notes
///
/// Since `KeychainManager` does not currently have a protocol,
/// this mock cannot be injected via protocol conformance. It is designed to:
/// 1. Test credential logic without Keychain side effects
/// 2. Serve as a ready-to-use mock when a protocol is introduced
/// 3. Track method calls for verifying interactions
///
/// ## Example Usage
///
/// ```swift
/// let mock = MockKeychainManager()
/// _ = mock.saveUserCredentials(email: "test@example.com", password: "pass", username: "user")
/// #expect(mock.isLoggedIn)
/// #expect(mock.userEmail == "test@example.com")
/// ```
@MainActor
final class MockKeychainManager {

    // MARK: - Call Tracking

    private(set) var saveCalled = false
    private(set) var saveCallCount = 0
    private(set) var getStringCalled = false
    private(set) var deleteCalled = false
    private(set) var deleteAllCalled = false
    private(set) var saveCredentialsCalled = false
    private(set) var clearCredentialsCalled = false

    // MARK: - Mock Configuration

    /// Set to true to make save operations fail
    var shouldFailSave = false

    // MARK: - In-Memory Storage

    private var storage: [String: String] = [:]

    // MARK: - Public Methods (mirrors KeychainManager API)

    func save(_ value: String, forKey key: KeychainManager.KeychainKey) -> Bool {
        saveCalled = true
        saveCallCount += 1

        if shouldFailSave { return false }

        storage[key.rawValue] = value
        return true
    }

    func getString(forKey key: KeychainManager.KeychainKey) -> String? {
        getStringCalled = true
        return storage[key.rawValue]
    }

    func save(_ value: Bool, forKey key: KeychainManager.KeychainKey) -> Bool {
        save(value ? "true" : "false", forKey: key)
    }

    func getBool(forKey key: KeychainManager.KeychainKey) -> Bool {
        getString(forKey: key) == "true"
    }

    @discardableResult
    func delete(forKey key: KeychainManager.KeychainKey) -> Bool {
        deleteCalled = true
        storage.removeValue(forKey: key.rawValue)
        return true
    }

    func deleteAll() -> Bool {
        deleteAllCalled = true
        storage.removeAll()
        return true
    }

    func saveUserCredentials(email: String, password: String, username: String) -> Bool {
        saveCredentialsCalled = true

        if shouldFailSave { return false }

        var success = true
        success = success && save(email, forKey: .userEmail)
        success = success && save(password, forKey: .userPassword)
        success = success && save(username, forKey: .username)
        success = success && save(true, forKey: .isLoggedIn)
        return success
    }

    func clearUserCredentials() -> Bool {
        clearCredentialsCalled = true
        delete(forKey: .userEmail)
        delete(forKey: .userPassword)
        delete(forKey: .username)
        delete(forKey: .isLoggedIn)
        return true
    }

    // MARK: - Convenience Properties (mirrors KeychainManager)

    var userEmail: String? { getString(forKey: .userEmail) }
    var userPassword: String? { getString(forKey: .userPassword) }
    var username: String? { getString(forKey: .username) }
    var isLoggedIn: Bool { getBool(forKey: .isLoggedIn) }

    // MARK: - Test Helpers

    /// Reset all tracking state and stored data
    func reset() {
        storage.removeAll()
        saveCalled = false
        saveCallCount = 0
        getStringCalled = false
        deleteCalled = false
        deleteAllCalled = false
        saveCredentialsCalled = false
        clearCredentialsCalled = false
        shouldFailSave = false
    }
}
