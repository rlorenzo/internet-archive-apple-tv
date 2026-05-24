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
    // MARK: - Sizing

    /// How the thumbnail constrains its dimensions.
    ///
    /// - `.fixed`: explicit width × height in points. Use when the surrounding
    ///   layout has a known card size (tvOS rows, fixed-width components).
    /// - `.aspectRatio`: stretches to fill the available width and derives
    ///   height from the aspect ratio. Use inside adaptive `LazyVGrid` cells
    ///   on compact-width platforms (iPhone, iPad Split View) so the
    ///   thumbnail tracks the cell rather than overflowing it.
    enum Sizing {
        case fixed(CGSize)
        case aspectRatio(CGFloat)
    }

    // MARK: - Properties

    /// The Internet Archive item identifier
    let identifier: String

    /// Media type determines the placeholder icon
    let mediaType: MediaItemCard.MediaType

    /// How to size the thumbnail
    let sizing: Sizing

    /// Corner radius (default 12)
    var cornerRadius: CGFloat = 12

    // MARK: - Convenience Initializers

    /// Fixed-size thumbnail (legacy path; preferred on tvOS).
    init(
        identifier: String,
        mediaType: MediaItemCard.MediaType,
        size: CGSize,
        cornerRadius: CGFloat = 12
    ) {
        self.identifier = identifier
        self.mediaType = mediaType
        self.sizing = .fixed(size)
        self.cornerRadius = cornerRadius
    }

    /// Aspect-ratio-driven thumbnail that fills its grid cell.
    init(
        identifier: String,
        mediaType: MediaItemCard.MediaType,
        aspectRatio: CGFloat,
        cornerRadius: CGFloat = 12
    ) {
        self.identifier = identifier
        self.mediaType = mediaType
        self.sizing = .aspectRatio(aspectRatio)
        self.cornerRadius = cornerRadius
    }

    /// Resolved fixed-mode size. Returns the stored `CGSize` for fixed sizing
    /// and `.zero` for adaptive aspect-ratio sizing (which has no intrinsic
    /// width until the parent layout resolves). Kept for tests that assert
    /// the size was stored correctly.
    var size: CGSize {
        if case let .fixed(size) = sizing { return size }
        return .zero
    }

    // MARK: - Body

    var body: some View {
        sizedContent
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// The fixed-size branch sets an explicit frame and lets the AsyncImage
    /// fill it. The aspect-ratio branch uses a `Color.clear` shim to own the
    /// aspect ratio so the outer container's bounds are deterministic — then
    /// overlays the AsyncImage with `.fill` + clip so the loaded image
    /// crops-to-fill instead of dictating the container's natural size.
    @ViewBuilder
    private var sizedContent: some View {
        switch sizing {
        case .fixed(let size):
            asyncImage
                .frame(width: size.width, height: size.height)
                .clipped()
        case .aspectRatio(let ratio):
            Color.clear
                .aspectRatio(ratio, contentMode: .fit)
                .overlay {
                    asyncImage
                }
                .clipped()
        }
    }

    @ViewBuilder
    private var asyncImage: some View {
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
    }

    // MARK: - Private Views

    private var thumbnailURL: URL? {
        URL(string: "https://archive.org/services/img/\(identifier)")
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.placeholderFill)
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
    .background(Color.libraryCharcoal)
}

#Preview("Music Thumbnail") {
    MediaThumbnailView(
        identifier: "example-album",
        mediaType: .music,
        size: CGSize(width: 220, height: 220)
    )
    .padding()
    .background(Color.libraryCharcoal)
}
