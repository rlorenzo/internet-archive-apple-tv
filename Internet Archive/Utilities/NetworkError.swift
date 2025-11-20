//
//  NetworkError.swift
//  Internet Archive
//
//  Created for Sprint 4: Networking Layer Rewrite
//  Modern error handling for async/await API calls
//

import Foundation

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
}
