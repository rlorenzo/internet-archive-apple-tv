//
//  ItemDetailPlaceholderHelpers.swift
//  Internet Archive
//
//  Testable helper functions for ItemDetailPlaceholderView
//

import SwiftUI

/// Pure functions for ItemDetailPlaceholderView logic
/// Extracted from view to enable comprehensive unit testing
enum ItemDetailPlaceholderHelpers {

    // MARK: - Icon Selection

    /// Returns the SF Symbol name for the given media type
    /// - Parameter mediaType: The media type (.video or .music)
    /// - Returns: The SF Symbol name string
    static func iconName(for mediaType: MediaItemCard.MediaType) -> String {
        switch mediaType {
        case .video:
            return "film"
        case .music:
            return "music.note"
        }
    }

    // MARK: - Display Logic

    /// Whether the year should be displayed for the given media type
    /// - Parameters:
    ///   - year: The optional year string
    ///   - mediaType: The media type
    /// - Returns: True if the year should be shown
    static func shouldShowYear(_ year: String?, mediaType: MediaItemCard.MediaType) -> Bool {
        guard year != nil else { return false }
        return mediaType == .music
    }

    /// Returns the display title for the item
    /// - Parameter item: The search result
    /// - Returns: The safe title string
    static func displayTitle(for item: SearchResult) -> String {
        item.safeTitle
    }
}
