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
            let attributedString = try convertElement(
                document.body() ?? document,
                baseFont: baseFont,
                textColor: textColor
            )
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

    /// Convert a SwiftSoup element to NSAttributedString
    private func convertElement(
        _ element: Element,
        baseFont: UIFont,
        textColor: UIColor,
        isBold: Bool = false,
        isItalic: Bool = false
    ) throws -> NSMutableAttributedString {
        let result = NSMutableAttributedString()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6

        for node in element.getChildNodes() {
            if let textNode = node as? TextNode {
                // Text node - add with current formatting
                let text = textNode.text()
                if !text.isEmpty {
                    let font = fontForStyle(baseFont: baseFont, bold: isBold, italic: isItalic)
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: textColor,
                        .paragraphStyle: paragraphStyle
                    ]
                    result.append(NSAttributedString(string: text, attributes: attributes))
                }
            } else if let childElement = node as? Element {
                let tagName = childElement.tagName().lowercased()

                // Determine formatting for this element
                var childBold = isBold
                var childItalic = isItalic

                switch tagName {
                case "b", "strong":
                    childBold = true
                case "i", "em":
                    childItalic = true
                case "br":
                    let font = fontForStyle(baseFont: baseFont, bold: isBold, italic: isItalic)
                    result.append(NSAttributedString(
                        string: "\n",
                        attributes: [.font: font, .foregroundColor: textColor]
                    ))
                    continue
                case "p", "div":
                    // Add paragraph break before if we have content
                    if result.length > 0 {
                        let lastChar = result.string.last
                        if lastChar != "\n" {
                            result.append(NSAttributedString(string: "\n\n"))
                        }
                    }
                case "li":
                    // Add bullet point
                    let font = fontForStyle(baseFont: baseFont, bold: isBold, italic: isItalic)
                    if result.length > 0 && result.string.last != "\n" {
                        result.append(NSAttributedString(string: "\n"))
                    }
                    result.append(NSAttributedString(
                        string: "• ",
                        attributes: [.font: font, .foregroundColor: textColor]
                    ))
                case "ul", "ol":
                    // Add newline before list
                    if result.length > 0 && result.string.last != "\n" {
                        result.append(NSAttributedString(string: "\n"))
                    }
                default:
                    break
                }

                // Recursively process child elements
                let childResult = try convertElement(
                    childElement,
                    baseFont: baseFont,
                    textColor: textColor,
                    isBold: childBold,
                    isItalic: childItalic
                )
                result.append(childResult)

                // Add paragraph break after block elements
                if tagName == "p" || tagName == "div" {
                    if result.length > 0 && result.string.last != "\n" {
                        result.append(NSAttributedString(string: "\n"))
                    }
                }
            }
        }

        return result
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
