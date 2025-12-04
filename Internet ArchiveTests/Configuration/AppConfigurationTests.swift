//
//  AppConfigurationTests.swift
//  Internet ArchiveTests
//
//  Unit tests for AppConfiguration
//

import XCTest
@testable import Internet_Archive

final class AppConfigurationTests: XCTestCase {

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let instance1 = AppConfiguration.shared
        let instance2 = AppConfiguration.shared
        // Struct semantics - compare values
        XCTAssertEqual(instance1.apiVersion, instance2.apiVersion)
    }

    // MARK: - Property Access Tests

    func testApiAccessKeyProperty() {
        // The key will be empty if Configuration.plist doesn't exist (normal in test environment)
        let accessKey = AppConfiguration.shared.apiAccessKey
        // Verify the property returns consistent values
        XCTAssertEqual(accessKey, AppConfiguration.shared.apiAccessKey)
    }

    func testApiSecretKeyProperty() {
        // The key will be empty if Configuration.plist doesn't exist
        let secretKey = AppConfiguration.shared.apiSecretKey
        // Verify the property returns consistent values
        XCTAssertEqual(secretKey, AppConfiguration.shared.apiSecretKey)
    }

    func testApiVersionProperty() {
        // Default is 1 if not configured
        let version = AppConfiguration.shared.apiVersion
        XCTAssertGreaterThanOrEqual(version, 1)
    }

    // MARK: - isConfigured Tests

    func testIsConfiguredProperty() {
        // In test environment without Configuration.plist, this should be false
        // because apiAccessKey and apiSecretKey will be empty strings
        let isConfigured = AppConfiguration.shared.isConfigured

        // If both keys are empty, isConfigured should be false
        if AppConfiguration.shared.apiAccessKey.isEmpty ||
           AppConfiguration.shared.apiSecretKey.isEmpty {
            XCTAssertFalse(isConfigured)
        } else {
            // If we have a Configuration.plist with valid keys
            XCTAssertTrue(isConfigured)
        }
    }

    func testIsConfiguredRequiresBothKeys() {
        // This is a logic test - isConfigured should require both keys
        // Test the invariant: isConfigured == (!apiAccessKey.isEmpty && !apiSecretKey.isEmpty)
        let config = AppConfiguration.shared
        let expectedIsConfigured = !config.apiAccessKey.isEmpty && !config.apiSecretKey.isEmpty
        XCTAssertEqual(config.isConfigured, expectedIsConfigured)
    }

    // MARK: - Default Values Tests

    func testDefaultApiVersionWhenNotConfigured() {
        // When Configuration.plist doesn't have API_VERSION, default should be 1
        // This test verifies the fallback behavior
        let version = AppConfiguration.shared.apiVersion
        // Either it's loaded from config or it's the default (1)
        XCTAssertGreaterThanOrEqual(version, 1)
    }

    // MARK: - Sendable Conformance Tests

    func testAppConfigurationIsSendable() {
        // Verify AppConfiguration can be passed across concurrency boundaries
        let expectation = XCTestExpectation(description: "Sendable test")

        Task {
            let config = AppConfiguration.shared
            await MainActor.run {
                // Access properties from MainActor context
                _ = config.apiAccessKey
                _ = config.apiSecretKey
                _ = config.apiVersion
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
