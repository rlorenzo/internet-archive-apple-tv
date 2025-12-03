//
//  ErrorPresenterTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ErrorPresenter user-friendly messages
//

import XCTest
@testable import Internet_Archive

final class ErrorPresenterTests: XCTestCase {

    // MARK: - Singleton Tests

    @MainActor
    func testSharedInstance() {
        let instance1 = ErrorPresenter.shared
        let instance2 = ErrorPresenter.shared
        XCTAssertTrue(instance1 === instance2, "Shared instance should be the same object")
    }

    // MARK: - User-Friendly Message Tests

    @MainActor
    func testNoConnectionMessage() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .noConnection)
        XCTAssertTrue(message.contains("No internet connection"))
        XCTAssertTrue(message.contains("network settings"))
    }

    @MainActor
    func testTimeoutMessage() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .timeout)
        XCTAssertTrue(message.contains("took too long"))
        XCTAssertTrue(message.contains("connection"))
    }

    @MainActor
    func testServerError500Message() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .serverError(statusCode: 500))
        XCTAssertTrue(message.contains("Internet Archive servers"))
        XCTAssertTrue(message.contains("issues"))
    }

    @MainActor
    func testServerError503Message() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .serverError(statusCode: 503))
        XCTAssertTrue(message.contains("Internet Archive servers"))
    }

    @MainActor
    func testServerError404Message() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .serverError(statusCode: 404))
        XCTAssertTrue(message.contains("could not be found"))
    }

    @MainActor
    func testServerError429Message() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .serverError(statusCode: 429))
        XCTAssertTrue(message.contains("Too many requests"))
        XCTAssertTrue(message.contains("wait"))
    }

    @MainActor
    func testServerError400Message() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .serverError(statusCode: 400))
        XCTAssertTrue(message.contains("Server error"))
        XCTAssertTrue(message.contains("400"))
    }

    @MainActor
    func testUnauthorizedMessage() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .unauthorized)
        XCTAssertTrue(message.contains("credentials"))
        XCTAssertTrue(message.contains("invalid") || message.contains("log in"))
    }

    @MainActor
    func testAuthenticationFailedMessage() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .authenticationFailed)
        XCTAssertTrue(message.contains("credentials"))
    }

    @MainActor
    func testInvalidCredentialsMessage() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .invalidCredentials)
        XCTAssertTrue(message.contains("credentials"))
    }

    @MainActor
    func testInvalidResponseMessage() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .invalidResponse)
        XCTAssertTrue(message.contains("unexpected data"))
    }

    @MainActor
    func testDecodingFailedMessage() {
        let underlyingError = NSError(domain: "decode", code: 1)
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .decodingFailed(underlyingError))
        XCTAssertTrue(message.contains("unexpected data"))
    }

    @MainActor
    func testInvalidDataMessage() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .invalidData)
        XCTAssertTrue(message.contains("unexpected data"))
    }

    @MainActor
    func testResourceNotFoundMessage() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .resourceNotFound)
        XCTAssertTrue(message.contains("could not be found"))
    }

    @MainActor
    func testInvalidParametersMessage() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .invalidParameters)
        XCTAssertTrue(message.contains("Invalid request"))
    }

    @MainActor
    func testApiErrorMessage() {
        let customMessage = "Custom API error message"
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .apiError(message: customMessage))
        XCTAssertEqual(message, customMessage)
    }

    @MainActor
    func testCookieRetrievalFailedMessage() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .cookieRetrievalFailed)
        XCTAssertTrue(message.contains("session"))
        XCTAssertTrue(message.contains("login") || message.contains("logging"))
    }

    @MainActor
    func testRequestFailedMessage() {
        let underlyingError = NSError(domain: "network", code: 1)
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .requestFailed(underlyingError))
        XCTAssertTrue(message.contains("Network request failed"))
    }

    @MainActor
    func testUnknownErrorMessage() {
        let message = ErrorPresenter.shared.userFriendlyMessage(for: .unknown(nil))
        XCTAssertTrue(message.contains("unexpected error"))
    }

    // MARK: - Error Context Default Title Tests

    func testDefaultUserFacingTitle() {
        let context = ErrorContext(operation: .login)
        XCTAssertEqual(context.userFacingTitle, "Error")
    }

    func testCustomUserFacingTitle() {
        let context = ErrorContext(operation: .login, userFacingTitle: "Login Failed")
        XCTAssertEqual(context.userFacingTitle, "Login Failed")
    }

    // MARK: - All Error Types Have Messages Tests

    @MainActor
    func testAllNetworkErrorTypesHaveUserFriendlyMessages() {
        let errors: [NetworkError] = [
            .noConnection,
            .timeout,
            .serverError(statusCode: 500),
            .serverError(statusCode: 404),
            .serverError(statusCode: 429),
            .serverError(statusCode: 400),
            .requestFailed(NSError(domain: "", code: 0)),
            .invalidResponse,
            .decodingFailed(NSError(domain: "", code: 0)),
            .invalidData,
            .unauthorized,
            .authenticationFailed,
            .invalidCredentials,
            .cookieRetrievalFailed,
            .apiError(message: "test"),
            .resourceNotFound,
            .invalidParameters,
            .unknown(nil)
        ]

        for error in errors {
            let message = ErrorPresenter.shared.userFriendlyMessage(for: error)
            XCTAssertFalse(message.isEmpty, "Error \(error) should have a non-empty user message")
        }
    }
}

// MARK: - ErrorOperation Tests

final class ErrorOperationTests: XCTestCase {

    func testLoginRawValue() {
        XCTAssertEqual(ErrorOperation.login.rawValue, "login")
    }

    func testRegisterRawValue() {
        XCTAssertEqual(ErrorOperation.register.rawValue, "register")
    }

    func testGetAccountInfoRawValue() {
        XCTAssertEqual(ErrorOperation.getAccountInfo.rawValue, "get_account_info")
    }

    func testSearchRawValue() {
        XCTAssertEqual(ErrorOperation.search.rawValue, "search")
    }

    func testGetCollectionsRawValue() {
        XCTAssertEqual(ErrorOperation.getCollections.rawValue, "get_collections")
    }

    func testGetMetadataRawValue() {
        XCTAssertEqual(ErrorOperation.getMetadata.rawValue, "get_metadata")
    }

    func testLoadMediaRawValue() {
        XCTAssertEqual(ErrorOperation.loadMedia.rawValue, "load_media")
    }

    func testPlayVideoRawValue() {
        XCTAssertEqual(ErrorOperation.playVideo.rawValue, "play_video")
    }

    func testPlayAudioRawValue() {
        XCTAssertEqual(ErrorOperation.playAudio.rawValue, "play_audio")
    }

    func testGetFavoritesRawValue() {
        XCTAssertEqual(ErrorOperation.getFavorites.rawValue, "get_favorites")
    }

    func testSaveFavoriteRawValue() {
        XCTAssertEqual(ErrorOperation.saveFavorite.rawValue, "save_favorite")
    }

    func testRemoveFavoriteRawValue() {
        XCTAssertEqual(ErrorOperation.removeFavorite.rawValue, "remove_favorite")
    }

    func testLoadImageRawValue() {
        XCTAssertEqual(ErrorOperation.loadImage.rawValue, "load_image")
    }

    func testUnknownRawValue() {
        XCTAssertEqual(ErrorOperation.unknown.rawValue, "unknown")
    }

    func testErrorOperationCanBeCreatedFromRawValue() {
        XCTAssertEqual(ErrorOperation(rawValue: "login"), .login)
        XCTAssertEqual(ErrorOperation(rawValue: "search"), .search)
        XCTAssertEqual(ErrorOperation(rawValue: "unknown"), .unknown)
    }

    func testErrorOperationWithInvalidRawValueReturnsNil() {
        XCTAssertNil(ErrorOperation(rawValue: "invalid_operation"))
    }
}

// MARK: - ErrorContext Additional Tests

final class ErrorContextAdditionalTests: XCTestCase {

    func testErrorContextWithAdditionalInfo() {
        let context = ErrorContext(
            operation: .search,
            userFacingTitle: "Search Failed",
            additionalInfo: ["query": "test", "page": 1]
        )

        XCTAssertEqual(context.operation, .search)
        XCTAssertEqual(context.userFacingTitle, "Search Failed")
        XCTAssertNotNil(context.additionalInfo)
        XCTAssertEqual(context.additionalInfo?["query"] as? String, "test")
        XCTAssertEqual(context.additionalInfo?["page"] as? Int, 1)
    }

    func testErrorContextWithNilAdditionalInfo() {
        let context = ErrorContext(
            operation: .login,
            userFacingTitle: "Login Failed",
            additionalInfo: nil
        )

        XCTAssertNil(context.additionalInfo)
    }

    func testErrorContextDefaultValues() {
        let context = ErrorContext(operation: .unknown)

        XCTAssertEqual(context.operation, .unknown)
        XCTAssertEqual(context.userFacingTitle, "Error")
        XCTAssertNil(context.additionalInfo)
    }
}
