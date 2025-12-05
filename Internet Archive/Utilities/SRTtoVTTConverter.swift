//
//  SRTtoVTTConverter.swift
//  Internet Archive
//
//  Converts SRT subtitle files to WebVTT format for AVPlayer compatibility
//

import Foundation

/// Converts SRT (SubRip) subtitle files to WebVTT format
/// AVPlayer on tvOS natively supports WebVTT but not SRT
actor SRTtoVTTConverter {

    /// Shared instance for app-wide subtitle conversion
    static let shared = SRTtoVTTConverter()

    // MARK: - Cache Management

    /// Cache directory for converted VTT files
    private var cacheDirectory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Subtitles", isDirectory: true)
    }

    /// Ensure the cache directory exists
    private func ensureCacheDirectory() throws {
        guard let cacheDir = cacheDirectory else {
            throw SubtitleConversionError.cacheDirectoryUnavailable
        }

        if !FileManager.default.fileExists(atPath: cacheDir.path) {
            try FileManager.default.createDirectory(
                at: cacheDir,
                withIntermediateDirectories: true
            )
        }
    }

    // MARK: - Public API

    /// Get a WebVTT URL for a subtitle track, converting from SRT if necessary
    /// - Parameter track: The subtitle track to process
    /// - Returns: A URL to a WebVTT file (local for converted SRT, remote for native VTT)
    func getWebVTTURL(for track: SubtitleTrack) async throws -> URL {
        // VTT files can be used directly
        if track.format.isNativelySupported {
            return track.url
        }

        // SRT files need conversion
        return try await convertSRTtoVTT(from: track.url, filename: track.filename)
    }

    /// Convert an SRT file to WebVTT format
    /// - Parameters:
    ///   - srtURL: URL to the SRT file
    ///   - filename: Original filename for cache naming
    /// - Returns: Local file URL to the converted WebVTT file
    func convertSRTtoVTT(from srtURL: URL, filename: String) async throws -> URL {
        try ensureCacheDirectory()

        guard let cacheDir = cacheDirectory else {
            throw SubtitleConversionError.cacheDirectoryUnavailable
        }

        // Generate cache filename
        let vttFilename = filename
            .replacingOccurrences(of: ".srt", with: ".vtt", options: .caseInsensitive)
        let cacheURL = cacheDir.appendingPathComponent(vttFilename)

        // Check if already cached
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            return cacheURL
        }

        // Download SRT content
        let (data, response) = try await URLSession.shared.data(from: srtURL)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SubtitleConversionError.downloadFailed
        }

        // Detect encoding and decode
        let srtContent = decodeSubtitleData(data)

        // Convert to WebVTT
        let vttContent = convertSRTStringToVTT(srtContent)

        // Write to cache
        try vttContent.write(to: cacheURL, atomically: true, encoding: .utf8)

        return cacheURL
    }

    /// Clear the subtitle cache
    func clearCache() throws {
        guard let cacheDir = cacheDirectory,
              FileManager.default.fileExists(atPath: cacheDir.path) else {
            return
        }

        try FileManager.default.removeItem(at: cacheDir)
    }

    /// Get the size of the subtitle cache in bytes
    func cacheSize() -> Int64 {
        guard let cacheDir = cacheDirectory,
              let enumerator = FileManager.default.enumerator(
                  at: cacheDir,
                  includingPropertiesForKeys: [.fileSizeKey]
              ) else {
            return 0
        }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }
        return totalSize
    }

    // MARK: - SRT Parsing and Conversion

    /// Decode subtitle data with encoding detection
    private func decodeSubtitleData(_ data: Data) -> String {
        // Try UTF-8 first (most common)
        if let utf8String = String(data: data, encoding: .utf8) {
            return utf8String
        }

        // Try Latin-1 (ISO-8859-1) for European subtitles
        if let latinString = String(data: data, encoding: .isoLatin1) {
            return latinString
        }

        // Try Windows-1252
        if let windowsString = String(data: data, encoding: .windowsCP1252) {
            return windowsString
        }

        // Fallback to UTF-8 with replacement
        return String(decoding: data, as: UTF8.self)
    }

    /// Convert SRT format string to WebVTT format
    private func convertSRTStringToVTT(_ srt: String) -> String {
        var vtt = "WEBVTT\n\n"

        // Normalize line endings
        let normalizedSRT = srt
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        // Split into cue blocks (separated by blank lines)
        let blocks = normalizedSRT.components(separatedBy: "\n\n")

        for block in blocks {
            let lines = block.split(separator: "\n", omittingEmptySubsequences: false)
                .map { String($0) }

            guard lines.count >= 2 else { continue }

            // Find the timing line (contains " --> ")
            var timingLineIndex = -1
            for (index, line) in lines.enumerated() {
                if line.contains(" --> ") {
                    timingLineIndex = index
                    break
                }
            }

            guard timingLineIndex >= 0 else { continue }

            // Convert timing line (SRT uses comma for milliseconds, VTT uses period)
            let timingLine = lines[timingLineIndex]
                .replacingOccurrences(of: ",", with: ".")

            // Get subtitle text (everything after timing line)
            let textLines = lines.dropFirst(timingLineIndex + 1)
            let text = textLines.joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !text.isEmpty else { continue }

            // Write VTT cue (no cue identifiers in VTT, just timing and text)
            vtt += "\(timingLine)\n"
            vtt += "\(text)\n\n"
        }

        return vtt
    }
}

// MARK: - Error Types

/// Errors that can occur during subtitle conversion
enum SubtitleConversionError: Error, LocalizedError {
    case cacheDirectoryUnavailable
    case downloadFailed
    case invalidSRTFormat
    case conversionFailed

    var errorDescription: String? {
        switch self {
        case .cacheDirectoryUnavailable:
            return "Unable to access subtitle cache directory"
        case .downloadFailed:
            return "Failed to download subtitle file"
        case .invalidSRTFormat:
            return "Invalid subtitle file format"
        case .conversionFailed:
            return "Failed to convert subtitle format"
        }
    }
}
