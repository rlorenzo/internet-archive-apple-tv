//
//  RetryMechanismTests.swift
//  Internet ArchiveTests
//
//  Unit tests for RetryMechanism
//

import Foundation
import Testing
@testable import Internet_Archive

@Suite("RetryMechanism Tests")
struct RetryMechanismTests {

    // MARK: - RetryConfig Tests

    @Test func standardConfig_hasExpectedValues() {
        let config = RetryMechanism.RetryConfig.standard
        #expect(config.maxAttempts == 3)
        #expect(config.initialDelay == 1.0)
        #expect(config.maxDelay == 10.0)
        #expect(config.backoffMultiplier == 2.0)
    }

    @Test func aggressiveConfig_hasExpectedValues() {
        let config = RetryMechanism.RetryConfig.aggressive
        #expect(config.maxAttempts == 5)
        #expect(config.initialDelay == 0.5)
        #expect(config.maxDelay == 30.0)
        #expect(config.backoffMultiplier == 2.0)
    }

    @Test func singleConfig_hasExpectedValues() {
        let config = RetryMechanism.RetryConfig.single
        #expect(config.maxAttempts == 2)
        #expect(config.initialDelay == 2.0)
        #expect(config.maxDelay == 2.0)
        #expect(config.backoffMultiplier == 1.0)
    }

    @Test func customConfig_hasExpectedValues() {
        let config = RetryMechanism.RetryConfig(
            maxAttempts: 10,
            initialDelay: 0.1,
            maxDelay: 5.0,
            backoffMultiplier: 1.5
        )
        #expect(config.maxAttempts == 10)
        #expect(config.initialDelay == 0.1)
        #expect(config.maxDelay == 5.0)
        #expect(config.backoffMultiplier == 1.5)
    }

    // MARK: - Execute Success Tests

    @Test func execute_successOnFirstAttempt() async throws {
        let counter = AtomicCounter()

        let result = try await RetryMechanism.execute(config: .standard) {
            counter.increment()
            return "success"
        }

        #expect(result == "success")
        #expect(counter.value == 1)
    }

    @Test func execute_returnsCorrectType() async throws {
        let result: Int = try await RetryMechanism.execute(config: .standard) {
            return 42
        }

        #expect(result == 42)
    }

    // MARK: - Execute Retry Tests

    @Test func execute_retriesOnRetryableError() async throws {
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

        #expect(result == "success after retry")
        #expect(counter.value == 3)
    }

    // MARK: - Non-Retryable Error Tests

    @Test func execute_throwsImmediatelyOnNonRetryableError() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.invalidCredentials
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 1, "Should not retry on non-retryable error")
            #expect(error is NetworkError)
        }
    }

    @Test func execute_throwsImmediatelyOnUnauthorized() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.unauthorized
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 1)
        }
    }

    @Test func execute_throwsImmediatelyOnAuthenticationFailed() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.authenticationFailed
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 1)
        }
    }

    @Test func execute_throwsImmediatelyOnInvalidResponse() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.invalidResponse
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 1)
        }
    }

    @Test func execute_throwsImmediatelyOnDecodingFailed() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.decodingFailed(NSError(domain: "", code: 0))
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 1)
        }
    }

    @Test func execute_throwsImmediatelyOnResourceNotFound() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.resourceNotFound
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 1)
        }
    }

    @Test func execute_throwsImmediatelyOnApiError() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.apiError(message: "API error")
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 1)
        }
    }

    // MARK: - Retryable Error Tests

    @Test func execute_retriesOnTimeout() async {
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
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 2, "Should retry on timeout")
        }
    }

    @Test func execute_retriesOnServerError500() async {
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
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 2, "Should retry on 500 error")
        }
    }

    @Test func execute_retriesOnServerError503() async {
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
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 2, "Should retry on 503 error")
        }
    }

    @Test func execute_doesNotRetryOnServerError400() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.serverError(statusCode: 400)
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 1, "Should not retry on 400 error")
        }
    }

    @Test func execute_doesNotRetryOnServerError404() async {
        let counter = AtomicCounter()

        do {
            _ = try await RetryMechanism.execute(config: .standard) {
                counter.increment()
                throw NetworkError.serverError(statusCode: 404)
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 1, "Should not retry on 404 error")
        }
    }

    // MARK: - Custom Should Retry Tests

    @Test func execute_usesCustomShouldRetry() async {
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
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 1, "Custom shouldRetry should prevent retry")
        }
    }

    @Test func execute_customShouldRetry_allowsRetry() async {
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
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 2, "Custom shouldRetry should allow retry")
        }
    }

    // MARK: - Max Attempts Tests

    @Test func execute_stopsAtMaxAttempts() async {
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
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 5)
        }
    }

    @Test func execute_singleAttemptConfig() async {
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
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(counter.value == 1)
        }
    }
}

// MARK: - Network Injection Tests

/// Tests for RetryMechanism using MockNetworkMonitor dependency injection.
/// These tests verify network-dependent behavior without relying on actual connectivity.
@Suite("RetryMechanism Network Injection Tests")
@MainActor
struct RetryMechanismNetworkInjectionTests {

    var mockMonitor: MockNetworkMonitor

    init() {
        mockMonitor = MockNetworkMonitor()
    }

    // MARK: - Offline Path Tests

    @Test func execute_withOfflineMonitor_throwsNoConnectionImmediately() async {
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
            Issue.record("Expected noConnection error")
        } catch {
            if case .noConnection = error as? NetworkError {
                // Expected
            } else {
                Issue.record("Expected noConnection error, got \(error)")
            }
            // Operation should not have been attempted
            #expect(counter.value == 0, "Operation should not run when offline")
        }
    }

    @Test func execute_withOfflineMonitor_doesNotRetry() async {
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
            Issue.record("Expected noConnection error")
        } catch {
            // Should throw immediately on first connection check
            #expect(mockMonitor.checkConnectionCallCount == 1)
        }
    }

    // MARK: - Online Path Tests

    @Test func execute_withOnlineMonitor_succeedsNormally() async throws {
        mockMonitor.simulateConnected()
        let counter = AtomicCounter()

        let result = try await RetryMechanism.execute(
            config: .standard,
            networkMonitor: mockMonitor
        ) {
            counter.increment()
            return "success"
        }

        #expect(result == "success")
        #expect(counter.value == 1)
        #expect(mockMonitor.checkConnectionCallCount == 1)
    }

    @Test func execute_withOnlineMonitor_retriesOnFailure() async throws {
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

        #expect(result == "success after retry")
        #expect(counter.value == 3)
        // Connection should be checked before each attempt
        #expect(mockMonitor.checkConnectionCallCount == 3)
    }

    // MARK: - Network State Transition Tests

    @Test func execute_networkBecomesOffline_stopsRetrying() async {
        // Start online, then go offline after first attempt
        mockMonitor.simulateConnected()
        let counter = AtomicCounter()
        let monitor = mockMonitor  // Capture locally for use in closure

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
            Issue.record("Expected error to be thrown")
        } catch {
            // Should have attempted once, then failed on network check for retry
            #expect(counter.value == 1)
            if case .noConnection = error as? NetworkError {
                // Expected
            } else {
                Issue.record("Expected noConnection error, got \(error)")
            }
        }
    }

    // MARK: - Connection Type Tests

    @Test func execute_withCellularConnection_succeeds() async throws {
        mockMonitor.simulateCellular()

        let result = try await RetryMechanism.execute(
            config: .standard,
            networkMonitor: mockMonitor
        ) {
            return "success on cellular"
        }

        #expect(result == "success on cellular")
    }

    @Test func execute_withWiredConnection_succeeds() async throws {
        mockMonitor.simulateWired()

        let result = try await RetryMechanism.execute(
            config: .standard,
            networkMonitor: mockMonitor
        ) {
            return "success on wired"
        }

        #expect(result == "success on wired")
    }

    // MARK: - Static vs Instance Method Parity

    @Test func execute_staticMethodUsesSharedMonitor() async throws {
        // This test verifies the static method works (uses NetworkMonitor.shared)
        // We can't easily mock it, but we can verify the method signature exists
        let result = try await RetryMechanism.execute(config: .standard) {
            return "static method works"
        }

        #expect(result == "static method works")
    }

    @Test func execute_injectableMethodAcceptsNil() async throws {
        // Passing nil should fall back to NetworkMonitor.shared
        let result = try await RetryMechanism.execute(
            config: .standard,
            networkMonitor: nil
        ) {
            return "nil monitor works"
        }

        #expect(result == "nil monitor works")
    }
}
