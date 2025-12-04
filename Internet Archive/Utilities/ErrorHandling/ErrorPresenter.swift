//
//  ErrorPresenter.swift
//  Internet Archive
//
//  Centralized error presentation with user-friendly messages
//

import UIKit

/// Centralized error presentation with automatic progress HUD management
/// and user-friendly error messages
@MainActor
final class ErrorPresenter {

    static let shared = ErrorPresenter()

    private init() {}

    // MARK: - Error Presentation

    /// Present an error to the user with automatic progress HUD dismissal
    /// - Parameters:
    ///   - error: The error to present
    ///   - context: Additional context about where/when the error occurred
    ///   - viewController: The view controller to present the alert on
    ///   - retry: Optional retry action
    func present(
        _ error: Error,
        context: ErrorContext,
        on viewController: UIViewController,
        retry: (() -> Void)? = nil
    ) {
        // Always hide the progress HUD first
        AppProgressHUD.sharedManager.hide()

        // Get user-friendly message
        let userMessage = getUserFriendlyMessage(for: error, context: context)

        // Log the error for debugging
        ErrorLogger.shared.log(error: error, context: context)

        // Show alert with optional retry
        if let retry = retry {
            showAlertWithRetry(
                title: context.userFacingTitle,
                message: userMessage,
                on: viewController,
                retry: retry
            )
        } else {
            Global.showAlert(
                title: context.userFacingTitle,
                message: userMessage,
                target: viewController
            )
        }
    }

    /// Present a service unavailable error (Internet Archive maintenance/outage)
    func presentServiceUnavailable(on viewController: UIViewController) {
        AppProgressHUD.sharedManager.hide()
        Global.showServiceUnavailableAlert(target: viewController)
    }

    // MARK: - User-Friendly Messages

    private func getUserFriendlyMessage(for error: Error, context: ErrorContext) -> String {
        if let networkError = error as? NetworkError {
            return userFriendlyMessage(for: networkError, context: context)
        }

        // Generic error message
        return "An unexpected error occurred. Please try again."
    }

    /// Returns a user-friendly message for a network error.
    /// Exposed for testing purposes.
    func userFriendlyMessage(for networkError: NetworkError, context: ErrorContext = ErrorContext(operation: .unknown)) -> String {
        switch networkError {
        case .noConnection:
            return "No internet connection. Please check your network settings and try again."

        case .timeout:
            return "The request took too long. Please check your connection and try again."

        case .serverError(let statusCode):
            if statusCode >= 500 {
                return "Internet Archive servers are experiencing issues. Please try again later."
            } else if statusCode == 404 {
                return "The requested content could not be found."
            } else if statusCode == 429 {
                return "Too many requests. Please wait a moment and try again."
            } else {
                return "Server error (HTTP \(statusCode)). Please try again later."
            }

        case .unauthorized, .authenticationFailed, .invalidCredentials:
            return "Your login credentials are invalid. Please log in again."

        case .invalidResponse, .decodingFailed, .invalidData:
            return "Received unexpected data from the server. Please try again."

        case .resourceNotFound:
            return "The requested item could not be found."

        case .invalidParameters:
            return "Invalid request. Please try again."

        case .apiError(let message):
            // API errors might contain user-friendly messages
            return message

        case .cookieRetrievalFailed:
            return "Login session could not be established. Please try logging in again."

        case .requestFailed:
            return "Network request failed. Please check your connection and try again."

        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }

    // MARK: - Alert with Retry

    private func showAlertWithRetry(
        title: String,
        message: String,
        on viewController: UIViewController,
        retry: @escaping () -> Void
    ) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alertController.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            retry()
        })

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        viewController.present(alertController, animated: true)
    }
}

// MARK: - Error Context

/// Context information for error handling
struct ErrorContext {
    let operation: ErrorOperation
    let userFacingTitle: String
    let additionalInfo: [String: Any]?

    init(
        operation: ErrorOperation,
        userFacingTitle: String = "Error",
        additionalInfo: [String: Any]? = nil
    ) {
        self.operation = operation
        self.userFacingTitle = userFacingTitle
        self.additionalInfo = additionalInfo
    }
}

/// Types of operations that can fail
enum ErrorOperation: String {
    // Authentication
    case login = "login"
    case register = "register"
    case getAccountInfo = "get_account_info"

    // Search & Browse
    case search = "search"
    case getCollections = "get_collections"
    case getMetadata = "get_metadata"

    // Playback
    case loadMedia = "load_media"
    case playVideo = "play_video"
    case playAudio = "play_audio"

    // Favorites
    case getFavorites = "get_favorites"
    case saveFavorite = "save_favorite"
    case removeFavorite = "remove_favorite"

    // Image Loading
    case loadImage = "load_image"

    // General
    case unknown = "unknown"
}
