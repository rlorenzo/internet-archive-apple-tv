//
//  AccessibilityTests.swift
//  Internet ArchiveTests
//
//  Comprehensive accessibility tests for VoiceOver support
//

import XCTest
@testable import Internet_Archive

/// Tests to verify accessibility properties are correctly configured across the app.
///
/// `Slider` is gated to tvOS — its accessibility increment / decrement / step API
/// only exists in the focus-engine implementation, so we only run these tests when
/// the test target is built for tvOS.
#if os(tvOS)
@MainActor
final class AccessibilityTests: XCTestCase {

    // MARK: - Slider Accessibility Tests

    func testSlider_hasAdjustableTrait() {
        let slider = Slider()

        XCTAssertTrue(slider.accessibilityTraits.contains(.adjustable),
                      "Slider should have .adjustable trait for VoiceOver")
    }

    func testSlider_accessibilityIncrement_increasesValue() {
        let slider = Slider()
        slider.min = 0
        slider.max = 100
        slider.set(value: 50, animated: false)

        let initialValue = slider.value
        slider.accessibilityIncrement()

        XCTAssertGreaterThan(slider.value, initialValue,
                            "accessibilityIncrement should increase slider value")
    }

    func testSlider_accessibilityDecrement_decreasesValue() {
        let slider = Slider()
        slider.min = 0
        slider.max = 100
        slider.set(value: 50, animated: false)

        let initialValue = slider.value
        slider.accessibilityDecrement()

        XCTAssertLessThan(slider.value, initialValue,
                         "accessibilityDecrement should decrease slider value")
    }

    func testSlider_accessibilityIncrement_respectsMax() {
        let slider = Slider()
        slider.min = 0
        slider.max = 100
        slider.set(value: 95, animated: false)

        for _ in 0..<5 {
            slider.accessibilityIncrement()
        }

        XCTAssertLessThanOrEqual(slider.value, slider.max,
                                 "accessibilityIncrement should not exceed max value")
    }

    func testSlider_accessibilityDecrement_respectsMin() {
        let slider = Slider()
        slider.min = 0
        slider.max = 100
        slider.set(value: 5, animated: false)

        for _ in 0..<5 {
            slider.accessibilityDecrement()
        }

        XCTAssertGreaterThanOrEqual(slider.value, slider.min,
                                    "accessibilityDecrement should not go below min value")
    }

    func testSlider_incrementStep_isReasonable() {
        let slider = Slider()

        // Default step should be reasonable for media playback (e.g., 10 seconds).
        XCTAssertGreaterThan(slider.accessibilityIncrementStep, 0,
                            "Increment step should be positive")
        XCTAssertLessThanOrEqual(slider.accessibilityIncrementStep, 30,
                                 "Increment step should not be too large")
    }

    // MARK: - Accessibility Trait Combination Tests

    func testAdjustableTrait_isNotCombinedWithStaticText() {
        let slider = Slider()

        let hasAdjustable = slider.accessibilityTraits.contains(.adjustable)
        let hasStaticText = slider.accessibilityTraits.contains(.staticText)

        XCTAssertTrue(hasAdjustable, "Should have adjustable trait")
        XCTAssertFalse(hasStaticText, "Adjustable elements should not be static text")
    }
}
#endif
