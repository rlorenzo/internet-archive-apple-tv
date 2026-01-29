//
//  ValidationHelperTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ValidationHelper
//

import XCTest
@testable import Internet_Archive

final class ValidationHelperTests: XCTestCase {

    // MARK: - Email Validation Tests

    func testIsValidEmail_validEmail() {
        XCTAssertTrue(ValidationHelper.isValidEmail("user@example.com"))
        XCTAssertTrue(ValidationHelper.isValidEmail("user.name@example.com"))
        XCTAssertTrue(ValidationHelper.isValidEmail("user+tag@example.com"))
        XCTAssertTrue(ValidationHelper.isValidEmail("user_name@example.co.uk"))
        XCTAssertTrue(ValidationHelper.isValidEmail("user123@example.org"))
    }

    func testIsValidEmail_invalidEmail() {
        XCTAssertFalse(ValidationHelper.isValidEmail(""))
        XCTAssertFalse(ValidationHelper.isValidEmail("invalid"))
        XCTAssertFalse(ValidationHelper.isValidEmail("invalid@"))
        XCTAssertFalse(ValidationHelper.isValidEmail("@example.com"))
        XCTAssertFalse(ValidationHelper.isValidEmail("user@"))
        XCTAssertFalse(ValidationHelper.isValidEmail("user@.com"))
        XCTAssertFalse(ValidationHelper.isValidEmail("user example.com"))
    }

    func testIsValidEmail_edgeCases() {
        // Valid edge cases
        XCTAssertTrue(ValidationHelper.isValidEmail("a@b.co"))
        XCTAssertTrue(ValidationHelper.isValidEmail("user%name@example.com"))
        XCTAssertTrue(ValidationHelper.isValidEmail("user-name@example.com"))

        // Invalid edge cases
        XCTAssertFalse(ValidationHelper.isValidEmail("user@example"))  // No TLD
        XCTAssertFalse(ValidationHelper.isValidEmail("user@."))
    }

    // MARK: - Password Validation Tests

    func testIsValidPassword_validPassword() {
        XCTAssertTrue(ValidationHelper.isValidPassword("abc"))  // Minimum length
        XCTAssertTrue(ValidationHelper.isValidPassword("password123"))
        XCTAssertTrue(ValidationHelper.isValidPassword("a very long password with spaces"))
    }

    func testIsValidPassword_invalidPassword() {
        XCTAssertFalse(ValidationHelper.isValidPassword(""))
        XCTAssertFalse(ValidationHelper.isValidPassword("ab"))  // Too short
        XCTAssertFalse(ValidationHelper.isValidPassword("a"))
    }

    func testValidatePassword_returnsCorrectMessage() {
        // Valid password
        let validResult = ValidationHelper.validatePassword("password")
        XCTAssertTrue(validResult.isValid)
        XCTAssertNil(validResult.message)

        // Invalid password
        let invalidResult = ValidationHelper.validatePassword("ab")
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertNotNil(invalidResult.message)
        XCTAssertTrue(invalidResult.message?.contains("3") ?? false)
    }

    func testMinimumPasswordLength_constant() {
        XCTAssertEqual(ValidationHelper.minimumPasswordLength, 3)
    }
}
