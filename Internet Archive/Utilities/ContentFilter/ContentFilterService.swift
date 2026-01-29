//
//  ContentFilterService.swift
//  Internet Archive
//
//  Service for filtering adult/mature content to comply with App Store guidelines.
//  Adult content filtering is always enabled and cannot be disabled.
//  License filtering is an optional user preference.
//

import Foundation

/// Service for filtering content for App Store compliance.
/// Adult content filtering is always active and cannot be disabled.
/// License filtering is optional and can be enabled by users who want only openly-licensed content.
@MainActor
public final class ContentFilterService {

    // MARK: - Singleton

    public static let shared = ContentFilterService()

    // MARK: - Constants

    private let preferencesKey = "ContentFilterPreferences"

    /// Collections that trigger Internet Archive's "content may be inappropriate" warning
    private let contentWarningCollections: Set<String> = [
        "no-preview"
    ]

    /// Known adult/mature collections on Internet Archive
    /// These collections are always blocked for App Store compliance
    private let blockedCollections: Set<String> = [
        "no-preview",
        "adultcdroms",
        "hentai",
        "hentaiarchive",
        "adult",
        "adults_only",
        "adultsoftware",
        "adult-games",
        "adultgames",
        "erotic",
        "erotica",
        "xxx",
        "porn",
        "pornography",
        "nsfw",
        "18plus",
        "r18",
        "explicit",
        "nudity",
        "fetish"
    ]

    /// Keywords that indicate adult content in titles
    private let blockedKeywords: Set<String> = [
        "xxx",
        "porn",
        "pornographic",
        "sexually explicit"
    ]

    /// Allowed license URL patterns for open content
    /// Based on actual licenses found in Internet Archive media content
    private let allowedLicensePatterns: [String] = [
        // Public Domain
        "creativecommons.org/publicdomain/zero",      // CC0
        "creativecommons.org/publicdomain/mark",      // Public Domain Mark
        "creativecommons.org/licenses/publicdomain",  // Legacy Public Domain Dedication

        // Creative Commons licenses (all versions 2.0, 2.5, 3.0, 4.0)
        "creativecommons.org/licenses/by/",           // CC BY
        "creativecommons.org/licenses/by-sa/",        // CC BY-SA
        "creativecommons.org/licenses/by-nc/",        // CC BY-NC
        "creativecommons.org/licenses/by-nc-sa/",     // CC BY-NC-SA
        "creativecommons.org/licenses/by-nd/",        // CC BY-ND
        "creativecommons.org/licenses/by-nc-nd/"      // CC BY-NC-ND
    ]

    // MARK: - Properties

    private var preferences: ContentFilterPreferences
    private var stats: ContentFilterStats = .empty

    // MARK: - Initialization

    private init() {
        self.preferences = Self.loadPreferences()
    }

    // MARK: - Public API

    /// Whether license filtering is enabled (only show open-licensed content)
    /// This is an optional user preference
    public var isLicenseFilteringEnabled: Bool {
        preferences.requireOpenLicense
    }

    /// Get current filter statistics
    public var filterStatistics: ContentFilterStats {
        stats
    }

    // MARK: - Content Filtering

    /// Check if a search result should be filtered
    public func shouldFilter(_ result: SearchResult) -> ContentFilterResult {
        stats.totalItemsChecked += 1

        // Always check for blocked collections (adult content - cannot be disabled)
        if let collections = result.collection {
            for collection in collections {
                let lowercased = collection.lowercased()
                if blockedCollections.contains(lowercased) {
                    stats.totalItemsFiltered += 1
                    incrementReason("collection:\(lowercased)")
                    return .filtered(reason: .blockedCollection(collection))
                }
            }
        }

        // Always check title for blocked keywords (adult content - cannot be disabled)
        if let title = result.title?.lowercased() {
            for keyword in blockedKeywords where title.contains(keyword) {
                stats.totalItemsFiltered += 1
                incrementReason("keyword")
                return .filtered(reason: .blockedKeyword(keyword))
            }
        }

        // Check license if license filtering is enabled (optional user preference)
        if preferences.requireOpenLicense {
            if let licenseurl = result.licenseurl {
                if !isOpenLicense(licenseurl) {
                    stats.totalItemsFiltered += 1
                    incrementReason("license")
                    return .filtered(reason: .restrictedLicense(licenseurl))
                }
            } else {
                stats.totalItemsFiltered += 1
                incrementReason("no_license")
                return .filtered(reason: .noLicense)
            }
        }

        return .allowed
    }

    /// Check if metadata should be filtered
    public func shouldFilter(_ metadata: ItemMetadata) -> ContentFilterResult {
        stats.totalItemsChecked += 1

        // Always check for blocked collections
        if let collectionValue = metadata.collection {
            let collections = collectionValue.asArray
            for collection in collections {
                let lowercased = collection.lowercased()
                if blockedCollections.contains(lowercased) {
                    stats.totalItemsFiltered += 1
                    incrementReason("collection:\(lowercased)")
                    return .filtered(reason: .blockedCollection(collection))
                }
            }
        }

        // Always check title for blocked keywords
        if let title = metadata.title?.lowercased() {
            for keyword in blockedKeywords where title.contains(keyword) {
                stats.totalItemsFiltered += 1
                incrementReason("keyword")
                return .filtered(reason: .blockedKeyword(keyword))
            }
        }

        // Check license if license filtering is enabled
        if preferences.requireOpenLicense {
            if let licenseurl = metadata.licenseurl {
                if !isOpenLicense(licenseurl) {
                    stats.totalItemsFiltered += 1
                    incrementReason("license")
                    return .filtered(reason: .restrictedLicense(licenseurl))
                }
            } else {
                stats.totalItemsFiltered += 1
                incrementReason("no_license")
                return .filtered(reason: .noLicense)
            }
        }

        return .allowed
    }

    /// Filter an array of search results
    public func filter(_ results: [SearchResult]) -> [SearchResult] {
        results.filter { !shouldFilter($0).isFiltered }
    }

    // MARK: - License Validation

    /// Check if a license URL represents an open/free license
    public func isOpenLicense(_ licenseURL: String) -> Bool {
        let lowercased = licenseURL.lowercased()
        return allowedLicensePatterns.contains { pattern in
            lowercased.contains(pattern.lowercased())
        }
    }

    /// Get the license type from a URL
    public func getLicenseType(_ licenseURL: String) -> String {
        let lowercased = licenseURL.lowercased()

        if lowercased.contains("publicdomain/zero") {
            return "CC0 (Public Domain)"
        } else if lowercased.contains("publicdomain/mark") {
            return "Public Domain"
        } else if lowercased.contains("/licenses/publicdomain") {
            // Legacy Creative Commons Public Domain Dedication URL format
            return "Public Domain"
        } else if lowercased.contains("/by-nc-sa/") {
            return "CC BY-NC-SA"
        } else if lowercased.contains("/by-nc-nd/") {
            return "CC BY-NC-ND"
        } else if lowercased.contains("/by-nc/") {
            return "CC BY-NC"
        } else if lowercased.contains("/by-sa/") {
            return "CC BY-SA"
        } else if lowercased.contains("/by-nd/") {
            return "CC BY-ND"
        } else if lowercased.contains("/by/") {
            return "CC BY"
        }

        return "Unknown License"
    }

    // MARK: - Collection Checks

    /// Check if a collection identifier is blocked
    public func isCollectionBlocked(_ collection: String) -> Bool {
        blockedCollections.contains(collection.lowercased())
    }

    /// Check if a collection has Internet Archive's content warning
    public func hasContentWarning(_ collections: [String]) -> Bool {
        collections.contains { contentWarningCollections.contains($0.lowercased()) }
    }

    /// Build a search query exclusion string for API calls
    public func buildExclusionQuery() -> String {
        let exclusions = blockedCollections.map { "-collection:(\($0))" }
        return exclusions.joined(separator: " ")
    }

    // MARK: - Preferences Management

    /// Enable or disable license filtering (optional user preference)
    public func setLicenseFilteringEnabled(_ enabled: Bool) {
        preferences.requireOpenLicense = enabled
        savePreferences()
    }

    /// Reset preferences to defaults
    public func resetToDefaults() {
        preferences = .default
        savePreferences()
    }

    /// Reset filter statistics
    public func resetStatistics() {
        stats = .empty
    }

    // MARK: - Private Helpers

    private func incrementReason(_ reason: String) {
        stats.filterReasons[reason, default: 0] += 1
    }

    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: preferencesKey)
        }
    }

    private static func loadPreferences() -> ContentFilterPreferences {
        guard let data = UserDefaults.standard.data(forKey: "ContentFilterPreferences"),
              let preferences = try? JSONDecoder().decode(ContentFilterPreferences.self, from: data) else {
            return .default
        }
        return preferences
    }
}

// MARK: - SearchResult Extension for Filtering

extension SearchResult {
    /// Check if this result should be filtered based on content filter settings
    @MainActor
    var isFiltered: Bool {
        ContentFilterService.shared.shouldFilter(self).isFiltered
    }
}

// MARK: - ItemMetadata Extension for Filtering

extension ItemMetadata {
    /// Check if this metadata should be filtered based on content filter settings
    @MainActor
    var isFiltered: Bool {
        ContentFilterService.shared.shouldFilter(self).isFiltered
    }
}
