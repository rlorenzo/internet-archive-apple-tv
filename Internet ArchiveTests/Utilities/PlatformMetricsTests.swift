//
//  PlatformMetricsTests.swift
//  Internet ArchiveTests
//
//  Unit tests for the adaptive sizing constants returned by `PlatformMetrics`.
//  The test target compiles for tvOS, so only the tvOS branch is reachable
//  here — the iOS / iPadOS / visionOS branches are verified at compile time
//  via the four-destination `xcodebuild build` matrix.
//

import Testing
import CoreGraphics
@testable import Internet_Archive

@Suite("PlatformMetrics (tvOS path)")
@MainActor
struct PlatformMetricsTests {

    // MARK: - horizontalPadding(compact:)

    @Test("tvOS returns fixed 80pt regardless of compact:")
    func horizontalPaddingFixedOnTV() {
        #expect(PlatformMetrics.horizontalPadding(compact: nil) == 80)
        #expect(PlatformMetrics.horizontalPadding(compact: true) == 80)
        #expect(PlatformMetrics.horizontalPadding(compact: false) == 80)
    }

    @Test("default argument matches explicit nil")
    func horizontalPaddingDefaultArg() {
        let withDefault = PlatformMetrics.horizontalPadding()
        let withNil = PlatformMetrics.horizontalPadding(compact: nil)
        #expect(withDefault == withNil)
    }

    // MARK: - controlButtonSize

    @Test("primary control button is 110pt on tvOS for 10-foot UI")
    func controlButtonSizeOnTV() {
        #expect(PlatformMetrics.controlButtonSize == 110)
    }

    @Test("primary control is larger than secondary control")
    func controlSizeHierarchy() {
        #expect(PlatformMetrics.controlButtonSize > PlatformMetrics.secondaryControlButtonSize)
    }

    // MARK: - secondaryControlButtonSize

    @Test("secondary control button is 90pt on tvOS")
    func secondaryControlButtonSizeOnTV() {
        #expect(PlatformMetrics.secondaryControlButtonSize == 90)
    }

    // MARK: - Type / API surface

    @Test("all metrics return positive sizes")
    func metricsArePositive() {
        #expect(PlatformMetrics.horizontalPadding(compact: nil) > 0)
        #expect(PlatformMetrics.controlButtonSize > 0)
        #expect(PlatformMetrics.secondaryControlButtonSize > 0)
    }
}
