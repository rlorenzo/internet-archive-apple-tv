//
//  ItemDetailPlaceholderView.swift
//  Internet Archive
//
//  Temporary placeholder view for item detail navigation (to be implemented in Phase 4)
//

import SwiftUI

/// Temporary placeholder view for item detail navigation
///
/// This unified placeholder view supports both video and music items,
/// displaying the appropriate icon based on media type.
struct ItemDetailPlaceholderView: View {
    let item: SearchResult
    let mediaType: MediaItemCard.MediaType

    @Environment(\.dismiss) private var dismiss

    init(item: SearchResult, mediaType: MediaItemCard.MediaType = .video) {
        self.item = item
        self.mediaType = mediaType
    }

    private var iconName: String {
        switch mediaType {
        case .video:
            return "film"
        case .music:
            return "music.note"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(item.safeTitle)
                .font(.title)
                .fontWeight(.bold)

            if let creator = item.creator {
                Text(creator)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            if let year = item.year, mediaType == .music {
                Text(year)
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            }

            Text("Item detail view coming in Phase 4")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .padding(.top, 20)

            Button("Back") {
                dismiss()
            }
            .padding(.top, 40)
        }
        .padding()
        .navigationTitle(item.safeTitle)
        .onPlayPauseCommand {
            // Placeholder for future play action
        }
        .onExitCommand {
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview("Video Item") {
    NavigationStack {
        ItemDetailPlaceholderView(
            item: SearchResult(identifier: "test", title: "Test Video", creator: "Test Creator"),
            mediaType: .video
        )
    }
}

#Preview("Music Item") {
    NavigationStack {
        ItemDetailPlaceholderView(
            item: SearchResult(identifier: "test", title: "Test Music", creator: "Test Artist", year: "2024"),
            mediaType: .music
        )
    }
}
