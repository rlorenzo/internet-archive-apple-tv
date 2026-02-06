//
//  TVCardButtonStyleTests.swift
//  Internet ArchiveTests
//
//  Unit tests for TVCardButtonStyle
//

import XCTest
import SwiftUI
@testable import Internet_Archive

@MainActor
final class TVCardButtonStyleTests: XCTestCase {

    // MARK: - Default Configuration Tests

    func testDefaultFocusedScale() {
        let style = TVCardButtonStyle()
        XCTAssertEqual(style.focusedScale, 1.08)
    }

    func testDefaultAnimationDuration() {
        let style = TVCardButtonStyle()
        XCTAssertEqual(style.animationDuration, 0.2)
    }

    // MARK: - Custom Configuration Tests

    func testCustomFocusedScale() {
        let style = TVCardButtonStyle(focusedScale: 1.15)
        XCTAssertEqual(style.focusedScale, 1.15)
    }

    func testCustomAnimationDuration() {
        let style = TVCardButtonStyle(animationDuration: 0.5)
        XCTAssertEqual(style.animationDuration, 0.5)
    }

    func testCustomBothParameters() {
        let style = TVCardButtonStyle(focusedScale: 1.2, animationDuration: 0.3)
        XCTAssertEqual(style.focusedScale, 1.2)
        XCTAssertEqual(style.animationDuration, 0.3)
    }

    // MARK: - Scale Value Tests

    func testFocusedScale_minimumValue() {
        let style = TVCardButtonStyle(focusedScale: 1.0)
        XCTAssertEqual(style.focusedScale, 1.0)
    }

    func testFocusedScale_largerValue() {
        let style = TVCardButtonStyle(focusedScale: 1.5)
        XCTAssertEqual(style.focusedScale, 1.5)
    }

    func testFocusedScale_smallerValue() {
        let style = TVCardButtonStyle(focusedScale: 0.9)
        XCTAssertEqual(style.focusedScale, 0.9)
    }

    // MARK: - Animation Duration Tests

    func testAnimationDuration_zero() {
        let style = TVCardButtonStyle(animationDuration: 0)
        XCTAssertEqual(style.animationDuration, 0)
    }

    func testAnimationDuration_longDuration() {
        let style = TVCardButtonStyle(animationDuration: 1.0)
        XCTAssertEqual(style.animationDuration, 1.0)
    }

    // MARK: - ButtonStyle Conformance Tests

    func testStyle_conformsToButtonStyle() {
        let style: any ButtonStyle = TVCardButtonStyle()
        XCTAssertNotNil(style)
    }

    // MARK: - Multiple Instance Tests

    func testMultipleInstances_areIndependent() {
        let style1 = TVCardButtonStyle(focusedScale: 1.1)
        let style2 = TVCardButtonStyle(focusedScale: 1.2)

        XCTAssertNotEqual(style1.focusedScale, style2.focusedScale)
    }

    func testInstanceValues_remainConstant() {
        let style = TVCardButtonStyle(focusedScale: 1.15, animationDuration: 0.4)

        // Access multiple times to ensure values don't change
        XCTAssertEqual(style.focusedScale, 1.15)
        XCTAssertEqual(style.focusedScale, 1.15)
        XCTAssertEqual(style.animationDuration, 0.4)
        XCTAssertEqual(style.animationDuration, 0.4)
    }

    // MARK: - Practical Scale Values Tests

    func testTypicalFocusedScale_for_standardCards() {
        let style = TVCardButtonStyle()
        // Default should be between 1.0 and 1.2 for subtle effect
        XCTAssertGreaterThan(style.focusedScale, 1.0)
        XCTAssertLessThan(style.focusedScale, 1.2)
    }

    func testTypicalAnimationDuration_isSmooth() {
        let style = TVCardButtonStyle()
        // Animation should be quick enough to feel responsive
        XCTAssertGreaterThan(style.animationDuration, 0.1)
        XCTAssertLessThan(style.animationDuration, 0.5)
    }
}
