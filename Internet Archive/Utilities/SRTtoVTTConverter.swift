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

    /// Cache time-to-live: 7 days in seconds
    private let cacheTTL: TimeInterval = 7 * 24 * 60 * 60

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
        let vttFilename = SRTConversionHelpers.vttFilename(from: filename)
        let cacheURL = cacheDir.appendingPathComponent(vttFilename)

        // Check if already cached and not expired (7-day TTL)
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: cacheURL.path),
               let modDate = attributes[.modificationDate] as? Date,
               Date().timeIntervalSince(modDate) < cacheTTL {
                return cacheURL
            }
            // Expired - remove stale file
            try? FileManager.default.removeItem(at: cacheURL)
        }

        // Download SRT content
        let (data, response) = try await URLSession.shared.data(from: srtURL)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SubtitleConversionError.downloadFailed
        }

        // Detect encoding and decode
        let srtContent = SRTConversionHelpers.decodeSubtitleData(data)

        // Convert to WebVTT
        let vttContent = SRTConversionHelpers.convertSRTStringToVTT(srtContent)

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
