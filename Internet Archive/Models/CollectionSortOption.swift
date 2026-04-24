//
//  CollectionSortOption.swift
//  Internet Archive
//
//  Sort options for browsing collections, mapped to Internet Archive API sort fields
//

import Foundation

/// Sort options for browsing Internet Archive collections.
///
/// Maps user-facing display names to API sort field expressions.
/// The default (`.weeklyViews`) matches the archive.org website behavior.
enum CollectionSortOption: String, CaseIterable, Identifiable, Sendable {
    case weeklyViews
    case monthlyViews
    case allTimeDownloads

    var id: String { rawValue }

    /// User-facing label for picker UI
    var displayName: String {
        switch self {
        case .weeklyViews: return "Week"
        case .monthlyViews: return "Month"
        case .allTimeDownloads: return "All Time"
        }
    }

    /// Solr sort expression for the Internet Archive API
    var apiSortString: String {
        switch self {
        case .weeklyViews: return "week desc"
        case .monthlyViews: return "month desc"
        case .allTimeDownloads: return "downloads desc"
        }
    }
}
