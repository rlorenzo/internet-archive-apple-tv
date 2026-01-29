//
//  MockNetworkMonitor.swift
//  Internet ArchiveTests
//
//  Mock network monitor for deterministic testing of network-dependent code paths.
//

import Foundation
@testable import Internet_Archive

/// A mock implementation of `NetworkMonitorProtocol` for testing.
///
/// This mock allows tests to simulate different network connectivity states
/// without relying on actual network conditions. Use the `simulate*` methods
/// to set up the desired state before running tests.
///
/// ## Example Usage
///
/// ```swift
/// @MainActor
/// func testOfflineBehavior() async throws {
///     let mockMonitor = MockNetworkMonitor()
///     mockMonitor.simulateDisconnected()
///
///     do {
///         try await RetryMechanism.execute(networkMonitor: mockMonitor) {
///             return "success"
///         }
///         XCTFail("Should throw noConnection error")
///     } catch {
///         XCTAssertEqual(error as? NetworkError, .noConnection)
///     }
/// }
/// ```
@MainActor
final class MockNetworkMonitor: NetworkMonitorProtocol {

    // MARK: - Protocol Properties

    var isConnected: Bool = true
    var connectionType: NetworkConnectionType = .wifi

    // MARK: - Computed Properties

    var hasHighQualityConnection: Bool {
        isConnected && (connectionType == .wifi || connectionType == .wired)
    }

    // MARK: - Protocol Methods

    func checkConnection() throws {
        checkConnectionCallCount += 1
        if !isConnected {
            throw NetworkError.noConnection
        }
    }

    // MARK: - Test Recording

    /// Number of times `checkConnection()` was called.
    private(set) var checkConnectionCallCount = 0

    // MARK: - Simulation Methods

    /// Simulates a connected state via WiFi.
    func simulateConnected() {
        isConnected = true
        connectionType = .wifi
    }

    /// Simulates a connected state via cellular.
    func simulateCellular() {
        isConnected = true
        connectionType = .cellular
    }

    /// Simulates a connected state via wired Ethernet.
    func simulateWired() {
        isConnected = true
        connectionType = .wired
    }

    /// Simulates a disconnected state.
    func simulateDisconnected() {
        isConnected = false
        connectionType = .unknown
    }

    /// Resets the mock to its default connected state and clears call counts.
    func reset() {
        isConnected = true
        connectionType = .wifi
        checkConnectionCallCount = 0
    }
}
