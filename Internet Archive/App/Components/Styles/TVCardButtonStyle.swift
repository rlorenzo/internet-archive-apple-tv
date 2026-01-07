//
//  TVCardButtonStyle.swift
//  Internet Archive
//
//  Custom button style for tvOS card focus effects
//

import SwiftUI

/// A button style that provides tvOS-native focus effects for card-based interfaces.
///
/// This style applies:
/// - Scale animation on focus (lift effect)
/// - Shadow animation on focus
/// - Smooth transitions between states
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
    var focusedScale: CGFloat = 1.05

    /// Shadow radius when focused
    var focusedShadowRadius: CGFloat = 20

    /// Shadow opacity when focused (0.0 to 1.0)
    var focusedShadowOpacity: Double = 0.4

    /// Animation duration for focus transitions
    var animationDuration: Double = 0.2

    // MARK: - Environment

    @Environment(\.isFocused) private var isFocused

    // MARK: - Body

    func makeBody(configuration: Configuration) -> some View {
        TVCardButtonContent(
            configuration: configuration,
            focusedScale: focusedScale,
            focusedShadowRadius: focusedShadowRadius,
            focusedShadowOpacity: focusedShadowOpacity,
            animationDuration: animationDuration
        )
    }
}

// MARK: - Internal Content View

/// Internal view that handles focus state tracking
private struct TVCardButtonContent: View {
    let configuration: ButtonStyle.Configuration
    let focusedScale: CGFloat
    let focusedShadowRadius: CGFloat
    let focusedShadowOpacity: Double
    let animationDuration: Double

    @FocusState private var isFocused: Bool

    var body: some View {
        configuration.label
            .scaleEffect(isFocused ? focusedScale : 1.0)
            .shadow(
                color: .black.opacity(isFocused ? focusedShadowOpacity : 0),
                radius: isFocused ? focusedShadowRadius : 0,
                x: 0,
                y: isFocused ? 10 : 0
            )
            .animation(.easeInOut(duration: animationDuration), value: isFocused)
            .focusable()
            .focused($isFocused)
    }
}

// MARK: - View Extension

extension View {
    /// Applies the tvOS card button style with default parameters
    func tvCardStyle() -> some View {
        self.buttonStyle(TVCardButtonStyle())
    }

    /// Applies the tvOS card button style with custom parameters
    ///
    /// - Parameters:
    ///   - scale: Scale factor when focused (default: 1.05)
    ///   - shadowRadius: Shadow radius when focused (default: 20)
    ///   - shadowOpacity: Shadow opacity when focused (default: 0.4)
    func tvCardStyle(
        scale: CGFloat,
        shadowRadius: CGFloat = 20,
        shadowOpacity: Double = 0.4
    ) -> some View {
        self.buttonStyle(TVCardButtonStyle(
            focusedScale: scale,
            focusedShadowRadius: shadowRadius,
            focusedShadowOpacity: shadowOpacity
        ))
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
