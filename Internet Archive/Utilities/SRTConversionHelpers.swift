//
//  SRTConversionHelpers.swift
//  Internet Archive
//
//  Testable helper functions for SRT to VTT conversion
//

import Foundation

/// Pure functions for SRT to VTT subtitle conversion
/// Extracted from SRTtoVTTConverter to enable comprehensive unit testing
enum SRTConversionHelpers {

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

            // Find the timing line (contains " --> ")
            guard let timingLineIndex = lines.firstIndex(where: { $0.contains(" --> ") }) else {
                continue
            }

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

    // MARK: - Encoding Detection

    /// Decode subtitle data with encoding detection
    /// Tries UTF-8, then Windows-1252, then falls back to Latin-1
    /// - Parameter data: The raw subtitle data
    /// - Returns: The decoded string
    static func decodeSubtitleData(_ data: Data) -> String {
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

    // MARK: - Timing Validation

    /// Check if a string is a valid SRT/VTT timing line
    /// - Parameter line: The line to check
    /// - Returns: True if the line contains a valid timing arrow
    static func isTimingLine(_ line: String) -> Bool {
        line.contains(" --> ")
    }

    /// Convert SRT timestamp format to VTT format (comma to period)
    /// - Parameter srtTimestamp: Timestamp like "00:01:23,456"
    /// - Returns: VTT format "00:01:23.456"
    static func convertTimestamp(_ srtTimestamp: String) -> String {
        srtTimestamp.replacingOccurrences(of: ",", with: ".")
    }
}
