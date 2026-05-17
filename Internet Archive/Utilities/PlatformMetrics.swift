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
    static var horizontalPadding: CGFloat {
        #if os(tvOS)
        return 80
        #elseif os(visionOS)
        return 48
        #else
        if isCompactWidth { return 16 }
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
    /// Heuristic for "compact" width on iPhone / iPad split-screen.
    /// SwiftUI views with access to `@Environment(\.horizontalSizeClass)` should pass
    /// their explicit size class instead; this is a fallback for UIKit / global access.
    private static var isCompactWidth: Bool {
        let bounds = UIScreen.main.bounds
        return Swift.min(bounds.width, bounds.height) < 600
    }
    #endif
}
