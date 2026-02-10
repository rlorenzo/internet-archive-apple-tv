//
//  TestHelpers+SwiftTesting.swift
//  Internet ArchiveTests
//
//  Shared helpers for Swift Testing based tests
//

import Foundation
import Combine
import Testing
@testable import Internet_Archive

// MARK: - Async Helpers

/// Thread-safe state container for publisher awaiting.
private final class PublisherAwaiter<Output: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var cancellable: AnyCancellable?
    private var didResume = false

    func await(
        publisher: some Publisher<Output, Never>,
        timeout: TimeInterval,
        continuation: CheckedContinuation<Output, any Error>
    ) {
        cancellable = publisher
            .first()
            .timeout(.seconds(timeout), scheduler: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    lock.lock()
                    defer { lock.unlock() }
                    guard !didResume else { return }
                    didResume = true
                    cancellable?.cancel()
                    if case .failure = completion {
                        continuation.resume(throwing: TestError.timeout)
                    }
                },
                receiveValue: { [self] value in
                    lock.lock()
                    defer { lock.unlock() }
                    guard !didResume else { return }
                    didResume = true
                    cancellable?.cancel()
                    continuation.resume(returning: value)
                }
            )

        // Fallback timeout for publishers that complete without emitting
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout + 0.1) { [self] in
            lock.lock()
            defer { lock.unlock() }
            guard !didResume else { return }
            didResume = true
            cancellable?.cancel()
            continuation.resume(throwing: TestError.timeout)
        }
    }
}

/// Wait for a Combine publisher to emit a value within a timeout.
///
/// Converts a Combine publisher into an async value, with a configurable timeout.
/// Useful for testing code that uses `@Published` properties or Combine pipelines.
///
/// ## Example Usage
///
/// ```swift
/// let value = try await awaitPublisher(viewModel.$items.dropFirst())
/// #expect(value.count == 3)
/// ```
///
/// - Parameters:
///   - publisher: The Combine publisher to await
///   - timeout: Maximum time to wait for a value (default: 2 seconds)
/// - Returns: The first emitted value
/// - Throws: `TestError.timeout` if no value is emitted within the timeout
func awaitPublisher<Output: Sendable>(
    _ publisher: some Publisher<Output, Never>,
    timeout: TimeInterval = 2.0
) async throws -> Output {
    let awaiter = PublisherAwaiter<Output>()
    return try await withCheckedThrowingContinuation { continuation in
        awaiter.await(publisher: publisher, timeout: timeout, continuation: continuation)
    }
}

// MARK: - Floating Point Comparison

extension FloatingPoint {
    /// Check if two floating point values are approximately equal within a tolerance.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// #expect(calculatedValue.isApproximatelyEqual(to: 3.14, tolerance: 0.01))
    /// ```
    func isApproximatelyEqual(to other: Self, tolerance: Self) -> Bool {
        abs(self - other) <= tolerance
    }
}

// MARK: - Test Error

/// Standard error type for use in test mocks and helpers.
///
/// Provides common error cases for simulating failures in mock objects.
enum TestError: Error, Sendable {
    /// Simulates a network failure
    case networkError
    /// Operation exceeded the expected time limit
    case timeout
    /// Requested resource was not found
    case notFound
    /// Generic mock failure with a custom message
    case mockFailure(String)
}
