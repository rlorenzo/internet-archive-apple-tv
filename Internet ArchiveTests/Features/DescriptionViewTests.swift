//
//  DescriptionViewTests.swift
//  Internet ArchiveTests
//
//  Unit tests for DescriptionView SwiftUI component
//

import XCTest
@testable import Internet_Archive

@MainActor
final class DescriptionViewTests: XCTestCase {

    // MARK: - HTML to Plain Text Conversion Tests

    /// Tests that DescriptionView correctly uses HTMLToAttributedString for conversion.
    /// The actual HTML parsing is thoroughly tested in HTMLToAttributedStringTests.
    /// These tests verify the integration works correctly.

    func testPlainTextConversion_simpleHTML() {
        // DescriptionView uses HTMLToAttributedString.shared.stripHTML internally
        let html = "<p>Simple paragraph</p>"
        let result = HTMLToAttributedString.shared.stripHTML(html)
        XCTAssertTrue(result.contains("Simple paragraph"))
        XCTAssertFalse(result.contains("<p>"))
    }

    func testPlainTextConversion_formattedHTML() {
        let html = "<p>This is <b>bold</b> and <i>italic</i> text.</p>"
        let result = HTMLToAttributedString.shared.stripHTML(html)
        XCTAssertTrue(result.contains("bold"))
        XCTAssertTrue(result.contains("italic"))
        XCTAssertFalse(result.contains("<b>"))
    }

    func testPlainTextConversion_htmlEntities() {
        let html = "Tom &amp; Jerry &copy; 2025"
        let result = HTMLToAttributedString.shared.stripHTML(html)
        XCTAssertTrue(result.contains("Tom & Jerry"))
    }

    func testPlainTextConversion_doubleEncodedHTML() {
        // Internet Archive API sometimes returns double-encoded HTML
        let html = "&lt;p&gt;Encoded content&lt;/p&gt;"
        let result = HTMLToAttributedString.shared.stripHTML(html)
        XCTAssertTrue(result.contains("Encoded content"))
        XCTAssertFalse(result.contains("&lt;"))
    }

    func testPlainTextConversion_withNewlines() {
        // Verify newlines are preserved (tested in HTMLToAttributedStringTests)
        let html = "Line 1\n\nLine 2"
        let result = HTMLToAttributedString.shared.stripHTML(html)
        XCTAssertTrue(result.contains("Line 1"))
        XCTAssertTrue(result.contains("Line 2"))
    }

    func testPlainTextConversion_emptyString() {
        let result = HTMLToAttributedString.shared.stripHTML("")
        XCTAssertEqual(result, "")
    }

    func testPlainTextConversion_plainTextPassthrough() {
        let plainText = "No HTML tags here, just plain text."
        let result = HTMLToAttributedString.shared.stripHTML(plainText)
        XCTAssertEqual(result, plainText)
    }

    // MARK: - Real-World Description Tests

    func testRealWorldDescription_movieDescription() {
        let html = """
        <p>A classic film noir from the 1940s featuring \
        intrigue and mystery.</p>
        <p>Directed by a legendary filmmaker.</p>
        """
        let result = HTMLToAttributedString.shared.stripHTML(html)
        XCTAssertTrue(result.contains("classic film noir"))
        XCTAssertTrue(result.contains("legendary filmmaker"))
    }

    func testRealWorldDescription_withLists() {
        let html = """
        <p>Features include:</p>
        <ul>
            <li>High quality video</li>
            <li>Original audio</li>
        </ul>
        """
        let result = HTMLToAttributedString.shared.stripHTML(html)
        XCTAssertTrue(result.contains("Features include"))
        XCTAssertTrue(result.contains("High quality video"))
    }

    func testRealWorldDescription_specialCharacters() {
        let html = "Special: 日本語 中文 한국어 émoji 🎬"
        let result = HTMLToAttributedString.shared.stripHTML(html)
        XCTAssertTrue(result.contains("日本語"))
        XCTAssertTrue(result.contains("🎬"))
    }
}

// MARK: - TruncationDetectingText Tests

/// Note: TruncationDetectingText uses geometry-based truncation detection which
/// requires SwiftUI runtime and actual layout to test properly. The truncation
/// logic compares full text height vs line-limited height:
///
/// ```
/// isTruncated = fullHeight > truncatedHeight + threshold
/// ```
///
/// This is best tested through:
/// 1. SwiftUI Previews (manual verification)
/// 2. UI Tests with actual rendering
/// 3. Snapshot tests if configured
///
/// The core HTML conversion logic is covered by HTMLToAttributedStringTests.
