//
//  AppConfiguration.swift
//  Internet Archive
//
//  Created for Sprint 7: Security & Configuration
//  Secure configuration loading without hardcoded credentials
//

import Foundation

/// Centralized configuration management for the app
struct AppConfiguration: @unchecked Sendable {

    // MARK: - Configuration Keys

    private enum ConfigKey: String {
        case apiAccessKey = "API_ACCESS_KEY"
        case apiSecretKey = "API_SECRET_KEY"
        case apiVersion = "API_VERSION"
    }

    // MARK: - Singleton

    static let shared = AppConfiguration()

    // MARK: - Properties

    private let configuration: [String: Any]

    // MARK: - Initialization

    private init() {
        // Try to load from Configuration.plist first (for local development)
        if let path = Bundle.main.path(forResource: "Configuration", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path) as? [String: Any] {
            self.configuration = config
        } else {
            // Fallback to empty configuration
            // In production, these should be set via environment or build configuration
            self.configuration = [:]
            NSLog("⚠️ Warning: Configuration.plist not found. API credentials not loaded.")
            NSLog("⚠️ Please create Configuration.plist from Configuration.plist.template")
        }
    }

    // MARK: - Public API

    /// Internet Archive API access key (optional - app works in read-only mode without it)
    var apiAccessKey: String {
        configuration[ConfigKey.apiAccessKey.rawValue] as? String ?? ""
    }

    /// Internet Archive API secret key (optional - app works in read-only mode without it)
    var apiSecretKey: String {
        configuration[ConfigKey.apiSecretKey.rawValue] as? String ?? ""
    }

    /// API version number
    var apiVersion: Int {
        configuration[ConfigKey.apiVersion.rawValue] as? Int ?? 1
    }

    /// Check if configuration is valid
    var isConfigured: Bool {
        !apiAccessKey.isEmpty && !apiSecretKey.isEmpty
    }
}
