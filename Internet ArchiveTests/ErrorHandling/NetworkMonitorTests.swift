//
//  NetworkMonitorTests.swift
//  Internet ArchiveTests
//
//  Unit tests for NetworkMonitor
//

import XCTest
@testable import Internet_Archive

@MainActor
final class NetworkMonitorTests: XCTestCase {

    func testNetworkMonitorSingleton() {
        let monitor1 = NetworkMonitor.shared
        let monitor2 = NetworkMonitor.shared

        XCTAssertTrue(monitor1 === monitor2, "NetworkMonitor should be a singleton")
    }

    func testCheckConnectionWhenConnected() throws {
        let monitor = NetworkMonitor.shared

        // Assuming device is connected during tests
        XCTAssertNoThrow(try monitor.checkConnection())
    }

    func testConnectionTypes() {
        let monitor = NetworkMonitor.shared

        // Test connection type enum
        XCTAssertNotNil(monitor.connectionType)

        switch monitor.connectionType {
        case .wifi, .cellular, .wired, .unknown:
            // Valid connection types
            break
        }
    }

    func testHighQualityConnection() {
        let monitor = NetworkMonitor.shared

        // High quality connection is wifi or wired
        if monitor.connectionType == .wifi || monitor.connectionType == .wired {
            XCTAssertTrue(monitor.hasHighQualityConnection)
        }
    }
}
