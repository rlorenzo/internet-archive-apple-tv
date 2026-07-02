//
//  ErrorMessageMapper.swift
//  Internet Archive
//
//  Shared error-to-user-message mapping for view models
//

import Foundation

/// Maps arbitrary errors to user-facing messages.
///
/// Single source of truth for the mapping that was previously duplicated in
/// every view model. The message wording is intentionally unchanged - unit
/// tests assert on it.
enum ErrorMessageMapper {

    /// Fallback message for errors that aren't `NetworkError`s
    static let genericMessage = "An unexpected error occurred. Please try again."

    /// Map an error to a user-friendly message.
    /// - Parameter error: The error to map.
    /// - Returns: A message suitable for direct display to the user.
    @MainActor
    static func message(for error: Error) -> String {
        if let networkError = error as? NetworkError {
            return ErrorPresenter.shared.userFriendlyMessage(for: networkError)
        }
        return genericMessage
    }
}
