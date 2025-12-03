//
//  LoginViewModel.swift
//  Internet Archive
//
//  ViewModel for login/authentication with testable business logic
//

import Foundation

/// Protocol for authentication operations - enables dependency injection for testing
protocol AuthServiceProtocol: Sendable {
    func login(email: String, password: String) async throws -> AuthResponse
    func getAccountInfo(email: String) async throws -> AccountInfoResponse
}

/// ViewModel state for login
struct LoginViewState: Equatable, Sendable {
    var isLoading: Bool = false
    var isLoggedIn: Bool = false
    var errorMessage: String?
    var email: String = ""
    var username: String?

    static let initial = LoginViewState()
}

/// Validation result for login form
struct LoginValidation: Equatable {
    let isValid: Bool
    let emailError: String?
    let passwordError: String?

    static let valid = LoginValidation(isValid: true, emailError: nil, passwordError: nil)
}

/// ViewModel for login screen - handles all business logic
@MainActor
final class LoginViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var state = LoginViewState.initial

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol

    // MARK: - Initialization

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    // MARK: - Public Methods

    /// Validate login form inputs
    func validateInputs(email: String, password: String) -> LoginValidation {
        var emailError: String?
        var passwordError: String?

        // Email validation
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emailError = "Email is required"
        } else if !isValidEmail(email) {
            emailError = "Please enter a valid email address"
        }

        // Password validation
        if password.isEmpty {
            passwordError = "Password is required"
        } else if password.count < 3 {
            passwordError = "Password is too short"
        }

        let isValid = emailError == nil && passwordError == nil
        return LoginValidation(isValid: isValid, emailError: emailError, passwordError: passwordError)
    }

    /// Attempt to log in with credentials
    func login(email: String, password: String) async -> Bool {
        let validation = validateInputs(email: email, password: password)
        guard validation.isValid else {
            state.errorMessage = validation.emailError ?? validation.passwordError
            return false
        }

        state.isLoading = true
        state.errorMessage = nil

        do {
            let response = try await authService.login(email: email, password: password)

            if response.isSuccess {
                // Save user data
                let userData: [String: Any?] = [
                    "email": email,
                    "logged-in": true
                ]
                Global.saveUserData(userData: userData)

                // Store credentials securely
                let username = response.values?.screenname ?? email
                _ = KeychainManager.shared.saveUserCredentials(email: email, password: password, username: username)

                state.email = email
                state.isLoggedIn = true
                state.isLoading = false
                return true
            } else {
                state.errorMessage = response.error ?? "Login failed. Please check your credentials."
                state.isLoading = false
                return false
            }
        } catch {
            state.errorMessage = mapErrorToMessage(error)
            state.isLoading = false
            return false
        }
    }

    /// Log out the current user
    func logout() {
        // Clear stored data
        Global.saveUserData(userData: [:])
        _ = KeychainManager.shared.clearUserCredentials()
        Global.resetFavoriteData()

        state = LoginViewState.initial
    }

    /// Check if user is currently logged in
    func checkLoginStatus() {
        state.isLoggedIn = Global.isLoggedIn()
        if let userData = Global.getUserData() {
            state.email = userData["email"] as? String ?? ""
        }
    }

    /// Fetch account info through injected auth service (respects mock mode)
    func fetchAccountInfo(email: String) async throws -> AccountInfoResponse {
        try await authService.getAccountInfo(email: email)
    }

    // MARK: - Private Methods

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func mapErrorToMessage(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            return ErrorPresenter.shared.userFriendlyMessage(for: networkError)
        }
        return "An unexpected error occurred. Please try again."
    }
}

// MARK: - Default Auth Service Implementation

/// Default implementation using APIManager.networkService (supports mock data for UI testing)
struct DefaultAuthService: AuthServiceProtocol {

    @MainActor
    func login(email: String, password: String) async throws -> AuthResponse {
        try await APIManager.networkService.login(email: email, password: password)
    }

    @MainActor
    func getAccountInfo(email: String) async throws -> AccountInfoResponse {
        try await APIManager.networkService.getAccountInfo(email: email)
    }
}
