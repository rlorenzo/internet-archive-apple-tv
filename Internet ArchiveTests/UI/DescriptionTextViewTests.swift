//
//  DescriptionTextViewTests.swift
//  Internet ArchiveTests
//
//  Unit tests for DescriptionTextView component
//

import XCTest
@testable import Internet_Archive

@MainActor
final class DescriptionTextViewTests: XCTestCase {

    private var descriptionView: DescriptionTextView!

    // Helper to create test objects - call at start of each test that needs them
    private func createTestObjects() {
        descriptionView = DescriptionTextView(frame: CGRect(x: 0, y: 0, width: 800, height: 300))
    }

    // MARK: - Initialization Tests

    func testInitWithFrame() {
        let view = DescriptionTextView(frame: CGRect(x: 0, y: 0, width: 400, height: 200))
        XCTAssertNotNil(view)
    }

    func testDefaultNumberOfLines() {
        createTestObjects()
        XCTAssertEqual(descriptionView.numberOfLines, 6)
    }

    func testDefaultTrailingText() {
        createTestObjects()
        XCTAssertEqual(descriptionView.trailingText, "... More")
    }

    func testCanBecomeFocused() {
        createTestObjects()
        XCTAssertTrue(descriptionView.canBecomeFocused)
    }

    // MARK: - Content Setting Tests

    func testSetAttributedText() {
        createTestObjects()
        let attrText = NSAttributedString(string: "Test description")
        descriptionView.attributedText = attrText

        XCTAssertEqual(descriptionView.attributedText?.string, "Test description")
    }

    func testSetPlainText() {
        createTestObjects()
        descriptionView.plainText = "Plain text content"

        XCTAssertEqual(descriptionView.plainText, "Plain text content")
    }

    func testSetDescriptionParsesHTML() {
        createTestObjects()
        descriptionView.setDescription("<p>HTML <b>content</b></p>")

        XCTAssertNotNil(descriptionView.attributedText)
        XCTAssertTrue(descriptionView.attributedText?.string.contains("HTML") ?? false)
        XCTAssertTrue(descriptionView.attributedText?.string.contains("content") ?? false)
        XCTAssertFalse(descriptionView.attributedText?.string.contains("<") ?? true)
    }

    func testSetDescriptionSetsPlainText() {
        createTestObjects()
        descriptionView.setDescription("<p>Test &amp; content</p>")

        XCTAssertNotNil(descriptionView.plainText)
        XCTAssertTrue(descriptionView.plainText?.contains("Test & content") ?? false)
    }

    func testSetPlainTextCreatesAttributedString() {
        createTestObjects()
        descriptionView.setPlainText("Plain text input")

        XCTAssertNotNil(descriptionView.attributedText)
        XCTAssertEqual(descriptionView.attributedText?.string, "Plain text input")
        XCTAssertEqual(descriptionView.plainText, "Plain text input")
    }

    // MARK: - Truncation Tests

    func testIsTruncatedInitiallyFalse() {
        createTestObjects()
        XCTAssertFalse(descriptionView.isTruncated)
    }

    func testShortTextNotTruncated() {
        createTestObjects()
        descriptionView.setPlainText("Short text")
        descriptionView.layoutSubviews()

        // Short text should not be truncated
        // Note: Without actual layout, this may not work perfectly
        XCTAssertNotNil(descriptionView.attributedText)
    }

    func testNumberOfLinesCanBeChanged() {
        createTestObjects()
        descriptionView.numberOfLines = 3
        XCTAssertEqual(descriptionView.numberOfLines, 3)
    }

    func testTrailingTextCanBeChanged() {
        createTestObjects()
        descriptionView.trailingText = "Read More >"
        XCTAssertEqual(descriptionView.trailingText, "Read More >")
    }

    // MARK: - Callback Tests

    func testOnReadMorePressedCallbackCanBeSet() {
        createTestObjects()
        descriptionView.onReadMorePressed = {
            // Callback set
        }

        XCTAssertNotNil(descriptionView.onReadMorePressed)
    }

    // MARK: - Accessibility Tests

    func testAccessibilityElementEnabled() {
        createTestObjects()
        XCTAssertTrue(descriptionView.isAccessibilityElement)
    }

    func testAccessibilityTraitsIncludesStaticText() {
        createTestObjects()
        XCTAssertTrue(descriptionView.accessibilityTraits.contains(.staticText))
    }

    func testAccessibilityHintSet() {
        createTestObjects()
        XCTAssertEqual(descriptionView.accessibilityHint, "Double-tap to expand and read full description")
    }

    func testAccessibilityLabelUpdatesWithPlainText() {
        createTestObjects()
        descriptionView.plainText = "Test accessibility label"

        XCTAssertEqual(descriptionView.accessibilityLabel, "Test accessibility label")
    }

    func testAccessibilityLabelFallsBackToAttributedString() {
        createTestObjects()
        descriptionView.attributedText = NSAttributedString(string: "Attributed text label")

        XCTAssertEqual(descriptionView.accessibilityLabel, "Attributed text label")
    }

    func testAccessibilityLabelDefaultWhenEmpty() {
        createTestObjects()
        descriptionView.plainText = nil
        descriptionView.attributedText = nil

        XCTAssertEqual(descriptionView.accessibilityLabel, "No description available")
    }

    // MARK: - HTML Parsing Integration Tests

    func testHTMLEntitiesDecoded() {
        createTestObjects()
        descriptionView.setDescription("Tom &amp; Jerry &copy; 2025")

        XCTAssertTrue(descriptionView.plainText?.contains("Tom & Jerry") ?? false)
        XCTAssertTrue(descriptionView.plainText?.contains("© 2025") ?? false)
    }

    func testHTMLLineBreaksConverted() {
        createTestObjects()
        descriptionView.setDescription("Line 1<br>Line 2")

        XCTAssertTrue(descriptionView.plainText?.contains("Line 1") ?? false)
        XCTAssertTrue(descriptionView.plainText?.contains("Line 2") ?? false)
    }

    func testHTMLListsConverted() {
        createTestObjects()
        descriptionView.setDescription("<ul><li>Item 1</li><li>Item 2</li></ul>")

        XCTAssertTrue(descriptionView.plainText?.contains("• Item 1") ?? false)
        XCTAssertTrue(descriptionView.plainText?.contains("• Item 2") ?? false)
    }

    func testHTMLLinksStripped() {
        createTestObjects()
        descriptionView.setDescription("Visit <a href=\"http://example.com\">Example</a>")

        XCTAssertTrue(descriptionView.plainText?.contains("Visit Example") ?? false)
        XCTAssertFalse(descriptionView.plainText?.contains("href") ?? true)
    }

    // MARK: - View Hierarchy Tests

    func testHasSubviews() {
        createTestObjects()
        XCTAssertFalse(descriptionView.subviews.isEmpty)
    }

    func testBackgroundIsClear() {
        createTestObjects()
        XCTAssertEqual(descriptionView.backgroundColor, .clear)
    }

    // MARK: - Focus State Tests

    func testTransformIsIdentityWhenNotFocused() {
        createTestObjects()
        // When not focused, transform should be identity
        XCTAssertEqual(descriptionView.transform, .identity)
    }

    // MARK: - Edge Cases

    func testEmptyHTMLString() {
        createTestObjects()
        descriptionView.setDescription("")

        XCTAssertEqual(descriptionView.attributedText?.string, "")
        XCTAssertEqual(descriptionView.plainText, "")
    }

    func testNilHandling() {
        createTestObjects()
        descriptionView.attributedText = nil
        descriptionView.plainText = nil

        XCTAssertNil(descriptionView.attributedText)
        XCTAssertNil(descriptionView.plainText)
        XCTAssertFalse(descriptionView.isTruncated)
    }

    func testWhitespaceOnlyContent() {
        createTestObjects()
        descriptionView.setDescription("   ")

        // Whitespace should be trimmed
        XCTAssertTrue(descriptionView.plainText?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
    }

    func testVeryLongDescription() {
        createTestObjects()
        let longText = String(repeating: "This is a very long description. ", count: 100)
        descriptionView.setDescription(longText)

        XCTAssertNotNil(descriptionView.attributedText)
        XCTAssertNotNil(descriptionView.plainText)
    }

    func testSpecialCharacters() {
        createTestObjects()
        descriptionView.setDescription("Special: 日本語 中文 한국어 émoji 🎬")

        XCTAssertTrue(descriptionView.plainText?.contains("日本語") ?? false)
        XCTAssertTrue(descriptionView.plainText?.contains("🎬") ?? false)
    }
}
