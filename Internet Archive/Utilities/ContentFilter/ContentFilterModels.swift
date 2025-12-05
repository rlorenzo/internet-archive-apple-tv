//
//  ContentFilterModels.swift
//  Internet Archive
//
//  Models for content filtering and parental controls
//

import Foundation

/// Content maturity level classifications
/// Note: Currently only `general` (default) and `adult` (blocked) are used.
/// Additional levels can be added when Internet Archive provides content ratings.
public enum ContentMaturityLevel: String, Codable, Sendable {
    case general   // Suitable for all ages (default)
    case adult     // Blocked adult content
}

/// Reason why content was filtered
public enum ContentFilterReason: Sendable {
    case blockedCollection(String)
    case blockedKeyword(String)
    case restrictedLicense(String)
    case noLicense

    var description: String {
        switch self {
        case .blockedCollection(let collection):
            return "Blocked collection: \(collection)"
        case .blockedKeyword(let keyword):
            return "Contains blocked keyword: \(keyword)"
        case .restrictedLicense(let license):
            return "Restricted license: \(license)"
        case .noLicense:
            return "No open license specified"
        }
    }
}

/// Result of content filtering check
public struct ContentFilterResult: Sendable {
    let isFiltered: Bool
    let reason: ContentFilterReason?
    let maturityLevel: ContentMaturityLevel

    static let allowed = ContentFilterResult(isFiltered: false, reason: nil, maturityLevel: .general)

    static func filtered(reason: ContentFilterReason, level: ContentMaturityLevel = .adult) -> ContentFilterResult {
        ContentFilterResult(isFiltered: true, reason: reason, maturityLevel: level)
    }
}

/// User preferences for content filtering
public struct ContentFilterPreferences: Codable, Sendable {
    /// Whether content filtering is enabled (default: true for App Store compliance)
    var isEnabled: Bool

    /// Maximum maturity level allowed (reserved for future use when IA provides ratings)
    var maxMaturityLevel: ContentMaturityLevel

    /// Whether to require open licenses (CC, public domain, etc.)
    /// When enabled, only content with recognized open licenses is shown
    var requireOpenLicense: Bool

    /// Custom blocked collections added by user
    var customBlockedCollections: [String]

    /// Custom blocked keywords added by user
    var customBlockedKeywords: [String]

    /// Whether PIN is required to modify settings
    var requirePINForSettings: Bool

    /// Hashed PIN for settings protection (nil if not set)
    /// Note: Uses simple obfuscation, not cryptographic security
    var pinHash: String?

    /// Default preferences (safe for App Store)
    static let `default` = ContentFilterPreferences(
        isEnabled: true,
        maxMaturityLevel: .general,
        requireOpenLicense: false,
        customBlockedCollections: [],
        customBlockedKeywords: [],
        requirePINForSettings: false,
        pinHash: nil
    )
}

/// Statistics about filtered content
public struct ContentFilterStats: Sendable {
    var totalItemsChecked: Int
    var totalItemsFiltered: Int
    var filterReasons: [String: Int]

    var filterPercentage: Double {
        guard totalItemsChecked > 0 else { return 0 }
        return Double(totalItemsFiltered) / Double(totalItemsChecked) * 100
    }

    static let empty = ContentFilterStats(
        totalItemsChecked: 0,
        totalItemsFiltered: 0,
        filterReasons: [:]
    )
}
