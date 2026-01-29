//
//  YearBrowseHelpers.swift
//  Internet Archive
//
//  Testable helper functions for YearBrowseView
//

import SwiftUI

/// Pure functions for YearBrowseView computations
/// Extracted from YearBrowseView for comprehensive unit testing
enum YearBrowseHelpers {

    // MARK: - Card Sizing

    /// Card width for video items
    static let videoCardWidth: CGFloat = 320

    /// Card size for music items (square)
    static let musicCardSize: CGFloat = 180

    /// Sidebar width
    static let sidebarWidth: CGFloat = 300

    /// Get the card width based on media type
    /// - Parameter mediaType: The media type
    /// - Returns: The card width in points
    static func cardWidth(for mediaType: MediaItemCard.MediaType) -> CGFloat {
        switch mediaType {
        case .video:
            return videoCardWidth
        case .music:
            return musicCardSize
        }
    }

    /// Get the card height based on media type
    /// - Parameter mediaType: The media type
    /// - Returns: The card height in points
    static func cardHeight(for mediaType: MediaItemCard.MediaType) -> CGFloat {
        switch mediaType {
        case .video:
            return videoCardWidth * 9 / 16 // 16:9 aspect ratio
        case .music:
            return musicCardSize // Square
        }
    }

    // MARK: - Grid Layout

    /// Get the number of columns for the grid based on media type
    /// - Parameter mediaType: The media type
    /// - Returns: Number of columns
    static func gridColumnCount(for mediaType: MediaItemCard.MediaType) -> Int {
        switch mediaType {
        case .video:
            return 4
        case .music:
            return 5
        }
    }

    /// Get the grid spacing based on media type
    /// - Parameter mediaType: The media type
    /// - Returns: Spacing in points
    static func gridSpacing(for mediaType: MediaItemCard.MediaType) -> CGFloat {
        switch mediaType {
        case .video:
            return 48
        case .music:
            return 40
        }
    }

    /// Create grid columns for the items grid
    /// - Parameter mediaType: The media type
    /// - Returns: Array of GridItem definitions
    static func gridColumns(for mediaType: MediaItemCard.MediaType) -> [GridItem] {
        let count = gridColumnCount(for: mediaType)
        let spacing = gridSpacing(for: mediaType)
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }

    // MARK: - Text Styling

    /// Get the title font for item cards
    /// - Parameter mediaType: The media type
    /// - Returns: The font to use for titles
    static func titleFont(for mediaType: MediaItemCard.MediaType) -> Font {
        switch mediaType {
        case .video:
            return .callout
        case .music:
            return .caption
        }
    }

    /// Get the creator font for item cards
    /// - Parameter mediaType: The media type
    /// - Returns: The font to use for creator text
    static func creatorFont(for mediaType: MediaItemCard.MediaType) -> Font {
        switch mediaType {
        case .video:
            return .caption
        case .music:
            return .caption2
        }
    }

    // MARK: - Accessibility

    /// Generate an accessibility label for an item
    /// - Parameters:
    ///   - item: The search result item
    ///   - mediaType: The media type for labeling
    /// - Returns: A descriptive accessibility label
    static func itemAccessibilityLabel(for item: SearchResult, mediaType: MediaItemCard.MediaType) -> String {
        var components = [item.safeTitle]
        if let creator = item.creator {
            components.append(creator)
        }
        let typeLabel = mediaType == .video ? "Video" : "Music"
        components.append(typeLabel)
        return components.joined(separator: ", ")
    }

    /// Generate accessibility label for a year button
    /// - Parameters:
    ///   - year: The year string
    ///   - itemCount: Number of items in that year
    /// - Returns: A descriptive accessibility label
    static func yearButtonAccessibilityLabel(year: String, itemCount: Int) -> String {
        "\(year), \(itemCount) items"
    }

    /// Generate accessibility hint for a year button
    /// - Parameter isSelected: Whether the year is currently selected
    /// - Returns: An accessibility hint
    static func yearButtonAccessibilityHint(year: String, isSelected: Bool) -> String {
        isSelected ? "Currently selected" : "Double-tap to browse items from \(year)"
    }

    // MARK: - API Mapping

    /// Map media type to collection type for API queries
    /// - Parameter mediaType: The media type
    /// - Returns: The collection type string for the API
    static func collectionType(for mediaType: MediaItemCard.MediaType) -> String {
        switch mediaType {
        case .video:
            return "movies"
        case .music:
            return "etree"
        }
    }
}
