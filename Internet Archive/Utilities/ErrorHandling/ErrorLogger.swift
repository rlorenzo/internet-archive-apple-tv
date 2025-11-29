//
//  ErrorLogger.swift
//  Internet Archive
//
//  Comprehensive error logging for debugging
//

import Foundation
import os.log

/// Centralized error logging system
@MainActor
final class ErrorLogger {

    static let shared = ErrorLogger()

    private let logger = Logger(subsystem: "org.archive.InternetArchive", category: "Errors")

    /// Controls whether console output is enabled (can be disabled during tests)
    nonisolated(unsafe) static var isConsoleOutputEnabled: Bool = true

    /// Check if running in test environment
    nonisolated private static var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }

    private init() {}

    // MARK: - Logging

    /// Log an error with context
    nonisolated func log(error: Error, context: ErrorContext) {
        let errorDescription = getDetailedDescription(for: error)

        // Log with appropriate level based on error type
        let level = getLogLevel(for: error)

        let message = """
        [\(context.operation.rawValue)] \(errorDescription)
        Additional info: \(context.additionalInfo?.description ?? "none")
        """

        switch level {
        case .error:
            logger.error("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .info:
            logger.info("\(message)")
        }

        // Also log to console for development (suppressed during tests)
        #if DEBUG
        if Self.isConsoleOutputEnabled && !Self.isRunningTests {
            print("🔴 Error [\(context.operation.rawValue)]: \(errorDescription)")
            if let additionalInfo = context.additionalInfo {
                print("   Additional info: \(additionalInfo)")
            }
        }
        #endif
    }

    /// Log a successful operation (for debugging)
    nonisolated func logSuccess(operation: ErrorOperation, info: [String: Any]? = nil) {
        #if DEBUG
        if Self.isConsoleOutputEnabled && !Self.isRunningTests {
            print("✅ Success [\(operation.rawValue)]")
            if let info = info {
                print("   Info: \(info)")
            }
        }
        #endif

        logger.debug("[\(operation.rawValue)] Success")
    }

    /// Log a warning (non-fatal issue)
    nonisolated func logWarning(_ message: String, operation: ErrorOperation) {
        logger.warning("[\(operation.rawValue)] \(message)")

        #if DEBUG
        if Self.isConsoleOutputEnabled && !Self.isRunningTests {
            print("⚠️ Warning [\(operation.rawValue)]: \(message)")
        }
        #endif
    }

    // MARK: - Private Helpers

    nonisolated private func getDetailedDescription(for error: Error) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .serverError(let statusCode):
                return "Server error (HTTP \(statusCode))"
            case .decodingFailed(let underlyingError):
                return "Decoding failed: \(underlyingError.localizedDescription)"
            case .requestFailed(let underlyingError):
                return "Request failed: \(underlyingError.localizedDescription)"
            case .unknown(let underlyingError):
                return "Unknown error: \(underlyingError?.localizedDescription ?? "no details")"
            default:
                return networkError.localizedDescription
            }
        }

        return error.localizedDescription
    }

    nonisolated private func getLogLevel(for error: Error) -> LogLevel {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .noConnection, .timeout:
                return .warning
            case .serverError(let statusCode):
                return statusCode >= 500 ? .error : .warning
            case .unauthorized, .authenticationFailed:
                return .warning
            case .invalidResponse, .decodingFailed:
                return .error
            default:
                return .error
            }
        }

        return .error
    }

    private enum LogLevel {
        case error
        case warning
        case info
    }
}
