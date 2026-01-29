//
//  FavoriteButton.swift
//  Internet Archive
//
//  Animated favorite toggle button for item detail view
//

import SwiftUI
import UIKit

// MARK: - Animation Helper

/// Performs a bounce animation on a scale binding.
/// - Parameters:
///   - scale: The binding to animate
///   - peakScale: The maximum scale during the bounce (default 1.3)
private func animateBounce(scale: Binding<CGFloat>, peakScale: CGFloat = 1.3) {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
        scale.wrappedValue = peakScale
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale.wrappedValue = 1.0
        }
    }
}

/// An animated favorite toggle button with heart icon.
///
/// This button displays:
/// - Filled heart when favorited
/// - Outlined heart when not favorited
/// - Scale animation on toggle
/// - VoiceOver accessibility
///
/// ## Usage
/// ```swift
/// @State private var isFavorited = false
///
/// FavoriteButton(
///     isFavorited: $isFavorited,
///     onToggle: { saveFavorite() }
/// )
/// ```
struct FavoriteButton: View {
    // MARK: - Properties

    /// Whether the item is currently favorited
    @Binding var isFavorited: Bool

    /// Action when the favorite state changes
    let onToggle: () -> Void

    // MARK: - State

    /// Animation scale for bounce effect
    @State private var animationScale: CGFloat = 1.0

    // MARK: - Body

    var body: some View {
        Button(action: toggleFavorite) {
            HStack(spacing: 12) {
                Image(systemName: isFavorited ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundStyle(isFavorited ? .red : .primary)
                    .scaleEffect(animationScale)

                Text(isFavorited ? "Favorited" : "Add to Favorites")
                    .font(.title3)
                    .fontWeight(.medium)
            }
            .frame(minWidth: 220)
            .padding(.horizontal, 30)
            .padding(.vertical, 16)
        }
        .buttonStyle(FavoriteButtonStyle(isFavorited: isFavorited))
        .accessibilityLabel(isFavorited ? "Remove from favorites" : "Add to favorites")
        .accessibilityHint("Double-tap to \(isFavorited ? "remove this item from" : "add this item to") your favorites")
        .accessibilityValue(isFavorited ? "Favorited" : "Not favorited")
    }

    // MARK: - Actions

    private func toggleFavorite() {
        animateBounce(scale: $animationScale)
        onToggle()

        // Announce change to VoiceOver (isFavorited now reflects the NEW state after toggle)
        let announcement = isFavorited ? "Added to favorites" : "Removed from favorites"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}

// MARK: - Favorite Button Style

/// Custom button style for the favorite button with tvOS focus effects.
/// Uses a separate view to properly track focus state on tvOS.
struct FavoriteButtonStyle: ButtonStyle {
    let isFavorited: Bool

    func makeBody(configuration: Configuration) -> some View {
        FavoriteButtonContent(
            configuration: configuration,
            isFavorited: isFavorited
        )
    }
}

/// Inner view that properly tracks focus state using @Environment(\.isFocused)
private struct FavoriteButtonContent: View {
    let configuration: ButtonStyleConfiguration
    let isFavorited: Bool

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        configuration.label
            .foregroundStyle(isFavorited ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(borderColor, lineWidth: isFocused ? 4 : 2)
            )
            .scaleEffect(scaleValue)
            .shadow(color: shadowColor, radius: isFocused ? 15 : 0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    private var isPressed: Bool {
        configuration.isPressed
    }

    private var scaleValue: CGFloat {
        if isPressed {
            return 0.95
        } else if isFocused {
            return 1.05
        } else {
            return 1.0
        }
    }

    private var shadowColor: Color {
        if isFocused {
            return isFavorited ? Color.red.opacity(0.6) : Color.white.opacity(0.4)
        }
        return Color.clear
    }

    private var backgroundColor: Color {
        if isFocused {
            return isFavorited ? Color.red : Color.white.opacity(0.3)
        } else if isFavorited {
            return isPressed ? Color.red.opacity(0.7) : Color.red.opacity(0.8)
        } else {
            return isPressed ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
        }
    }

    private var borderColor: Color {
        if isFocused {
            return isFavorited ? Color.red : Color.white
        }
        return isFavorited ? Color.red.opacity(0.6) : Color.gray.opacity(0.4)
    }
}

// MARK: - Compact Favorite Button

/// A compact favorite button showing only the heart icon.
///
/// Use this for smaller UI contexts like grid items or toolbars.
struct CompactFavoriteButton: View {
    @Binding var isFavorited: Bool
    let onToggle: () -> Void

    @State private var animationScale: CGFloat = 1.0

    var body: some View {
        Button(action: toggleFavorite) {
            Image(systemName: isFavorited ? "heart.fill" : "heart")
                .font(.title2)
                .foregroundStyle(isFavorited ? .red : .secondary)
                .scaleEffect(animationScale)
                .frame(width: 50, height: 50)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorited ? "Remove from favorites" : "Add to favorites")
    }

    private func toggleFavorite() {
        animateBounce(scale: $animationScale, peakScale: 1.4)
        onToggle()

        // Announce change to VoiceOver (isFavorited now reflects the NEW state after toggle)
        let announcement = isFavorited ? "Added to favorites" : "Removed from favorites"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}

// MARK: - Preview

#Preview("Not Favorited") {
    @Previewable @State var isFavorited = false

    FavoriteButton(
        isFavorited: $isFavorited,
        onToggle: { isFavorited.toggle() }
    )
    .padding(50)
    .background(Color.black)
}

#Preview("Favorited") {
    @Previewable @State var isFavorited = true

    FavoriteButton(
        isFavorited: $isFavorited,
        onToggle: { isFavorited.toggle() }
    )
    .padding(50)
    .background(Color.black)
}

#Preview("Compact Button") {
    @Previewable @State var isFavorited = false

    HStack(spacing: 20) {
        CompactFavoriteButton(
            isFavorited: .constant(false),
            onToggle: {}
        )
        CompactFavoriteButton(
            isFavorited: .constant(true),
            onToggle: {}
        )
    }
    .padding(50)
    .background(Color.black)
}
