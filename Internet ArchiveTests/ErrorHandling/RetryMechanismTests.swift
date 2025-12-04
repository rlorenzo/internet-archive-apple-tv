//
//  RetryMechanismTests.swift
//  Internet ArchiveTests
//
//  Unit tests for RetryMechanism
//

import XCTest
@testable import Internet_Archive

final class RetryMechanismTests: XCTestCase {

    // MARK: - RetryConfig Tests

    func testStandardConfig_hasExpectedValues() {
        let config = RetryMechanism.RetryConfig.standard
        XCTAssertEqual(config.maxAttempts, 3)
        XCTAssertEqual(config.initialDelay, 1.0)
        XCTAssertEqual(config.maxDelay, 10.0)
        XCTAssertEqual(config.backoffMultiplier, 2.0)
    }

    func testAggressiveConfig_hasExpectedValues() {
        let config = RetryMechanism.RetryConfig.aggressive
        XCTAssertEqual(config.maxAttempts, 5)
        XCTAssertEqual(config.initialDelay, 0.5)
        XCTAssertEqual(config.maxDelay, 30.0)
        XCTAssertEqual(config.backoffMultiplier, 2.0)
    }

    func testSingleConfig_hasExpectedValues() {
        let config = RetryMechanism.RetryConfig.single
        XCTAssertEqual(config.maxAttempts, 2)
        XCTAssertEqual(config.initialDelay, 2.0)
        XCTAssertEqual(config.maxDelay, 2.0)
        XCTAssertEqual(config.backoffMultiplier, 1.0)
    }

    func testCustomConfig_hasExpectedValues() {
        let config = RetryMechanism.RetryConfig(
            maxAttempts: 10,
            initialDelay: 0.1,
            maxDelay: 5.0,
            backoffMultiplier: 1.5
        )
        XCTAssertEqual(config.maxAttempts, 10)
        XCTAssertEqual(config.initialDelay, 0.1)
        XCTAssertEqual(config.maxDelay, 5.0)
        XCTAssertEqual(config.backoffMultiplier, 1.5)
    }

    // MARK: - Execute Success Tests

    func testExecute_successOnFirstAttempt() async throws {
        let counter = AtomicCounter()

        let result = try await RetryMechanism.execute(config: .standard) {
            counter.increment()
            return "success"
        }

        XCTAssertEqual(result, "success")
        XCTAssertEqual(counter.value, 1)
    }

    func testExecute_returnsCorrectType() async throws {
        let result: Int = try await RetryMechanism.execute(config: .standard) {
            return 42
        }

        XCTAssertEqual(result, 42)
    }

    // MARK: - Execute Retry Tests

    func testExecute_retriesOnRetryableError() async throws {
        let counter = AtomicCounter()

        let result = try await RetryMechanism.execute(
            config: RetryMechanism.RetryConfig(
                maxAttempts: 3,
                initialDelay: 0.01,
                maxDelay: 0.1,
                backoffMultiplier: 1.0
            )
        ) {
            counter.increment()
            if counter.value < 3 {
                throw NetworkError.timeout
            }
            return "success after retry"
        }

        XCTAssertEqual(result, "success after retry")
        XCTAssertEqual(counter.value, 3)
    }

    // MARK: - Non-Retryable Error Tests

    func testExecute_throwsImmediatelyOnNonRetryableError() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.invalidCredentials
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 1, "Should not retry on non-retryable error")
            XCTAssertTrue(error is NetworkError)
        }
    }

    func testExecute_throwsImmediatelyOnUnauthorized() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.unauthorized
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 1)
        }
    }

    func testExecute_throwsImmediatelyOnAuthenticationFailed() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.authenticationFailed
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 1)
        }
    }

    func testExecute_throwsImmediatelyOnInvalidResponse() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.invalidResponse
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 1)
        }
    }

    func testExecute_throwsImmediatelyOnDecodingFailed() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.decodingFailed(NSError(domain: "", code: 0))
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 1)
        }
    }

    func testExecute_throwsImmediatelyOnResourceNotFound() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.resourceNotFound
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 1)
        }
    }

    func testExecute_throwsImmediatelyOnApiError() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.apiError(message: "API error")
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 1)
        }
    }

    // MARK: - Retryable Error Tests

    func testExecute_retriesOnTimeout() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(
                config: RetryMechanism.RetryConfig(
                    maxAttempts: 2,
                    initialDelay: 0.01,
                    maxDelay: 0.01,
                    backoffMultiplier: 1.0
                )
            ) {
                counter.increment()
                throw NetworkError.timeout
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 2, "Should retry on timeout")
        }
    }

    func testExecute_retriesOnServerError500() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(
                config: RetryMechanism.RetryConfig(
                    maxAttempts: 2,
                    initialDelay: 0.01,
                    maxDelay: 0.01,
                    backoffMultiplier: 1.0
                )
            ) {
                counter.increment()
                throw NetworkError.serverError(statusCode: 500)
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 2, "Should retry on 500 error")
        }
    }

    func testExecute_retriesOnServerError503() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(
                config: RetryMechanism.RetryConfig(
                    maxAttempts: 2,
                    initialDelay: 0.01,
                    maxDelay: 0.01,
                    backoffMultiplier: 1.0
                )
            ) {
                counter.increment()
                throw NetworkError.serverError(statusCode: 503)
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 2, "Should retry on 503 error")
        }
    }

    func testExecute_doesNotRetryOnServerError400() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.serverError(statusCode: 400)
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 1, "Should not retry on 400 error")
        }
    }

    func testExecute_doesNotRetryOnServerError404() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.serverError(statusCode: 404)
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 1, "Should not retry on 404 error")
        }
    }

    // MARK: - Custom Should Retry Tests

    func testExecute_usesCustomShouldRetry() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(
                config: RetryMechanism.RetryConfig(
                    maxAttempts: 3,
                    initialDelay: 0.01,
                    maxDelay: 0.01,
                    backoffMultiplier: 1.0
                ),
                shouldRetry: { _ in false }
            ) {
                counter.increment()
                throw NetworkError.timeout
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 1, "Custom shouldRetry should prevent retry")
        }
    }

    func testExecute_customShouldRetry_allowsRetry() async {
        // Note: shouldRetry returning true means "don't skip retry based on this check",
        // but the isRetryable check still happens. Use a retryable error here.
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(
                config: RetryMechanism.RetryConfig(
                    maxAttempts: 2,
                    initialDelay: 0.01,
                    maxDelay: 0.01,
                    backoffMultiplier: 1.0
                ),
                shouldRetry: { _ in true }
            ) {
                counter.increment()
                throw NetworkError.timeout // Retryable error
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 2, "Custom shouldRetry should allow retry")
        }
    }

    // MARK: - Max Attempts Tests

    func testExecute_stopsAtMaxAttempts() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(
                config: RetryMechanism.RetryConfig(
                    maxAttempts: 5,
                    initialDelay: 0.01,
                    maxDelay: 0.01,
                    backoffMultiplier: 1.0
                )
            ) {
                counter.increment()
                throw NetworkError.timeout
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 5)
        }
    }

    func testExecute_singleAttemptConfig() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(
                config: RetryMechanism.RetryConfig(
                    maxAttempts: 1,
                    initialDelay: 0.01,
                    maxDelay: 0.01,
                    backoffMultiplier: 1.0
                )
            ) {
                counter.increment()
                throw NetworkError.timeout
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(counter.value, 1)
        }
    }
}
