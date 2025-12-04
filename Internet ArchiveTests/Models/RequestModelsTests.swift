//
//  RequestModelsTests.swift
//  Internet ArchiveTests
//
//  Unit tests for API request models
//

import XCTest
@testable import Internet_Archive

final class RequestModelsTests: XCTestCase {

    // MARK: - RegisterRequest Tests

    func testRegisterRequestEncoding() throws {
        let params: [String: Any] = [
            "email": "test@example.com",
            "password": "password123",
            "screenname": "TestUser"
        ]
        let request = RegisterRequest(
            params: params,
            access: "test_access",
            secret: "test_secret",
            version: 1
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["access"] as? String, "test_access")
        XCTAssertEqual(json?["secret"] as? String, "test_secret")
        XCTAssertEqual(json?["version"] as? Int, 1)
        XCTAssertEqual(json?["email"] as? String, "test@example.com")
        XCTAssertEqual(json?["password"] as? String, "password123")
        XCTAssertEqual(json?["screenname"] as? String, "TestUser")
    }

    func testRegisterRequestFromDictionary() {
        let params: [String: Any] = [
            "email": "user@test.com",
            "password": "secret"
        ]
        let request = RegisterRequest(
            params: params,
            access: "access_key",
            secret: "secret_key",
            version: 2
        )

        XCTAssertEqual(request.access, "access_key")
        XCTAssertEqual(request.secret, "secret_key")
        XCTAssertEqual(request.version, 2)
        XCTAssertEqual(request.email, "user@test.com")
        XCTAssertEqual(request.password, "secret")
        XCTAssertNil(request.screenname)
    }

    func testRegisterRequestOptionalFields() throws {
        let params: [String: Any] = [:]
        let request = RegisterRequest(
            params: params,
            access: "access",
            secret: "secret",
            version: 1
        )

        XCTAssertNil(request.email)
        XCTAssertNil(request.password)
        XCTAssertNil(request.screenname)

        // Verify encoding doesn't include nil values
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["access"] as? String, "access")
        XCTAssertEqual(json?["secret"] as? String, "secret")
        XCTAssertEqual(json?["version"] as? Int, 1)
        // Optional fields should not be present when nil (encodeIfPresent)
        XCTAssertNil(json?["email"])
        XCTAssertNil(json?["password"])
        XCTAssertNil(json?["screenname"])
    }

    // MARK: - LoginRequest Tests

    func testLoginRequestEncoding() throws {
        let request = LoginRequest(
            email: "login@test.com",
            password: "mypassword",
            access: "login_access",
            secret: "login_secret",
            version: 1
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["email"] as? String, "login@test.com")
        XCTAssertEqual(json?["password"] as? String, "mypassword")
        XCTAssertEqual(json?["access"] as? String, "login_access")
        XCTAssertEqual(json?["secret"] as? String, "login_secret")
        XCTAssertEqual(json?["version"] as? Int, 1)
    }

    func testLoginRequestProperties() {
        let request = LoginRequest(
            email: "user@domain.com",
            password: "pass123",
            access: "acc",
            secret: "sec",
            version: 3
        )

        XCTAssertEqual(request.email, "user@domain.com")
        XCTAssertEqual(request.password, "pass123")
        XCTAssertEqual(request.access, "acc")
        XCTAssertEqual(request.secret, "sec")
        XCTAssertEqual(request.version, 3)
    }

    // MARK: - AccountInfoRequest Tests

    func testAccountInfoRequestEncoding() throws {
        let request = AccountInfoRequest(
            email: "info@test.com",
            access: "info_access",
            secret: "info_secret",
            version: 1
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["email"] as? String, "info@test.com")
        XCTAssertEqual(json?["access"] as? String, "info_access")
        XCTAssertEqual(json?["secret"] as? String, "info_secret")
        XCTAssertEqual(json?["version"] as? Int, 1)
    }

    func testAccountInfoRequestProperties() {
        let request = AccountInfoRequest(
            email: "account@example.org",
            access: "key1",
            secret: "key2",
            version: 2
        )

        XCTAssertEqual(request.email, "account@example.org")
        XCTAssertEqual(request.access, "key1")
        XCTAssertEqual(request.secret, "key2")
        XCTAssertEqual(request.version, 2)
    }
}
