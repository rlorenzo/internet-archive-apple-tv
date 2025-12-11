//
//  SubtitleManager.swift
//  Internet Archive
//
//  Manages subtitle detection, parsing, and preference storage
//

import Foundation

/// Manages subtitle detection, language parsing, and user preferences
@MainActor
final class SubtitleManager {

    /// Shared instance for app-wide subtitle management
    static let shared = SubtitleManager()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let subtitlesEnabled = "subtitles_enabled"
        static let preferredLanguage = "subtitle_preferred_language"
        static let lastSelectedTrack = "subtitle_last_selected_track"
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Subtitle Detection

    /// Extract subtitle tracks from item metadata
    /// - Parameters:
    ///   - files: Array of FileInfo from metadata response
    ///   - identifier: The item identifier for URL building
    ///   - server: Optional specific server (ignored - always uses archive.org for reliability)
    /// - Returns: Array of available subtitle tracks, sorted by language
    func extractSubtitleTracks(
        from files: [FileInfo],
        identifier: String,
        server: String? = nil
    ) -> [SubtitleTrack] {
        // Always use archive.org for subtitle downloads - specific servers may not have all files
        let baseURL = "https://archive.org"

        let tracks = files.compactMap { file -> SubtitleTrack? in
            guard file.isSubtitleFile,
                  let format = file.subtitleFormat else {
                return nil
            }

            // Parse language from filename
            let (languageCode, displayName, isDefault) = parseLanguage(from: file.name)

            // Build the download URL
            guard let encodedFilename = file.name.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            ),
            let url = URL(string: "\(baseURL)/download/\(identifier)/\(encodedFilename)") else {
                return nil
            }

            return SubtitleTrack(
                filename: file.name,
                format: format,
                languageCode: languageCode,
                languageDisplayName: displayName,
                isDefault: isDefault,
                url: url
            )
        }

        // Deduplicate by language, preferring VTT over SRT
        let deduplicatedTracks = deduplicateByLanguage(tracks)

        // Sort tracks: default first, then by language name
        return deduplicatedTracks.sorted { lhs, rhs in
            if lhs.isDefault != rhs.isDefault {
                return lhs.isDefault
            }
            return lhs.languageDisplayName < rhs.languageDisplayName
        }
    }

    /// Deduplicate subtitle tracks by language, preferring VTT format over SRT
    /// - Parameter tracks: Array of subtitle tracks that may contain duplicates
    /// - Returns: Deduplicated array with VTT preferred when both formats exist
    private func deduplicateByLanguage(_ tracks: [SubtitleTrack]) -> [SubtitleTrack] {
        var tracksByLanguage: [String: SubtitleTrack] = [:]

        for track in tracks {
            // Include display name to distinguish variants like "English" vs "English (Auto)"
            let keyBase = track.languageCode ?? track.languageDisplayName
            let key = "\(keyBase.lowercased())|\(track.languageDisplayName.lowercased())"

            if let existing = tracksByLanguage[key] {
                // Determine which track to keep based on format preference
                let shouldReplaceExisting = track.format.isNativelySupported && !existing.format.isNativelySupported
                let shouldTransferDefault = (existing.isDefault || track.isDefault)

                if shouldReplaceExisting {
                    // VTT replaces SRT - preserve isDefault from either track
                    let preservedTrack = shouldTransferDefault && !track.isDefault
                        ? SubtitleTrack(
                            filename: track.filename,
                            format: track.format,
                            languageCode: track.languageCode,
                            languageDisplayName: track.languageDisplayName,
                            isDefault: true,
                            url: track.url
                        )
                        : track
                    tracksByLanguage[key] = preservedTrack
                } else if !existing.format.isNativelySupported && !track.format.isNativelySupported {
                    // Both are SRT - keep existing but transfer default flag if new track has it
                    if track.isDefault && !existing.isDefault {
                        tracksByLanguage[key] = SubtitleTrack(
                            filename: existing.filename,
                            format: existing.format,
                            languageCode: existing.languageCode,
                            languageDisplayName: existing.languageDisplayName,
                            isDefault: true,
                            url: existing.url
                        )
                    }
                } else if existing.format.isNativelySupported && !track.format.isNativelySupported {
                    // Existing is VTT, new is SRT - keep VTT but transfer default flag if SRT has it
                    if track.isDefault && !existing.isDefault {
                        tracksByLanguage[key] = SubtitleTrack(
                            filename: existing.filename,
                            format: existing.format,
                            languageCode: existing.languageCode,
                            languageDisplayName: existing.languageDisplayName,
                            isDefault: true,
                            url: existing.url
                        )
                    }
                }
                // If both are VTT, keep the first one
            } else {
                tracksByLanguage[key] = track
            }
        }

        return Array(tracksByLanguage.values)
    }

    /// Parse language information from a subtitle filename
    /// - Parameter filename: The subtitle filename (e.g., "movie_english.srt")
    /// - Returns: Tuple of (languageCode, displayName, isDefault)
    func parseLanguage(from filename: String) -> (code: String?, displayName: String, isDefault: Bool) {
        // Remove extension and split by common separators
        let nameWithoutExt = removeSubtitleExtension(from: filename)
        let components = nameWithoutExt
            .replacingOccurrences(of: "_", with: ".")
            .replacingOccurrences(of: "-", with: ".")
            .replacingOccurrences(of: " ", with: ".")
            .split(separator: ".")
            .map { String($0).lowercased() }

        // Check for ASR (auto-generated) subtitles
        let isAutoGenerated = components.contains { $0 == "asr" }

        // Check each component for a language match
        for component in components.reversed() {
            if let language = SubtitleLanguage.fromFilename(component) {
                let displayName = isAutoGenerated ? "\(language.displayName) (Auto)" : language.displayName
                return (language.rawValue, displayName, false)
            }
        }

        // Check for common patterns like "cc" (closed captions) or "sdh" (subtitles for deaf/hard of hearing)
        let isClosedCaption = components.contains { ["cc", "sdh", "hi"].contains($0) }

        // Build display name based on what we know
        var displayName: String
        if isClosedCaption {
            displayName = "Closed Captions"
        } else if isAutoGenerated {
            displayName = "Auto-generated"
        } else {
            displayName = "Subtitles"
        }

        // No language detected - mark as default/primary
        return (nil, displayName, true)
    }

    /// Remove subtitle file extension from filename
    private func removeSubtitleExtension(from filename: String) -> String {
        for format in SubtitleFormat.allCases where filename.lowercased().hasSuffix(format.fileExtension) {
            return String(filename.dropLast(format.fileExtension.count))
        }
        return filename
    }

    // MARK: - Preference Management

    /// Whether subtitles are enabled by default
    var subtitlesEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.subtitlesEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.subtitlesEnabled) }
    }

    /// User's preferred subtitle language code
    var preferredLanguageCode: String? {
        get { UserDefaults.standard.string(forKey: Keys.preferredLanguage) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.preferredLanguage) }
    }

    /// Last selected track identifier (for resuming playback)
    var lastSelectedTrackIdentifier: String? {
        get { UserDefaults.standard.string(forKey: Keys.lastSelectedTrack) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastSelectedTrack) }
    }

    /// Get the best matching subtitle track based on user preferences
    /// - Parameter tracks: Available subtitle tracks
    /// - Returns: The best matching track, or nil if subtitles are disabled
    func preferredTrack(from tracks: [SubtitleTrack]) -> SubtitleTrack? {
        guard subtitlesEnabled, !tracks.isEmpty else {
            return nil
        }

        // First, try to match the last selected track
        if let lastId = lastSelectedTrackIdentifier,
           let track = tracks.first(where: { $0.identifier == lastId }) {
            return track
        }

        // Then, try to match preferred language
        if let preferredCode = preferredLanguageCode,
           let track = tracks.first(where: { $0.languageCode == preferredCode }) {
            return track
        }

        // Default to English if available
        if let englishTrack = tracks.first(where: { $0.languageCode == "en" }) {
            return englishTrack
        }

        // Fall back to the first (default) track
        return tracks.first
    }

    /// Save the user's track selection for future sessions
    /// - Parameter track: The selected subtitle track
    func saveTrackSelection(_ track: SubtitleTrack) {
        lastSelectedTrackIdentifier = track.identifier
        if let code = track.languageCode {
            preferredLanguageCode = code
        }
        subtitlesEnabled = true
    }

    /// Clear subtitle selection (user turned off subtitles)
    func clearTrackSelection() {
        lastSelectedTrackIdentifier = nil
        subtitlesEnabled = false
    }

    // MARK: - Subtitle URL Building

    /// Build a subtitle URL for a specific file
    /// - Parameters:
    ///   - filename: The subtitle filename
    ///   - identifier: The item identifier
    ///   - server: Optional specific server (ignored - always uses archive.org for reliability)
    /// - Returns: The full URL to the subtitle file, or nil if URL building fails
    func buildSubtitleURL(
        filename: String,
        identifier: String,
        server: String? = nil
    ) -> URL? {
        // Always use archive.org for subtitle downloads - specific servers may not have all files
        let baseURL = "https://archive.org"

        guard let encodedFilename = filename.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) else {
            return nil
        }

        return URL(string: "\(baseURL)/download/\(identifier)/\(encodedFilename)")
    }
}
