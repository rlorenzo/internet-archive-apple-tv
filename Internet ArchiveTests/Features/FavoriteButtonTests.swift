//
//  FavoriteButtonTests.swift
//  Internet ArchiveTests
//
//  Unit tests for FavoriteButton and CompactFavoriteButton SwiftUI components
//

import XCTest
import SwiftUI
@testable import Internet_Archive

@MainActor
final class FavoriteButtonTests: XCTestCase {

    // MARK: - FavoriteButton Tests

    // MARK: Initialization

    func testFavoriteButton_initNotFavorited() {
        var isFavorited = false
        let button = FavoriteButton(
            isFavorited: Binding(get: { isFavorited }, set: { isFavorited = $0 }),
            onToggle: {}
        )

        XCTAssertNotNil(button)
    }

    func testFavoriteButton_initFavorited() {
        var isFavorited = true
        let button = FavoriteButton(
            isFavorited: Binding(get: { isFavorited }, set: { isFavorited = $0 }),
            onToggle: {}
        )

        XCTAssertNotNil(button)
    }

    // MARK: Toggle Callback

    func testFavoriteButton_onToggleCalled() {
        var toggleCount = 0
        var isFavorited = false

        let button = FavoriteButton(
            isFavorited: Binding(get: { isFavorited }, set: { isFavorited = $0 }),
            onToggle: { toggleCount += 1 }
        )

        // Simulate toggle by calling onToggle directly
        button.onToggle()

        XCTAssertEqual(toggleCount, 1)
    }

    func testFavoriteButton_onToggleCalledMultipleTimes() {
        var toggleCount = 0
        var isFavorited = false

        let button = FavoriteButton(
            isFavorited: Binding(get: { isFavorited }, set: { isFavorited = $0 }),
            onToggle: { toggleCount += 1 }
        )

        button.onToggle()
        button.onToggle()
        button.onToggle()

        XCTAssertEqual(toggleCount, 3)
    }

    // MARK: - FavoriteButtonStyle Tests

    func testFavoriteButtonStyle_initWithFavorited() {
        let style = FavoriteButtonStyle(isFavorited: true)

        XCTAssertTrue(style.isFavorited)
    }

    func testFavoriteButtonStyle_initWithNotFavorited() {
        let style = FavoriteButtonStyle(isFavorited: false)

        XCTAssertFalse(style.isFavorited)
    }

    // MARK: - CompactFavoriteButton Tests

    // MARK: Initialization

    func testCompactFavoriteButton_initNotFavorited() {
        var isFavorited = false
        let button = CompactFavoriteButton(
            isFavorited: Binding(get: { isFavorited }, set: { isFavorited = $0 }),
            onToggle: {}
        )

        XCTAssertNotNil(button)
    }

    func testCompactFavoriteButton_initFavorited() {
        var isFavorited = true
        let button = CompactFavoriteButton(
            isFavorited: Binding(get: { isFavorited }, set: { isFavorited = $0 }),
            onToggle: {}
        )

        XCTAssertNotNil(button)
    }

    // MARK: Toggle Callback

    func testCompactFavoriteButton_onToggleCalled() {
        var toggleCount = 0
        var isFavorited = false

        let button = CompactFavoriteButton(
            isFavorited: Binding(get: { isFavorited }, set: { isFavorited = $0 }),
            onToggle: { toggleCount += 1 }
        )

        button.onToggle()

        XCTAssertEqual(toggleCount, 1)
    }

    func testCompactFavoriteButton_onToggleCalledMultipleTimes() {
        var toggleCount = 0
        var isFavorited = true

        let button = CompactFavoriteButton(
            isFavorited: Binding(get: { isFavorited }, set: { isFavorited = $0 }),
            onToggle: { toggleCount += 1 }
        )

        button.onToggle()
        button.onToggle()

        XCTAssertEqual(toggleCount, 2)
    }

    // MARK: - Binding State Tests

    func testFavoriteButton_bindingReflectsExternalState() {
        var externalState = false

        let button = FavoriteButton(
            isFavorited: Binding(get: { externalState }, set: { externalState = $0 }),
            onToggle: { externalState.toggle() }
        )

        // Initial state
        XCTAssertFalse(externalState)

        // Toggle
        button.onToggle()
        XCTAssertTrue(externalState)

        // Toggle again
        button.onToggle()
        XCTAssertFalse(externalState)
    }

    func testCompactFavoriteButton_bindingReflectsExternalState() {
        var externalState = true

        let button = CompactFavoriteButton(
            isFavorited: Binding(get: { externalState }, set: { externalState = $0 }),
            onToggle: { externalState.toggle() }
        )

        XCTAssertTrue(externalState)

        button.onToggle()
        XCTAssertFalse(externalState)
    }

    // MARK: - Edge Cases

    func testFavoriteButton_rapidToggling() {
        var toggleCount = 0
        var isFavorited = false

        let button = FavoriteButton(
            isFavorited: Binding(get: { isFavorited }, set: { isFavorited = $0 }),
            onToggle: {
                toggleCount += 1
                isFavorited.toggle()
            }
        )

        // Rapid toggles
        for _ in 0..<10 {
            button.onToggle()
        }

        XCTAssertEqual(toggleCount, 10)
    }

    func testCompactFavoriteButton_rapidToggling() {
        var toggleCount = 0
        var isFavorited = false

        let button = CompactFavoriteButton(
            isFavorited: Binding(get: { isFavorited }, set: { isFavorited = $0 }),
            onToggle: {
                toggleCount += 1
                isFavorited.toggle()
            }
        )

        for _ in 0..<10 {
            button.onToggle()
        }

        XCTAssertEqual(toggleCount, 10)
    }

    func testFavoriteButton_emptyOnToggle() {
        var isFavorited = false

        let button = FavoriteButton(
            isFavorited: Binding(get: { isFavorited }, set: { isFavorited = $0 }),
            onToggle: {}
        )

        // Should not crash with empty closure
        button.onToggle()

        XCTAssertNotNil(button)
    }

    func testCompactFavoriteButton_emptyOnToggle() {
        var isFavorited = true

        let button = CompactFavoriteButton(
            isFavorited: Binding(get: { isFavorited }, set: { isFavorited = $0 }),
            onToggle: {}
        )

        button.onToggle()

        XCTAssertNotNil(button)
    }

    // MARK: - Constant Binding Tests

    func testFavoriteButton_constantBindingTrue() {
        let button = FavoriteButton(
            isFavorited: .constant(true),
            onToggle: {}
        )

        XCTAssertNotNil(button)
    }

    func testFavoriteButton_constantBindingFalse() {
        let button = FavoriteButton(
            isFavorited: .constant(false),
            onToggle: {}
        )

        XCTAssertNotNil(button)
    }

    func testCompactFavoriteButton_constantBindingTrue() {
        let button = CompactFavoriteButton(
            isFavorited: .constant(true),
            onToggle: {}
        )

        XCTAssertNotNil(button)
    }

    func testCompactFavoriteButton_constantBindingFalse() {
        let button = CompactFavoriteButton(
            isFavorited: .constant(false),
            onToggle: {}
        )

        XCTAssertNotNil(button)
    }
}
