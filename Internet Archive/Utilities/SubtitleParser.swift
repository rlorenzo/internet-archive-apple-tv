//
//  SubtitleParser.swift
//  Internet Archive
//
//  Parses WebVTT subtitle files for display
//

import Foundation

/// A single subtitle cue with timing and text
struct SubtitleCue: Sendable, Equatable {
    /// Start time in seconds
    let startTime: Double

    /// End time in seconds
    let endTime: Double

    /// The subtitle text (may contain multiple lines)
    let text: String

    /// Check if this cue should be displayed at the given time
    func isActive(at time: Double) -> Bool {
        time >= startTime && time < endTime
    }
}

/// Parses WebVTT subtitle files into cues
final class SubtitleParser: Sendable {

    /// Shared instance for parsing subtitles
    static let shared = SubtitleParser()

    private init() {}

    /// Parse a WebVTT file from a URL
    /// - Parameter url: URL to the WebVTT file (local or remote)
    /// - Returns: Array of subtitle cues sorted by start time
    func parse(from url: URL) async throws -> [SubtitleCue] {
        let (data, _) = try await URLSession.shared.data(from: url)

        guard let content = String(data: data, encoding: .utf8) else {
            throw SubtitleParseError.invalidEncoding
        }

        return try parse(vttContent: content)
    }

    /// Parse a WebVTT string into cues
    /// - Parameter vttContent: The WebVTT file content
    /// - Returns: Array of subtitle cues sorted by start time
    func parse(vttContent: String) throws -> [SubtitleCue] {
        // Normalize line endings
        let normalized = vttContent
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        // Check for WEBVTT header
        guard normalized.hasPrefix("WEBVTT") else {
            throw SubtitleParseError.missingHeader
        }

        var cues: [SubtitleCue] = []

        // Split into blocks
        let blocks = normalized.components(separatedBy: "\n\n")

        for block in blocks.dropFirst() { // Skip header block
            if let cue = parseCueBlock(block) {
                cues.append(cue)
            }
        }

        // Sort by start time
        return cues.sorted { $0.startTime < $1.startTime }
    }

    /// Parse a single cue block
    private func parseCueBlock(_ block: String) -> SubtitleCue? {
        let lines = block.split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0) }

        guard !lines.isEmpty else { return nil }

        // Find the timing line
        var timingLineIndex = -1
        for (index, line) in lines.enumerated() {
            if line.contains(" --> ") {
                timingLineIndex = index
                break
            }
        }

        guard timingLineIndex >= 0 else { return nil }

        // Parse timing
        let timingLine = lines[timingLineIndex]
        guard let (startTime, endTime) = parseTimingLine(timingLine) else {
            return nil
        }

        // Get text content
        let textLines = lines.dropFirst(timingLineIndex + 1)
        var text = textLines.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip basic HTML-like tags (VTT supports some styling tags)
        text = stripTags(from: text)

        guard !text.isEmpty else { return nil }

        return SubtitleCue(startTime: startTime, endTime: endTime, text: text)
    }

    /// Parse a VTT timing line (e.g., "00:00:01.000 --> 00:00:04.000")
    private func parseTimingLine(_ line: String) -> (start: Double, end: Double)? {
        let components = line.components(separatedBy: " --> ")
        guard components.count >= 2 else { return nil }

        // The end timestamp might have additional settings after it
        let endComponent = components[1].split(separator: " ").first.map(String.init) ?? components[1]

        guard let startTime = parseTimestamp(components[0].trimmingCharacters(in: .whitespaces)),
              let endTime = parseTimestamp(endComponent.trimmingCharacters(in: .whitespaces)) else {
            return nil
        }

        return (startTime, endTime)
    }

    /// Parse a VTT timestamp (e.g., "00:00:01.000" or "00:01.000")
    private func parseTimestamp(_ timestamp: String) -> Double? {
        let parts = timestamp.components(separatedBy: ":")

        guard parts.count >= 2 else { return nil }

        var hours: Double = 0
        var minutes: Double = 0
        var seconds: Double = 0

        if parts.count == 3 {
            // HH:MM:SS.mmm
            guard let h = Double(parts[0]),
                  let m = Double(parts[1]) else { return nil }
            hours = h
            minutes = m

            // Handle seconds with milliseconds
            let secondsPart = parts[2].replacingOccurrences(of: ",", with: ".")
            guard let s = Double(secondsPart) else { return nil }
            seconds = s
        } else if parts.count == 2 {
            // MM:SS.mmm
            guard let m = Double(parts[0]) else { return nil }
            minutes = m

            let secondsPart = parts[1].replacingOccurrences(of: ",", with: ".")
            guard let s = Double(secondsPart) else { return nil }
            seconds = s
        }

        return hours * 3600 + minutes * 60 + seconds
    }

    /// Strip HTML-like tags from text
    private func stripTags(from text: String) -> String {
        // Common VTT styling tags: <b>, <i>, <u>, <c.classname>, <v speaker>
        var result = text

        // Remove voice tags <v ...>text</v>
        let voicePattern = "<v[^>]*>"
        if let regex = try? NSRegularExpression(pattern: voicePattern, options: .caseInsensitive) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }

        // Remove common HTML tags
        let tagPattern = "<[^>]+>"
        if let regex = try? NSRegularExpression(pattern: tagPattern, options: .caseInsensitive) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }

        return result
    }
}

/// Errors during subtitle parsing
enum SubtitleParseError: Error, LocalizedError {
    case invalidEncoding
    case missingHeader
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return "Unable to decode subtitle file"
        case .missingHeader:
            return "Invalid WebVTT file - missing WEBVTT header"
        case .invalidFormat:
            return "Invalid subtitle file format"
        }
    }
}
