//
//  NetworkErrorTests.swift
//  Internet ArchiveTests
//
//  Unit tests for NetworkError enum
//

import XCTest
@testable import Internet_Archive

final class NetworkErrorTests: XCTestCase {

    // MARK: - Network Error Cases

    func testNoConnectionError() {
        let error = NetworkError.noConnection
        XCTAssertEqual(error.localizedDescription, "No internet connection available")
    }

    func testTimeoutError() {
        let error = NetworkError.timeout
        XCTAssertEqual(error.localizedDescription, "Request timed out")
    }

    func testServerError500() {
        let error = NetworkError.serverError(statusCode: 500)
        XCTAssertEqual(error.localizedDescription, "Server error (HTTP 500)")
    }

    func testServerError503() {
        let error = NetworkError.serverError(statusCode: 503)
        XCTAssertEqual(error.localizedDescription, "Server error (HTTP 503)")
    }

    func testServerError404() {
        let error = NetworkError.serverError(statusCode: 404)
        XCTAssertEqual(error.localizedDescription, "Server error (HTTP 404)")
    }

    func testRequestFailedError() {
        let underlyingError = NSError(domain: "TestDomain", code: 123, userInfo: [
            NSLocalizedDescriptionKey: "Test underlying error"
        ])
        let error = NetworkError.requestFailed(underlyingError)
        XCTAssertTrue(error.localizedDescription.contains("Request failed:"))
        XCTAssertTrue(error.localizedDescription.contains("Test underlying error"))
    }

    // MARK: - Data Parsing Error Cases

    func testInvalidResponseError() {
        let error = NetworkError.invalidResponse
        XCTAssertEqual(error.localizedDescription, "Invalid response from server")
    }

    func testDecodingFailedError() {
        let underlyingError = NSError(domain: "DecodingDomain", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "JSON parsing failed"
        ])
        let error = NetworkError.decodingFailed(underlyingError)
        XCTAssertTrue(error.localizedDescription.contains("Failed to decode response:"))
        XCTAssertTrue(error.localizedDescription.contains("JSON parsing failed"))
    }

    func testInvalidDataError() {
        let error = NetworkError.invalidData
        XCTAssertEqual(error.localizedDescription, "Invalid data received")
    }

    // MARK: - Authentication Error Cases

    func testUnauthorizedError() {
        let error = NetworkError.unauthorized
        XCTAssertEqual(error.localizedDescription, "Unauthorized access")
    }

    func testAuthenticationFailedError() {
        let error = NetworkError.authenticationFailed
        XCTAssertEqual(error.localizedDescription, "Authentication failed")
    }

    func testInvalidCredentialsError() {
        let error = NetworkError.invalidCredentials
        XCTAssertEqual(error.localizedDescription, "Invalid email or password")
    }

    func testCookieRetrievalFailedError() {
        let error = NetworkError.cookieRetrievalFailed
        XCTAssertEqual(error.localizedDescription, "Failed to retrieve authentication cookies")
    }

    // MARK: - API-Specific Error Cases

    func testApiErrorWithMessage() {
        let error = NetworkError.apiError(message: "Rate limit exceeded")
        XCTAssertEqual(error.localizedDescription, "API Error: Rate limit exceeded")
    }

    func testApiErrorWithEmptyMessage() {
        let error = NetworkError.apiError(message: "")
        XCTAssertEqual(error.localizedDescription, "API Error: ")
    }

    func testResourceNotFoundError() {
        let error = NetworkError.resourceNotFound
        XCTAssertEqual(error.localizedDescription, "Resource not found")
    }

    func testInvalidParametersError() {
        let error = NetworkError.invalidParameters
        XCTAssertEqual(error.localizedDescription, "Invalid request parameters")
    }

    // MARK: - Unknown Error Cases

    func testUnknownErrorWithUnderlyingError() {
        let underlyingError = NSError(domain: "UnknownDomain", code: 999, userInfo: [
            NSLocalizedDescriptionKey: "Something went wrong"
        ])
        let error = NetworkError.unknown(underlyingError)
        XCTAssertTrue(error.localizedDescription.contains("Something went wrong"))
    }

    func testUnknownErrorWithNilError() {
        let error = NetworkError.unknown(nil)
        XCTAssertEqual(error.localizedDescription, "Unknown error occurred")
    }

    // MARK: - Service Unavailable Message

    func testServiceUnavailableMessage() {
        let message = NetworkError.serviceUnavailableMessage
        XCTAssertTrue(message.contains("Internet Archive services are temporarily unavailable"))
        XCTAssertTrue(message.contains("archive.org"))
        XCTAssertTrue(message.contains("try again later"))
    }

    // MARK: - Error Protocol Conformance

    func testNetworkErrorConformsToError() {
        let error: Error = NetworkError.noConnection
        XCTAssertNotNil(error)
    }

    func testNetworkErrorConformsToSendable() {
        // This test verifies compile-time Sendable conformance
        // by passing the error across an async boundary
        let expectation = XCTestExpectation(description: "Sendable test")

        Task {
            let error: NetworkError = .timeout
            await MainActor.run {
                XCTAssertEqual(error.localizedDescription, "Request timed out")
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - All Error Cases Coverage

    func testAllErrorCasesHaveDescriptions() {
        // Ensure all cases have non-empty descriptions
        let errors: [NetworkError] = [
            .noConnection,
            .timeout,
            .serverError(statusCode: 500),
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
            XCTAssertFalse(error.localizedDescription.isEmpty,
                          "Error \(error) should have non-empty description")
        }
    }
}
