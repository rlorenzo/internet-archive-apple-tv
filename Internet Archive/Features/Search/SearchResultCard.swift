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

    /// When true, the card stretches to fill its grid cell (compact-width
    /// iPhone / Split View). When false, the card locks to its tvOS-sized
    /// fixed width so 10-foot UI layouts stay rhythmic.
    var stretches: Bool = false

    /// Card size used when `stretches` is false.
    private var fixedSize: CGSize {
        mediaType == .video
            ? CGSize(width: 380, height: 380 * 9 / 16)
            : CGSize(width: 220, height: 220)
    }

    private var aspectRatio: CGFloat {
        mediaType == .video ? 16.0 / 9.0 : 1.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(item.safeTitle)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                    .frame(height: stretches ? nil : (mediaType == .video ? 56 : nil),
                           alignment: .bottomLeading)

                Text(item.creator ?? item.year ?? " ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .modifier(CardWidthModifier(stretches: stretches, fixedWidth: fixedSize.width))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint("Double-tap to view details")
    }

    @ViewBuilder
    private var thumbnail: some View {
        if stretches {
            MediaThumbnailView(
                identifier: item.identifier,
                mediaType: mediaType,
                aspectRatio: aspectRatio
            )
        } else {
            MediaThumbnailView(
                identifier: item.identifier,
                mediaType: mediaType,
                size: fixedSize
            )
        }
    }

    private struct CardWidthModifier: ViewModifier {
        let stretches: Bool
        let fixedWidth: CGFloat

        func body(content: Content) -> some View {
            if stretches {
                content.frame(maxWidth: .infinity, alignment: .leading)
            } else {
                content.frame(width: fixedWidth)
            }
        }
    }

    // MARK: - Accessibility

    /// Combined accessibility label for the search result
    private var accessibilityLabelText: String {
        var components = [item.safeTitle]

        if let creator = item.creator {
            components.append(creator)
        } else if let year = item.year {
            components.append(year)
        }

        let typeLabel = mediaType == .video ? "Video" : "Music"
        components.append(typeLabel)

        return components.joined(separator: ", ")
    }
}
