//
//  HTMLToAttributedString.swift
//  Internet Archive
//
//  Converts HTML strings to NSAttributedString for tvOS
//  Uses SwiftSoup for robust HTML parsing
//

import UIKit
import SwiftSoup

/// Converts HTML strings to NSAttributedString using SwiftSoup
/// Supports common HTML tags found in Internet Archive descriptions
@MainActor
final class HTMLToAttributedString {

    // MARK: - Shared Instance

    static let shared = HTMLToAttributedString()

    private init() {}

    // MARK: - Public Methods

    /// Convert an HTML string to NSAttributedString
    /// - Parameters:
    ///   - html: The HTML string to convert
    ///   - baseFont: The base font for regular text (default: system 29pt)
    ///   - textColor: The text color (default: .label)
    /// - Returns: Formatted NSAttributedString
    func convert(
        _ html: String,
        baseFont: UIFont = .systemFont(ofSize: 29),
        textColor: UIColor = .label
    ) -> NSAttributedString {
        guard !html.isEmpty else {
            return NSAttributedString(string: "")
        }

        // Pre-process to handle double-encoded HTML from the API
        // Some descriptions come with &lt;p&gt; which needs to be decoded first
        let preprocessed = preprocessHTML(html)

        do {
            let document = try SwiftSoup.parse(preprocessed)
            let style = TextStyle(baseFont: baseFont, textColor: textColor)
            let attributedString = try convertElement(document.body() ?? document, style: style)
            return cleanupAttributedString(attributedString)
        } catch {
            // Fallback to plain text if parsing fails
            return NSAttributedString(
                string: stripHTML(html),
                attributes: [.font: baseFont, .foregroundColor: textColor]
            )
        }
    }

    /// Strip all HTML tags and return plain text
    /// - Parameter html: The HTML string to strip
    /// - Returns: Plain text with HTML removed
    func stripHTML(_ html: String) -> String {
        guard !html.isEmpty else { return "" }

        // Pre-process to handle double-encoded HTML
        let preprocessed = preprocessHTML(html)

        do {
            let document = try SwiftSoup.parse(preprocessed)

            // Process block elements to add newline placeholders
            try processBlockElements(document)

            // Get text content
            var text = try document.text()

            // Replace placeholders with actual newlines
            text = text.replacingOccurrences(of: newlinePlaceholder, with: "\n")

            // Clean up multiple consecutive newlines (more than 2)
            text = text.replacingOccurrences(
                of: "\n{3,}",
                with: "\n\n",
                options: .regularExpression
            )

            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            // Fallback: use regex to strip tags
            return fallbackStripHTML(html)
        }
    }

    // MARK: - Private Methods

    /// Pre-process HTML to handle double-encoded content from the API
    /// Internet Archive sometimes returns descriptions with encoded HTML entities
    /// e.g., "&lt;p&gt;text&lt;/p&gt;" instead of "<p>text</p>"
    /// Also preserves literal newlines in the text as <br> tags
    ///
    /// - Note: Uses multiple sequential string replacements which is O(n×m) where n is string
    ///   length and m is number of replacements. This prioritizes code clarity over optimization
    ///   for typical description lengths (<10KB). Profile before optimizing.
    private func preprocessHTML(_ html: String) -> String {
        var result = html

        // Decode common HTML tag entities (only for tag characters, not content)
        // This handles double-encoded HTML like &lt;p&gt; -> <p>
        let tagEntities: [(String, String)] = [
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&amp;lt;", "<"),   // Triple-encoded case
            ("&amp;gt;", ">")    // Triple-encoded case
        ]

        for (entity, replacement) in tagEntities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Convert literal newlines to <br> tags before SwiftSoup parsing
        // This preserves paragraph breaks in descriptions that use plain text newlines
        // instead of HTML block elements. Handle various newline formats.
        result = result.replacingOccurrences(of: "\r\n", with: "<br>")
        result = result.replacingOccurrences(of: "\r", with: "<br>")
        result = result.replacingOccurrences(of: "\n", with: "<br>")

        return result
    }

    /// Style context passed down the recursion in `convertElement`.
    private struct TextStyle {
        let baseFont: UIFont
        let textColor: UIColor
        var isBold = false
        var isItalic = false
    }

    /// Convert a SwiftSoup element to NSAttributedString
    private func convertElement(_ element: Element, style: TextStyle) throws -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6

        for node in element.getChildNodes() {
            if let textNode = node as? TextNode {
                appendTextNode(textNode.text(), to: result, style: style, paragraphStyle: paragraphStyle)
            } else if let childElement = node as? Element {
                try appendChildElement(childElement, to: result, style: style)
            }
        }

        return result
    }

    private func appendTextNode(
        _ text: String,
        to result: NSMutableAttributedString,
        style: TextStyle,
        paragraphStyle: NSParagraphStyle
    ) {
        guard !text.isEmpty else { return }
        let font = fontForStyle(baseFont: style.baseFont, bold: style.isBold, italic: style.isItalic)
        result.append(NSAttributedString(
            string: text,
            attributes: [.font: font, .foregroundColor: style.textColor, .paragraphStyle: paragraphStyle]
        ))
    }

    private func appendChildElement(
        _ childElement: Element,
        to result: NSMutableAttributedString,
        style: TextStyle
    ) throws {
        let tagName = childElement.tagName().lowercased()
        let opening = handleTagOpening(tagName: tagName, result: result, style: style)
        guard opening.shouldRecurse else { return }

        var childStyle = style
        childStyle.isBold = opening.childBold
        childStyle.isItalic = opening.childItalic
        let childResult = try convertElement(childElement, style: childStyle)
        result.append(childResult)

        if tagName == "p" || tagName == "div" {
            appendNewlineIfNeeded(to: result)
        }
    }

    /// Pre-recursion bookkeeping for a child tag. Returns the formatting to apply to
    /// descendants and whether the caller should recurse into the child (false for `<br>`,
    /// whose content is handled inline here).
    private func handleTagOpening(
        tagName: String,
        result: NSMutableAttributedString,
        style: TextStyle
    ) -> (childBold: Bool, childItalic: Bool, shouldRecurse: Bool) {
        switch tagName {
        case "b", "strong":
            return (true, style.isItalic, true)
        case "i", "em":
            return (style.isBold, true, true)
        case "br":
            let font = fontForStyle(baseFont: style.baseFont, bold: style.isBold, italic: style.isItalic)
            result.append(NSAttributedString(
                string: "\n",
                attributes: [.font: font, .foregroundColor: style.textColor]
            ))
            return (style.isBold, style.isItalic, false)
        case "p", "div":
            appendParagraphBreakIfNeeded(to: result)
            return (style.isBold, style.isItalic, true)
        case "li":
            appendNewlineIfNeeded(to: result)
            let font = fontForStyle(baseFont: style.baseFont, bold: style.isBold, italic: style.isItalic)
            result.append(NSAttributedString(
                string: "• ",
                attributes: [.font: font, .foregroundColor: style.textColor]
            ))
            return (style.isBold, style.isItalic, true)
        case "ul", "ol":
            appendNewlineIfNeeded(to: result)
            return (style.isBold, style.isItalic, true)
        default:
            return (style.isBold, style.isItalic, true)
        }
    }

    private func appendNewlineIfNeeded(to result: NSMutableAttributedString) {
        if result.length > 0 && result.string.last != "\n" {
            result.append(NSAttributedString(string: "\n"))
        }
    }

    private func appendParagraphBreakIfNeeded(to result: NSMutableAttributedString) {
        if result.length > 0 && result.string.last != "\n" {
            result.append(NSAttributedString(string: "\n\n"))
        }
    }

    /// Get font with bold/italic style
    private func fontForStyle(baseFont: UIFont, bold: Bool, italic: Bool) -> UIFont {
        if bold && italic {
            // Create bold-italic font
            if let descriptor = baseFont.fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic]) {
                return UIFont(descriptor: descriptor, size: baseFont.pointSize)
            }
            return UIFont.boldSystemFont(ofSize: baseFont.pointSize)
        } else if bold {
            return UIFont.boldSystemFont(ofSize: baseFont.pointSize)
        } else if italic {
            return UIFont.italicSystemFont(ofSize: baseFont.pointSize)
        }
        return baseFont
    }

    /// Clean up the final attributed string
    private func cleanupAttributedString(_ attributedString: NSMutableAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: attributedString)

        // Remove excessive newlines while preserving attributes
        var searchRange = NSRange(location: 0, length: result.length)
        while searchRange.location < result.length {
            let tripleNewlineRange = (result.string as NSString).range(
                of: "\n\n\n",
                options: [],
                range: searchRange
            )
            if tripleNewlineRange.location == NSNotFound {
                break
            }
            // Replace triple newline with double, preserving attributes at that location
            result.replaceCharacters(in: tripleNewlineRange, with: "\n\n")
            // Adjust search range for next iteration
            searchRange = NSRange(
                location: tripleNewlineRange.location + 2,
                length: result.length - tripleNewlineRange.location - 2
            )
        }

        // Trim leading whitespace/newlines while preserving attributes
        while result.length > 0 {
            let firstChar = (result.string as NSString).substring(to: 1)
            if firstChar.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
                result.deleteCharacters(in: NSRange(location: 0, length: 1))
            } else {
                break
            }
        }

        // Trim trailing whitespace/newlines while preserving attributes
        while result.length > 0 {
            let lastChar = (result.string as NSString).substring(from: result.length - 1)
            if lastChar.rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
                result.deleteCharacters(in: NSRange(location: result.length - 1, length: 1))
            } else {
                break
            }
        }

        return result
    }

    // Unique placeholder that won't be normalized by SwiftSoup
    private let newlinePlaceholder = "⏎NEWLINE⏎"

    /// Process block elements to insert newlines for text extraction
    private func processBlockElements(_ document: Document) throws {
        // Replace br tags with placeholder (br.text() doesn't preserve newlines)
        for br in try document.select("br") {
            try br.after(newlinePlaceholder)
        }

        // Add newline AFTER block elements only (not before)
        // This prevents double-spacing when consecutive divs are used
        for tagName in ["p", "div"] {
            for element in try document.select(tagName) {
                try element.after(newlinePlaceholder)
            }
        }

        // Add bullet points for list items with newline
        for li in try document.select("li") {
            try li.before(newlinePlaceholder)
            try li.prepend("• ")
        }
    }

    /// Fallback regex-based HTML stripping
    private func fallbackStripHTML(_ html: String) -> String {
        var result = html

        // Convert br tags to newlines
        if let regex = try? NSRegularExpression(pattern: "<br[^>]*/?>", options: .caseInsensitive) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "\n"
            )
        }

        // Convert p and div tags to newlines
        if let regex = try? NSRegularExpression(pattern: "</?(?:p|div)[^>]*>", options: .caseInsensitive) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "\n"
            )
        }

        // Strip all remaining tags
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }

        // Decode common HTML entities
        let entities: [(String, String)] = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&apos;", "'"),
            ("&#39;", "'"),
            ("&nbsp;", " "),
            ("&mdash;", "—"),
            ("&ndash;", "–"),
            ("&hellip;", "…")
        ]

        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Clean up whitespace
        result = result.replacingOccurrences(
            of: "\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
