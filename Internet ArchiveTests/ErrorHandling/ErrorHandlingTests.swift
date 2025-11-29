//
//  ErrorHandlingTests.swift
//  Internet ArchiveTests
//
//  Unit tests for error handling system
//

import XCTest
@testable import Internet_Archive

/// Thread-safe counter for testing async operations
final class AtomicCounter: @unchecked Sendable {
    private var _value: Int = 0
    private let lock = NSLock()

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func increment() {
        lock.lock()
        _value += 1
        lock.unlock()
    }
}

final class ErrorHandlingTests: XCTestCase {

    // MARK: - NetworkError Tests

    func testNetworkErrorLocalizedDescriptions() {
        XCTAssertEqual(
            NetworkError.noConnection.localizedDescription,
            "No internet connection available"
        )

        XCTAssertEqual(
            NetworkError.timeout.localizedDescription,
            "Request timed out"
        )

        XCTAssertEqual(
            NetworkError.serverError(statusCode: 500).localizedDescription,
            "Server error (HTTP 500)"
        )

        XCTAssertEqual(
            NetworkError.unauthorized.localizedDescription,
            "Unauthorized access"
        )

        XCTAssertEqual(
            NetworkError.invalidCredentials.localizedDescription,
            "Invalid email or password"
        )

        XCTAssertEqual(
            NetworkError.resourceNotFound.localizedDescription,
            "Resource not found"
        )
    }

    func testNetworkErrorServiceUnavailableMessage() {
        XCTAssertTrue(NetworkError.serviceUnavailableMessage.contains("temporarily unavailable"))
        XCTAssertTrue(NetworkError.serviceUnavailableMessage.contains("archive.org"))
    }

    // MARK: - RetryMechanism Tests

    func testRetryMechanismSuccess() async throws {
        let attemptCount = AtomicCounter()

        let result = try await RetryMechanism.execute(config: .standard) {
            attemptCount.increment()
            return "success"
        }

        XCTAssertEqual(result, "success")
        XCTAssertEqual(attemptCount.value, 1)
    }

    func testRetryMechanismRetries() async throws {
        let attemptCount = AtomicCounter()

        let result = try await RetryMechanism.execute(config: .standard) {
            attemptCount.increment()
            if attemptCount.value < 3 {
                throw NetworkError.timeout
            }
            return "success"
        }

        XCTAssertEqual(result, "success")
        XCTAssertEqual(attemptCount.value, 3)
    }

    func testRetryMechanismMaxAttemptsReached() async {
        let attemptCount = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                attemptCount.increment()
                throw NetworkError.timeout
            }
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(attemptCount.value, 3) // standard config has 3 attempts
            XCTAssertTrue(error is NetworkError)
        }
    }

    func testRetryMechanismNonRetryableError() async {
        let attemptCount = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                attemptCount.increment()
                throw NetworkError.invalidCredentials
            }
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(attemptCount.value, 1) // Non-retryable, should not retry
        }
    }

    func testRetryMechanismSingleConfig() async {
        let attemptCount = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .single) {
                attemptCount.increment()
                throw NetworkError.timeout
            }
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(attemptCount.value, 2) // single config has 2 attempts
        }
    }

    func testRetryMechanismAggressiveConfig() async {
        let attemptCount = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .aggressive) {
                attemptCount.increment()
                throw NetworkError.serverError(statusCode: 500)
            }
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(attemptCount.value, 5) // aggressive config has 5 attempts
        }
    }

    // MARK: - ErrorContext Tests

    func testErrorContextCreation() {
        let context = ErrorContext(
            operation: .search,
            userFacingTitle: "Search Failed",
            additionalInfo: ["query": "test"]
        )

        XCTAssertEqual(context.operation, .search)
        XCTAssertEqual(context.userFacingTitle, "Search Failed")
        XCTAssertNotNil(context.additionalInfo)
        XCTAssertEqual(context.additionalInfo?["query"] as? String, "test")
    }

    func testErrorOperationRawValues() {
        XCTAssertEqual(ErrorOperation.login.rawValue, "login")
        XCTAssertEqual(ErrorOperation.search.rawValue, "search")
        XCTAssertEqual(ErrorOperation.loadMedia.rawValue, "load_media")
        XCTAssertEqual(ErrorOperation.saveFavorite.rawValue, "save_favorite")
    }
}
