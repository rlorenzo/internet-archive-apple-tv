//
//  ValidationHelper.swift
//  Internet Archive
//
//  Centralized validation logic for user input
//

import Foundation

/// Provides centralized validation logic for forms and user input.
///
/// This helper ensures consistent validation across all entry points
/// (LoginFormView, RegisterFormView, LoginViewModel) with a single source of truth.
enum ValidationHelper {

    // MARK: - Email Validation

    /// Validates an email address using a consistent regex pattern.
    ///
    /// - Parameter email: The email address to validate
    /// - Returns: `true` if the email format is valid
    static func isValidEmail(_ email: String) -> Bool {
        // Pattern allows: letters, numbers, dots, underscores, percent, plus, hyphen
        // before @, and standard domain format after
        let pattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    // MARK: - Password Validation

    /// Minimum required password length
    static let minimumPasswordLength = 3

    /// Validates a password and returns validation result with optional error message.
    ///
    /// - Parameter password: The password to validate
    /// - Returns: Tuple containing validation status and optional error message
    static func validatePassword(_ password: String) -> (isValid: Bool, message: String?) {
        guard password.count >= minimumPasswordLength else {
            return (false, "Password must be at least \(minimumPasswordLength) characters")
        }
        return (true, nil)
    }

    /// Simple check if password meets minimum requirements.
    ///
    /// - Parameter password: The password to check
    /// - Returns: `true` if password is valid
    static func isValidPassword(_ password: String) -> Bool {
        password.count >= minimumPasswordLength
    }
}
