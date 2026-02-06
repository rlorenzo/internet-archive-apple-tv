//
//  AppStateTests.swift
//  Internet ArchiveTests
//
//  Tests for AppState authentication state management
//

import Testing
@testable import Internet_Archive

@Suite("AppState Tests")
@MainActor
struct AppStateTests {

    // MARK: - Test Constants

    private let testEmail = "test@example.com"
    private let testUsername = "TestUser"
    private let testCredential = "testcredential123"

    private let altEmail = "user@archive.org"
    private let altUsername = "ArchiveUser"

    private let refreshEmail = "refresh@example.com"
    private let refreshUsername = "RefreshUser"

    // MARK: - Initial State Tests

    @Test func initialStateWhenNotLoggedInIsUnauthenticated() {
        // Given: Fresh AppState with no keychain credentials
        _ = KeychainManager.shared.clearUserCredentials()
        let sut = AppState()

        // Then: Should be unauthenticated
        #expect(!sut.isAuthenticated)
        #expect(sut.username == nil)
        #expect(sut.userEmail == nil)
    }

    @Test func initialStateWhenLoggedInIsAuthenticated() {
        // Given: Keychain has saved credentials
        _ = KeychainManager.shared.clearUserCredentials()
        _ = KeychainManager.shared.saveUserCredentials(
            email: testEmail,
            password: testCredential,
            username: testUsername
        )

        // When: Creating a new AppState
        let appState = AppState()

        // Then: Should be authenticated with correct values
        #expect(appState.isAuthenticated)
        #expect(appState.username == testUsername)
        #expect(appState.userEmail == testEmail)

        // Cleanup
        _ = KeychainManager.shared.clearUserCredentials()
    }

    // MARK: - setLoggedIn Tests

    @Test func setLoggedInUpdatesAllProperties() {
        // Given: Unauthenticated state
        _ = KeychainManager.shared.clearUserCredentials()
        let sut = AppState()
        #expect(!sut.isAuthenticated)

        // When: Setting logged in
        sut.setLoggedIn(email: altEmail, username: altUsername)

        // Then: All properties should be updated
        #expect(sut.isAuthenticated)
        #expect(sut.username == altUsername)
        #expect(sut.userEmail == altEmail)

        // Cleanup
        _ = KeychainManager.shared.clearUserCredentials()
    }

    // MARK: - logout Tests

    @Test func logoutClearsAllProperties() {
        // Given: Authenticated state
        _ = KeychainManager.shared.clearUserCredentials()
        let sut = AppState()
        sut.setLoggedIn(email: altEmail, username: altUsername)
        #expect(sut.isAuthenticated)

        // When: Logging out
        sut.logout()

        // Then: All properties should be cleared
        #expect(!sut.isAuthenticated)
        #expect(sut.username == nil)
        #expect(sut.userEmail == nil)
    }

    @Test func logoutClearsKeychainCredentials() {
        // Given: Saved keychain credentials
        _ = KeychainManager.shared.clearUserCredentials()
        _ = KeychainManager.shared.saveUserCredentials(
            email: testEmail,
            password: testCredential,
            username: testUsername
        )
        let sut = AppState()
        sut.refreshAuthState()
        #expect(sut.isAuthenticated)

        // When: Logging out
        sut.logout()

        // Then: Keychain should be cleared
        #expect(!KeychainManager.shared.isLoggedIn)
        #expect(KeychainManager.shared.username == nil)
        #expect(KeychainManager.shared.userEmail == nil)
    }

    // MARK: - refreshAuthState Tests

    @Test func refreshAuthStateUpdatesFromKeychain() {
        // Given: AppState is unauthenticated
        _ = KeychainManager.shared.clearUserCredentials()
        let sut = AppState()
        #expect(!sut.isAuthenticated)

        // When: Credentials are saved to keychain and state is refreshed
        _ = KeychainManager.shared.saveUserCredentials(
            email: refreshEmail,
            password: testCredential,
            username: refreshUsername
        )
        sut.refreshAuthState()

        // Then: AppState should reflect keychain state
        #expect(sut.isAuthenticated)
        #expect(sut.username == refreshUsername)
        #expect(sut.userEmail == refreshEmail)

        // Cleanup
        _ = KeychainManager.shared.clearUserCredentials()
    }

    @Test func refreshAuthStateWhenKeychainClearedBecomesUnauthenticated() {
        // Given: Authenticated state from keychain
        _ = KeychainManager.shared.clearUserCredentials()
        _ = KeychainManager.shared.saveUserCredentials(
            email: testEmail,
            password: testCredential,
            username: testUsername
        )
        let sut = AppState()
        sut.refreshAuthState()
        #expect(sut.isAuthenticated)

        // When: Keychain is cleared externally and state is refreshed
        _ = KeychainManager.shared.clearUserCredentials()
        sut.refreshAuthState()

        // Then: AppState should be unauthenticated
        #expect(!sut.isAuthenticated)
        #expect(sut.username == nil)
        #expect(sut.userEmail == nil)
    }
}
