//
//  ContentFilterModels.swift
//  Internet Archive
//
//  Models for content filtering to ensure App Store compliance
//

import Foundation

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

    static let allowed = ContentFilterResult(isFiltered: false, reason: nil)

    static func filtered(reason: ContentFilterReason) -> ContentFilterResult {
        ContentFilterResult(isFiltered: true, reason: reason)
    }
}

/// User preferences for content filtering
/// Note: Adult content filtering is always enabled and cannot be disabled (App Store requirement)
public struct ContentFilterPreferences: Codable, Sendable {
    /// Whether to require open licenses (CC, public domain, etc.)
    /// When enabled, only content with recognized open licenses is shown
    /// Default: ON to suppress content without clear licensing
    var requireOpenLicense: Bool

    /// Default preferences
    static let `default` = ContentFilterPreferences(
        requireOpenLicense: true  // Default ON to show only openly-licensed content
    )
}

/// Statistics about filtered content (for debugging/logging)
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
