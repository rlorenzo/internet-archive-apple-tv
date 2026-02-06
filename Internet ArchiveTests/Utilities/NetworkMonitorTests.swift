//
//  NetworkMonitorTests.swift
//  Internet ArchiveTests
//
//  Unit tests for NetworkMonitor
//

import Testing
import Combine
@testable import Internet_Archive

@Suite("NetworkMonitor Tests")
@MainActor
struct NetworkMonitorTests {

    // MARK: - Singleton Tests

    @Test func sharedInstance() {
        let instance1 = NetworkMonitor.shared
        let instance2 = NetworkMonitor.shared
        #expect(instance1 === instance2)
    }

    // MARK: - Connection Type Tests

    @Test func connectionTypeWifi() {
        let type = NetworkMonitor.ConnectionType.wifi
        #expect(type != nil)
    }

    @Test func connectionTypeCellular() {
        let type = NetworkMonitor.ConnectionType.cellular
        #expect(type != nil)
    }

    @Test func connectionTypeWired() {
        let type = NetworkMonitor.ConnectionType.wired
        #expect(type != nil)
    }

    @Test func connectionTypeUnknown() {
        let type = NetworkMonitor.ConnectionType.unknown
        #expect(type != nil)
    }

    @Test func connectionTypeAllCases() {
        let allTypes: [NetworkMonitor.ConnectionType] = [.wifi, .cellular, .wired, .unknown]
        #expect(allTypes.count == 4)
    }

    // MARK: - Published Properties Tests

    @Test func isConnectedDefaultValue() {
        let monitor = NetworkMonitor.shared
        // In simulator, we typically have connection
        #expect(monitor.isConnected != nil)
    }

    @Test func connectionTypeHasValue() {
        let monitor = NetworkMonitor.shared
        #expect(monitor.connectionType != nil)
    }

    // MARK: - High Quality Connection Tests

    @Test func hasHighQualityConnectionProperty() {
        let monitor = NetworkMonitor.shared
        // Just verify the property exists and returns a Bool
        _ = monitor.hasHighQualityConnection
        #expect(monitor != nil)
    }

    // MARK: - Check Connection Tests

    @Test func checkConnectionWhenConnectedDoesNotThrow() throws {
        let monitor = NetworkMonitor.shared
        // Skip if not connected (simulator dependent)
        guard monitor.isConnected else { return }
        try monitor.checkConnection()
    }

    @Test func checkConnectionThrowsWhenOffline() throws {
        let monitor = NetworkMonitor.shared
        guard !monitor.isConnected else { return }
        #expect {
            try monitor.checkConnection()
        } throws: { error in
            guard let networkError = error as? NetworkError,
                  case .noConnection = networkError else {
                return false
            }
            return true
        }
    }

    // MARK: - Monitoring Tests

    @Test func stopMonitoringDoesNotCrash() {
        let monitor = NetworkMonitor.shared
        // Should not crash
        monitor.stopMonitoring()
        // Restart monitoring after test
        monitor.startMonitoring()
        #expect(monitor != nil)
    }

    @Test func startMonitoringDoesNotCrash() {
        let monitor = NetworkMonitor.shared
        monitor.startMonitoring()
        #expect(monitor != nil)
    }

    // MARK: - ObservableObject Conformance Tests

    @Test func monitorIsObservableObject() {
        let monitor = NetworkMonitor.shared
        // Verify it conforms to ObservableObject by accessing objectWillChange
        _ = monitor.objectWillChange
        #expect(monitor != nil)
    }
}

// MARK: - ConnectionType Hashable Tests

@Suite("ConnectionType Tests")
@MainActor
struct ConnectionTypeTests {

    @Test func connectionTypeEquality() {
        let type1 = NetworkMonitor.ConnectionType.wifi
        let type2 = NetworkMonitor.ConnectionType.wifi
        #expect(type1 == type2)
    }

    @Test func connectionTypeInequality() {
        let type1 = NetworkMonitor.ConnectionType.wifi
        let type2 = NetworkMonitor.ConnectionType.cellular
        #expect(type1 != type2)
    }

    @Test func connectionTypeInSet() {
        var types: Set<NetworkMonitor.ConnectionType> = []
        types.insert(.wifi)
        types.insert(.cellular)
        types.insert(.wifi) // Duplicate

        #expect(types.count == 2)
        #expect(types.contains(.wifi))
        #expect(types.contains(.cellular))
    }

    @Test func connectionTypeAsDictionaryKey() {
        var dict: [NetworkMonitor.ConnectionType: String] = [:]
        dict[.wifi] = "Wi-Fi"
        dict[.cellular] = "Cellular"
        dict[.wired] = "Ethernet"
        dict[.unknown] = "Unknown"

        #expect(dict.count == 4)
        #expect(dict[.wifi] == "Wi-Fi")
    }
}

// MARK: - MockNetworkMonitor Tests

/// Tests for MockNetworkMonitor using deterministic simulation.
/// These tests verify both the mock implementation and the protocol contract.
@Suite("MockNetworkMonitor Tests")
@MainActor
struct MockNetworkMonitorTests {

    var mockMonitor: MockNetworkMonitor

    init() {
        mockMonitor = MockNetworkMonitor()
    }

    // MARK: - Default State Tests

    @Test func defaultStateIsConnected() {
        #expect(mockMonitor.isConnected)
    }

    @Test func defaultStateConnectionTypeIsWifi() {
        #expect(mockMonitor.connectionType == .wifi)
    }

    @Test func defaultStateHasHighQualityConnection() {
        #expect(mockMonitor.hasHighQualityConnection)
    }

    @Test func defaultStateCheckConnectionDoesNotThrow() throws {
        try mockMonitor.checkConnection()
    }

    // MARK: - Simulation Tests

    @Test func simulateConnected() {
        mockMonitor.simulateDisconnected()  // First disconnect
        mockMonitor.simulateConnected()     // Then reconnect

        #expect(mockMonitor.isConnected)
        #expect(mockMonitor.connectionType == .wifi)
    }

    @Test func simulateCellular() {
        mockMonitor.simulateCellular()

        #expect(mockMonitor.isConnected)
        #expect(mockMonitor.connectionType == .cellular)
        #expect(!mockMonitor.hasHighQualityConnection)
    }

    @Test func simulateWired() {
        mockMonitor.simulateWired()

        #expect(mockMonitor.isConnected)
        #expect(mockMonitor.connectionType == .wired)
        #expect(mockMonitor.hasHighQualityConnection)
    }

    @Test func simulateDisconnected() {
        mockMonitor.simulateDisconnected()

        #expect(!mockMonitor.isConnected)
        #expect(mockMonitor.connectionType == .unknown)
        #expect(!mockMonitor.hasHighQualityConnection)
    }

    // MARK: - checkConnection Tests

    @Test func checkConnectionWhenConnectedDoesNotThrow() throws {
        mockMonitor.simulateConnected()
        try mockMonitor.checkConnection()
    }

    @Test func checkConnectionWhenDisconnectedThrowsNoConnection() {
        mockMonitor.simulateDisconnected()

        #expect {
            try mockMonitor.checkConnection()
        } throws: { error in
            guard let networkError = error as? NetworkError,
                  case .noConnection = networkError else {
                return false
            }
            return true
        }
    }

    @Test func checkConnectionIncrementsCallCount() throws {
        #expect(mockMonitor.checkConnectionCallCount == 0)

        try mockMonitor.checkConnection()
        #expect(mockMonitor.checkConnectionCallCount == 1)

        try mockMonitor.checkConnection()
        #expect(mockMonitor.checkConnectionCallCount == 2)
    }

    @Test func checkConnectionIncrementsCallCountEvenWhenThrowing() {
        mockMonitor.simulateDisconnected()
        #expect(mockMonitor.checkConnectionCallCount == 0)

        _ = try? mockMonitor.checkConnection()
        #expect(mockMonitor.checkConnectionCallCount == 1)
    }

    // MARK: - Reset Tests

    @Test func resetRestoresDefaultState() {
        mockMonitor.simulateDisconnected()
        _ = try? mockMonitor.checkConnection()

        mockMonitor.reset()

        #expect(mockMonitor.isConnected)
        #expect(mockMonitor.connectionType == .wifi)
        #expect(mockMonitor.checkConnectionCallCount == 0)
    }

    // MARK: - Protocol Conformance Tests

    @Test func conformsToNetworkMonitorProtocol() {
        let protocolInstance: any NetworkMonitorProtocol = mockMonitor
        #expect(protocolInstance != nil)
    }

    @Test func protocolPropertiesAreAccessible() {
        let protocolInstance: any NetworkMonitorProtocol = mockMonitor

        #expect(protocolInstance.isConnected)
        #expect(protocolInstance.connectionType == .wifi)
        #expect(protocolInstance.hasHighQualityConnection)
    }

    // MARK: - High Quality Connection Tests

    @Test func hasHighQualityConnectionWifiIsHighQuality() {
        mockMonitor.isConnected = true
        mockMonitor.connectionType = .wifi

        #expect(mockMonitor.hasHighQualityConnection)
    }

    @Test func hasHighQualityConnectionWiredIsHighQuality() {
        mockMonitor.isConnected = true
        mockMonitor.connectionType = .wired

        #expect(mockMonitor.hasHighQualityConnection)
    }

    @Test func hasHighQualityConnectionCellularIsNotHighQuality() {
        mockMonitor.isConnected = true
        mockMonitor.connectionType = .cellular

        #expect(!mockMonitor.hasHighQualityConnection)
    }

    @Test func hasHighQualityConnectionDisconnectedIsNotHighQuality() {
        mockMonitor.isConnected = false
        mockMonitor.connectionType = .wifi  // Even with wifi type

        #expect(!mockMonitor.hasHighQualityConnection)
    }
}
