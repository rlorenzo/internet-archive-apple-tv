//
//  LoginViewModelTests.swift
//  Internet ArchiveTests
//
//  Unit tests for LoginViewModel
//

import Testing
@testable import Internet_Archive

// MARK: - Mock Auth Service

final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    var loginCalled = false
    var getAccountInfoCalled = false
    var lastEmail: String?
    var lastPassword: String?
    var mockLoginResponse: AuthResponse?
    var mockAccountInfoResponse: AccountInfoResponse?
    var errorToThrow: Error?

    func login(email: String, password: String) async throws -> AuthResponse {
        loginCalled = true
        lastEmail = email
        lastPassword = password

        if let error = errorToThrow {
            throw error
        }

        guard let response = mockLoginResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

    func getAccountInfo(email: String) async throws -> AccountInfoResponse {
        getAccountInfoCalled = true
        lastEmail = email

        if let error = errorToThrow {
            throw error
        }

        guard let response = mockAccountInfoResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

    func reset() {
        loginCalled = false
        getAccountInfoCalled = false
        lastEmail = nil
        lastPassword = nil
        mockLoginResponse = nil
        mockAccountInfoResponse = nil
        errorToThrow = nil
    }
}

// MARK: - LoginViewModel Tests

@Suite("LoginViewModel Tests", .serialized)
@MainActor
struct LoginViewModelTests {

    var viewModel: LoginViewModel
    var mockService: MockAuthService

    init() {
        let service = MockAuthService()
        mockService = service
        viewModel = LoginViewModel(authService: service)
        // Clean up any stored data
        Global.saveUserData(userData: [:])
        _ = KeychainManager.shared.clearUserCredentials()
    }

    // MARK: - Initial State Tests

    @Test func initialState() {
        #expect(!viewModel.state.isLoading)
        #expect(!viewModel.state.isLoggedIn)
        #expect(viewModel.state.errorMessage == nil)
        #expect(viewModel.state.email == "")
    }

    // MARK: - Validation Tests

    @Test func validateInputsValidCredentials() {
        let result = viewModel.validateInputs(email: "test@example.com", password: "password123")

        #expect(result.isValid)
        #expect(result.emailError == nil)
        #expect(result.passwordError == nil)
    }

    @Test func validateInputsEmptyEmail() {
        let result = viewModel.validateInputs(email: "", password: "password123")

        #expect(!result.isValid)
        #expect(result.emailError != nil)
        #expect(result.emailError?.contains("required") ?? false)
    }

    @Test func validateInputsInvalidEmail() {
        let result = viewModel.validateInputs(email: "notanemail", password: "password123")

        #expect(!result.isValid)
        #expect(result.emailError != nil)
        #expect(result.emailError?.contains("valid email") ?? false)
    }

    @Test func validateInputsEmptyPassword() {
        let result = viewModel.validateInputs(email: "test@example.com", password: "")

        #expect(!result.isValid)
        #expect(result.passwordError != nil)
        #expect(result.passwordError?.contains("required") ?? false)
    }

    @Test func validateInputsShortPassword() {
        let result = viewModel.validateInputs(email: "test@example.com", password: "ab")

        #expect(!result.isValid)
        #expect(result.passwordError != nil)
        #expect(result.passwordError?.contains("short") ?? false)
    }

    @Test func validateInputsBothInvalid() {
        let result = viewModel.validateInputs(email: "", password: "")

        #expect(!result.isValid)
        #expect(result.emailError != nil)
        #expect(result.passwordError != nil)
    }

    // MARK: - Login Tests

    @Test func loginWithValidCredentialsCallsService() async {
        mockService.mockLoginResponse = TestFixtures.successfulAuthResponse

        _ = await viewModel.login(email: "test@example.com", password: "password123")

        #expect(mockService.loginCalled)
        #expect(mockService.lastEmail == "test@example.com")
        #expect(mockService.lastPassword == "password123")
        // Cleanup
        Global.saveUserData(userData: [:])
        _ = KeychainManager.shared.clearUserCredentials()
    }

    @Test func loginWithSuccessfulResponseUpdatesState() async {
        mockService.mockLoginResponse = TestFixtures.successfulAuthResponse

        let success = await viewModel.login(email: "test@example.com", password: "password123")

        #expect(success)
        #expect(viewModel.state.isLoggedIn)
        #expect(viewModel.state.email == "test@example.com")
        #expect(!viewModel.state.isLoading)
        // Cleanup
        Global.saveUserData(userData: [:])
        _ = KeychainManager.shared.clearUserCredentials()
    }

    @Test func loginWithFailedResponseSetsError() async {
        mockService.mockLoginResponse = TestFixtures.failedAuthResponse

        let success = await viewModel.login(email: "test@example.com", password: "wrongpassword")

        #expect(!success)
        #expect(!viewModel.state.isLoggedIn)
        #expect(viewModel.state.errorMessage != nil)
    }

    @Test func loginWithInvalidEmailDoesNotCallService() async {
        let success = await viewModel.login(email: "invalid", password: "password123")

        #expect(!success)
        #expect(!mockService.loginCalled)
        #expect(viewModel.state.errorMessage != nil)
    }

    @Test func loginWithNetworkErrorSetsErrorMessage() async {
        mockService.errorToThrow = NetworkError.timeout

        let success = await viewModel.login(email: "test@example.com", password: "password123")

        #expect(!success)
        #expect(viewModel.state.errorMessage != nil)
        #expect(!viewModel.state.isLoading)
    }

    // MARK: - Logout Tests

    @Test func logoutClearsState() async {
        // First login
        mockService.mockLoginResponse = TestFixtures.successfulAuthResponse
        _ = await viewModel.login(email: "test@example.com", password: "password123")

        // Then logout
        viewModel.logout()

        #expect(!viewModel.state.isLoggedIn)
        #expect(viewModel.state.email == "")
        #expect(!Global.isLoggedIn())
        // Cleanup
        Global.saveUserData(userData: [:])
        _ = KeychainManager.shared.clearUserCredentials()
    }

    // MARK: - Check Login Status Tests

    @Test func checkLoginStatusWhenLoggedIn() {
        Global.saveUserData(userData: ["logged-in": true, "email": "test@example.com"])

        viewModel.checkLoginStatus()

        #expect(viewModel.state.isLoggedIn)
        #expect(viewModel.state.email == "test@example.com")
        // Cleanup
        Global.saveUserData(userData: [:])
    }

    @Test func checkLoginStatusWhenNotLoggedIn() {
        Global.saveUserData(userData: [:])

        viewModel.checkLoginStatus()

        #expect(!viewModel.state.isLoggedIn)
    }

    // MARK: - Fetch Account Info Tests

    @Test func fetchAccountInfoCallsService() async throws {
        mockService.mockAccountInfoResponse = AccountInfoResponse(
            success: true,
            values: AccountInfoResponse.AccountValues(
                email: "test@example.com",
                screenname: "TestUser",
                verified: true
            )
        )

        let response = try await viewModel.fetchAccountInfo(email: "test@example.com")

        #expect(mockService.getAccountInfoCalled)
        #expect(mockService.lastEmail == "test@example.com")
        #expect(response.values?.screenname == "TestUser")
    }

    @Test func fetchAccountInfoWithErrorThrows() async {
        mockService.errorToThrow = NetworkError.invalidResponse

        await #expect(throws: NetworkError.self) {
            _ = try await viewModel.fetchAccountInfo(email: "test@example.com")
        }
    }
}

// MARK: - LoginViewState Tests

@Suite("LoginViewState Tests")
struct LoginViewStateTests {

    @Test func initialState() {
        let state = LoginViewState.initial

        #expect(!state.isLoading)
        #expect(!state.isLoggedIn)
        #expect(state.errorMessage == nil)
        #expect(state.email == "")
        #expect(state.username == nil)
    }
}

// MARK: - LoginValidation Tests

@Suite("LoginValidation Tests")
struct LoginValidationTests {

    @Test func validState() {
        let validation = LoginValidation.valid

        #expect(validation.isValid)
        #expect(validation.emailError == nil)
        #expect(validation.passwordError == nil)
    }

    @Test func equatable() {
        let v1 = LoginValidation(isValid: true, emailError: nil, passwordError: nil)
        let v2 = LoginValidation.valid

        #expect(v1 == v2)
    }
}
