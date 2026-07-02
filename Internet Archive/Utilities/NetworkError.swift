//
//  NetworkError.swift
//  Internet Archive
//
//  Modern error handling for async/await API calls
//

import Foundation
import Alamofire

/// Comprehensive error types for network operations
enum NetworkError: Error, Sendable {
    // Network-related errors
    case noConnection
    case timeout
    case serverError(statusCode: Int)
    case requestFailed(Error)

    // Data parsing errors
    case invalidResponse
    case decodingFailed(Error)
    case invalidData

    // Authentication errors
    case unauthorized
    case authenticationFailed
    case invalidCredentials
    case cookieRetrievalFailed

    // API-specific errors
    case apiError(message: String)
    case resourceNotFound
    case invalidParameters

    // Content filtering
    case contentFiltered

    // Unknown errors
    case unknown(Error?)

    /// Human-readable error description
    var localizedDescription: String {
        switch self {
        case .noConnection:
            return "No internet connection available"
        case .timeout:
            return "Request timed out"
        case .serverError(let statusCode):
            return "Server error (HTTP \(statusCode))"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid data received"
        case .unauthorized:
            return "Unauthorized access"
        case .authenticationFailed:
            return "Authentication failed"
        case .invalidCredentials:
            return "Invalid email or password"
        case .cookieRetrievalFailed:
            return "Failed to retrieve authentication cookies"
        case .apiError(let message):
            return "API Error: \(message)"
        case .resourceNotFound:
            return "Resource not found"
        case .invalidParameters:
            return "Invalid request parameters"
        case .contentFiltered:
            return "This content is not available"
        case .unknown(let error):
            return error?.localizedDescription ?? "Unknown error occurred"
        }
    }

    // MARK: - User-Facing Messages

    /// Standard message shown when Internet Archive services are unavailable
    /// Used consistently across VideoVC, MusicVC, and YearsVC for maintenance/outage scenarios
    static let serviceUnavailableMessage = """
    Internet Archive services are temporarily unavailable.

    Please check archive.org for the latest status, or try again later.
    """

    // MARK: - Error Mapping

    /// Map an arbitrary error (Alamofire `AFError`, `URLError`, ...) to a
    /// `NetworkError` so the whole error-handling stack (RetryMechanism,
    /// ErrorLogger, ErrorPresenter) works with a single error type.
    /// Existing `NetworkError` values pass through unchanged.
    init(mapping error: Error) {
        if let networkError = error as? NetworkError {
            self = networkError
            return
        }

        if let afError = error.asAFError {
            // Validation failures carry the HTTP status code
            if let statusCode = afError.responseCode {
                switch statusCode {
                case 401:
                    self = .unauthorized
                case 404:
                    self = .resourceNotFound
                default:
                    self = .serverError(statusCode: statusCode)
                }
                return
            }

            if afError.isResponseSerializationError {
                self = .decodingFailed(afError)
                return
            }

            // Session task failures wrap the transport-level error (usually a URLError)
            if case .sessionTaskFailed(let underlyingError) = afError {
                self.init(mapping: underlyingError)
                return
            }

            self = .requestFailed(afError)
            return
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                self = .noConnection
            case .timedOut:
                self = .timeout
            default:
                self = .requestFailed(urlError)
            }
            return
        }

        self = .unknown(error)
    }
}

// MARK: - LocalizedError Conformance

/// Bridges the human-readable descriptions through `Error` existentials.
/// Without this, `(error as Error).localizedDescription` produces generic
/// Cocoa text like "NetworkError error 12" instead of our messages.
extension NetworkError: LocalizedError {
    var errorDescription: String? { localizedDescription }
}
