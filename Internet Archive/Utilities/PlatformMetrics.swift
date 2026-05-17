//
//  PlatformMetrics.swift
//  Internet Archive
//
//  Adaptive sizing for tvOS / iOS / iPadOS / visionOS.
//

import UIKit

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

    // MARK: - Grid

    /// Number of grid columns for the main media browser.
    static var gridColumns: Int {
        #if os(tvOS)
        return 5
        #elseif os(visionOS)
        return 5
        #else
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return isCompactWidth ? 3 : 4
        case .phone:
            return isCompactWidth ? 2 : 3
        default:
            return 3
        }
        #endif
    }

    /// Inter-item spacing for collection view grids.
    static var gridSpacing: CGFloat {
        #if os(tvOS)
        return 40
        #elseif os(visionOS)
        return 32
        #else
        return UIDevice.current.userInterfaceIdiom == .pad ? 24 : 16
        #endif
    }

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

    // MARK: - Cards

    /// Corner radius for media item cards.
    static var cardCornerRadius: CGFloat {
        #if os(tvOS)
        return 14
        #elseif os(visionOS)
        return 20
        #else
        return UIDevice.current.userInterfaceIdiom == .pad ? 12 : 10
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
