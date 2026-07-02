//
//  SRTConversionHelpers.swift
//  Internet Archive
//
//  Testable helper functions for SRT to VTT conversion
//

import CryptoKit
import Foundation

/// Pure functions for SRT to VTT subtitle conversion
/// Extracted from SRTtoVTTConverter to enable comprehensive unit testing
enum SRTConversionHelpers {

    /// Regex matching the SRT/VTT timing arrow with optional surrounding whitespace.
    /// Real-world files use "-->" without spaces or with tabs around it.
    /// Internal so `SubtitleParser` can share the same pattern.
    static let timingArrowPattern = "\\s*-->\\s*"

    // MARK: - SRT to VTT Conversion

    /// Convert SRT format string to WebVTT format
    /// - Parameter srt: The SRT subtitle content
    /// - Returns: The converted WebVTT content
    static func convertSRTStringToVTT(_ srt: String) -> String {
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

            // Find the timing line (contains the "-->" arrow, spacing optional)
            guard let timingLineIndex = lines.firstIndex(where: { isTimingLine($0) }) else {
                continue
            }

            // Normalize the arrow spacing, then convert the timestamps
            // (SRT uses comma for milliseconds, VTT uses period)
            let timingLine = lines[timingLineIndex]
                .replacingOccurrences(
                    of: timingArrowPattern,
                    with: " --> ",
                    options: .regularExpression
                )
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

    // MARK: - Encoding Detection

    /// Decode subtitle data with encoding detection
    /// Honors UTF-8/UTF-16 byte-order marks, then tries UTF-8,
    /// then Windows-1252, then falls back to Latin-1
    /// - Parameter data: The raw subtitle data
    /// - Returns: The decoded string
    static func decodeSubtitleData(_ data: Data) -> String {
        // Check byte-order marks first. UTF-16 data would otherwise fail the
        // UTF-8 decode and "succeed" as CP1252/Latin-1 garbage.
        if data.starts(with: [0xEF, 0xBB, 0xBF]),
           let utf8String = String(data: data.dropFirst(3), encoding: .utf8) {
            return utf8String
        }
        if data.starts(with: [0xFF, 0xFE]),
           let utf16String = String(data: data.dropFirst(2), encoding: .utf16LittleEndian) {
            return utf16String
        }
        if data.starts(with: [0xFE, 0xFF]),
           let utf16String = String(data: data.dropFirst(2), encoding: .utf16BigEndian) {
            return utf16String
        }

        // Try UTF-8 first (most common)
        if let utf8String = String(data: data, encoding: .utf8) {
            return utf8String
        }

        // Try Windows-1252 (common legacy encoding; preserves smart quotes, em-dashes, etc.)
        // Must try before Latin-1 since Latin-1 is a "total" decode that always succeeds.
        if let windowsString = String(data: data, encoding: .windowsCP1252) {
            return windowsString
        }

        // Final fallback: treat bytes as Latin-1 (ISO-8859-1).
        // Latin-1 can decode any byte sequence since it maps bytes 0x00-0xFF directly.
        return String(data: data, encoding: .isoLatin1) ?? ""
    }

    // MARK: - VTT Filename Generation

    /// Generate a VTT filename from an SRT filename
    /// - Parameter srtFilename: The original SRT filename
    /// - Returns: The corresponding VTT filename
    static func vttFilename(from srtFilename: String) -> String {
        srtFilename.replacingOccurrences(of: ".srt", with: ".vtt", options: .caseInsensitive)
    }

    /// Generate a cache filename for a converted VTT file that is unique per source URL.
    /// Different archive items often share subtitle filenames (e.g. "english.srt"),
    /// so a stable hash of the source URL is inserted before the extension to
    /// prevent cache collisions between items.
    /// - Parameters:
    ///   - srtURL: The source URL of the SRT file
    ///   - filename: The original SRT filename
    /// - Returns: A cache filename like "english.3f6a9b2c1d4e.vtt"
    static func cacheFilename(for srtURL: URL, filename: String) -> String {
        let digest = SHA256.hash(data: Data(srtURL.absoluteString.utf8))
        let hashPrefix = digest
            .map { String(format: "%02x", $0) }
            .joined()
            .prefix(12)

        let vttName = vttFilename(from: filename)
        if let dotIndex = vttName.lastIndex(of: ".") {
            let base = vttName[..<dotIndex]
            let ext = vttName[dotIndex...]
            return "\(base).\(hashPrefix)\(ext)"
        }
        return "\(vttName).\(hashPrefix)"
    }

    // MARK: - Timing Validation

    /// Check if a string is a valid SRT/VTT timing line
    /// Tolerates missing or non-space whitespace around the arrow ("a-->b", "a\t-->\tb")
    /// - Parameter line: The line to check
    /// - Returns: True if the line contains a valid timing arrow
    static func isTimingLine(_ line: String) -> Bool {
        line.range(of: timingArrowPattern, options: .regularExpression) != nil
    }

    /// Convert SRT timestamp format to VTT format (comma to period)
    /// - Parameter srtTimestamp: Timestamp like "00:01:23,456"
    /// - Returns: VTT format "00:01:23.456"
    static func convertTimestamp(_ srtTimestamp: String) -> String {
        srtTimestamp.replacingOccurrences(of: ",", with: ".")
    }
}
