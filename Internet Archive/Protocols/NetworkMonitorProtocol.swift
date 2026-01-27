//
//  NetworkMonitorProtocol.swift
//  Internet Archive
//
//  Protocol for network monitoring to enable dependency injection and testing.
//

import Foundation

/// Protocol defining the interface for network connectivity monitoring.
///
/// This protocol enables dependency injection for testing network-dependent code paths
/// without relying on actual network connectivity. The production implementation
/// (`NetworkMonitor`) monitors real network state, while `MockNetworkMonitor` can
/// simulate different connectivity scenarios for deterministic testing.
///
/// ## Example Usage
///
/// ```swift
/// // In production code, use the shared instance
/// let monitor: NetworkMonitorProtocol = NetworkMonitor.shared
///
/// // In tests, inject a mock
/// let mockMonitor = MockNetworkMonitor()
/// mockMonitor.simulateConnected()
/// ```
///
/// ## Main Actor Isolation
///
/// All properties and methods are accessed from the main actor to ensure
/// thread-safe access to connectivity state from UI code.
@MainActor
public protocol NetworkMonitorProtocol: AnyObject {

    // MARK: - Connection State

    /// Whether the device currently has network connectivity.
    ///
    /// Returns `true` when any network path (WiFi, cellular, wired) is available
    /// and satisfies connectivity requirements.
    var isConnected: Bool { get }

    /// The current type of network connection.
    ///
    /// Indicates whether the device is connected via WiFi, cellular, wired Ethernet,
    /// or unknown network type.
    var connectionType: NetworkConnectionType { get }

    // MARK: - Connection Quality

    /// Whether the current connection is high-quality (WiFi or wired).
    ///
    /// Returns `true` if connected via WiFi or wired Ethernet, which typically
    /// provide higher bandwidth and lower latency than cellular connections.
    var hasHighQualityConnection: Bool { get }

    // MARK: - Connection Check

    /// Throws an error if the device is offline.
    ///
    /// Use this method to preemptively check network connectivity before
    /// making network requests.
    ///
    /// - Throws: `NetworkError.noConnection` if the device is offline.
    func checkConnection() throws
}

/// Represents the type of network connection.
///
/// This enum is used by both the protocol and implementation to describe
/// the current network interface type.
public enum NetworkConnectionType: Hashable, Sendable {
    /// Connected via WiFi.
    case wifi
    /// Connected via cellular data (3G, 4G, 5G).
    case cellular
    /// Connected via wired Ethernet (common on Apple TV).
    case wired
    /// Connection type cannot be determined.
    case unknown
}
