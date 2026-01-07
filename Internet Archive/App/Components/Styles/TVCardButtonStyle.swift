//
//  TVCardButtonStyle.swift
//  Internet Archive
//
//  Custom button style for tvOS card focus effects
//

import SwiftUI

/// A button style that provides tvOS-native focus effects for card-based interfaces.
///
/// This style uses tvOS's native `.card` button style which provides proper focus handling,
/// then wraps the content in a focusable container to add custom visual effects.
///
/// ## Usage
/// ```swift
/// Button(action: { /* handle tap */ }) {
///     MediaItemCard(identifier: "movie", title: "Title", mediaType: .video)
/// }
/// .buttonStyle(TVCardButtonStyle())
/// ```
///
/// Or use the convenience modifier:
/// ```swift
/// Button(action: { /* handle tap */ }) {
///     MediaItemCard(identifier: "movie", title: "Title", mediaType: .video)
/// }
/// .tvCardStyle()
/// ```
struct TVCardButtonStyle: ButtonStyle {
    // MARK: - Configuration

    /// Scale factor when focused (1.0 = no change)
    var focusedScale: CGFloat = 1.08

    /// Animation duration for focus transitions
    var animationDuration: Double = 0.2

    // MARK: - Body

    func makeBody(configuration: Configuration) -> some View {
        FocusableCardContent(
            label: configuration.label,
            isPressed: configuration.isPressed,
            focusedScale: focusedScale,
            animationDuration: animationDuration
        )
    }
}

// MARK: - Focusable Card Content

/// A wrapper view that properly tracks focus state on tvOS
private struct FocusableCardContent<Label: View>: View {
    let label: Label
    let isPressed: Bool
    let focusedScale: CGFloat
    let animationDuration: Double

    @Environment(\.isFocused) private var envFocused
    @FocusState private var isFocused: Bool

    private var isCurrentlyFocused: Bool {
        envFocused || isFocused
    }

    var body: some View {
        label
            .scaleEffect(isCurrentlyFocused ? focusedScale : 1.0)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .brightness(isCurrentlyFocused ? 0.1 : 0)
            .shadow(
                color: .white.opacity(isCurrentlyFocused ? 0.6 : 0),
                radius: isCurrentlyFocused ? 25 : 0
            )
            .shadow(
                color: .black.opacity(isCurrentlyFocused ? 0.5 : 0),
                radius: isCurrentlyFocused ? 20 : 0,
                x: 0,
                y: isCurrentlyFocused ? 15 : 0
            )
            .zIndex(isCurrentlyFocused ? 1 : 0)
            .animation(.easeInOut(duration: animationDuration), value: isCurrentlyFocused)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .focused($isFocused)
    }
}

// MARK: - View Extension

extension View {
    /// Applies the tvOS card button style with default parameters
    func tvCardStyle() -> some View {
        self.buttonStyle(TVCardButtonStyle())
    }

    /// Applies the tvOS card button style with custom scale
    ///
    /// - Parameter scale: Scale factor when focused (default: 1.08)
    func tvCardStyle(scale: CGFloat) -> some View {
        self.buttonStyle(TVCardButtonStyle(focusedScale: scale))
    }
}

// MARK: - Preview

#Preview("Card Focus Effect") {
    HStack(spacing: 40) {
        Button {
            // Card 1 action
        } label: {
            VStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
                    .frame(width: 200, height: 112)
                Text("Card 1")
            }
        }
        .tvCardStyle()

        Button {
            // Card 2 action
        } label: {
            VStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green)
                    .frame(width: 200, height: 112)
                Text("Card 2")
            }
        }
        .tvCardStyle()

        Button {
            // Card 3 action
        } label: {
            VStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange)
                    .frame(width: 200, height: 112)
                Text("Card 3")
            }
        }
        .tvCardStyle()
    }
    .padding()
}
