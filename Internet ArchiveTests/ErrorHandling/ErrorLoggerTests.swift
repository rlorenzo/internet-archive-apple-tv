//
//  ErrorLoggerTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ErrorLogger
//

import XCTest
@testable import Internet_Archive

final class ErrorLoggerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Disable console output during tests
        ErrorLogger.isConsoleOutputEnabled = false
    }

    override func tearDown() {
        super.tearDown()
        ErrorLogger.isConsoleOutputEnabled = true
    }

    // MARK: - Singleton Tests

    @MainActor
    func testSharedInstance() {
        let instance1 = ErrorLogger.shared
        let instance2 = ErrorLogger.shared
        XCTAssertTrue(instance1 === instance2, "Shared instance should be the same object")
    }

    // MARK: - Log Error Tests

    @MainActor
    func testLogErrorDoesNotThrow() {
        let error = NetworkError.noConnection
        let context = ErrorContext(operation: .search)

        // This should not throw
        ErrorLogger.shared.log(error: error, context: context)
    }

    @MainActor
    func testLogErrorWithAdditionalInfo() {
        let error = NetworkError.serverError(statusCode: 500)
        let context = ErrorContext(
            operation: .getCollections,
            additionalInfo: ["query": "test", "page": 1]
        )

        // This should not throw
        ErrorLogger.shared.log(error: error, context: context)
    }

    @MainActor
    func testLogErrorWithAllNetworkErrorTypes() {
        // Test logging each NetworkError type
        let errors: [NetworkError] = [
            .noConnection,
            .timeout,
            .serverError(statusCode: 500),
            .serverError(statusCode: 404),
            .requestFailed(NSError(domain: "test", code: 1)),
            .invalidResponse,
            .decodingFailed(NSError(domain: "decode", code: 1)),
            .invalidData,
            .unauthorized,
            .authenticationFailed,
            .invalidCredentials,
            .cookieRetrievalFailed,
            .apiError(message: "Test error"),
            .resourceNotFound,
            .invalidParameters,
            .unknown(nil)
        ]

        for error in errors {
            let context = ErrorContext(operation: .unknown)
            ErrorLogger.shared.log(error: error, context: context)
        }
    }

    // MARK: - Log Success Tests

    @MainActor
    func testLogSuccessDoesNotThrow() {
        ErrorLogger.shared.logSuccess(operation: .login)
    }

    @MainActor
    func testLogSuccessWithInfo() {
        ErrorLogger.shared.logSuccess(operation: .search, info: ["results": 42])
    }

    // MARK: - Log Warning Tests

    @MainActor
    func testLogWarningDoesNotThrow() {
        ErrorLogger.shared.logWarning("Test warning message", operation: .getMetadata)
    }

    // MARK: - Error Operation Tests

    func testErrorOperationRawValues() {
        XCTAssertEqual(ErrorOperation.login.rawValue, "login")
        XCTAssertEqual(ErrorOperation.register.rawValue, "register")
        XCTAssertEqual(ErrorOperation.getAccountInfo.rawValue, "get_account_info")
        XCTAssertEqual(ErrorOperation.search.rawValue, "search")
        XCTAssertEqual(ErrorOperation.getCollections.rawValue, "get_collections")
        XCTAssertEqual(ErrorOperation.getMetadata.rawValue, "get_metadata")
        XCTAssertEqual(ErrorOperation.loadMedia.rawValue, "load_media")
        XCTAssertEqual(ErrorOperation.playVideo.rawValue, "play_video")
        XCTAssertEqual(ErrorOperation.playAudio.rawValue, "play_audio")
        XCTAssertEqual(ErrorOperation.getFavorites.rawValue, "get_favorites")
        XCTAssertEqual(ErrorOperation.saveFavorite.rawValue, "save_favorite")
        XCTAssertEqual(ErrorOperation.removeFavorite.rawValue, "remove_favorite")
        XCTAssertEqual(ErrorOperation.loadImage.rawValue, "load_image")
        XCTAssertEqual(ErrorOperation.unknown.rawValue, "unknown")
    }

    // MARK: - Error Context Tests

    func testErrorContextInit() {
        let context = ErrorContext(operation: .login)
        XCTAssertEqual(context.operation, .login)
        XCTAssertEqual(context.userFacingTitle, "Error") // default value
        XCTAssertNil(context.additionalInfo)
    }

    func testErrorContextWithAllParameters() {
        let additionalInfo: [String: Any] = ["userId": "123", "attempt": 3]
        let context = ErrorContext(
            operation: .register,
            userFacingTitle: "Registration Failed",
            additionalInfo: additionalInfo
        )

        XCTAssertEqual(context.operation, .register)
        XCTAssertEqual(context.userFacingTitle, "Registration Failed")
        XCTAssertNotNil(context.additionalInfo)
        XCTAssertEqual(context.additionalInfo?["userId"] as? String, "123")
        XCTAssertEqual(context.additionalInfo?["attempt"] as? Int, 3)
    }

    // MARK: - Console Output Control Tests

    func testConsoleOutputCanBeDisabled() {
        let originalValue = ErrorLogger.isConsoleOutputEnabled
        ErrorLogger.isConsoleOutputEnabled = false
        XCTAssertFalse(ErrorLogger.isConsoleOutputEnabled)
        ErrorLogger.isConsoleOutputEnabled = originalValue
    }

    func testConsoleOutputCanBeEnabled() {
        let originalValue = ErrorLogger.isConsoleOutputEnabled
        ErrorLogger.isConsoleOutputEnabled = true
        XCTAssertTrue(ErrorLogger.isConsoleOutputEnabled)
        ErrorLogger.isConsoleOutputEnabled = originalValue
    }
}
