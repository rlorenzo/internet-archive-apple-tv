//
//  AppState.swift
//  Internet Archive
//
//  Observable app state for authentication and user preferences
//

import SwiftUI

/// Manages the global application state including authentication status
/// and user preferences.
///
/// This class bridges the existing `KeychainManager` authentication system
/// with SwiftUI's reactive state management. It publishes changes to
/// authentication state that views can observe and react to.
///
/// ## Usage
/// ```swift
/// @EnvironmentObject private var appState: AppState
///
/// if appState.isAuthenticated {
///     Text("Welcome, \(appState.username ?? "User")")
/// }
/// ```
@MainActor
final class AppState: ObservableObject {

    // MARK: - Published Properties

    /// Whether the user is currently authenticated
    @Published private(set) var isAuthenticated: Bool = false

    /// The authenticated user's username, if available
    @Published private(set) var username: String?

    /// The authenticated user's email, if available
    @Published private(set) var userEmail: String?

    /// Monotonically increasing counter bumped whenever the device-local
    /// favorites list changes (heart button). Views displaying favorites
    /// observe this to refresh their content.
    @Published private(set) var favoritesVersion = 0

    // MARK: - Initialization

    init() {
        // Load initial auth state from Keychain
        refreshAuthState()
    }

    // MARK: - Authentication Methods

    /// Refreshes the authentication state from the Keychain.
    ///
    /// Call this method after login/logout operations to update
    /// the published state properties.
    func refreshAuthState() {
        let keychain = KeychainManager.shared
        isAuthenticated = keychain.isLoggedIn
        username = keychain.username
        userEmail = keychain.userEmail
    }

    /// Updates the authentication state after a successful login.
    ///
    /// - Parameters:
    ///   - email: The user's email address
    ///   - username: The user's display name
    func setLoggedIn(email: String, username: String) {
        self.isAuthenticated = true
        self.username = username
        self.userEmail = email
    }

    /// Clears the authentication state after logout.
    ///
    /// This method clears the in-memory state, the persisted Keychain
    /// credentials, and the legacy UserDefaults login flag written by
    /// `LoginViewModel.login` (so `Global.isLoggedIn()` agrees with the
    /// Keychain state).
    ///
    /// Device-local favorites are intentionally preserved: they are
    /// device-scoped, not account-bound.
    func logout() {
        _ = KeychainManager.shared.clearUserCredentials()
        Global.saveUserData(userData: [:])
        isAuthenticated = false
        username = nil
        userEmail = nil
    }

    // MARK: - Favorites

    /// Notify observers that the device-local favorites list changed.
    ///
    /// Call this after toggling a favorite so the Favorites tab reloads.
    func notifyFavoritesChanged() {
        favoritesVersion += 1
    }
}
