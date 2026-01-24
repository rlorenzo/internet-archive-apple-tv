//
//  SkeletonLoadingView.swift
//  Internet Archive
//
//  Skeleton loading views with shimmer animation for loading states
//

import SwiftUI

// MARK: - Shimmer Modifier

/// A view modifier that adds a shimmer animation effect.
///
/// This creates a gradient overlay that moves across the view,
/// providing visual feedback that content is loading.
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Adds a shimmer loading effect to the view
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Card

/// A skeleton placeholder for a media card with shimmer effect.
///
/// Use this view to show loading state for individual cards.
///
/// ## Usage
/// ```swift
/// SkeletonCard(aspectRatio: 16/9) // Video card
/// SkeletonCard(aspectRatio: 1)    // Music card
/// ```
struct SkeletonCard: View {
    let aspectRatio: CGFloat
    var titleHeight: CGFloat = 20
    var subtitleHeight: CGFloat = 16
    var subtitleWidth: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(aspectRatio, contentMode: .fit)
                .shimmer()

            // Text skeletons
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: titleHeight)
                    .shimmer()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: subtitleWidth, height: subtitleHeight)
                    .shimmer()
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
        SkeletonCard(aspectRatio: 1, titleHeight: 18, subtitleHeight: 14, subtitleWidth: 120)
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

    var body: some View {
        LazyVGrid(
            columns: gridColumns,
            spacing: 40
        ) {
            ForEach(0..<(columns * rows), id: \.self) { _ in
                switch cardType {
                case .video:
                    SkeletonCard.video
                case .music:
                    SkeletonCard.music
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        let minWidth: CGFloat = cardType == .video ? 300 : 180
        let maxWidth: CGFloat = cardType == .video ? 400 : 220

        return [
            GridItem(.adaptive(minimum: minWidth, maximum: maxWidth), spacing: 40)
        ]
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

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 40) {
                ForEach(0..<count, id: \.self) { _ in
                    switch cardType {
                    case .video:
                        SkeletonCard.video
                            .frame(width: 350)
                    case .music:
                        SkeletonCard.music
                            .frame(width: 200)
                    }
                }
            }
            .padding(.horizontal, 80)
        }
    }
}

// MARK: - Skeleton Text Lines

/// Skeleton placeholder for text content (like descriptions).
struct SkeletonText: View {
    let lineCount: Int
    var lineSpacing: CGFloat = 8
    var lastLineWidth: CGFloat = 0.7

    var body: some View {
        VStack(alignment: .leading, spacing: lineSpacing) {
            ForEach(0..<lineCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 16)
                    .frame(
                        maxWidth: index == lineCount - 1 ? .infinity : .infinity,
                        alignment: .leading
                    )
                    .scaleEffect(
                        x: index == lineCount - 1 ? lastLineWidth : 1.0,
                        y: 1.0,
                        anchor: .leading
                    )
                    .shimmer()
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
                        .padding(.horizontal, 80)
                }

                SkeletonGrid(
                    cardType: cardType == .video ? .video : .music,
                    columns: cardType == .video ? 4 : 6,
                    rows: 2
                )
                .padding(.horizontal, 80)
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

#Preview("Shimmer Effect") {
    RoundedRectangle(cornerRadius: 12)
        .fill(Color.gray.opacity(0.3))
        .frame(width: 300, height: 170)
        .shimmer()
        .padding()
}

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
