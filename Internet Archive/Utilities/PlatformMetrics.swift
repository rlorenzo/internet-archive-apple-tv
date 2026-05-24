//
//  PlatformMetrics.swift
//  Internet Archive
//
//  Adaptive sizing for tvOS / iOS / iPadOS / visionOS.
//

import SwiftUI
import UIKit

extension EnvironmentValues {
    /// Resolved compact-width flag, derived from `horizontalSizeClass`.
    ///
    /// - `nil` on tvOS — the focus engine carries the 10-foot layout, no size class concept.
    /// - `true` on iOS / iPadOS / visionOS when `horizontalSizeClass == .compact`
    ///   (iPhone portrait, iPhone non-Plus landscape, iPad Split View narrow column).
    /// - `false` on regular-width touch / spatial surfaces (iPad full screen, iPhone Plus
    ///   landscape, visionOS standard window).
    ///
    /// Use directly in views via `@Environment(\.isCompactLayout)` instead of duplicating
    /// the `#if !os(tvOS)` + `horizontalSizeClass` read at every call site.
    @MainActor
    var isCompactLayout: Bool? {
        #if os(tvOS)
        return nil
        #else
        guard let horizontalSizeClass else { return nil }
        return horizontalSizeClass == .compact
        #endif
    }
}

/// Sizing constants that differ between TV (10-foot UI) and touch / spatial platforms.
///
/// Call sites should use these accessors instead of hard-coding pixel values so the
/// same SwiftUI / UIKit code lays out correctly across all four supported platforms.
///
/// SwiftUI views that already read `@Environment(\.horizontalSizeClass)` should pass
/// the resolved value via `compact:` for tighter accuracy. Callers that omit it fall
/// back to the foreground window's reported width — which tracks iPad Split View,
/// Stage Manager, and visionOS window resizing far more reliably than `UIScreen.main`.
@MainActor
enum PlatformMetrics {

    // MARK: - Padding

    /// Horizontal padding for top-level content (e.g. collection browser, headers).
    static func horizontalPadding(compact: Bool? = nil) -> CGFloat {
        #if os(tvOS)
        return 80
        #elseif os(visionOS)
        return 48
        #else
        let isCompact = compact ?? isCompactWidth
        if isCompact { return 16 }
        return UIDevice.current.userInterfaceIdiom == .pad ? 32 : 16
        #endif
    }

    // MARK: - Controls

    /// Diameter for primary transport controls (play / pause).
    static var controlButtonSize: CGFloat {
        #if os(tvOS)
        return 110
        #elseif os(visionOS)
        return 64
        #else
        return UIDevice.current.userInterfaceIdiom == .pad ? 60 : 48
        #endif
    }

    /// Diameter for secondary transport controls (skip, shuffle).
    static var secondaryControlButtonSize: CGFloat {
        #if os(tvOS)
        return 90
        #elseif os(visionOS)
        return 52
        #else
        return UIDevice.current.userInterfaceIdiom == .pad ? 48 : 40
        #endif
    }

    // MARK: - Private helpers

    #if !os(tvOS) && !os(visionOS)
    /// Heuristic for "compact" width when no explicit size class is supplied.
    /// Reads the active foreground window's bounds so it tracks iPad Split View
    /// and Stage Manager. `UIScreen.main` is only consulted as a last resort.
    private static var isCompactWidth: Bool {
        let width = foregroundWindowWidth ?? UIScreen.main.bounds.width
        return width < 600
    }

    private static var foregroundWindowWidth: CGFloat? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter {
                $0.activationState == .foregroundActive
                    || $0.activationState == .foregroundInactive
            }
        let window = scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? scenes.flatMap(\.windows).first
        return window?.bounds.width
    }
    #endif
}
