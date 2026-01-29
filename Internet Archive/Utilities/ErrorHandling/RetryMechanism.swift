//
//  RetryMechanism.swift
//  Internet Archive
//
//  Automatic retry logic for failed operations
//

import Foundation

/// Provides automatic retry logic for async operations.
///
/// Supports dependency injection of a `NetworkMonitorProtocol` for deterministic testing.
/// When no monitor is provided, uses the shared `NetworkMonitor.shared` singleton.
struct RetryMechanism {

    /// Check if running in test environment
    private static var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }

    /// Retry configuration
    struct RetryConfig {
        let maxAttempts: Int
        let initialDelay: TimeInterval
        let maxDelay: TimeInterval
        let backoffMultiplier: Double

        /// Standard retry configuration for API calls
        static let standard = RetryConfig(
            maxAttempts: 3,
            initialDelay: 1.0,
            maxDelay: 10.0,
            backoffMultiplier: 2.0
        )

        /// Aggressive retry configuration for critical operations
        static let aggressive = RetryConfig(
            maxAttempts: 5,
            initialDelay: 0.5,
            maxDelay: 30.0,
            backoffMultiplier: 2.0
        )

        /// Single retry configuration for less critical operations
        static let single = RetryConfig(
            maxAttempts: 2,
            initialDelay: 2.0,
            maxDelay: 2.0,
            backoffMultiplier: 1.0
        )
    }

    // MARK: - Retry Logic

    /// Execute an async operation with automatic retry on failure (static convenience).
    ///
    /// This is the primary API for most use cases. Uses `NetworkMonitor.shared` for connectivity checks.
    /// Network check runs on MainActor, but the operation itself runs off the main thread.
    ///
    /// - Parameters:
    ///   - config: Retry configuration
    ///   - shouldRetry: Optional closure to determine if error is retryable
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation
    static func execute<T>(
        config: RetryConfig = .standard,
        shouldRetry: ((Error) -> Bool)? = nil,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var delay = config.initialDelay

        for attempt in 1...config.maxAttempts {
            do {
                // Check network connection before attempting (requires MainActor for NetworkMonitor)
                try await MainActor.run {
                    try NetworkMonitor.shared.checkConnection()
                }

                // Execute the operation
                let result = try await operation()

                // Log success on retry (suppressed during tests)
                if attempt > 1 && !isRunningTests {
                    await MainActor.run {
                        ErrorLogger.shared.logWarning(
                            "Succeeded on attempt \(attempt)",
                            operation: .unknown
                        )
                    }
                }

                return result

            } catch {
                lastError = error

                // Check if we should retry this error
                if let shouldRetry = shouldRetry, !shouldRetry(error) {
                    throw error
                }

                // Check if error is retryable
                if !isRetryable(error) {
                    throw error
                }

                // Don't retry on last attempt
                if attempt == config.maxAttempts {
                    break
                }

                // Log retry attempt (suppressed during tests)
                if !isRunningTests {
                    let errorDescription = error.localizedDescription
                    await MainActor.run {
                        ErrorLogger.shared.logWarning(
                            "Attempt \(attempt) failed, retrying in \(String(format: "%.1f", delay))s: \(errorDescription)",
                            operation: .unknown
                        )
                    }
                }

                // Wait before retrying with exponential backoff
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                // Increase delay with exponential backoff
                delay = min(delay * config.backoffMultiplier, config.maxDelay)
            }
        }

        // All retries failed, throw the last error
        throw lastError ?? NetworkError.unknown(nil)
    }

    /// Execute an async operation with automatic retry on failure with injected network monitor.
    ///
    /// Use this overload for testing with a mock network monitor.
    /// This method runs on MainActor to safely access the injected network monitor.
    ///
    /// - Parameters:
    ///   - config: Retry configuration
    ///   - networkMonitor: Optional network monitor for dependency injection. If nil, uses `NetworkMonitor.shared`.
    ///   - shouldRetry: Optional closure to determine if error is retryable
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation
    @MainActor
    static func execute<T>(
        config: RetryConfig = .standard,
        networkMonitor: (any NetworkMonitorProtocol)? = nil,
        shouldRetry: ((Error) -> Bool)? = nil,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var delay = config.initialDelay

        for attempt in 1...config.maxAttempts {
            do {
                // Check network connection before attempting
                if let monitor = networkMonitor {
                    try monitor.checkConnection()
                } else {
                    try NetworkMonitor.shared.checkConnection()
                }

                // Execute the operation
                let result = try await operation()

                // Log success on retry (suppressed during tests)
                if attempt > 1 && !isRunningTests {
                    ErrorLogger.shared.logWarning(
                        "Succeeded on attempt \(attempt)",
                        operation: .unknown
                    )
                }

                return result

            } catch {
                lastError = error

                // Check if we should retry this error
                if let shouldRetry = shouldRetry, !shouldRetry(error) {
                    throw error
                }

                // Check if error is retryable
                if !isRetryable(error) {
                    throw error
                }

                // Don't retry on last attempt
                if attempt == config.maxAttempts {
                    break
                }

                // Log retry attempt (suppressed during tests)
                if !isRunningTests {
                    ErrorLogger.shared.logWarning(
                        "Attempt \(attempt) failed, retrying in \(String(format: "%.1f", delay))s: \(error.localizedDescription)",
                        operation: .unknown
                    )
                }

                // Wait before retrying with exponential backoff
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                // Increase delay with exponential backoff
                delay = min(delay * config.backoffMultiplier, config.maxDelay)
            }
        }

        // All retries failed, throw the last error
        throw lastError ?? NetworkError.unknown(nil)
    }

    // MARK: - Retryable Error Detection

    /// Determine if an error is retryable
    private static func isRetryable(_ error: Error) -> Bool {
        if let networkError = error as? NetworkError {
            switch networkError {
            // Retryable network errors
            case .timeout:
                return true

            // No connection is not retryable - no point retrying when offline
            case .noConnection:
                return false

            // Retryable server errors (5xx)
            case .serverError(let statusCode):
                return statusCode >= 500

            // Retryable request failures (depends on underlying error)
            case .requestFailed:
                return true

            // Non-retryable errors
            case .unauthorized, .authenticationFailed, .invalidCredentials:
                return false

            case .invalidResponse, .decodingFailed, .invalidData:
                return false

            case .apiError, .resourceNotFound, .invalidParameters:
                return false

            case .cookieRetrievalFailed:
                return false

            case .contentFiltered:
                return false  // Content filtered items should not be retried

            case .unknown:
                return true
            }
        }

        // By default, don't retry unknown errors
        return false
    }
}
