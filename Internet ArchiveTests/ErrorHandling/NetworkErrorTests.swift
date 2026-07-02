//
//  NetworkErrorTests.swift
//  Internet ArchiveTests
//
//  Unit tests for NetworkError enum
//

import XCTest
import Alamofire
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

    /// The custom descriptions must bridge through `Error` existentials via
    /// `LocalizedError`; without it, logs show "NetworkError error N" garbage.
    func testLocalizedDescriptionBridgesThroughErrorExistential() {
        let error: Error = NetworkError.timeout
        XCTAssertEqual(error.localizedDescription, "Request timed out")

        let serverError: Error = NetworkError.serverError(statusCode: 502)
        XCTAssertEqual(serverError.localizedDescription, "Server error (HTTP 502)")
    }

    func testErrorDescriptionMatchesLocalizedDescription() {
        let error = NetworkError.noConnection
        XCTAssertEqual(error.errorDescription, error.localizedDescription)
    }

    // MARK: - Error Mapping

    func testMappingPassesThroughExistingNetworkError() {
        let mapped = NetworkError(mapping: NetworkError.contentFiltered)
        guard case .contentFiltered = mapped else {
            XCTFail("Expected contentFiltered to pass through, got \(mapped)")
            return
        }
    }

    func testMappingURLErrorNotConnectedToNoConnection() {
        let mapped = NetworkError(mapping: URLError(.notConnectedToInternet))
        guard case .noConnection = mapped else {
            XCTFail("Expected noConnection, got \(mapped)")
            return
        }
    }

    func testMappingURLErrorConnectionLostToNoConnection() {
        let mapped = NetworkError(mapping: URLError(.networkConnectionLost))
        guard case .noConnection = mapped else {
            XCTFail("Expected noConnection, got \(mapped)")
            return
        }
    }

    func testMappingURLErrorTimedOutToTimeout() {
        let mapped = NetworkError(mapping: URLError(.timedOut))
        guard case .timeout = mapped else {
            XCTFail("Expected timeout, got \(mapped)")
            return
        }
    }

    func testMappingOtherURLErrorToRequestFailed() {
        let mapped = NetworkError(mapping: URLError(.badURL))
        guard case .requestFailed = mapped else {
            XCTFail("Expected requestFailed, got \(mapped)")
            return
        }
    }

    func testMappingAFError500ToServerError() {
        let afError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 500))
        let mapped = NetworkError(mapping: afError)
        guard case .serverError(let statusCode) = mapped else {
            XCTFail("Expected serverError, got \(mapped)")
            return
        }
        XCTAssertEqual(statusCode, 500)
    }

    func testMappingAFError404ToResourceNotFound() {
        let afError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))
        let mapped = NetworkError(mapping: afError)
        guard case .resourceNotFound = mapped else {
            XCTFail("Expected resourceNotFound, got \(mapped)")
            return
        }
    }

    func testMappingAFError401ToUnauthorized() {
        let afError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
        let mapped = NetworkError(mapping: afError)
        guard case .unauthorized = mapped else {
            XCTFail("Expected unauthorized, got \(mapped)")
            return
        }
    }

    func testMappingAFErrorSerializationFailureToDecodingFailed() {
        let afError = AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
        let mapped = NetworkError(mapping: afError)
        guard case .decodingFailed = mapped else {
            XCTFail("Expected decodingFailed, got \(mapped)")
            return
        }
    }

    func testMappingAFErrorSessionTaskFailedUnwrapsUnderlyingURLError() {
        let afError = AFError.sessionTaskFailed(error: URLError(.timedOut))
        let mapped = NetworkError(mapping: afError)
        guard case .timeout = mapped else {
            XCTFail("Expected timeout, got \(mapped)")
            return
        }
    }

    func testMappingUnrecognizedErrorToUnknown() {
        let nsError = NSError(domain: "SomeDomain", code: 7)
        let mapped = NetworkError(mapping: nsError)
        guard case .unknown(let underlying) = mapped else {
            XCTFail("Expected unknown, got \(mapped)")
            return
        }
        XCTAssertEqual((underlying as? NSError)?.domain, "SomeDomain")
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
