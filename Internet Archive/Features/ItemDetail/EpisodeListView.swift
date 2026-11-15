//
//  EpisodeListView.swift
//  Internet Archive
//
//  Episode picker for multi-video items (e.g. "Complete Series" uploads).
//

import SwiftUI

/// Numbered list of an item's episodes with running time and watch progress.
/// Selecting a row plays that episode (resuming it if partly watched).
struct EpisodeListView: View {
    let episodes: [VideoEpisode]

    /// Saved progress keyed by episode filename
    let progressByFilename: [String: PlaybackProgress]

    /// Most recently watched episode, highlighted at rest
    let lastWatchedFilename: String?

    let onSelect: (VideoEpisode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Episodes")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)

            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(Array(episodes.enumerated()), id: \.element.id) { index, episode in
                    EpisodeRow(
                        number: index + 1,
                        episode: episode,
                        progress: progressByFilename[episode.filename],
                        isLastWatched: episode.filename == lastWatchedFilename,
                        onSelect: { onSelect(episode) }
                    )
                }
            }
        }
        .tvFocusSection()
    }
}

// MARK: - Row

private struct EpisodeRow: View {
    let number: Int
    let episode: VideoEpisode
    let progress: PlaybackProgress?
    let isLastWatched: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 20) {
                Text("\(number)")
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 44, alignment: .trailing)

                VStack(alignment: .leading, spacing: 8) {
                    Text(episode.title)
                        .font(.body)
                        .lineLimit(2)
                    if let progress, !progress.isComplete {
                        ProgressView(value: progress.progressPercentage)
                            .tint(.primary)
                            .frame(maxWidth: 240)
                    }
                }

                Spacer(minLength: 12)

                if progress?.isComplete == true {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                if let duration = episode.duration {
                    Text(EpisodeListHelpers.formatDuration(duration))
                        .font(.callout)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isLastWatched ? Color.chromeRest : Color.clear)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(EpisodeListHelpers.accessibilityLabel(
            number: number,
            episode: episode,
            progress: progress
        ))
        .accessibilityHint(progress.map { $0.isComplete ? "Double-tap to watch again" : "Double-tap to resume" }
            ?? "Double-tap to play")
    }
}

// MARK: - Helpers

enum EpisodeListHelpers {
    /// "44 min", "1 hr 5 min", or "<1 min"
    static func formatDuration(_ seconds: Double) -> String {
        // Int(_:) traps on NaN, infinity, or values beyond Int's range
        guard let totalMinutes = Int(exactly: (seconds / 60).rounded()) else {
            return "Unknown duration"
        }
        guard totalMinutes > 0 else { return "<1 min" }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        switch (hours, minutes) {
        case (0, _): return "\(minutes) min"
        case (_, 0): return "\(hours) hr"
        default: return "\(hours) hr \(minutes) min"
        }
    }

    static func accessibilityLabel(number: Int, episode: VideoEpisode, progress: PlaybackProgress?) -> String {
        var parts = ["Episode \(number)", episode.title]
        if let duration = episode.duration {
            parts.append(formatDuration(duration))
        }
        if let progress {
            parts.append(progress.isComplete ? "Watched" : progress.formattedTimeRemaining)
        }
        return parts.joined(separator: ", ")
    }
}
