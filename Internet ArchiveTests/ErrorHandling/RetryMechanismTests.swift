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

// MARK: - Network Injection Tests

/// Tests for RetryMechanism using MockNetworkMonitor dependency injection.
/// These tests verify network-dependent behavior without relying on actual connectivity.
@MainActor
final class RetryMechanismNetworkInjectionTests: XCTestCase {

    var mockMonitor: MockNetworkMonitor!

    override func setUp() async throws {
        try await super.setUp()
        mockMonitor = MockNetworkMonitor()
    }

    override func tearDown() async throws {
        mockMonitor = nil
        try await super.tearDown()
    }

    // MARK: - Offline Path Tests

    func testExecute_withOfflineMonitor_throwsNoConnectionImmediately() async {
        mockMonitor.simulateDisconnected()
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(
                config: .standard,
                networkMonitor: mockMonitor
            ) {
                counter.increment()
                return "success"
            }
            XCTFail("Expected noConnection error")
        } catch {
            if case .noConnection = error as? NetworkError {
                // Expected
            } else {
                XCTFail("Expected noConnection error, got \(error)")
            }
            // Operation should not have been attempted
            XCTAssertEqual(counter.value, 0, "Operation should not run when offline")
        }
    }

    func testExecute_withOfflineMonitor_doesNotRetry() async {
        mockMonitor.simulateDisconnected()

        do {
            _ = try await RetryMechanism.execute(
                config: RetryMechanism.RetryConfig(
                    maxAttempts: 5,
                    initialDelay: 0.01,
                    maxDelay: 0.01,
                    backoffMultiplier: 1.0
                ),
                networkMonitor: mockMonitor
            ) {
                return "success"
            }
            XCTFail("Expected noConnection error")
        } catch {
            // Should throw immediately on first connection check
            XCTAssertEqual(mockMonitor.checkConnectionCallCount, 1)
        }
    }

    // MARK: - Online Path Tests

    func testExecute_withOnlineMonitor_succeedsNormally() async throws {
        mockMonitor.simulateConnected()
        let counter = AtomicCounter()

        let result = try await RetryMechanism.execute(
            config: .standard,
            networkMonitor: mockMonitor
        ) {
            counter.increment()
            return "success"
        }

        XCTAssertEqual(result, "success")
        XCTAssertEqual(counter.value, 1)
        XCTAssertEqual(mockMonitor.checkConnectionCallCount, 1)
    }

    func testExecute_withOnlineMonitor_retriesOnFailure() async throws {
        mockMonitor.simulateConnected()
        let counter = AtomicCounter()

        let result = try await RetryMechanism.execute(
            config: RetryMechanism.RetryConfig(
                maxAttempts: 3,
                initialDelay: 0.01,
                maxDelay: 0.01,
                backoffMultiplier: 1.0
            ),
            networkMonitor: mockMonitor
        ) {
            counter.increment()
            if counter.value < 3 {
                throw NetworkError.timeout
            }
            return "success after retry"
        }

        XCTAssertEqual(result, "success after retry")
        XCTAssertEqual(counter.value, 3)
        // Connection should be checked before each attempt
        XCTAssertEqual(mockMonitor.checkConnectionCallCount, 3)
    }

    // MARK: - Network State Transition Tests

    func testExecute_networkBecomesOffline_stopsRetrying() async {
        // Start online, then go offline after first attempt
        mockMonitor.simulateConnected()
        let counter = AtomicCounter()
        let monitor = mockMonitor!  // Capture locally for use in closure

        do {
            _ = try await RetryMechanism.execute(
                config: RetryMechanism.RetryConfig(
                    maxAttempts: 5,
                    initialDelay: 0.01,
                    maxDelay: 0.01,
                    backoffMultiplier: 1.0
                ),
                networkMonitor: monitor
            ) { @MainActor in
                counter.increment()
                // Go offline after first attempt
                if counter.value == 1 {
                    monitor.simulateDisconnected()
                }
                throw NetworkError.timeout
            }
            XCTFail("Expected error to be thrown")
        } catch {
            // Should have attempted once, then failed on network check for retry
            XCTAssertEqual(counter.value, 1)
            if case .noConnection = error as? NetworkError {
                // Expected
            } else {
                XCTFail("Expected noConnection error, got \(error)")
            }
        }
    }

    // MARK: - Connection Type Tests

    func testExecute_withCellularConnection_succeeds() async throws {
        mockMonitor.simulateCellular()

        let result = try await RetryMechanism.execute(
            config: .standard,
            networkMonitor: mockMonitor
        ) {
            return "success on cellular"
        }

        XCTAssertEqual(result, "success on cellular")
    }

    func testExecute_withWiredConnection_succeeds() async throws {
        mockMonitor.simulateWired()

        let result = try await RetryMechanism.execute(
            config: .standard,
            networkMonitor: mockMonitor
        ) {
            return "success on wired"
        }

        XCTAssertEqual(result, "success on wired")
    }

    // MARK: - Static vs Instance Method Parity

    func testExecute_staticMethodUsesSharedMonitor() async throws {
        // This test verifies the static method works (uses NetworkMonitor.shared)
        // We can't easily mock it, but we can verify the method signature exists
        let result = try await RetryMechanism.execute(config: .standard) {
            return "static method works"
        }

        XCTAssertEqual(result, "static method works")
    }

    func testExecute_injectableMethodAcceptsNil() async throws {
        // Passing nil should fall back to NetworkMonitor.shared
        let result = try await RetryMechanism.execute(
            config: .standard,
            networkMonitor: nil
        ) {
            return "nil monitor works"
        }

        XCTAssertEqual(result, "nil monitor works")
    }
}
