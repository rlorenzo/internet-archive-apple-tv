//
//  ContentFilterService.swift
//  Internet Archive
//
//  Service for filtering adult/mature content and copyrighted material
//  to comply with App Store guidelines
//

import Foundation

/// Service for filtering adult/mature content and ensuring open-license content
/// This service ensures App Store compliance by:
/// 1. Blocking known adult collections (including "no-preview" which triggers IA's content warning)
/// 2. Optionally filtering to only show openly-licensed content
/// 3. Keyword-based content detection
@MainActor
public final class ContentFilterService {

    // MARK: - Singleton

    public static let shared = ContentFilterService()

    // MARK: - Constants

    private let preferencesKey = "ContentFilterPreferences"

    /// Collections that trigger Internet Archive's "content may be inappropriate" warning
    /// The "no-preview" collection is the key indicator - items added to it show the warning
    private let contentWarningCollections: Set<String> = [
        "no-preview"  // Primary indicator - items with IA's content warning are in this collection
    ]

    /// Known adult/mature collections on Internet Archive
    /// These collections are blocked by default for App Store compliance
    private let blockedCollections: Set<String> = [
        // Collections that typically contain adult content
        "no-preview",        // Items flagged by IA as potentially inappropriate
        "adultcdroms",       // Mature CD-ROM software
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

    /// Allowed license URL patterns for open content
    /// These are Creative Commons and public domain licenses that allow redistribution
    private let allowedLicensePatterns: [String] = [
        // Public Domain
        "creativecommons.org/publicdomain/zero",      // CC0
        "creativecommons.org/publicdomain/mark",      // Public Domain Mark
        "creativecommons.org/licenses/publicdomain",  // Legacy public domain

        // Creative Commons licenses (all versions)
        "creativecommons.org/licenses/by/",           // CC BY
        "creativecommons.org/licenses/by-sa/",        // CC BY-SA
        "creativecommons.org/licenses/by-nc/",        // CC BY-NC
        "creativecommons.org/licenses/by-nc-sa/",     // CC BY-NC-SA
        "creativecommons.org/licenses/by-nd/",        // CC BY-ND
        "creativecommons.org/licenses/by-nc-nd/",     // CC BY-NC-ND

        // GNU licenses
        "gnu.org/licenses/gpl",                       // GPL
        "gnu.org/licenses/lgpl",                      // LGPL
        "gnu.org/licenses/fdl",                       // GFDL

        // Other open licenses
        "opensource.org/licenses/MIT",                // MIT
        "opensource.org/licenses/Apache",             // Apache
        "opensource.org/licenses/BSD"                 // BSD
    ]

    /// Keywords that indicate adult content in titles/descriptions
    /// These are checked in addition to collection-based filtering
    private let blockedKeywords: Set<String> = [
        "xxx",
        "porn",
        "pornographic",
        "sexually explicit"
    ]

    // MARK: - Properties

    private var preferences: ContentFilterPreferences
    private var stats: ContentFilterStats = .empty

    // MARK: - Initialization

    private init() {
        self.preferences = Self.loadPreferences()
    }

    // MARK: - Public API

    /// Whether content filtering is currently enabled
    public var isFilteringEnabled: Bool {
        preferences.isEnabled
    }

    /// Whether license filtering is enabled (only show open-licensed content)
    public var isLicenseFilteringEnabled: Bool {
        preferences.requireOpenLicense
    }

    /// Current maximum maturity level allowed
    public var maxMaturityLevel: ContentMaturityLevel {
        preferences.maxMaturityLevel
    }

    /// Get current filter statistics
    public var filterStatistics: ContentFilterStats {
        stats
    }

    // MARK: - Content Filtering

    /// Check if a search result should be filtered
    /// - Parameter result: The search result to check
    /// - Returns: Filter result indicating if content should be hidden
    public func shouldFilter(_ result: SearchResult) -> ContentFilterResult {
        guard preferences.isEnabled else {
            return .allowed
        }

        stats.totalItemsChecked += 1

        // Check for blocked collections (including no-preview which triggers IA's warning)
        if let collections = result.collection {
            for collection in collections {
                let lowercased = collection.lowercased()
                if blockedCollections.contains(lowercased) ||
                   preferences.customBlockedCollections.contains(where: { $0.lowercased() == lowercased }) {
                    stats.totalItemsFiltered += 1
                    incrementReason("collection:\(lowercased)")
                    return .filtered(reason: .blockedCollection(collection))
                }
            }
        }

        // Check title for blocked keywords
        if let title = result.title?.lowercased() {
            for keyword in blockedKeywords where title.contains(keyword) {
                stats.totalItemsFiltered += 1
                incrementReason("keyword")
                return .filtered(reason: .blockedKeyword(keyword))
            }
            for keyword in preferences.customBlockedKeywords where title.contains(keyword.lowercased()) {
                stats.totalItemsFiltered += 1
                incrementReason("custom_keyword")
                return .filtered(reason: .blockedKeyword(keyword))
            }
        }

        // Check license if license filtering is enabled
        if preferences.requireOpenLicense {
            if let licenseurl = result.licenseurl {
                if !isOpenLicense(licenseurl) {
                    stats.totalItemsFiltered += 1
                    incrementReason("license")
                    return .filtered(reason: .restrictedLicense(licenseurl))
                }
            } else {
                // No license specified - filter if we require open licenses
                stats.totalItemsFiltered += 1
                incrementReason("no_license")
                return .filtered(reason: .noLicense)
            }
        }

        return .allowed
    }

    /// Check if metadata should be filtered
    /// - Parameter metadata: The item metadata to check
    /// - Returns: Filter result indicating if content should be hidden
    public func shouldFilter(_ metadata: ItemMetadata) -> ContentFilterResult {
        guard preferences.isEnabled else {
            return .allowed
        }

        stats.totalItemsChecked += 1

        // Check for blocked collections
        if let collectionValue = metadata.collection {
            let collections = collectionValue.asArray
            for collection in collections {
                let lowercased = collection.lowercased()
                if blockedCollections.contains(lowercased) ||
                   preferences.customBlockedCollections.contains(where: { $0.lowercased() == lowercased }) {
                    stats.totalItemsFiltered += 1
                    incrementReason("collection:\(lowercased)")
                    return .filtered(reason: .blockedCollection(collection))
                }
            }
        }

        // Check title for blocked keywords
        if let title = metadata.title?.lowercased() {
            for keyword in blockedKeywords where title.contains(keyword) {
                stats.totalItemsFiltered += 1
                incrementReason("keyword")
                return .filtered(reason: .blockedKeyword(keyword))
            }
            for keyword in preferences.customBlockedKeywords where title.contains(keyword.lowercased()) {
                stats.totalItemsFiltered += 1
                incrementReason("custom_keyword")
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
    /// - Parameter results: Array of search results to filter
    /// - Returns: Filtered array with blocked content removed
    public func filter(_ results: [SearchResult]) -> [SearchResult] {
        guard preferences.isEnabled else {
            return results
        }

        return results.filter { !shouldFilter($0).isFiltered }
    }

    // MARK: - License Validation

    /// Check if a license URL represents an open/free license
    /// - Parameter licenseURL: The license URL to check
    /// - Returns: True if the license allows free redistribution
    public func isOpenLicense(_ licenseURL: String) -> Bool {
        let lowercased = licenseURL.lowercased()
        return allowedLicensePatterns.contains { pattern in
            lowercased.contains(pattern.lowercased())
        }
    }

    /// Get the license type from a URL
    /// - Parameter licenseURL: The license URL
    /// - Returns: Human-readable license name
    public func getLicenseType(_ licenseURL: String) -> String {
        let lowercased = licenseURL.lowercased()

        if lowercased.contains("publicdomain/zero") {
            return "CC0 (Public Domain)"
        } else if lowercased.contains("publicdomain/mark") {
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
        } else if lowercased.contains("gnu.org") {
            if lowercased.contains("gpl") { return "GPL" }
            if lowercased.contains("lgpl") { return "LGPL" }
            if lowercased.contains("fdl") { return "GFDL" }
            return "GNU License"
        } else if lowercased.contains("mit") {
            return "MIT"
        } else if lowercased.contains("apache") {
            return "Apache"
        } else if lowercased.contains("bsd") {
            return "BSD"
        }

        return "Unknown License"
    }

    // MARK: - Collection Checks

    /// Check if a collection identifier is blocked
    /// - Parameter collection: Collection identifier to check
    /// - Returns: True if the collection is blocked
    public func isCollectionBlocked(_ collection: String) -> Bool {
        guard preferences.isEnabled else {
            return false
        }

        let lowercased = collection.lowercased()
        return blockedCollections.contains(lowercased) ||
               preferences.customBlockedCollections.contains(where: { $0.lowercased() == lowercased })
    }

    /// Check if a collection has Internet Archive's content warning
    /// - Parameter collections: Array of collection identifiers
    /// - Returns: True if any collection triggers the content warning
    public func hasContentWarning(_ collections: [String]) -> Bool {
        collections.contains { contentWarningCollections.contains($0.lowercased()) }
    }

    /// Build a search query exclusion string for API calls
    /// - Returns: String to append to search queries to exclude blocked collections
    public func buildExclusionQuery() -> String {
        guard preferences.isEnabled else {
            return ""
        }

        // Build exclusion for each blocked collection
        var exclusions = blockedCollections.map { "-collection:(\($0))" }

        // Add custom blocked collections
        exclusions += preferences.customBlockedCollections.map { "-collection:(\($0))" }

        return exclusions.joined(separator: " ")
    }

    /// Build a license filter query for API calls
    /// - Returns: String to append to search queries to only include open-licensed content
    public func buildLicenseQuery() -> String {
        guard preferences.isEnabled && preferences.requireOpenLicense else {
            return ""
        }

        // Filter for items with Creative Commons or public domain licenses
        return "licenseurl:*creativecommons* OR licenseurl:*publicdomain*"
    }

    // MARK: - Preferences Management

    /// Update content filter preferences
    /// - Parameter newPreferences: New preferences to save
    public func updatePreferences(_ newPreferences: ContentFilterPreferences) {
        self.preferences = newPreferences
        savePreferences()
    }

    /// Enable or disable content filtering
    /// - Parameter enabled: Whether filtering should be enabled
    public func setFilteringEnabled(_ enabled: Bool) {
        preferences.isEnabled = enabled
        savePreferences()
    }

    /// Enable or disable license filtering
    /// - Parameter enabled: Whether to only show open-licensed content
    public func setLicenseFilteringEnabled(_ enabled: Bool) {
        preferences.requireOpenLicense = enabled
        savePreferences()
    }

    /// Set the maximum allowed maturity level
    /// - Parameter level: Maximum maturity level to allow
    public func setMaxMaturityLevel(_ level: ContentMaturityLevel) {
        preferences.maxMaturityLevel = level
        savePreferences()
    }

    /// Add a custom blocked collection
    /// - Parameter collection: Collection identifier to block
    public func addBlockedCollection(_ collection: String) {
        if !preferences.customBlockedCollections.contains(collection) {
            preferences.customBlockedCollections.append(collection)
            savePreferences()
        }
    }

    /// Remove a custom blocked collection
    /// - Parameter collection: Collection identifier to unblock
    public func removeBlockedCollection(_ collection: String) {
        preferences.customBlockedCollections.removeAll { $0 == collection }
        savePreferences()
    }

    /// Add a custom blocked keyword
    /// - Parameter keyword: Keyword to block
    public func addBlockedKeyword(_ keyword: String) {
        if !preferences.customBlockedKeywords.contains(keyword) {
            preferences.customBlockedKeywords.append(keyword)
            savePreferences()
        }
    }

    /// Remove a custom blocked keyword
    /// - Parameter keyword: Keyword to unblock
    public func removeBlockedKeyword(_ keyword: String) {
        preferences.customBlockedKeywords.removeAll { $0 == keyword }
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

    /// Get current preferences (read-only copy)
    public func getPreferences() -> ContentFilterPreferences {
        preferences
    }

    // MARK: - PIN Management

    /// Check if PIN protection is enabled
    public var isPINProtectionEnabled: Bool {
        preferences.requirePINForSettings && preferences.pinHash != nil
    }

    /// Set up PIN protection
    /// - Parameter pin: The PIN to set (will be hashed)
    public func setPIN(_ pin: String) {
        preferences.pinHash = hashPIN(pin)
        preferences.requirePINForSettings = true
        savePreferences()
    }

    /// Verify a PIN
    /// - Parameter pin: The PIN to verify
    /// - Returns: True if PIN is correct
    public func verifyPIN(_ pin: String) -> Bool {
        guard let storedHash = preferences.pinHash else {
            return true // No PIN set, always allow
        }
        return hashPIN(pin) == storedHash
    }

    /// Remove PIN protection
    public func removePIN() {
        preferences.pinHash = nil
        preferences.requirePINForSettings = false
        savePreferences()
    }

    // MARK: - Private Helpers

    private func incrementReason(_ reason: String) {
        stats.filterReasons[reason, default: 0] += 1
    }

    private func hashPIN(_ pin: String) -> String {
        // Simple hash for PIN - in production, use more secure hashing
        let data = Data(pin.utf8)
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { bytes in
            for (index, byte) in bytes.enumerated() {
                hash[index % 32] ^= byte
                hash[(index + 1) % 32] = hash[(index + 1) % 32] &+ byte
            }
        }
        return hash.map { String(format: "%02x", $0) }.joined()
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
