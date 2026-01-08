//
//  PlaybackButtons.swift
//  Internet Archive
//
//  Playback control buttons for item detail view (Play, Resume, Start Over)
//

import SwiftUI

/// Playback control buttons that adapt based on saved progress.
///
/// When there is no saved progress, shows a single "Play" button.
/// When there is saved progress, shows "Resume" and "Start Over" buttons
/// with time remaining information.
///
/// ## Usage
/// ```swift
/// PlaybackButtons(
///     savedProgress: progress,
///     onPlay: { startPlayback() },
///     onResume: { resumePlayback() },
///     onStartOver: { startFromBeginning() }
/// )
/// ```
struct PlaybackButtons: View {
    // MARK: - Properties

    /// Saved playback progress (nil if no progress saved)
    let savedProgress: PlaybackProgress?

    /// Action when Play button is tapped (no saved progress)
    let onPlay: () -> Void

    /// Action when Resume button is tapped
    let onResume: () -> Void

    /// Action when Start Over button is tapped
    let onStartOver: () -> Void

    // MARK: - State

    /// Track which button is focused for visual feedback
    @FocusState private var focusedButton: ButtonType?

    private enum ButtonType: Hashable {
        case play
        case resume
        case startOver
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let progress = savedProgress, progress.hasResumableProgress {
                // Has saved progress: show Resume and Start Over
                resumeButtons(progress: progress)
            } else {
                // No saved progress: show Play
                playButton
            }
        }
    }

    // MARK: - Play Button (No Progress)

    private var playButton: some View {
        Button(action: onPlay) {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.title2)
                Text("Play")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(minWidth: 200)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
        }
        .buttonStyle(PlaybackButtonStyle(isPrimary: true))
        .focused($focusedButton, equals: .play)
        .accessibilityLabel("Play")
        .accessibilityHint("Double-tap to start playback")
    }

    // MARK: - Resume Buttons (With Progress)

    private func resumeButtons(progress: PlaybackProgress) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 20) {
                // Resume button (primary)
                Button(action: onResume) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.title2)
                        Text("Resume")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(minWidth: 180)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                }
                .buttonStyle(PlaybackButtonStyle(isPrimary: true))
                .focused($focusedButton, equals: .resume)
                .accessibilityLabel("Resume")
                .accessibilityHint("Double-tap to continue from where you left off")

                // Start Over button (secondary)
                Button(action: onStartOver) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                        Text("Start Over")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .frame(minWidth: 180)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                }
                .buttonStyle(PlaybackButtonStyle(isPrimary: false))
                .focused($focusedButton, equals: .startOver)
                .accessibilityLabel("Start Over")
                .accessibilityHint("Double-tap to start playback from the beginning")
            }

            // Time remaining info
            Text(progress.formattedTimeRemaining)
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
                .accessibilityLabel("Time remaining: \(progress.formattedTimeRemaining)")
        }
    }
}

// MARK: - Playback Button Style

/// Custom button style for playback buttons with tvOS focus effects.
struct PlaybackButtonStyle: ButtonStyle {
    /// Whether this is a primary (filled) or secondary (outlined) button
    let isPrimary: Bool

    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor(isPressed: configuration.isPressed))
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(borderColor(isPressed: configuration.isPressed), lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        if isPrimary {
            // High contrast: black text on white button
            return isPressed ? .black.opacity(0.8) : .black
        } else {
            return isPressed ? .white.opacity(0.8) : .white
        }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isPrimary {
            // High contrast: white background for primary button
            return isPressed ? Color.white.opacity(0.8) : Color.white
        } else {
            // Semi-transparent for secondary
            return isPressed ? Color.white.opacity(0.3) : Color.white.opacity(0.15)
        }
    }

    private func borderColor(isPressed: Bool) -> Color {
        if isPrimary {
            return .clear
        } else {
            return isPressed ? Color.white.opacity(0.6) : Color.white.opacity(0.4)
        }
    }
}

// MARK: - Preview

#Preview("No Progress") {
    PlaybackButtons(
        savedProgress: nil,
        onPlay: { print("Play") },
        onResume: { print("Resume") },
        onStartOver: { print("Start Over") }
    )
    .padding(50)
    .background(Color.black)
}

#Preview("With Progress") {
    let progress = PlaybackProgress.video(MediaProgressInfo(
        identifier: "test",
        filename: "test.mp4",
        currentTime: 1200,
        duration: 5400,
        title: "Test Video",
        imageURL: nil
    ))

    PlaybackButtons(
        savedProgress: progress,
        onPlay: { print("Play") },
        onResume: { print("Resume") },
        onStartOver: { print("Start Over") }
    )
    .padding(50)
    .background(Color.black)
}

#Preview("Audio Progress") {
    let progress = PlaybackProgress.audio(MediaProgressInfo(
        identifier: "test",
        filename: "test.mp3",
        currentTime: 600,
        duration: 3600,
        title: "Test Album",
        imageURL: nil
    ))

    PlaybackButtons(
        savedProgress: progress,
        onPlay: { print("Play") },
        onResume: { print("Resume") },
        onStartOver: { print("Start Over") }
    )
    .padding(50)
    .background(Color.black)
}
