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

    /// Track which button is focused for visual feedback (tvOS focus engine only)
    #if os(tvOS)
    @FocusState private var focusedButton: ButtonType?
    #endif

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
                    .lineLimit(1)
            }
            .fixedSize()
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
        }
        .buttonStyle(PlaybackButtonStyle(isPrimary: true))
        #if os(tvOS)
        .focused($focusedButton, equals: .play)
        #endif
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
                            .lineLimit(1)
                    }
                    .fixedSize()
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                }
                .buttonStyle(PlaybackButtonStyle(isPrimary: true))
                #if os(tvOS)
                .focused($focusedButton, equals: .resume)
                #endif
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
                            .lineLimit(1)
                    }
                    .fixedSize()
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                }
                .buttonStyle(PlaybackButtonStyle(isPrimary: false))
                #if os(tvOS)
                .focused($focusedButton, equals: .startOver)
                #endif
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
/// Uses a separate view to properly track focus state on tvOS.
struct PlaybackButtonStyle: ButtonStyle {
    /// Whether this is a primary (filled) or secondary (outlined) button
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        PlaybackButtonContent(
            configuration: configuration,
            isPrimary: isPrimary
        )
    }
}

/// Inner view that properly tracks focus state using @Environment(\.isFocused)
private struct PlaybackButtonContent: View {
    let configuration: ButtonStyleConfiguration
    let isPrimary: Bool

    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .foregroundStyle(foregroundColor)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(borderColor, lineWidth: isFocused ? 4 : 2)
            )
            .scaleEffect(scaleValue)
            .shadow(color: shadowColor, radius: isFocused ? 20 : 0)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.15), value: configuration.isPressed)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isFocused)
    }

    private var isPressed: Bool {
        configuration.isPressed
    }

    private var scaleValue: CGFloat {
        if isPressed {
            return 0.95
        } else if isFocused {
            return 1.08
        } else {
            return 1.0
        }
    }

    private var shadowColor: Color {
        isFocused ? Color.chromeFocus : Color.clear
    }

    private var foregroundColor: Color {
        if isPrimary {
            // High contrast: black text on white button
            return isPressed ? .black.opacity(0.8) : .black
        } else {
            return isPressed ? .white.opacity(0.8) : .white
        }
    }

    private var backgroundColor: Color {
        if isFocused {
            return isPrimary ? Color.actionPrimaryFocused : Color.chromeActive
        } else if isPrimary {
            return isPressed ? Color.actionPrimaryPressed : Color.actionPrimaryRest
        } else {
            return isPressed ? Color.chromeActive : Color.chromeRest
        }
    }

    private var borderColor: Color {
        if isFocused {
            return Color.white
        } else if isPrimary {
            return .clear
        } else {
            return isPressed ? Color.white.opacity(0.6) : Color.chromeOutline
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
    .background(Color.libraryCharcoal)
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
    .background(Color.libraryCharcoal)
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
    .background(Color.libraryCharcoal)
}
