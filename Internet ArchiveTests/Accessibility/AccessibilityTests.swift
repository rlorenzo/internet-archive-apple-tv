//
//  AccessibilityTests.swift
//  Internet ArchiveTests
//
//  Comprehensive accessibility tests for VoiceOver support
//

import XCTest
@testable import Internet_Archive

/// Tests to verify accessibility properties are correctly configured across the app
@MainActor
final class AccessibilityTests: XCTestCase {

    // MARK: - Slider Accessibility Tests

    func testSlider_hasAdjustableTrait() {
        let slider = Slider()

        // Verify adjustable trait is set (required for VoiceOver increment/decrement)
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

        // Increment multiple times
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

        // Decrement multiple times
        for _ in 0..<5 {
            slider.accessibilityDecrement()
        }

        XCTAssertGreaterThanOrEqual(slider.value, slider.min,
                                    "accessibilityDecrement should not go below min value")
    }

    func testSlider_incrementStep_isReasonable() {
        let slider = Slider()

        // Default step should be reasonable for media playback (e.g., 10 seconds)
        XCTAssertGreaterThan(slider.accessibilityIncrementStep, 0,
                            "Increment step should be positive")
        XCTAssertLessThanOrEqual(slider.accessibilityIncrementStep, 30,
                                 "Increment step should not be too large")
    }

    // MARK: - EmptyStateView Accessibility Tests

    func testEmptyStateView_isAccessibilityElement() {
        let emptyState = EmptyStateView(image: nil, title: "Test Title", message: "Test message")

        XCTAssertTrue(emptyState.isAccessibilityElement,
                      "EmptyStateView should be an accessibility element")
    }

    func testEmptyStateView_hasStaticTextTrait() {
        let emptyState = EmptyStateView(image: nil, title: "Test", message: nil)

        XCTAssertTrue(emptyState.accessibilityTraits.contains(.staticText),
                      "EmptyStateView should have .staticText trait")
    }

    func testEmptyStateView_accessibilityLabel_includesTitleAndMessage() {
        let emptyState = EmptyStateView(image: nil, title: "No Results", message: "Try again")

        XCTAssertNotNil(emptyState.accessibilityLabel)
        XCTAssertTrue(emptyState.accessibilityLabel?.contains("No Results") ?? false,
                      "Accessibility label should include title")
        XCTAssertTrue(emptyState.accessibilityLabel?.contains("Try again") ?? false,
                      "Accessibility label should include message")
    }

    func testEmptyStateView_accessibilityLabel_titleOnly() {
        let emptyState = EmptyStateView(image: nil, title: "Empty", message: nil)

        XCTAssertEqual(emptyState.accessibilityLabel, "Empty",
                       "Accessibility label should be just the title when no message")
    }

    func testEmptyStateView_presets_haveAccessibility() {
        let presets: [EmptyStateView] = [
            .noSearchResults(),
            .noFavorites(),
            .noItems(),
            .networkError(),
            .error(message: "Test error")
        ]

        for preset in presets {
            XCTAssertTrue(preset.isAccessibilityElement,
                          "Preset empty state should be accessible")
            XCTAssertNotNil(preset.accessibilityLabel,
                           "Preset empty state should have accessibility label")
        }
    }

    // MARK: - ContinueSectionHeaderView Accessibility Tests

    func testContinueSectionHeaderView_hasHeaderTrait() {
        let header = ContinueSectionHeaderView(frame: CGRect(x: 0, y: 0, width: 300, height: 50))

        XCTAssertTrue(header.accessibilityTraits.contains(.header),
                      "Section header should have .header trait")
    }

    func testContinueSectionHeaderView_isAccessibilityElement() {
        let header = ContinueSectionHeaderView(frame: CGRect(x: 0, y: 0, width: 300, height: 50))

        XCTAssertTrue(header.isAccessibilityElement,
                      "Section header should be an accessibility element")
    }

    func testContinueSectionHeaderView_configure_setsAccessibilityLabel() {
        let header = ContinueSectionHeaderView(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
        header.configure(with: "Continue Watching")

        XCTAssertNotNil(header.accessibilityLabel)
        XCTAssertTrue(header.accessibilityLabel?.contains("Continue Watching") ?? false,
                      "Accessibility label should include the title")
    }

    // MARK: - SkeletonView Accessibility Tests

    func testSkeletonView_isNotAccessibilityElement() {
        let skeleton = SkeletonView()

        XCTAssertFalse(skeleton.isAccessibilityElement,
                       "SkeletonView should not be an accessibility element")
    }

    func testSkeletonView_elementsAreHidden() {
        let skeleton = SkeletonView()

        XCTAssertTrue(skeleton.accessibilityElementsHidden,
                      "SkeletonView elements should be hidden from accessibility")
    }

    func testSkeletonItemCell_isNotAccessibilityElement() {
        let cell = SkeletonItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))

        XCTAssertFalse(cell.isAccessibilityElement,
                       "SkeletonItemCell should not be an accessibility element")
    }

    // MARK: - ModernItemCell Accessibility Tests

    func testModernItemCell_isAccessibilityElement() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))

        XCTAssertTrue(cell.isAccessibilityElement,
                      "ModernItemCell should be an accessibility element")
    }

    func testModernItemCell_hasButtonTrait() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))

        XCTAssertTrue(cell.accessibilityTraits.contains(.button),
                      "ModernItemCell should have .button trait")
    }

    func testModernItemCell_configure_setsAccessibilityLabel() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        let searchResult = SearchResult(
            identifier: "test",
            title: "Test Movie",
            mediatype: "movies",
            creator: nil,
            description: nil,
            date: nil,
            year: nil,
            downloads: nil,
            subject: nil,
            collection: nil
        )
        let viewModel = ItemViewModel(item: searchResult)

        cell.configure(with: viewModel)

        XCTAssertEqual(cell.accessibilityLabel, "Test Movie",
                       "Cell should have title as accessibility label")
    }

    func testModernItemCell_hasAccessibilityHint() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))

        XCTAssertNotNil(cell.accessibilityHint,
                        "ModernItemCell should have an accessibility hint")
    }

    // MARK: - ContinueWatchingCell Accessibility Tests

    func testContinueWatchingCell_isAccessibilityElement() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 300, height: 200))

        XCTAssertTrue(cell.isAccessibilityElement,
                      "ContinueWatchingCell should be an accessibility element")
    }

    func testContinueWatchingCell_hasButtonTrait() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 300, height: 200))

        XCTAssertTrue(cell.accessibilityTraits.contains(.button),
                      "ContinueWatchingCell should have .button trait")
    }

    // MARK: - Accessibility Label Format Tests

    func testAccessibilityLabel_notEmpty() {
        // Test that configured accessibility labels are never empty strings
        let emptyState = EmptyStateView(image: nil, title: "Title", message: nil)
        XCTAssertFalse(emptyState.accessibilityLabel?.isEmpty ?? true,
                       "Accessibility label should not be empty")
    }

    // MARK: - Accessibility Trait Combination Tests

    func testHeaderTrait_isNotCombinedWithButton() {
        let header = ContinueSectionHeaderView(frame: CGRect(x: 0, y: 0, width: 300, height: 50))

        // Headers should not also be buttons (confusing for VoiceOver)
        let hasHeader = header.accessibilityTraits.contains(.header)
        let hasButton = header.accessibilityTraits.contains(.button)

        XCTAssertTrue(hasHeader, "Should have header trait")
        XCTAssertFalse(hasButton, "Headers should not have button trait")
    }

    func testAdjustableTrait_isNotCombinedWithStaticText() {
        let slider = Slider()

        // Adjustable elements should not be static text
        let hasAdjustable = slider.accessibilityTraits.contains(.adjustable)
        let hasStaticText = slider.accessibilityTraits.contains(.staticText)

        XCTAssertTrue(hasAdjustable, "Should have adjustable trait")
        XCTAssertFalse(hasStaticText, "Adjustable elements should not be static text")
    }
}

// MARK: - Accessibility Audit Helper

/// Helper class to audit accessibility properties
@MainActor
final class AccessibilityAuditTests: XCTestCase {

    /// Verifies that a view hierarchy has reasonable accessibility
    func auditAccessibility(of view: UIView, depth: Int = 0) -> [String] {
        var issues: [String] = []
        let indent = String(repeating: "  ", count: depth)

        // Check if interactive elements are accessible
        if view is UIButton || view is UIControl {
            if !view.isAccessibilityElement && view.accessibilityElementsHidden != true {
                issues.append("\(indent)Interactive element \(type(of: view)) should be accessible")
            }
        }

        // Check for missing labels on accessible elements
        if view.isAccessibilityElement {
            if view.accessibilityLabel == nil || view.accessibilityLabel?.isEmpty == true {
                issues.append("\(indent)Accessible element \(type(of: view)) missing label")
            }
        }

        // Recurse into subviews
        for subview in view.subviews {
            issues.append(contentsOf: auditAccessibility(of: subview, depth: depth + 1))
        }

        return issues
    }

    func testEmptyStateView_passesAudit() {
        let emptyState = EmptyStateView(image: nil, title: "Test", message: "Test message")
        let issues = auditAccessibility(of: emptyState)

        XCTAssertTrue(issues.isEmpty, "EmptyStateView audit found issues: \(issues)")
    }

    func testModernItemCell_passesAudit() {
        let cell = ModernItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        let searchResult = SearchResult(
            identifier: "test",
            title: "Test",
            mediatype: "movies",
            creator: nil,
            description: nil,
            date: nil,
            year: nil,
            downloads: nil,
            subject: nil,
            collection: nil
        )
        cell.configure(with: ItemViewModel(item: searchResult))

        let issues = auditAccessibility(of: cell)

        XCTAssertTrue(issues.isEmpty, "ModernItemCell audit found issues: \(issues)")
    }
}
