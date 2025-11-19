//
//  KeychainManager.swift
//  Internet Archive
//
//  Created for Sprint 7: Security & Configuration
//  Secure storage for user credentials and sensitive data
//

import Foundation
import Security

/// Secure keychain storage for sensitive user data
class KeychainManager {

    // MARK: - Singleton

    static let shared = KeychainManager()

    private init() {}

    // MARK: - Service Identifier

    private let service = "com.internetarchive.appletv"

    // MARK: - Keys

    enum KeychainKey: String {
        case userEmail = "user_email"
        case userPassword = "user_password"
        case username = "username"
        case isLoggedIn = "is_logged_in"
    }

    // MARK: - Public Methods

    /// Save a string value to the keychain
    func save(_ value: String, forKey key: KeychainKey) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }

        // Delete any existing item
        delete(forKey: key)

        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Retrieve a string value from the keychain
    func getString(forKey key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    /// Save a boolean value to the keychain
    func save(_ value: Bool, forKey key: KeychainKey) -> Bool {
        save(value ? "true" : "false", forKey: key)
    }

    /// Retrieve a boolean value from the keychain
    func getBool(forKey key: KeychainKey) -> Bool {
        getString(forKey: key) == "true"
    }

    /// Delete a value from the keychain
    @discardableResult
    func delete(forKey key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Delete all keychain items for this service
    func deleteAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Convenience Methods for User Data

    /// Save complete user data securely
    func saveUserCredentials(email: String, password: String, username: String) -> Bool {
        var success = true
        success = success && save(email, forKey: .userEmail)
        success = success && save(password, forKey: .userPassword)
        success = success && save(username, forKey: .username)
        success = success && save(true, forKey: .isLoggedIn)
        return success
    }

    /// Get user email
    var userEmail: String? { getString(forKey: .userEmail) }

    /// Get user password
    var userPassword: String? { getString(forKey: .userPassword) }

    /// Get username
    var username: String? { getString(forKey: .username) }

    /// Check if user is logged in
    var isLoggedIn: Bool { getBool(forKey: .isLoggedIn) }

    /// Clear all user credentials (logout)
    func clearUserCredentials() -> Bool {
        var success = true
        success = success && delete(forKey: .userEmail)
        success = success && delete(forKey: .userPassword)
        success = success && delete(forKey: .username)
        success = success && delete(forKey: .isLoggedIn)
        return success
    }
}
