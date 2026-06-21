//
//  Color+DesignTokens.swift
//  Internet Archive
//
//  Design-system color tokens. These are the only project-defined colors;
//  every other color in the app should resolve to a platform-adaptive
//  semantic style (.primary, .secondary, .tertiary) or a status color (.red, .blue).
//
//  See DESIGN.md for the full token spec.
//

import SwiftUI

extension Color {
    /// The single canvas color for the app, matching the launch screen anchor.
    /// sRGB(0.133, 0.133, 0.133) — a neutral charcoal, untinted by intent
    /// (see DESIGN.md "The Untinted Charcoal Rule").
    static let libraryCharcoal = Color(red: 0.133, green: 0.133, blue: 0.133)

    /// Fill color for thumbnail and avatar placeholders shown before an
    /// image loads, or when an image fails. Always paired with a centered
    /// SF Symbol glyph in `.secondary`. Matches the DESIGN.md spec
    /// (`placeholder-fill: #80808080`, 50% gray alpha).
    static let placeholderFill = Color.gray.opacity(0.5)

    /// The dark scrim used as the track behind on-image progress bars.
    /// The only on-image overlay tint in the system.
    static let surfaceOverlayDim = Color.black.opacity(0.6)

    // MARK: - Chrome (white-on-charcoal interactive surface chrome)

    /// Subtle resting fill for interactive surfaces: button backgrounds at rest,
    /// selected list-item highlight, info indicator chips.
    static let chromeRest = Color.white.opacity(0.15)

    /// Engaged or pressed fill for interactive surfaces.
    static let chromeActive = Color.white.opacity(0.3)

    /// Border and inactive icon stroke on the dark canvas. Also the resting
    /// outline weight on bordered chrome.
    static let chromeOutline = Color.white.opacity(0.4)

    /// Focus halo shadow color. Pairs with the focus-state shadow radius
    /// in `TVCardButtonStyle` and the playback / favorite button styles.
    /// 60% white matches the card glow and the DESIGN.md elevation spec
    /// (`shadow(color: .white.opacity(0.6), radius: 25)`) so every focused
    /// surface lights up with the same halo.
    static let chromeFocus = Color.white.opacity(0.6)

    // MARK: - Skeleton (loading-state placeholder ramp)

    /// Quieter fill for secondary skeleton elements (subtitle rows, etc.).
    /// One step below `placeholderFill` for visual rhythm in loading states.
    static let skeletonSubtle = Color.gray.opacity(0.2)

    // MARK: - Divider

    /// Hairline divider on the dark canvas. Same hue family as `chromeOutline`
    /// but with the lower opacity required for static separators.
    static let surfaceDivider = Color.gray.opacity(0.3)

    // MARK: - Favorite (status palette for the heart button)

    /// Resting fill for the favorited heart button background.
    static let favoriteRest = Color.red.opacity(0.8)

    /// Pressed-state fill for the favorited heart button background.
    static let favoritePressed = Color.red.opacity(0.7)

    /// Focus halo / border color for the favorited heart button.
    static let favoriteFocusGlow = Color.red.opacity(0.6)

    // MARK: - Action (primary action surface ramp: Play, Resume)
    //
    // White-on-charcoal ramp for the primary playback buttons. Anchored at
    // full white (resting); steps down by small amounts so focus and press
    // states stay legible at TV viewing distance without flashing.

    /// Resting fill for the primary action button surface.
    static let actionPrimaryRest = Color.white

    /// Focused fill: one step quieter than `actionPrimaryRest` to avoid
    /// TV-brightness flash in a dim living room. Scale, border, and glow
    /// carry the focus signal; this only de-emphasizes the surface.
    static let actionPrimaryFocused = Color.white.opacity(0.95)

    /// Pressed fill for the primary action button surface.
    static let actionPrimaryPressed = Color.white.opacity(0.8)
}
