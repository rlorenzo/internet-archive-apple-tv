//
//  ItemDetailHelpers.swift
//  Internet Archive
//
//  Helper functions for item detail view logic - extracted for testability
//

import Foundation

// MARK: - Subtitle Helpers

/// Helper functions for parsing and formatting subtitle information
enum SubtitleHelpers {
    /// File extensions recognized as subtitle files
    static let subtitleExtensions: Set<String> = [".srt", ".vtt", ".webvtt"]

    /// Check if a filename is a subtitle file
    static func isSubtitleFile(_ filename: String) -> Bool {
        let lowercasedName = filename.lowercased()
        return subtitleExtensions.contains { lowercasedName.hasSuffix($0) }
    }

    /// Extract language name from subtitle filename
    /// - Parameter filename: Subtitle filename (e.g., "movie_english.srt")
    /// - Returns: Capitalized language name if found, nil otherwise
    static func extractLanguage(from filename: String) -> String? {
        let basename = (filename as NSString).deletingPathExtension
        guard let underscoreIndex = basename.lastIndex(of: "_") else {
            return nil
        }
        let langPart = String(basename[basename.index(after: underscoreIndex)...])
        // Only return if it looks like a language (not a number or very short)
        guard langPart.count >= 2, !langPart.allSatisfy({ $0.isNumber }) else {
            return nil
        }
        return langPart.capitalized
    }

    /// Filter files to get only subtitle files
    static func filterSubtitleFiles(_ files: [FileInfo]) -> [FileInfo] {
        files.filter { isSubtitleFile($0.name) }
    }

    /// Extract unique languages from a list of subtitle files
    static func extractLanguages(from subtitleFiles: [FileInfo]) -> [String] {
        let languages = subtitleFiles.compactMap { extractLanguage(from: $0.name) }
        return Array(Set(languages)).sorted()
    }

    /// Generate human-readable subtitle info text
    /// - Parameter files: All files for the item
    /// - Returns: Formatted string like "Subtitles: English, Spanish" or nil if no subtitles
    static func formatSubtitleInfo(files: [FileInfo]) -> String? {
        let subtitleFiles = filterSubtitleFiles(files)
        guard !subtitleFiles.isEmpty else { return nil }

        let uniqueLanguages = extractLanguages(from: subtitleFiles)

        if !uniqueLanguages.isEmpty {
            return "Subtitles: \(uniqueLanguages.joined(separator: ", "))"
        } else if subtitleFiles.count == 1 {
            return "1 subtitle track available"
        } else {
            return "\(subtitleFiles.count) subtitle tracks available"
        }
    }
}

// MARK: - Date Formatting Helpers

/// Helper functions for formatting item metadata dates
enum DateFormattingHelpers {
    // MARK: - Cached DateFormatters (expensive to create)

    /// ISO date formatter (YYYY-MM-DD)
    /// Configured for fixed-format parsing with POSIX locale and Gregorian calendar
    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Slash date formatter (YYYY/MM/DD)
    /// Configured for fixed-format parsing with POSIX locale and Gregorian calendar
    private static let slashDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    /// Display formatter for medium date style
    /// Uses UTC to match parsing formatters and avoid day shifts for date-only values
    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    /// Format a date string with optional license information
    /// - Parameters:
    ///   - dateString: Raw date string from API
    ///   - formattedDate: Pre-formatted date string (pass result of Global.formatDate)
    ///   - licenseType: Pre-resolved license type string (pass result of ContentFilterService.getLicenseType)
    /// - Returns: Formatted date text like "Date: Jan 15, 2024  •  License: CC BY"
    static func formatDateWithLicense(
        dateString: String?,
        formattedDate: String?,
        licenseType: String?
    ) -> String? {
        guard let date = dateString else { return nil }

        var text = "Date: \(formattedDate ?? date)"

        if let licenseType = licenseType {
            text += "  \u{2022}  License: \(licenseType)"
        }

        return text
    }

    /// Format a raw date string for display
    /// Handles various date formats: YYYY-MM-DD, YYYY/MM/DD, YYYY
    /// - Parameter dateString: Raw date string
    /// - Returns: Formatted date or original string if parsing fails
    static func formatDateString(_ dateString: String) -> String {
        // Try ISO date format (YYYY-MM-DD)
        if let date = isoDateFormatter.date(from: dateString) {
            return displayFormatter.string(from: date)
        }

        // Try slash format (YYYY/MM/DD)
        if let date = slashDateFormatter.date(from: dateString) {
            return displayFormatter.string(from: date)
        }

        // Return original if parsing fails
        return dateString
    }

    /// Extract license type from a license URL
    /// - Parameter licenseURL: URL string for the license
    /// - Returns: Human-readable license type like "CC BY" or "Public Domain"
    static func extractLicenseType(from licenseURL: String) -> String {
        let url = licenseURL.lowercased()

        // Check CC0/zero first (CC0 URLs contain "publicdomain/zero", must check before publicdomain)
        if url.contains("/zero/") || url.contains("/cc0/") {
            return "CC0"
        } else if url.contains("publicdomain") || url.contains("public-domain") {
            return "Public Domain"
        } else if url.contains("creativecommons.org") {
            // Extract license type from CC URL
            if url.contains("/by-nc-sa/") {
                return "CC BY-NC-SA"
            } else if url.contains("/by-nc-nd/") {
                return "CC BY-NC-ND"
            } else if url.contains("/by-nc/") {
                return "CC BY-NC"
            } else if url.contains("/by-sa/") {
                return "CC BY-SA"
            } else if url.contains("/by-nd/") {
                return "CC BY-ND"
            } else if url.contains("/by/") {
                return "CC BY"
            }
            return "Creative Commons"
        }

        return "See License"
    }
}

// MARK: - Thumbnail URL Helpers

/// Helper functions for building Internet Archive URLs
enum IAURLHelpers {
    /// Base URL for Internet Archive services
    static let baseURL = "https://archive.org"

    /// Cached character set for URL path encoding (expensive to create)
    private static let pathAllowedCharacters: CharacterSet = {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return allowed
    }()

    /// Build thumbnail URL for an item
    /// - Parameter identifier: Item identifier
    /// - Returns: URL for the item's thumbnail image
    static func thumbnailURL(for identifier: String) -> URL? {
        URL(string: "\(baseURL)/services/img/\(identifier)")
    }

    /// Build download URL for a file
    /// - Parameters:
    ///   - identifier: Item identifier
    ///   - filename: File name
    /// - Returns: URL for downloading the file, or nil if encoding fails
    static func downloadURL(identifier: String, filename: String) -> URL? {
        guard let encodedIdentifier = identifier.addingPercentEncoding(
            withAllowedCharacters: pathAllowedCharacters
        ) else {
            return nil
        }
        guard let encodedFilename = filename.addingPercentEncoding(
            withAllowedCharacters: pathAllowedCharacters
        ) else {
            return nil
        }

        return URL(string: "\(baseURL)/download/\(encodedIdentifier)/\(encodedFilename)")
    }
}

// MARK: - Playable File Helpers

/// Helper functions for filtering playable media files
enum PlayableFileHelpers {
    /// Video formats natively supported by tvOS AVPlayer
    static let supportedVideoExtensions: Set<String> = [".mp4", ".mov", ".m4v"]

    /// Audio formats natively supported by tvOS AVPlayer
    static let supportedAudioExtensions: Set<String> = [".mp3", ".m4a", ".aac"]

    /// Check if a file is a playable video
    static func isPlayableVideo(_ filename: String) -> Bool {
        let lowercased = filename.lowercased()
        return supportedVideoExtensions.contains { lowercased.hasSuffix($0) }
    }

    /// Check if a file is a playable audio
    static func isPlayableAudio(_ filename: String) -> Bool {
        let lowercased = filename.lowercased()
        return supportedAudioExtensions.contains { lowercased.hasSuffix($0) }
    }

    /// Filter files for playable video files
    static func filterPlayableVideos(_ files: [FileInfo]) -> [FileInfo] {
        files.filter { isPlayableVideo($0.name) }
    }

    /// Filter files for playable audio files
    static func filterPlayableAudio(_ files: [FileInfo]) -> [FileInfo] {
        files.filter { isPlayableAudio($0.name) }
    }
}
