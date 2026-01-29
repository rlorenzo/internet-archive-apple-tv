//
//  MediaThumbnailView.swift
//  Internet Archive
//
//  Reusable thumbnail view for media items with placeholder support
//

import SwiftUI

/// A reusable thumbnail view for media items.
///
/// Displays an async-loaded image from Internet Archive's thumbnail service
/// with a placeholder shown during loading or on failure.
///
/// ## Usage
/// ```swift
/// MediaThumbnailView(
///     identifier: "some-archive-item",
///     mediaType: .video,
///     size: CGSize(width: 380, height: 214)
/// )
/// ```
struct MediaThumbnailView: View {
    // MARK: - Properties

    /// The Internet Archive item identifier
    let identifier: String

    /// Media type determines the placeholder icon
    let mediaType: MediaItemCard.MediaType

    /// Size of the thumbnail
    let size: CGSize

    /// Corner radius (default 12)
    var cornerRadius: CGFloat = 12

    // MARK: - Body

    var body: some View {
        AsyncImage(url: thumbnailURL) { phase in
            switch phase {
            case .empty, .failure:
                placeholderView
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    // MARK: - Private Views

    private var thumbnailURL: URL? {
        URL(string: "https://archive.org/services/img/\(identifier)")
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: mediaType.placeholderIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            )
    }
}

// MARK: - Preview

#Preview("Video Thumbnail") {
    MediaThumbnailView(
        identifier: "example-video",
        mediaType: .video,
        size: CGSize(width: 380, height: 214)
    )
    .padding()
    .background(Color.black)
}

#Preview("Music Thumbnail") {
    MediaThumbnailView(
        identifier: "example-album",
        mediaType: .music,
        size: CGSize(width: 220, height: 220)
    )
    .padding()
    .background(Color.black)
}
