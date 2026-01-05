//
//  HTMLToAttributedStringTests.swift
//  Internet ArchiveTests
//
//  Unit tests for HTMLToAttributedString converter
//

import XCTest
@testable import Internet_Archive

@MainActor
final class HTMLToAttributedStringTests: XCTestCase {

    private var converter: HTMLToAttributedString!

    override func setUp() {
        super.setUp()
        converter = HTMLToAttributedString.shared
    }

    // MARK: - Basic Entity Conversion Tests

    func testDecodeAmpersand() {
        let result = converter.stripHTML("Tom &amp; Jerry")
        XCTAssertEqual(result, "Tom & Jerry")
    }

    func testDecodeLessThan() {
        let result = converter.stripHTML("5 &lt; 10")
        XCTAssertEqual(result, "5 < 10")
    }

    func testDecodeGreaterThan() {
        let result = converter.stripHTML("10 &gt; 5")
        XCTAssertEqual(result, "10 > 5")
    }

    func testDecodeQuotes() {
        let result = converter.stripHTML("He said &quot;Hello&quot;")
        XCTAssertEqual(result, "He said \"Hello\"")
    }

    func testDecodeApostrophe() {
        let result = converter.stripHTML("It&apos;s working")
        XCTAssertEqual(result, "It's working")
    }

    func testDecodeNbsp() {
        let result = converter.stripHTML("Hello&nbsp;World")
        // SwiftSoup may convert &nbsp; to non-breaking space (U+00A0) or regular space
        XCTAssertTrue(result.contains("Hello"))
        XCTAssertTrue(result.contains("World"))
    }

    func testDecodeMdash() {
        let result = converter.stripHTML("First&mdash;Second")
        XCTAssertEqual(result, "First—Second")
    }

    func testDecodeNdash() {
        let result = converter.stripHTML("2020&ndash;2025")
        XCTAssertEqual(result, "2020–2025")
    }

    func testDecodeHellip() {
        let result = converter.stripHTML("Wait&hellip;")
        XCTAssertEqual(result, "Wait…")
    }

    func testDecodeCopyright() {
        let result = converter.stripHTML("&copy; 2025 Archive")
        XCTAssertEqual(result, "© 2025 Archive")
    }

    func testDecodeNumericEntity() {
        let result = converter.stripHTML("&#169; Copyright")
        XCTAssertEqual(result, "© Copyright")
    }

    func testDecodeHexEntity() {
        let result = converter.stripHTML("&#xA9; Copyright")
        XCTAssertEqual(result, "© Copyright")
    }

    func testDecodeMultipleEntities() {
        // Test multiple different entity types in one string
        let result = converter.stripHTML("Tom &amp; Jerry &mdash; &copy; 2025 &quot;Classic&quot;")
        XCTAssertTrue(result.contains("Tom & Jerry"))
        XCTAssertTrue(result.contains("—"))
        XCTAssertTrue(result.contains("© 2025"))
        XCTAssertTrue(result.contains("\"Classic\""))
    }

    func testDecodeSmartQuotes() {
        let result = converter.stripHTML("&ldquo;Hello&rdquo; and &lsquo;World&rsquo;")
        XCTAssertEqual(result, "\u{201C}Hello\u{201D} and \u{2018}World\u{2019}")
    }

    // MARK: - Line Break Tests

    func testConvertBrTag() {
        let result = converter.stripHTML("Line 1<br>Line 2")
        XCTAssertTrue(result.contains("Line 1"))
        XCTAssertTrue(result.contains("Line 2"))
        XCTAssertTrue(result.contains("\n"), "Should contain newline")
    }

    func testConvertBrTagSelfClosing() {
        let result = converter.stripHTML("Line 1<br/>Line 2")
        XCTAssertTrue(result.contains("Line 1"))
        XCTAssertTrue(result.contains("Line 2"))
        XCTAssertTrue(result.contains("\n"), "Should contain newline")
    }

    func testConvertBrTagWithSpace() {
        let result = converter.stripHTML("Line 1<br />Line 2")
        XCTAssertTrue(result.contains("Line 1"))
        XCTAssertTrue(result.contains("Line 2"))
        XCTAssertTrue(result.contains("\n"), "Should contain newline")
    }

    func testConvertBrTagWithStyleAttribute() {
        // Real-world case from Internet Archive descriptions with inline styles
        let html = """
        First paragraph.<br style="color:rgb(51,51,51);font-family:'YouTube Noto';" />Second paragraph.
        """
        let result = converter.stripHTML(html)
        XCTAssertTrue(result.contains("First paragraph"))
        XCTAssertTrue(result.contains("Second paragraph"))
        XCTAssertTrue(result.contains("\n"), "Should contain newline from br tag")
    }

    func testConvertParagraphTags() {
        let result = converter.stripHTML("<p>Paragraph 1</p><p>Paragraph 2</p>")
        XCTAssertTrue(result.contains("Paragraph 1"))
        XCTAssertTrue(result.contains("Paragraph 2"))
    }

    func testConvertDivTags() {
        let result = converter.stripHTML("<div>Section 1</div><div>Section 2</div>")
        XCTAssertTrue(result.contains("Section 1"))
        XCTAssertTrue(result.contains("Section 2"))
    }

    func testMultipleConsecutiveBreaks() {
        let result = converter.stripHTML("Text<br><br><br><br>More")
        // Should not have more than 2 consecutive newlines
        XCTAssertFalse(result.contains("\n\n\n"))
    }

    // MARK: - List Conversion Tests

    func testConvertUnorderedList() {
        let result = converter.stripHTML("<ul><li>Item 1</li><li>Item 2</li></ul>")
        XCTAssertTrue(result.contains("• Item 1"))
        XCTAssertTrue(result.contains("• Item 2"))
    }

    func testConvertOrderedList() {
        let result = converter.stripHTML("<ol><li>First</li><li>Second</li></ol>")
        XCTAssertTrue(result.contains("• First"))
        XCTAssertTrue(result.contains("• Second"))
    }

    func testConvertNestedList() {
        let result = converter.stripHTML("<ul><li>Parent<ul><li>Child</li></ul></li></ul>")
        XCTAssertTrue(result.contains("• Parent"))
        XCTAssertTrue(result.contains("• Child"))
    }

    // MARK: - Bold/Italic Formatting Tests

    func testBoldTagCreatesAttributedString() {
        let result = converter.convert("This is <b>bold</b> text")
        XCTAssertEqual(result.string, "This is bold text")

        // Check that the word "bold" has bold font
        var range = NSRange()
        let font = result.attribute(.font, at: 8, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        // UIFont.boldSystemFont should have weight >= medium
        let traits = font?.fontDescriptor.symbolicTraits
        XCTAssertTrue(traits?.contains(.traitBold) ?? false)
    }

    func testStrongTagCreatesAttributedString() {
        let result = converter.convert("This is <strong>important</strong>")
        XCTAssertEqual(result.string, "This is important")
    }

    func testItalicTagCreatesAttributedString() {
        let result = converter.convert("This is <i>italic</i> text")
        XCTAssertEqual(result.string, "This is italic text")

        // Check that the word "italic" has italic font
        var range = NSRange()
        let font = result.attribute(.font, at: 8, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        let traits = font?.fontDescriptor.symbolicTraits
        XCTAssertTrue(traits?.contains(.traitItalic) ?? false)
    }

    func testEmTagCreatesAttributedString() {
        let result = converter.convert("This is <em>emphasized</em>")
        XCTAssertEqual(result.string, "This is emphasized")
    }

    // MARK: - Link Handling Tests

    func testLinkTagStrippedButTextPreserved() {
        let result = converter.stripHTML("Visit <a href=\"https://archive.org\">Internet Archive</a>")
        XCTAssertEqual(result, "Visit Internet Archive")
        XCTAssertFalse(result.contains("<a"))
        XCTAssertFalse(result.contains("href"))
    }

    func testMultipleLinks() {
        let result = converter.stripHTML("<a href=\"url1\">Link 1</a> and <a href=\"url2\">Link 2</a>")
        XCTAssertEqual(result, "Link 1 and Link 2")
    }

    // MARK: - Tag Stripping Tests

    func testStripUnknownTags() {
        let result = converter.stripHTML("Text with <span>span</span> and <custom>custom</custom> tags")
        XCTAssertEqual(result, "Text with span and custom tags")
    }

    func testStripNestedTags() {
        let result = converter.stripHTML("<div><p><span>Nested content</span></p></div>")
        XCTAssertTrue(result.contains("Nested content"))
        XCTAssertFalse(result.contains("<"))
    }

    func testStripTagsWithAttributes() {
        let result = converter.stripHTML("<p class=\"intro\" style=\"color:red\">Styled text</p>")
        XCTAssertTrue(result.contains("Styled text"))
        XCTAssertFalse(result.contains("class"))
        XCTAssertFalse(result.contains("style"))
    }

    // MARK: - Edge Cases

    func testEmptyString() {
        let result = converter.stripHTML("")
        XCTAssertEqual(result, "")
    }

    func testPlainTextPassthrough() {
        let result = converter.stripHTML("Just plain text without any HTML")
        XCTAssertEqual(result, "Just plain text without any HTML")
    }

    func testUnicodeCharacters() {
        let result = converter.stripHTML("Unicode: 日本語 中文 한국어 😀")
        XCTAssertEqual(result, "Unicode: 日本語 中文 한국어 😀")
    }

    func testMalformedHTML() {
        // Unclosed tags should be handled gracefully
        let result = converter.stripHTML("<p>Unclosed paragraph")
        XCTAssertTrue(result.contains("Unclosed paragraph"))
    }

    func testMismatchedTags() {
        let result = converter.stripHTML("<b>Bold <i>and italic</b> text</i>")
        // Should not crash, content should be preserved
        XCTAssertTrue(result.contains("Bold"))
        XCTAssertTrue(result.contains("italic"))
        XCTAssertTrue(result.contains("text"))
    }

    func testWhitespaceNormalization() {
        let result = converter.stripHTML("   Multiple   spaces   ")
        // SwiftSoup normalizes whitespace - trims ends and may collapse internal spaces
        XCTAssertTrue(result.contains("Multiple"))
        XCTAssertTrue(result.contains("spaces"))
        // Should not have leading/trailing whitespace
        XCTAssertEqual(result, result.trimmingCharacters(in: .whitespaces))
    }

    // MARK: - Real-World Description Tests

    func testTypicalArchiveDescription() {
        let html = """
        <p>This is a <b>classic film</b> from the 1920s.</p>
        <p>Features include:</p>
        <ul>
        <li>Silent film era</li>
        <li>Black &amp; white</li>
        </ul>
        <p>Visit <a href="https://archive.org">archive.org</a> for more.</p>
        """

        let result = converter.stripHTML(html)

        XCTAssertTrue(result.contains("classic film"))
        XCTAssertTrue(result.contains("Features include"))
        XCTAssertTrue(result.contains("• Silent film era"))
        XCTAssertTrue(result.contains("Black & white"))
        XCTAssertTrue(result.contains("archive.org"))
        XCTAssertFalse(result.contains("<"))
        XCTAssertFalse(result.contains("&amp;"))
    }

    func testDescriptionWithMixedFormatting() {
        let html = "<b>Title</b><br><i>Subtitle</i><br><br>Regular text with &quot;quotes&quot;."
        let result = converter.stripHTML(html)

        XCTAssertTrue(result.contains("Title"))
        XCTAssertTrue(result.contains("Subtitle"))
        XCTAssertTrue(result.contains("Regular text"))
        XCTAssertTrue(result.contains("\"quotes\""))
    }

    // MARK: - Attributed String Tests

    func testConvertReturnsAttributedString() {
        let result = converter.convert("Test text")
        XCTAssertEqual(result.string, "Test text")
    }

    func testConvertAppliesBaseFont() {
        let customFont = UIFont.systemFont(ofSize: 40)
        let result = converter.convert("Test", baseFont: customFont)

        var range = NSRange()
        let font = result.attribute(.font, at: 0, effectiveRange: &range) as? UIFont
        XCTAssertEqual(font?.pointSize, 40)
    }

    func testConvertAppliesTextColor() {
        let result = converter.convert("Test", textColor: .red)

        var range = NSRange()
        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: &range) as? UIColor
        XCTAssertEqual(color, .red)
    }

    func testConvertPreservesParagraphStructure() {
        let html = "<p>First paragraph.</p><p>Second paragraph.</p>"
        let result = converter.convert(html)

        XCTAssertTrue(result.string.contains("First paragraph"))
        XCTAssertTrue(result.string.contains("Second paragraph"))
    }

    // MARK: - Attribute Preservation Tests

    func testCleanupPreservesBoldStylingWithTrailingWhitespace() {
        // HTML with trailing whitespace that triggers cleanup
        let html = "Normal <b>bold</b> normal\n\n\n"
        let result = converter.convert(html)

        // Find the word "bold" in the result
        let boldRange = (result.string as NSString).range(of: "bold")
        XCTAssertNotEqual(boldRange.location, NSNotFound, "Should contain 'bold'")

        // Check that the word "bold" still has bold font after cleanup
        var effectiveRange = NSRange()
        let font = result.attribute(.font, at: boldRange.location, effectiveRange: &effectiveRange) as? UIFont
        XCTAssertNotNil(font)
        let traits = font?.fontDescriptor.symbolicTraits
        XCTAssertTrue(traits?.contains(.traitBold) ?? false, "Bold styling should be preserved after cleanup")
    }

    func testCleanupPreservesItalicStylingWithExcessiveNewlines() {
        // HTML with excessive newlines that triggers cleanup
        let html = "Text with <i>italic</i> styling<br><br><br><br>and more"
        let result = converter.convert(html)

        // Find the word "italic" in the result
        let italicRange = (result.string as NSString).range(of: "italic")
        XCTAssertNotEqual(italicRange.location, NSNotFound, "Should contain 'italic'")

        // Check that the word "italic" still has italic font after cleanup
        var effectiveRange = NSRange()
        let font = result.attribute(.font, at: italicRange.location, effectiveRange: &effectiveRange) as? UIFont
        XCTAssertNotNil(font)
        let traits = font?.fontDescriptor.symbolicTraits
        XCTAssertTrue(traits?.contains(.traitItalic) ?? false, "Italic styling should be preserved after cleanup")
    }

    func testCleanupPreservesMultipleStylesAfterTrimmingLeadingWhitespace() {
        // HTML with leading whitespace that needs trimming
        let html = "   <b>Bold</b> and <i>italic</i> text"
        let result = converter.convert(html)

        // Find "Bold" - it should be near the start after trimming
        let boldRange = (result.string as NSString).range(of: "Bold")
        XCTAssertNotEqual(boldRange.location, NSNotFound, "Should contain 'Bold'")

        // Check bold styling
        var effectiveRange = NSRange()
        let boldFont = result.attribute(.font, at: boldRange.location, effectiveRange: &effectiveRange) as? UIFont
        let boldTraits = boldFont?.fontDescriptor.symbolicTraits
        XCTAssertTrue(boldTraits?.contains(.traitBold) ?? false, "Bold styling should be preserved")

        // Find "italic"
        let italicRange = (result.string as NSString).range(of: "italic")
        XCTAssertNotEqual(italicRange.location, NSNotFound, "Should contain 'italic'")

        // Check italic styling
        let italicFont = result.attribute(.font, at: italicRange.location, effectiveRange: &effectiveRange) as? UIFont
        let italicTraits = italicFont?.fontDescriptor.symbolicTraits
        XCTAssertTrue(italicTraits?.contains(.traitItalic) ?? false, "Italic styling should be preserved")
    }

    // MARK: - Double-Encoded HTML Tests (preprocessHTML)

    func testDoubleEncodedParagraphTags() {
        // Internet Archive API sometimes returns double-encoded HTML
        // where <p> becomes &lt;p&gt; in the JSON
        let doubleEncoded = "&lt;p&gt;This is a paragraph&lt;/p&gt;"
        let result = converter.stripHTML(doubleEncoded)
        XCTAssertEqual(result, "This is a paragraph")
        XCTAssertFalse(result.contains("&lt;"))
        XCTAssertFalse(result.contains("&gt;"))
    }

    func testDoubleEncodedBoldTags() {
        let doubleEncoded = "This is &lt;b&gt;bold&lt;/b&gt; text"
        let result = converter.stripHTML(doubleEncoded)
        XCTAssertEqual(result, "This is bold text")
    }

    func testDoubleEncodedBreakTags() {
        let doubleEncoded = "Line 1&lt;br&gt;Line 2"
        let result = converter.stripHTML(doubleEncoded)
        XCTAssertTrue(result.contains("Line 1"))
        XCTAssertTrue(result.contains("Line 2"))
        XCTAssertTrue(result.contains("\n"), "Should contain newline from decoded br tag")
    }

    func testDoubleEncodedDivTags() {
        let doubleEncoded = "&lt;div&gt;Section content&lt;/div&gt;"
        let result = converter.stripHTML(doubleEncoded)
        XCTAssertTrue(result.contains("Section content"))
        XCTAssertFalse(result.contains("&lt;"))
    }

    func testTripleEncodedHTML() {
        // Triple-encoded case: &amp;lt; should become <
        let tripleEncoded = "&amp;lt;p&amp;gt;Triple encoded&amp;lt;/p&amp;gt;"
        let result = converter.stripHTML(tripleEncoded)
        XCTAssertTrue(result.contains("Triple encoded"))
        XCTAssertFalse(result.contains("&amp;"))
    }

    func testMixedEncodingHTML() {
        // Mix of normal HTML and double-encoded
        let mixed = "<p>Normal paragraph</p>&lt;p&gt;Encoded paragraph&lt;/p&gt;"
        let result = converter.stripHTML(mixed)
        XCTAssertTrue(result.contains("Normal paragraph"))
        XCTAssertTrue(result.contains("Encoded paragraph"))
    }

    func testDoubleEncodedHTMLWithAttributes() {
        // Real-world case from Internet Archive
        let html = "&lt;p style=\"margin:0\"&gt;Styled content&lt;/p&gt;"
        let result = converter.stripHTML(html)
        XCTAssertTrue(result.contains("Styled content"))
        XCTAssertFalse(result.contains("style"))
    }

    func testDoubleEncodedHTMLInConvert() {
        // Test that convert() also handles double-encoded HTML
        let doubleEncoded = "&lt;b&gt;Bold text&lt;/b&gt;"
        let result = converter.convert(doubleEncoded)

        XCTAssertEqual(result.string, "Bold text")

        // Check that it's actually rendered as bold
        var range = NSRange()
        let font = result.attribute(.font, at: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        let traits = font?.fontDescriptor.symbolicTraits
        XCTAssertTrue(traits?.contains(.traitBold) ?? false, "Should render as bold after decoding")
    }

    func testDoubleEncodedItalicInConvert() {
        let doubleEncoded = "&lt;i&gt;Italic text&lt;/i&gt;"
        let result = converter.convert(doubleEncoded)

        XCTAssertEqual(result.string, "Italic text")

        var range = NSRange()
        let font = result.attribute(.font, at: 0, effectiveRange: &range) as? UIFont
        XCTAssertNotNil(font)
        let traits = font?.fontDescriptor.symbolicTraits
        XCTAssertTrue(traits?.contains(.traitItalic) ?? false, "Should render as italic after decoding")
    }

    func testDoubleEncodedListItems() {
        let doubleEncoded = "&lt;ul&gt;&lt;li&gt;Item 1&lt;/li&gt;&lt;li&gt;Item 2&lt;/li&gt;&lt;/ul&gt;"
        let result = converter.stripHTML(doubleEncoded)
        XCTAssertTrue(result.contains("• Item 1"))
        XCTAssertTrue(result.contains("• Item 2"))
    }

    func testRealWorldTekzillaDescription() {
        // Simulated real-world case from Tekzilla podcast descriptions
        let tekzillaHTML = """
        &lt;p&gt;Welcome to Tekzilla! In this episode we cover:&lt;/p&gt;
        &lt;ul&gt;
        &lt;li&gt;Latest tech news&lt;/li&gt;
        &lt;li&gt;Product reviews&lt;/li&gt;
        &lt;/ul&gt;
        &lt;p&gt;Thanks for watching!&lt;/p&gt;
        """
        let result = converter.stripHTML(tekzillaHTML)

        XCTAssertTrue(result.contains("Welcome to Tekzilla"))
        XCTAssertTrue(result.contains("• Latest tech news"))
        XCTAssertTrue(result.contains("• Product reviews"))
        XCTAssertTrue(result.contains("Thanks for watching"))
        XCTAssertFalse(result.contains("&lt;"))
        XCTAssertFalse(result.contains("&gt;"))
    }

    func testDoubleEncodedWithAmpersandInContent() {
        // Content has both double-encoded tags AND ampersands in the text
        let html = "&lt;p&gt;Tom &amp; Jerry&lt;/p&gt;"
        let result = converter.stripHTML(html)
        XCTAssertEqual(result, "Tom & Jerry")
    }

    func testPreprocessDoesNotBreakNormalAmpersand() {
        // Normal text with ampersand should still work
        let normalText = "Tom &amp; Jerry - Best Friends"
        let result = converter.stripHTML(normalText)
        XCTAssertEqual(result, "Tom & Jerry - Best Friends")
    }

    func testPreprocessDoesNotBreakNormalHTML() {
        // Normal HTML (not double-encoded) should still work
        let normalHTML = "<p>Normal <b>bold</b> paragraph</p>"
        let result = converter.stripHTML(normalHTML)
        XCTAssertTrue(result.contains("Normal"))
        XCTAssertTrue(result.contains("bold"))
        XCTAssertTrue(result.contains("paragraph"))
    }
}
