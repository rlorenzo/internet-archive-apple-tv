//
//  NetworkMonitor.swift
//  Internet Archive
//
//  Network reachability monitoring
//

import Foundation
import Network

/// Monitors network connectivity status
@MainActor
final class NetworkMonitor: ObservableObject {

    static let shared = NetworkMonitor()

    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: ConnectionType = .unknown

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    /// Check if running in test environment
    private static var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }

    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown
    }

    private init() {
        startMonitoring()
    }

    // MARK: - Monitoring

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                self.isConnected = path.status == .satisfied

                // Determine connection type
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .wired
                } else {
                    self.connectionType = .unknown
                }

                #if DEBUG
                // Suppress logging during tests
                if !Self.isRunningTests {
                    if self.isConnected {
                        print("🌐 Network connected (\(self.connectionType))")
                    } else {
                        print("🔴 Network disconnected")
                    }
                }
                #endif
            }
        }

        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }

    // MARK: - Offline Check

    /// Check if device is offline and throw appropriate error
    func checkConnection() throws {
        if !isConnected {
            throw NetworkError.noConnection
        }
    }

    // MARK: - Connection Quality

    /// Returns true if connection is good quality (wifi or wired)
    var hasHighQualityConnection: Bool {
        isConnected && (connectionType == .wifi || connectionType == .wired)
    }
}
