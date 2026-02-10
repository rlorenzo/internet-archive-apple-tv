//
//  VideoPlayerHelpers.swift
//  Internet Archive
//
//  Testable helper functions extracted from VideoPlayerViewController
//

import UIKit

/// Data for rendering a subtitle selection cell
struct SubtitleCellData {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let accessibilityHint: String
}

/// Pure helper functions for video player logic
/// Extracted from VideoPlayerViewController for unit testing
enum VideoPlayerHelpers {

    // MARK: - Subtitle Display Names

    /// Check if subtitle tracks have duplicate display names
    /// - Parameter tracks: Array of subtitle tracks
    /// - Returns: true if any tracks share the same language display name
    static func hasDuplicateDisplayNames(_ tracks: [SubtitleTrack]) -> Bool {
        let displayNames = tracks.map { $0.languageDisplayName }
        return Set(displayNames).count < displayNames.count
    }

    /// Build display name for a subtitle track, adding format suffix if needed
    /// - Parameters:
    ///   - track: The subtitle track
    ///   - hasDuplicateNames: Whether there are tracks with duplicate display names
    /// - Returns: Display name like "English" or "English (SRT)"
    static func subtitleDisplayName(track: SubtitleTrack, hasDuplicateNames: Bool) -> String {
        if hasDuplicateNames {
            return "\(track.languageDisplayName) (\(track.format.rawValue.uppercased()))"
        }
        return track.languageDisplayName
    }

    /// Build accessibility value for the subtitle button
    /// - Parameter selectedTrack: Currently selected track, or nil if subtitles are off
    /// - Returns: Accessibility value string like "On - English" or "Off"
    static func subtitleButtonAccessibilityValue(selectedTrack: SubtitleTrack?) -> String {
        if let track = selectedTrack {
            return "On - \(track.languageDisplayName)"
        }
        return "Off"
    }

    /// Build cell display data for the subtitle selection UI
    /// - Parameters:
    ///   - index: Row index (0 = Off, 1+ = track)
    ///   - tracks: Available subtitle tracks
    ///   - selectedTrack: Currently selected track, or nil
    /// - Returns: SubtitleCellData with title, subtitle, isSelected, and accessibility hint
    static func subtitleCellData(
        index: Int,
        tracks: [SubtitleTrack],
        selectedTrack: SubtitleTrack?
    ) -> SubtitleCellData {
        if index == 0 {
            return SubtitleCellData(
                title: "Off",
                subtitle: nil,
                isSelected: selectedTrack == nil,
                accessibilityHint: "Turn off subtitles"
            )
        }

        let trackIndex = index - 1
        guard trackIndex < tracks.count else {
            return SubtitleCellData(title: "Unknown", subtitle: nil, isSelected: false, accessibilityHint: "")
        }

        let track = tracks[trackIndex]
        let subtitle = track.format == .srt ? "SRT" : "WebVTT"
        return SubtitleCellData(
            title: track.languageDisplayName,
            subtitle: subtitle,
            isSelected: selectedTrack?.identifier == track.identifier,
            accessibilityHint: "Select \(track.languageDisplayName) subtitles"
        )
    }

    // MARK: - Container Sizing

    /// Calculate the container height for the subtitle selection panel
    /// - Parameter trackCount: Number of subtitle tracks
    /// - Returns: Height in points (capped at 500)
    static func containerHeight(trackCount: Int) -> CGFloat {
        min(CGFloat((trackCount + 1) * 66 + 80), 500)
    }
}
