//
//  MockAPIManagerTests.swift
//  Internet ArchiveTests
//
//  Tests for MockAPIManager to verify mock data functionality
//

import XCTest
@testable import Internet_Archive

@MainActor
final class MockAPIManagerTests: XCTestCase {

    nonisolated(unsafe) var mockManager: MockAPIManager!

    override func setUp() {
        super.setUp()
        let newMockManager = MainActor.assumeIsolated {
            return MockAPIManager.shared
        }
        mockManager = newMockManager
    }

    override func tearDown() {
        mockManager = nil
        super.tearDown()
    }

    // MARK: - Register Tests

    func testRegister_success() async throws {
        let params: [String: Any] = [
            "email": "newuser@test.com",
            "screenname": "NewUser"
        ]

        let result = try await mockManager.register(params: params)

        XCTAssertEqual(result.success, true)
        XCTAssertEqual(result.values?.email, "newuser@test.com")
        XCTAssertEqual(result.values?.screenname, "NewUser")
        XCTAssertEqual(result.values?.itemname, "@testuser")
    }

    func testRegister_withEmptyParams() async throws {
        let params: [String: Any] = [:]

        let result = try await mockManager.register(params: params)

        XCTAssertEqual(result.success, true)
        XCTAssertEqual(result.values?.email, "test@example.com") // Default value
    }

    // MARK: - Login Tests

    func testLogin_success() async throws {
        let result = try await mockManager.login(email: "user@test.com", password: "password123")

        XCTAssertEqual(result.success, true)
        XCTAssertEqual(result.values?.email, "user@test.com")
        XCTAssertEqual(result.values?.screenname, "TestUser")
        XCTAssertEqual(result.values?.itemname, "@testuser")
    }

    func testLogin_failure() async {
        do {
            _ = try await mockManager.login(email: "fail@test.com", password: "password")
            XCTFail("Expected login to fail")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    // MARK: - Get Account Info Tests

    func testGetAccountInfo_success() async throws {
        let result = try await mockManager.getAccountInfo(email: "user@test.com")

        XCTAssertEqual(result.success, true)
        XCTAssertEqual(result.values?.email, "user@test.com")
        XCTAssertEqual(result.values?.screenname, "TestUser")
        XCTAssertEqual(result.values?.verified, true)
    }

    // MARK: - Search Tests

    func testSearch_returnsMockData() async throws {
        let result = try await mockManager.search(query: "test query", options: [:])

        XCTAssertNotNil(result.response)
        XCTAssertGreaterThan(result.response.numFound, 0)
        XCTAssertNotNil(result.response.docs)
    }

    // MARK: - Get Collections Tests

    func testGetCollections_returnsMockData() async throws {
        let result = try await mockManager.getCollections(collection: "movies", resultType: "movies", limit: 10)

        XCTAssertEqual(result.collection, "movies")
        XCTAssertNotNil(result.results)
        XCTAssertGreaterThan(result.results.count, 0)
    }

    // MARK: - Get Metadata Tests

    func testGetMetadata_returnsMockData() async throws {
        let result = try await mockManager.getMetadata(identifier: "test_item_123")

        XCTAssertNotNil(result.metadata)
        XCTAssertEqual(result.metadata?.identifier, "test_item_123")
        XCTAssertNotNil(result.files)
    }

    // MARK: - Get Favorite Items Tests

    func testGetFavoriteItems_returnsMockData() async throws {
        let result = try await mockManager.getFavoriteItems(username: "testuser")

        XCTAssertNotNil(result.members)
        XCTAssertGreaterThan(result.members?.count ?? 0, 0)
    }

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let instance1 = MockAPIManager.shared
        let instance2 = MockAPIManager.shared
        XCTAssertTrue(instance1 === instance2)
    }
}
