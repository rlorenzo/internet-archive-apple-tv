//
//  ValidationHelperTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ValidationHelper
//

import Testing
@testable import Internet_Archive

@Suite("ValidationHelper Tests")
struct ValidationHelperTests {

    // MARK: - Email Validation Tests

    @Test func isValidEmailValidEmail() {
        #expect(ValidationHelper.isValidEmail("user@example.com"))
        #expect(ValidationHelper.isValidEmail("user.name@example.com"))
        #expect(ValidationHelper.isValidEmail("user+tag@example.com"))
        #expect(ValidationHelper.isValidEmail("user_name@example.co.uk"))
        #expect(ValidationHelper.isValidEmail("user123@example.org"))
    }

    @Test func isValidEmailInvalidEmail() {
        #expect(!ValidationHelper.isValidEmail(""))
        #expect(!ValidationHelper.isValidEmail("invalid"))
        #expect(!ValidationHelper.isValidEmail("invalid@"))
        #expect(!ValidationHelper.isValidEmail("@example.com"))
        #expect(!ValidationHelper.isValidEmail("user@"))
        #expect(!ValidationHelper.isValidEmail("user@.com"))
        #expect(!ValidationHelper.isValidEmail("user example.com"))
    }

    @Test func isValidEmailEdgeCases() {
        // Valid edge cases
        #expect(ValidationHelper.isValidEmail("a@b.co"))
        #expect(ValidationHelper.isValidEmail("user%name@example.com"))
        #expect(ValidationHelper.isValidEmail("user-name@example.com"))

        // Invalid edge cases
        #expect(!ValidationHelper.isValidEmail("user@example"))  // No TLD
        #expect(!ValidationHelper.isValidEmail("user@."))
    }

    // MARK: - Password Validation Tests

    @Test func isValidPasswordValidPassword() {
        #expect(ValidationHelper.isValidPassword("abc"))  // Minimum length
        #expect(ValidationHelper.isValidPassword("password123"))
        #expect(ValidationHelper.isValidPassword("a very long password with spaces"))
    }

    @Test func isValidPasswordInvalidPassword() {
        #expect(!ValidationHelper.isValidPassword(""))
        #expect(!ValidationHelper.isValidPassword("ab"))  // Too short
        #expect(!ValidationHelper.isValidPassword("a"))
    }

    @Test func validatePasswordReturnsCorrectMessage() {
        // Valid password
        let validResult = ValidationHelper.validatePassword("password")
        #expect(validResult.isValid)
        #expect(validResult.message == nil)

        // Invalid password
        let invalidResult = ValidationHelper.validatePassword("ab")
        #expect(!invalidResult.isValid)
        #expect(invalidResult.message != nil)
        #expect(invalidResult.message?.contains("3") ?? false)
    }

    @Test func minimumPasswordLengthConstant() {
        #expect(ValidationHelper.minimumPasswordLength == 3)
    }
}
