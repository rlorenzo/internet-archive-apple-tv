//
//  PlaybackButtonHelpers.swift
//  Internet Archive
//
//  Testable helper functions for PlaybackButton styling
//

import SwiftUI

/// Pure functions for PlaybackButton style computations
/// Extracted from PlaybackButtonContent for comprehensive unit testing
enum PlaybackButtonStyleHelpers {

    // MARK: - Scale Values

    /// Compute the scale value based on button state
    /// - Parameters:
    ///   - isPressed: Whether the button is currently pressed
    ///   - isFocused: Whether the button is currently focused
    /// - Returns: The scale factor to apply
    static func scaleValue(isPressed: Bool, isFocused: Bool) -> CGFloat {
        if isPressed {
            return 0.95
        } else if isFocused {
            return 1.08
        } else {
            return 1.0
        }
    }

    // MARK: - Shadow

    /// Compute the shadow color based on focus state
    /// - Parameter isFocused: Whether the button is focused
    /// - Returns: The shadow color
    static func shadowColor(isFocused: Bool) -> Color {
        isFocused ? Color.white.opacity(0.5) : Color.clear
    }

    // MARK: - Foreground Color

    /// Compute the foreground (text) color
    /// - Parameters:
    ///   - isPrimary: Whether this is a primary button
    ///   - isPressed: Whether the button is pressed
    /// - Returns: The foreground color
    static func foregroundColor(isPrimary: Bool, isPressed: Bool) -> Color {
        if isPrimary {
            // High contrast: black text on white button
            return isPressed ? .black.opacity(0.8) : .black
        } else {
            return isPressed ? .white.opacity(0.8) : .white
        }
    }

    // MARK: - Background Color

    /// Compute the background color
    /// - Parameters:
    ///   - isPrimary: Whether this is a primary button
    ///   - isFocused: Whether the button is focused
    ///   - isPressed: Whether the button is pressed
    /// - Returns: The background color
    static func backgroundColor(isPrimary: Bool, isFocused: Bool, isPressed: Bool) -> Color {
        if isFocused {
            // Bright white when focused for high visibility
            return isPrimary ? Color.white : Color.white.opacity(0.4)
        } else if isPrimary {
            // High contrast: white background for primary button
            return isPressed ? Color.white.opacity(0.8) : Color.white
        } else {
            // Semi-transparent for secondary
            return isPressed ? Color.white.opacity(0.3) : Color.white.opacity(0.15)
        }
    }

    // MARK: - Border Color

    /// Compute the border color
    /// - Parameters:
    ///   - isPrimary: Whether this is a primary button
    ///   - isFocused: Whether the button is focused
    ///   - isPressed: Whether the button is pressed
    /// - Returns: The border color
    static func borderColor(isPrimary: Bool, isFocused: Bool, isPressed: Bool) -> Color {
        if isFocused {
            return Color.white
        } else if isPrimary {
            return .clear
        } else {
            return isPressed ? Color.white.opacity(0.6) : Color.white.opacity(0.4)
        }
    }

    // MARK: - Border Width

    /// Compute the border width based on focus state
    /// - Parameter isFocused: Whether the button is focused
    /// - Returns: The border width in points
    static func borderWidth(isFocused: Bool) -> CGFloat {
        isFocused ? 4 : 2
    }
}
