//
//  SearchResultCard.swift
//  Internet Archive
//
//  Shared card component for displaying search results
//

import SwiftUI

/// A reusable card view for displaying a search result item.
///
/// Used by both SearchView (horizontal rows) and SearchResultsGridView (full grid).
struct SearchResultCard: View {
    let item: SearchResult
    let mediaType: MediaItemCard.MediaType

    /// Card size based on media type
    private var size: CGSize {
        mediaType == .video
            ? CGSize(width: 380, height: 380 * 9 / 16)
            : CGSize(width: 220, height: 220)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MediaThumbnailView(
                identifier: item.identifier,
                mediaType: mediaType,
                size: size
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.safeTitle)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                    .frame(height: mediaType == .video ? 56 : nil, alignment: .bottomLeading)

                Text(item.creator ?? item.year ?? " ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: size.width)
    }
}
