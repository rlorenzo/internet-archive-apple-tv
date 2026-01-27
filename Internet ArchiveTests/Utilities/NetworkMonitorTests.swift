//
//  NetworkMonitorTests.swift
//  Internet ArchiveTests
//
//  Unit tests for NetworkMonitor
//

import XCTest
import Combine
@testable import Internet_Archive

@MainActor
final class NetworkMonitorTests: XCTestCase {

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let instance1 = NetworkMonitor.shared
        let instance2 = NetworkMonitor.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Connection Type Tests

    func testConnectionType_wifi() {
        let type = NetworkMonitor.ConnectionType.wifi
        XCTAssertNotNil(type)
    }

    func testConnectionType_cellular() {
        let type = NetworkMonitor.ConnectionType.cellular
        XCTAssertNotNil(type)
    }

    func testConnectionType_wired() {
        let type = NetworkMonitor.ConnectionType.wired
        XCTAssertNotNil(type)
    }

    func testConnectionType_unknown() {
        let type = NetworkMonitor.ConnectionType.unknown
        XCTAssertNotNil(type)
    }

    func testConnectionType_allCases() {
        let allTypes: [NetworkMonitor.ConnectionType] = [.wifi, .cellular, .wired, .unknown]
        XCTAssertEqual(allTypes.count, 4)
    }

    // MARK: - Published Properties Tests

    func testIsConnected_defaultValue() {
        let monitor = NetworkMonitor.shared
        // In simulator, we typically have connection
        XCTAssertNotNil(monitor.isConnected)
    }

    func testConnectionType_hasValue() {
        let monitor = NetworkMonitor.shared
        XCTAssertNotNil(monitor.connectionType)
    }

    // MARK: - High Quality Connection Tests

    func testHasHighQualityConnection_property() {
        let monitor = NetworkMonitor.shared
        // Just verify the property exists and returns a Bool
        _ = monitor.hasHighQualityConnection
        XCTAssertNotNil(monitor)
    }

    // MARK: - Check Connection Tests

    func testCheckConnection_whenConnected_doesNotThrow() throws {
        let monitor = NetworkMonitor.shared

        try XCTSkipUnless(monitor.isConnected, "Requires active network connection")
        XCTAssertNoThrow(try monitor.checkConnection())
    }

    func testCheckConnection_throwsWhenOffline() throws {
        let monitor = NetworkMonitor.shared
        try XCTSkipUnless(!monitor.isConnected, "Requires offline state to validate error path")
        XCTAssertThrowsError(try monitor.checkConnection()) { error in
            guard case .noConnection = error as? NetworkError else {
                XCTFail("Expected noConnection error, got \(error)")
                return
            }
        }
    }

    // MARK: - Monitoring Tests

    func testStopMonitoring_doesNotCrash() {
        let monitor = NetworkMonitor.shared
        // Should not crash
        monitor.stopMonitoring()
        addTeardownBlock {
            monitor.startMonitoring()
        }
        XCTAssertNotNil(monitor)
    }

    func testStartMonitoring_doesNotCrash() {
        let monitor = NetworkMonitor.shared
        monitor.startMonitoring()
        XCTAssertNotNil(monitor)
    }

    // MARK: - ObservableObject Conformance Tests

    func testMonitor_isObservableObject() {
        let monitor = NetworkMonitor.shared
        // Verify it conforms to ObservableObject by accessing objectWillChange
        _ = monitor.objectWillChange
        XCTAssertNotNil(monitor)
    }
}

// MARK: - ConnectionType Hashable Tests

final class ConnectionTypeTests: XCTestCase {

    @MainActor
    func testConnectionType_equality() {
        let type1 = NetworkMonitor.ConnectionType.wifi
        let type2 = NetworkMonitor.ConnectionType.wifi
        XCTAssertEqual(type1, type2)
    }

    @MainActor
    func testConnectionType_inequality() {
        let type1 = NetworkMonitor.ConnectionType.wifi
        let type2 = NetworkMonitor.ConnectionType.cellular
        XCTAssertNotEqual(type1, type2)
    }

    @MainActor
    func testConnectionType_inSet() {
        var types: Set<NetworkMonitor.ConnectionType> = []
        types.insert(.wifi)
        types.insert(.cellular)
        types.insert(.wifi) // Duplicate

        XCTAssertEqual(types.count, 2)
        XCTAssertTrue(types.contains(.wifi))
        XCTAssertTrue(types.contains(.cellular))
    }

    @MainActor
    func testConnectionType_asDictionaryKey() {
        var dict: [NetworkMonitor.ConnectionType: String] = [:]
        dict[.wifi] = "Wi-Fi"
        dict[.cellular] = "Cellular"
        dict[.wired] = "Ethernet"
        dict[.unknown] = "Unknown"

        XCTAssertEqual(dict.count, 4)
        XCTAssertEqual(dict[.wifi], "Wi-Fi")
    }
}

// MARK: - MockNetworkMonitor Tests

/// Tests for MockNetworkMonitor using deterministic simulation.
/// These tests verify both the mock implementation and the protocol contract.
@MainActor
final class MockNetworkMonitorTests: XCTestCase {

    // MARK: - Setup

    var mockMonitor: MockNetworkMonitor!

    override func setUp() async throws {
        try await super.setUp()
        mockMonitor = MockNetworkMonitor()
    }

    override func tearDown() async throws {
        mockMonitor = nil
        try await super.tearDown()
    }

    // MARK: - Default State Tests

    func testDefaultState_isConnected() {
        XCTAssertTrue(mockMonitor.isConnected)
    }

    func testDefaultState_connectionTypeIsWifi() {
        XCTAssertEqual(mockMonitor.connectionType, .wifi)
    }

    func testDefaultState_hasHighQualityConnection() {
        XCTAssertTrue(mockMonitor.hasHighQualityConnection)
    }

    func testDefaultState_checkConnectionDoesNotThrow() {
        XCTAssertNoThrow(try mockMonitor.checkConnection())
    }

    // MARK: - Simulation Tests

    func testSimulateConnected() {
        mockMonitor.simulateDisconnected()  // First disconnect
        mockMonitor.simulateConnected()     // Then reconnect

        XCTAssertTrue(mockMonitor.isConnected)
        XCTAssertEqual(mockMonitor.connectionType, .wifi)
    }

    func testSimulateCellular() {
        mockMonitor.simulateCellular()

        XCTAssertTrue(mockMonitor.isConnected)
        XCTAssertEqual(mockMonitor.connectionType, .cellular)
        XCTAssertFalse(mockMonitor.hasHighQualityConnection)
    }

    func testSimulateWired() {
        mockMonitor.simulateWired()

        XCTAssertTrue(mockMonitor.isConnected)
        XCTAssertEqual(mockMonitor.connectionType, .wired)
        XCTAssertTrue(mockMonitor.hasHighQualityConnection)
    }

    func testSimulateDisconnected() {
        mockMonitor.simulateDisconnected()

        XCTAssertFalse(mockMonitor.isConnected)
        XCTAssertEqual(mockMonitor.connectionType, .unknown)
        XCTAssertFalse(mockMonitor.hasHighQualityConnection)
    }

    // MARK: - checkConnection Tests

    func testCheckConnection_whenConnected_doesNotThrow() throws {
        mockMonitor.simulateConnected()

        XCTAssertNoThrow(try mockMonitor.checkConnection())
    }

    func testCheckConnection_whenDisconnected_throwsNoConnection() {
        mockMonitor.simulateDisconnected()

        XCTAssertThrowsError(try mockMonitor.checkConnection()) { error in
            guard case .noConnection = error as? NetworkError else {
                XCTFail("Expected noConnection error, got \(error)")
                return
            }
        }
    }

    func testCheckConnection_incrementsCallCount() throws {
        XCTAssertEqual(mockMonitor.checkConnectionCallCount, 0)

        try mockMonitor.checkConnection()
        XCTAssertEqual(mockMonitor.checkConnectionCallCount, 1)

        try mockMonitor.checkConnection()
        XCTAssertEqual(mockMonitor.checkConnectionCallCount, 2)
    }

    func testCheckConnection_incrementsCallCountEvenWhenThrowing() {
        mockMonitor.simulateDisconnected()
        XCTAssertEqual(mockMonitor.checkConnectionCallCount, 0)

        _ = try? mockMonitor.checkConnection()
        XCTAssertEqual(mockMonitor.checkConnectionCallCount, 1)
    }

    // MARK: - Reset Tests

    func testReset_restoresDefaultState() {
        mockMonitor.simulateDisconnected()
        _ = try? mockMonitor.checkConnection()

        mockMonitor.reset()

        XCTAssertTrue(mockMonitor.isConnected)
        XCTAssertEqual(mockMonitor.connectionType, .wifi)
        XCTAssertEqual(mockMonitor.checkConnectionCallCount, 0)
    }

    // MARK: - Protocol Conformance Tests

    func testConformsToNetworkMonitorProtocol() {
        let protocolInstance: any NetworkMonitorProtocol = mockMonitor
        XCTAssertNotNil(protocolInstance)
    }

    func testProtocolProperties_areAccessible() {
        let protocolInstance: any NetworkMonitorProtocol = mockMonitor

        XCTAssertTrue(protocolInstance.isConnected)
        XCTAssertEqual(protocolInstance.connectionType, .wifi)
        XCTAssertTrue(protocolInstance.hasHighQualityConnection)
    }

    // MARK: - High Quality Connection Tests

    func testHasHighQualityConnection_wifiIsHighQuality() {
        mockMonitor.isConnected = true
        mockMonitor.connectionType = .wifi

        XCTAssertTrue(mockMonitor.hasHighQualityConnection)
    }

    func testHasHighQualityConnection_wiredIsHighQuality() {
        mockMonitor.isConnected = true
        mockMonitor.connectionType = .wired

        XCTAssertTrue(mockMonitor.hasHighQualityConnection)
    }

    func testHasHighQualityConnection_cellularIsNotHighQuality() {
        mockMonitor.isConnected = true
        mockMonitor.connectionType = .cellular

        XCTAssertFalse(mockMonitor.hasHighQualityConnection)
    }

    func testHasHighQualityConnection_disconnectedIsNotHighQuality() {
        mockMonitor.isConnected = false
        mockMonitor.connectionType = .wifi  // Even with wifi type

        XCTAssertFalse(mockMonitor.hasHighQualityConnection)
    }
}
