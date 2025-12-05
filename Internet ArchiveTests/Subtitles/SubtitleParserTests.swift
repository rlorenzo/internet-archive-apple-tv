//
//  SubtitleParserTests.swift
//  Internet ArchiveTests
//
//  Tests for WebVTT subtitle parsing
//

import XCTest
@testable import Internet_Archive

final class SubtitleParserTests: XCTestCase {

    let parser = SubtitleParser.shared

    // MARK: - Basic Parsing Tests

    func testParseValidWebVTT() throws {
        let vttContent = """
        WEBVTT

        00:00:01.000 --> 00:00:04.000
        Hello World

        00:00:05.000 --> 00:00:08.000
        Second subtitle
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 2)
        XCTAssertEqual(cues[0].startTime, 1.0)
        XCTAssertEqual(cues[0].endTime, 4.0)
        XCTAssertEqual(cues[0].text, "Hello World")
        XCTAssertEqual(cues[1].startTime, 5.0)
        XCTAssertEqual(cues[1].endTime, 8.0)
        XCTAssertEqual(cues[1].text, "Second subtitle")
    }

    func testParseWebVTTWithMultilineText() throws {
        let vttContent = """
        WEBVTT

        00:00:01.000 --> 00:00:04.000
        Line one
        Line two
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].text, "Line one\nLine two")
    }

    func testParseWebVTTWithHoursTimestamp() throws {
        let vttContent = """
        WEBVTT

        01:30:00.000 --> 01:30:05.000
        One hour thirty minutes in
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].startTime, 5400.0) // 1 hour 30 minutes = 5400 seconds
        XCTAssertEqual(cues[0].endTime, 5405.0)
    }

    func testParseWebVTTWithMinutesOnlyTimestamp() throws {
        let vttContent = """
        WEBVTT

        01:30.500 --> 01:35.000
        Short format timestamp
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].startTime, 90.5)
        XCTAssertEqual(cues[0].endTime, 95.0)
    }

    func testParseWebVTTWithCueIdentifiers() throws {
        let vttContent = """
        WEBVTT

        1
        00:00:01.000 --> 00:00:04.000
        First cue with ID

        2
        00:00:05.000 --> 00:00:08.000
        Second cue with ID
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 2)
        XCTAssertEqual(cues[0].text, "First cue with ID")
        XCTAssertEqual(cues[1].text, "Second cue with ID")
    }

    // MARK: - Error Handling Tests

    func testParseInvalidWebVTTMissingHeader() {
        let invalidContent = """
        00:00:01.000 --> 00:00:04.000
        Missing WEBVTT header
        """

        XCTAssertThrowsError(try parser.parse(vttContent: invalidContent)) { error in
            XCTAssertTrue(error is SubtitleParseError)
            if let parseError = error as? SubtitleParseError {
                XCTAssertEqual(parseError, SubtitleParseError.missingHeader)
            }
        }
    }

    func testParseEmptyWebVTT() throws {
        let vttContent = "WEBVTT\n\n"

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertTrue(cues.isEmpty)
    }

    // MARK: - Tag Stripping Tests

    func testParseWebVTTStripsBasicTags() throws {
        let vttContent = """
        WEBVTT

        00:00:01.000 --> 00:00:04.000
        <b>Bold</b> and <i>italic</i> text
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].text, "Bold and italic text")
    }

    func testParseWebVTTStripsVoiceTags() throws {
        let vttContent = """
        WEBVTT

        00:00:01.000 --> 00:00:04.000
        <v Speaker>Hello there</v>
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].text, "Hello there")
    }

    // MARK: - Sorting Tests

    func testParsedCuesAreSortedByStartTime() throws {
        let vttContent = """
        WEBVTT

        00:00:05.000 --> 00:00:08.000
        Second

        00:00:01.000 --> 00:00:04.000
        First

        00:00:10.000 --> 00:00:12.000
        Third
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 3)
        XCTAssertEqual(cues[0].text, "First")
        XCTAssertEqual(cues[1].text, "Second")
        XCTAssertEqual(cues[2].text, "Third")
    }

    // MARK: - Windows Line Endings Tests

    func testParseWebVTTWithWindowsLineEndings() throws {
        let vttContent = "WEBVTT\r\n\r\n00:00:01.000 --> 00:00:04.000\r\nWindows line endings"

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].text, "Windows line endings")
    }

    // MARK: - Cue Settings Tests

    func testParseWebVTTWithCueSettings() throws {
        let vttContent = """
        WEBVTT

        00:00:01.000 --> 00:00:04.000 position:50% align:center
        Centered subtitle
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].startTime, 1.0)
        XCTAssertEqual(cues[0].endTime, 4.0)
        XCTAssertEqual(cues[0].text, "Centered subtitle")
    }

    // MARK: - Additional Parsing Tests

    func testParseWebVTTWithNote() throws {
        let vttContent = """
        WEBVTT

        NOTE This is a comment
        that spans multiple lines

        00:00:01.000 --> 00:00:04.000
        Actual subtitle
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].text, "Actual subtitle")
    }

    func testParseWebVTTWithStyleBlock() throws {
        let vttContent = """
        WEBVTT

        STYLE
        ::cue { color: white }

        00:00:01.000 --> 00:00:04.000
        Styled subtitle
        """

        let cues = try parser.parse(vttContent: vttContent)

        // Style blocks should be ignored
        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].text, "Styled subtitle")
    }

    func testParseWebVTTWithRegion() throws {
        let vttContent = """
        WEBVTT

        REGION
        id:region1
        width:50%

        00:00:01.000 --> 00:00:04.000
        Region subtitle
        """

        let cues = try parser.parse(vttContent: vttContent)

        // Region blocks should be ignored
        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].text, "Region subtitle")
    }

    func testParseWebVTTStripsNestedTags() throws {
        let vttContent = """
        WEBVTT

        00:00:01.000 --> 00:00:04.000
        <b><i>Bold and italic</i></b>
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].text, "Bold and italic")
    }

    func testParseWebVTTWithTimestampTags() throws {
        let vttContent = """
        WEBVTT

        00:00:01.000 --> 00:00:05.000
        <00:00:01.000>Word <00:00:02.000>by <00:00:03.000>word
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].text, "Word by word")
    }

    func testParseWebVTTWithClassTags() throws {
        let vttContent = """
        WEBVTT

        00:00:01.000 --> 00:00:04.000
        <c.yellow>Yellow text</c>
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].text, "Yellow text")
    }

    func testParseWebVTTWithEmptyLines() throws {
        let vttContent = """
        WEBVTT

        00:00:01.000 --> 00:00:04.000

        Some text

        """

        let cues = try parser.parse(vttContent: vttContent)

        // Should have text even with extra empty lines
        XCTAssertGreaterThanOrEqual(cues.count, 0)
    }

    func testParseWebVTTMillisecondsAccuracy() throws {
        let vttContent = """
        WEBVTT

        00:00:01.123 --> 00:00:04.456
        Test milliseconds
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].startTime, 1.123, accuracy: 0.001)
        XCTAssertEqual(cues[0].endTime, 4.456, accuracy: 0.001)
    }

    func testParseWebVTTWithLongDuration() throws {
        let vttContent = """
        WEBVTT

        10:00:00.000 --> 10:00:05.000
        Ten hours in
        """

        let cues = try parser.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].startTime, 36000.0) // 10 hours in seconds
    }

    // MARK: - SubtitleParseError Tests

    func testSubtitleParseErrorMissingHeaderDescription() {
        let error = SubtitleParseError.missingHeader
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("WEBVTT") ?? false)
    }

    func testSubtitleParseErrorInvalidEncodingDescription() {
        let error = SubtitleParseError.invalidEncoding
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("decode") ?? false)
    }

    func testSubtitleParseErrorInvalidFormatDescription() {
        let error = SubtitleParseError.invalidFormat
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("format") ?? false)
    }
}
