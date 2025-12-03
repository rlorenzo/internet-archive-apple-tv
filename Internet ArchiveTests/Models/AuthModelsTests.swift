//
//  AuthModelsTests.swift
//  Internet ArchiveTests
//
//  Unit tests for authentication data models
//

import XCTest
@testable import Internet_Archive

final class AuthModelsTests: XCTestCase {

    // MARK: - AuthResponse Tests

    func testAuthResponseDecoding() throws {
        let json = """
        {
            "success": true,
            "version": 1,
            "values": {
                "email": "test@example.com",
                "itemname": "@testuser",
                "screenname": "Test User",
                "verified": true,
                "privs": ["upload"],
                "signedin": "2025-01-01"
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)

        XCTAssertEqual(response.success, true)
        XCTAssertEqual(response.version, 1)
        XCTAssertEqual(response.values?.email, "test@example.com")
        XCTAssertEqual(response.values?.itemname, "@testuser")
        XCTAssertEqual(response.values?.screenname, "Test User")
        XCTAssertEqual(response.values?.verified, true)
        XCTAssertEqual(response.values?.privs, ["upload"])
        XCTAssertEqual(response.values?.signedin, "2025-01-01")
    }

    func testAuthResponseWithError() throws {
        let json = """
        {
            "success": false,
            "version": 1,
            "error": "Invalid credentials"
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(AuthResponse.self, from: data)

        XCTAssertEqual(response.success, false)
        XCTAssertEqual(response.error, "Invalid credentials")
        XCTAssertNil(response.values)
    }

    func testAuthResponseIsSuccess_whenSuccessTrue() {
        let response = AuthResponse(success: true, version: 1, values: nil, error: nil)
        XCTAssertTrue(response.isSuccess)
    }

    func testAuthResponseIsSuccess_whenSuccessFalse() {
        let response = AuthResponse(success: false, version: 1, values: nil, error: nil)
        XCTAssertFalse(response.isSuccess)
    }

    func testAuthResponseIsSuccess_whenError() {
        let response = AuthResponse(success: true, version: 1, values: nil, error: "Some error")
        XCTAssertFalse(response.isSuccess)
    }

    func testAuthResponseIsSuccess_whenSuccessNil() {
        let response = AuthResponse(success: nil, version: 1, values: nil, error: nil)
        XCTAssertFalse(response.isSuccess)
    }

    func testAuthValuesIsVerified_whenTrue() {
        let values = AuthResponse.AuthValues(verified: true)
        XCTAssertTrue(values.isVerified)
    }

    func testAuthValuesIsVerified_whenFalse() {
        let values = AuthResponse.AuthValues(verified: false)
        XCTAssertFalse(values.isVerified)
    }

    func testAuthValuesIsVerified_whenNil() {
        let values = AuthResponse.AuthValues(verified: nil)
        XCTAssertFalse(values.isVerified)
    }

    func testAuthResponseToDictionary() {
        let response = TestFixtures.authResponse
        let dict = response.toDictionary()

        XCTAssertEqual(dict["success"] as? Bool, true)
        XCTAssertEqual(dict["version"] as? Int, 1)

        let valuesDict = dict["values"] as? [String: Any]
        XCTAssertNotNil(valuesDict)
        XCTAssertEqual(valuesDict?["email"] as? String, "test@example.com")
        XCTAssertEqual(valuesDict?["screenname"] as? String, "Test User")
    }

    func testAuthResponseMemberwiseInit() {
        let values = AuthResponse.AuthValues(
            email: "test@test.com",
            itemname: "@user",
            screenname: "User",
            verified: true,
            privs: ["admin"],
            signedin: "2025"
        )
        let response = AuthResponse(success: true, version: 2, values: values, error: nil)

        XCTAssertEqual(response.success, true)
        XCTAssertEqual(response.version, 2)
        XCTAssertEqual(response.values?.email, "test@test.com")
        XCTAssertEqual(response.values?.privs, ["admin"])
    }

    // MARK: - AccountInfoResponse Tests

    func testAccountInfoResponseDecoding() throws {
        let json = """
        {
            "success": true,
            "version": 1,
            "values": {
                "email": "account@example.com",
                "itemname": "@accountuser",
                "screenname": "Account User",
                "verified": true,
                "privs": ["download", "upload"]
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(AccountInfoResponse.self, from: data)

        XCTAssertEqual(response.success, true)
        XCTAssertEqual(response.version, 1)
        XCTAssertEqual(response.values?.email, "account@example.com")
        XCTAssertEqual(response.values?.itemname, "@accountuser")
        XCTAssertEqual(response.values?.screenname, "Account User")
        XCTAssertEqual(response.values?.verified, true)
        XCTAssertEqual(response.values?.privs, ["download", "upload"])
    }

    func testAccountInfoResponseWithError() throws {
        let json = """
        {
            "success": false,
            "error": "Not authenticated"
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(AccountInfoResponse.self, from: data)

        XCTAssertEqual(response.success, false)
        XCTAssertEqual(response.error, "Not authenticated")
        XCTAssertNil(response.values)
    }

    func testAccountInfoResponseToDictionary() {
        let response = TestFixtures.accountInfoResponse
        let dict = response.toDictionary()

        XCTAssertEqual(dict["success"] as? Bool, true)
        XCTAssertEqual(dict["version"] as? Int, 1)

        let valuesDict = dict["values"] as? [String: Any]
        XCTAssertNotNil(valuesDict)
        XCTAssertEqual(valuesDict?["email"] as? String, "test@example.com")
    }

    func testAccountInfoResponseMemberwiseInit() {
        let values = AccountInfoResponse.AccountValues(
            email: "new@test.com",
            itemname: "@newuser",
            screenname: "New User",
            verified: false,
            privs: nil
        )
        let response = AccountInfoResponse(success: true, version: 1, values: values, error: nil)

        XCTAssertEqual(response.success, true)
        XCTAssertEqual(response.values?.email, "new@test.com")
        XCTAssertEqual(response.values?.verified, false)
    }

    func testAccountInfoResponsePartialData() throws {
        let json = """
        {
            "success": true
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(AccountInfoResponse.self, from: data)

        XCTAssertEqual(response.success, true)
        XCTAssertNil(response.version)
        XCTAssertNil(response.values)
        XCTAssertNil(response.error)
    }
}
