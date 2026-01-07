//
//  PlaceholderCard.swift
//  Internet Archive
//
//  Reusable skeleton placeholder card for loading states
//

import SwiftUI

/// A skeleton placeholder card displayed while content is loading.
///
/// This view provides a consistent loading state appearance across
/// the app with configurable aspect ratio for different content types.
///
/// ## Usage
/// ```swift
/// // Video card (16:9)
/// PlaceholderCard(aspectRatio: 16 / 9)
///
/// // Album art (square)
/// PlaceholderCard(aspectRatio: 1)
/// ```
struct PlaceholderCard: View {
    /// The aspect ratio of the thumbnail image
    let aspectRatio: CGFloat

    /// The height of the title placeholder line
    var titleHeight: CGFloat = 20

    /// The height of the subtitle placeholder line
    var subtitleHeight: CGFloat = 16

    /// The width of the subtitle placeholder line
    var subtitleWidth: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .aspectRatio(aspectRatio, contentMode: .fit)

            // Text placeholders
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: titleHeight)
                    .frame(maxWidth: .infinity, alignment: .leading)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: subtitleWidth, height: subtitleHeight)
            }
        }
        .focusable()
    }
}

// MARK: - Convenience Initializers

extension PlaceholderCard {
    /// Creates a video placeholder card with 16:9 aspect ratio
    static var video: PlaceholderCard {
        PlaceholderCard(aspectRatio: 16 / 9)
    }

    /// Creates a music/album placeholder card with square aspect ratio
    static var music: PlaceholderCard {
        PlaceholderCard(aspectRatio: 1, titleHeight: 18, subtitleHeight: 14, subtitleWidth: 120)
    }
}

// MARK: - Preview

#Preview("Video Card") {
    PlaceholderCard.video
        .frame(width: 350)
        .padding()
}

#Preview("Music Card") {
    PlaceholderCard.music
        .frame(width: 200)
        .padding()
}
