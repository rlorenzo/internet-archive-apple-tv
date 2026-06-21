//
//  SkeletonLoadingView.swift
//  Internet Archive
//
//  Static skeleton placeholders for loading states.
//

import SwiftUI
import UIKit

// MARK: - Skeleton Card

/// A static skeleton placeholder for a media card.
///
/// Use this view to show loading state for individual cards.
/// No animation: depth and motion are reserved for the focus state
/// (see DESIGN.md "The Focus-Is-Depth Rule" and Principle 5).
///
/// ## Usage
/// ```swift
/// SkeletonCard(aspectRatio: 16/9) // Video card
/// SkeletonCard(aspectRatio: 1)    // Music card
/// ```
struct SkeletonCard: View {
    let aspectRatio: CGFloat
    // Heights derive from system text-style line heights so the placeholder
    // occupies the same vertical space as the eventual rendered text under
    // any Dynamic Type setting (no layout jump when content arrives).
    var titleHeight: CGFloat = UIFont.preferredFont(forTextStyle: .callout).lineHeight
    var subtitleHeight: CGFloat = UIFont.preferredFont(forTextStyle: .caption1).lineHeight
    var subtitleWidth: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.placeholderFill)
                .aspectRatio(aspectRatio, contentMode: .fit)

            // Text skeletons
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.placeholderFill)
                    .frame(height: titleHeight)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.skeletonSubtle)
                    .frame(width: subtitleWidth, height: subtitleHeight)
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: - Convenience Constructors

    /// Video card skeleton with 16:9 aspect ratio
    static var video: SkeletonCard {
        SkeletonCard(aspectRatio: 16.0 / 9.0)
    }

    /// Music card skeleton with square aspect ratio
    static var music: SkeletonCard {
        SkeletonCard(aspectRatio: 1, subtitleWidth: 120)
    }
}

// MARK: - Skeleton Grid

/// A grid of skeleton cards for loading states.
///
/// ## Usage
/// ```swift
/// SkeletonGrid(cardType: .video, columns: 4, rows: 2)
/// SkeletonGrid(cardType: .music, columns: 6, rows: 2)
/// ```
struct SkeletonGrid: View {
    enum CardType {
        case video
        case music
    }

    let cardType: CardType
    let columns: Int
    let rows: Int

    #if !os(tvOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    /// Hard cap on rendered placeholders for compact width, so a single column
    /// on iPhone does not blow up to a 12- or 18-item vertical scroll while
    /// loading. On tvOS / regular width the full `columns * rows` renders so the
    /// skeleton fills the same rows the real grid will. The adaptive grid still
    /// chooses how many fit per row; this only bounds total count.
    private static let placeholderCap = 8

    var body: some View {
        LazyVGrid(
            columns: gridColumns,
            spacing: gridSpacing
        ) {
            ForEach(0..<placeholderCount, id: \.self) { _ in
                switch cardType {
                case .video:
                    SkeletonCard.video
                case .music:
                    SkeletonCard.music
                }
            }
        }
    }

    private var placeholderCount: Int {
        let requested = columns * rows
        return isCompact ? min(requested, Self.placeholderCap) : requested
    }

    private var gridSpacing: CGFloat {
        // Mirror SearchResultsGridHelpers spacing exactly so the skeleton does
        // not reflow when real content lands: video uses 48pt at regular width,
        // music 40pt, both 16pt on compact.
        guard !isCompact else { return 16 }
        switch cardType {
        case .video:
            return 48
        case .music:
            return 40
        }
    }

    private var gridColumns: [GridItem] {
        // Mirror `SearchResultsGridHelpers.gridColumns` exactly so the skeleton
        // row count matches the real grid's column count on every platform —
        // otherwise the skeleton flashes one column count, then content reflows
        // to a different one when the data lands.
        let minWidth: CGFloat
        let maxWidth: CGFloat
        switch (cardType, isCompact) {
        case (.video, true):
            minWidth = 160
            maxWidth = 220
        case (.video, false):
            #if os(tvOS)
            minWidth = 340
            #else
            minWidth = 300
            #endif
            maxWidth = 420
        case (.music, true):
            minWidth = 140
            maxWidth = 180
        case (.music, false):
            #if os(tvOS)
            minWidth = 200
            #else
            minWidth = 180
            #endif
            maxWidth = 240
        }

        return [
            GridItem(.adaptive(minimum: minWidth, maximum: maxWidth), spacing: gridSpacing)
        ]
    }

    private var isCompact: Bool {
        #if os(tvOS)
        return false
        #else
        return horizontalSizeClass == .compact
        #endif
    }
}

// MARK: - Skeleton Row

/// A horizontal row of skeleton cards for loading states.
///
/// ## Usage
/// ```swift
/// SkeletonRow(cardType: .video, count: 5)
/// SkeletonRow(cardType: .music, count: 8)
/// ```
struct SkeletonRow: View {
    enum CardType {
        case video
        case music
    }

    let cardType: CardType
    let count: Int

    @Environment(\.isCompactLayout) private var isCompactLayout

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: isCompactLayout == true ? 16 : 40) {
                ForEach(0..<count, id: \.self) { _ in
                    switch cardType {
                    case .video:
                        SkeletonCard.video
                            .frame(width: cardWidth)
                    case .music:
                        SkeletonCard.music
                            .frame(width: cardWidth)
                    }
                }
            }
            // Gutter is owned by the parent container, matching the real
            // ContinueWatchingSection / grid shelves so the skeleton lines up
            // with the content it stands in for instead of overflowing compact.
        }
    }

    /// Placeholder width is single-sourced from the real shelf card sizing so
    /// swapping skeleton → content never reflows the row. Maps the skeleton's
    /// video/music type onto the shelf's video/audio filter.
    private var cardWidth: CGFloat {
        let filter: ContinueWatchingSection.MediaFilter = cardType == .video ? .video : .audio
        return ContinueWatchingHelpers.cardWidth(for: filter, compact: isCompactLayout == true)
    }
}

// MARK: - Skeleton Text Lines

/// Skeleton placeholder for text content (like descriptions).
struct SkeletonText: View {
    let lineCount: Int
    var lineSpacing: CGFloat = 8
    // Line height tracks `.body` so the placeholder matches the rendered
    // text under any Dynamic Type setting.
    var lineHeight: CGFloat = UIFont.preferredFont(forTextStyle: .body).lineHeight
    var lastLineWidth: CGFloat = 0.7

    var body: some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            ForEach(0..<lineCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.placeholderFill)
                    .frame(height: lineHeight)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .scaleEffect(
                        x: index == lineCount - 1 ? lastLineWidth : 1.0,
                        y: 1.0,
                        anchor: .leading
                    )
            }
        }
    }
}

// MARK: - Full Screen Loading

/// A full-screen loading view with skeleton content.
struct SkeletonLoadingView: View {
    /// Represents the type of media card to display
    enum CardType {
        case video
        case music
    }

    let title: String?
    let cardType: CardType

    @Environment(\.isCompactLayout) private var isCompactLayout

    init(title: String? = nil, cardType: CardType = .video) {
        self.title = title
        self.cardType = cardType
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                if let title = title {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, PlatformMetrics.horizontalPadding(compact: isCompactLayout))
                }

                SkeletonGrid(
                    cardType: cardType == .video ? .video : .music,
                    columns: cardType == .video ? 4 : 6,
                    rows: 2
                )
                .padding(.horizontal, PlatformMetrics.horizontalPadding(compact: isCompactLayout))
            }
            .padding(.vertical, 40)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading \(title ?? "content")")
        .accessibilityAddTraits(.updatesFrequently)
        .transition(.opacity)
    }
}

// MARK: - Previews

#Preview("Skeleton Cards") {
    HStack(spacing: 40) {
        SkeletonCard.video
            .frame(width: 350)

        SkeletonCard.music
            .frame(width: 200)
    }
    .padding()
}

#Preview("Skeleton Grid - Video") {
    SkeletonGrid(cardType: .video, columns: 4, rows: 2)
        .padding(80)
}

#Preview("Skeleton Grid - Music") {
    SkeletonGrid(cardType: .music, columns: 6, rows: 2)
        .padding(80)
}

#Preview("Skeleton Row") {
    VStack(spacing: 40) {
        SkeletonRow(cardType: .video, count: 5)
        SkeletonRow(cardType: .music, count: 8)
    }
}

#Preview("Skeleton Text") {
    SkeletonText(lineCount: 4)
        .frame(width: 400)
        .padding()
}

#Preview("Full Loading View") {
    SkeletonLoadingView(title: "Featured Videos", cardType: .video)
}
