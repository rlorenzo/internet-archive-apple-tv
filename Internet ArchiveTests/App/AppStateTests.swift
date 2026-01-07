//
//  AppStateTests.swift
//  Internet ArchiveTests
//
//  Tests for AppState authentication state management
//

import XCTest
@testable import Internet_Archive

@MainActor
final class AppStateTests: XCTestCase {

    // MARK: - Test Constants

    private let testEmail = "test@example.com"
    private let testUsername = "TestUser"
    private let testCredential = "testcredential123"

    private let altEmail = "user@archive.org"
    private let altUsername = "ArchiveUser"

    private let refreshEmail = "refresh@example.com"
    private let refreshUsername = "RefreshUser"

    var sut: AppState!

    override func setUp() {
        super.setUp()
        // Clear any existing keychain data before each test
        _ = KeychainManager.shared.clearUserCredentials()
        sut = AppState()
    }

    override func tearDown() {
        // Clean up keychain after each test
        _ = KeychainManager.shared.clearUserCredentials()
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_WhenNotLoggedIn_IsUnauthenticated() {
        // Given: Fresh AppState with no keychain credentials

        // Then: Should be unauthenticated
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.username)
        XCTAssertNil(sut.userEmail)
    }

    func testInitialState_WhenLoggedIn_IsAuthenticated() {
        // Given: Keychain has saved credentials
        _ = KeychainManager.shared.saveUserCredentials(
            email: testEmail,
            password: testCredential,
            username: testUsername
        )

        // When: Creating a new AppState
        let appState = AppState()

        // Then: Should be authenticated with correct values
        XCTAssertTrue(appState.isAuthenticated)
        XCTAssertEqual(appState.username, testUsername)
        XCTAssertEqual(appState.userEmail, testEmail)
    }

    // MARK: - setLoggedIn Tests

    func testSetLoggedIn_UpdatesAllProperties() {
        // Given: Unauthenticated state
        XCTAssertFalse(sut.isAuthenticated)

        // When: Setting logged in
        sut.setLoggedIn(email: altEmail, username: altUsername)

        // Then: All properties should be updated
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.username, altUsername)
        XCTAssertEqual(sut.userEmail, altEmail)
    }

    // MARK: - logout Tests

    func testLogout_ClearsAllProperties() {
        // Given: Authenticated state
        sut.setLoggedIn(email: altEmail, username: altUsername)
        XCTAssertTrue(sut.isAuthenticated)

        // When: Logging out
        sut.logout()

        // Then: All properties should be cleared
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.username)
        XCTAssertNil(sut.userEmail)
    }

    func testLogout_ClearsKeychainCredentials() {
        // Given: Saved keychain credentials
        _ = KeychainManager.shared.saveUserCredentials(
            email: testEmail,
            password: testCredential,
            username: testUsername
        )
        sut.refreshAuthState()
        XCTAssertTrue(sut.isAuthenticated)

        // When: Logging out
        sut.logout()

        // Then: Keychain should be cleared
        XCTAssertFalse(KeychainManager.shared.isLoggedIn)
        XCTAssertNil(KeychainManager.shared.username)
        XCTAssertNil(KeychainManager.shared.userEmail)
    }

    // MARK: - refreshAuthState Tests

    func testRefreshAuthState_UpdatesFromKeychain() {
        // Given: AppState is unauthenticated
        XCTAssertFalse(sut.isAuthenticated)

        // When: Credentials are saved to keychain and state is refreshed
        _ = KeychainManager.shared.saveUserCredentials(
            email: refreshEmail,
            password: testCredential,
            username: refreshUsername
        )
        sut.refreshAuthState()

        // Then: AppState should reflect keychain state
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.username, refreshUsername)
        XCTAssertEqual(sut.userEmail, refreshEmail)
    }

    func testRefreshAuthState_WhenKeychainCleared_BecomesUnauthenticated() {
        // Given: Authenticated state from keychain
        _ = KeychainManager.shared.saveUserCredentials(
            email: testEmail,
            password: testCredential,
            username: testUsername
        )
        sut.refreshAuthState()
        XCTAssertTrue(sut.isAuthenticated)

        // When: Keychain is cleared externally and state is refreshed
        _ = KeychainManager.shared.clearUserCredentials()
        sut.refreshAuthState()

        // Then: AppState should be unauthenticated
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.username)
        XCTAssertNil(sut.userEmail)
    }
}
