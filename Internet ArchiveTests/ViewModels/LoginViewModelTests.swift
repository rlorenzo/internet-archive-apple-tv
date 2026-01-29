//
//  LoginViewModelTests.swift
//  Internet ArchiveTests
//
//  Unit tests for LoginViewModel
//

import XCTest
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

@MainActor
final class LoginViewModelTests: XCTestCase {

    nonisolated(unsafe) var viewModel: LoginViewModel!
    nonisolated(unsafe) var mockService: MockAuthService!

    override func setUp() {
        super.setUp()
        let (newMockService, newViewModel) = MainActor.assumeIsolated {
            let service = MockAuthService()
            let vm = LoginViewModel(authService: service)
            // Clean up any stored data
            Global.saveUserData(userData: [:])
            _ = KeychainManager.shared.clearUserCredentials()
            return (service, vm)
        }
        mockService = newMockService
        viewModel = newViewModel
    }

    override func tearDown() {
        MainActor.assumeIsolated {
            // Clean up
            Global.saveUserData(userData: [:])
            _ = KeychainManager.shared.clearUserCredentials()
        }
        viewModel = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertFalse(viewModel.state.isLoggedIn)
        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertEqual(viewModel.state.email, "")
    }

    // MARK: - Validation Tests

    func testValidateInputs_validCredentials() {
        let result = viewModel.validateInputs(email: "test@example.com", password: "password123")

        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.emailError)
        XCTAssertNil(result.passwordError)
    }

    func testValidateInputs_emptyEmail() {
        let result = viewModel.validateInputs(email: "", password: "password123")

        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.emailError)
        XCTAssertTrue(result.emailError?.contains("required") ?? false)
    }

    func testValidateInputs_invalidEmail() {
        let result = viewModel.validateInputs(email: "notanemail", password: "password123")

        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.emailError)
        XCTAssertTrue(result.emailError?.contains("valid email") ?? false)
    }

    func testValidateInputs_emptyPassword() {
        let result = viewModel.validateInputs(email: "test@example.com", password: "")

        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.passwordError)
        XCTAssertTrue(result.passwordError?.contains("required") ?? false)
    }

    func testValidateInputs_shortPassword() {
        let result = viewModel.validateInputs(email: "test@example.com", password: "ab")

        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.passwordError)
        XCTAssertTrue(result.passwordError?.contains("short") ?? false)
    }

    func testValidateInputs_bothInvalid() {
        let result = viewModel.validateInputs(email: "", password: "")

        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.emailError)
        XCTAssertNotNil(result.passwordError)
    }

    // MARK: - Login Tests

    func testLogin_withValidCredentials_callsService() async {
        mockService.mockLoginResponse = TestFixtures.successfulAuthResponse

        _ = await viewModel.login(email: "test@example.com", password: "password123")

        XCTAssertTrue(mockService.loginCalled)
        XCTAssertEqual(mockService.lastEmail, "test@example.com")
        XCTAssertEqual(mockService.lastPassword, "password123")
    }

    func testLogin_withSuccessfulResponse_updatesState() async {
        mockService.mockLoginResponse = TestFixtures.successfulAuthResponse

        let success = await viewModel.login(email: "test@example.com", password: "password123")

        XCTAssertTrue(success)
        XCTAssertTrue(viewModel.state.isLoggedIn)
        XCTAssertEqual(viewModel.state.email, "test@example.com")
        XCTAssertFalse(viewModel.state.isLoading)
    }

    func testLogin_withFailedResponse_setsError() async {
        mockService.mockLoginResponse = TestFixtures.failedAuthResponse

        let success = await viewModel.login(email: "test@example.com", password: "wrongpassword")

        XCTAssertFalse(success)
        XCTAssertFalse(viewModel.state.isLoggedIn)
        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    func testLogin_withInvalidEmail_doesNotCallService() async {
        let success = await viewModel.login(email: "invalid", password: "password123")

        XCTAssertFalse(success)
        XCTAssertFalse(mockService.loginCalled)
        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    func testLogin_withNetworkError_setsErrorMessage() async {
        mockService.errorToThrow = NetworkError.timeout

        let success = await viewModel.login(email: "test@example.com", password: "password123")

        XCTAssertFalse(success)
        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertFalse(viewModel.state.isLoading)
    }

    // MARK: - Logout Tests

    func testLogout_clearsState() async {
        // First login
        mockService.mockLoginResponse = TestFixtures.successfulAuthResponse
        _ = await viewModel.login(email: "test@example.com", password: "password123")

        // Then logout
        viewModel.logout()

        XCTAssertFalse(viewModel.state.isLoggedIn)
        XCTAssertEqual(viewModel.state.email, "")
        XCTAssertFalse(Global.isLoggedIn())
    }

    // MARK: - Check Login Status Tests

    func testCheckLoginStatus_whenLoggedIn() {
        Global.saveUserData(userData: ["logged-in": true, "email": "test@example.com"])

        viewModel.checkLoginStatus()

        XCTAssertTrue(viewModel.state.isLoggedIn)
        XCTAssertEqual(viewModel.state.email, "test@example.com")
    }

    func testCheckLoginStatus_whenNotLoggedIn() {
        Global.saveUserData(userData: [:])

        viewModel.checkLoginStatus()

        XCTAssertFalse(viewModel.state.isLoggedIn)
    }

    // MARK: - Fetch Account Info Tests

    func testFetchAccountInfo_callsService() async throws {
        mockService.mockAccountInfoResponse = AccountInfoResponse(
            success: true,
            values: AccountInfoResponse.AccountValues(
                email: "test@example.com",
                screenname: "TestUser",
                verified: true
            )
        )

        let response = try await viewModel.fetchAccountInfo(email: "test@example.com")

        XCTAssertTrue(mockService.getAccountInfoCalled)
        XCTAssertEqual(mockService.lastEmail, "test@example.com")
        XCTAssertEqual(response.values?.screenname, "TestUser")
    }

    func testFetchAccountInfo_withError_throws() async {
        mockService.errorToThrow = NetworkError.invalidResponse

        do {
            _ = try await viewModel.fetchAccountInfo(email: "test@example.com")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
}

// MARK: - LoginViewState Tests

final class LoginViewStateTests: XCTestCase {

    func testInitialState() {
        let state = LoginViewState.initial

        XCTAssertFalse(state.isLoading)
        XCTAssertFalse(state.isLoggedIn)
        XCTAssertNil(state.errorMessage)
        XCTAssertEqual(state.email, "")
        XCTAssertNil(state.username)
    }
}

// MARK: - LoginValidation Tests

final class LoginValidationTests: XCTestCase {

    func testValidState() {
        let validation = LoginValidation.valid

        XCTAssertTrue(validation.isValid)
        XCTAssertNil(validation.emailError)
        XCTAssertNil(validation.passwordError)
    }

    func testEquatable() {
        let v1 = LoginValidation(isValid: true, emailError: nil, passwordError: nil)
        let v2 = LoginValidation.valid

        XCTAssertEqual(v1, v2)
    }
}
