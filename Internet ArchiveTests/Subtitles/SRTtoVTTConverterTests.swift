//
//  SRTtoVTTConverterTests.swift
//  Internet ArchiveTests
//
//  Tests for SRT to WebVTT conversion
//

import XCTest
@testable import Internet_Archive

final class SRTtoVTTConverterTests: XCTestCase {

    // MARK: - Test Helpers

    /// Performs lossy UTF-8 decoding, replacing invalid bytes with the replacement character (U+FFFD).
    /// This mirrors the behavior of SRTtoVTTConverter's fallback decoding for subtitle files.
    /// - Note: Uses String(decoding:as:) intentionally for lossy behavior - the lint rule exists to
    ///   warn against accidental use, but here it's the explicit purpose of this helper.
    private func decodeLossyUTF8(_ data: Data) -> String {
        // Intentionally using lossy decoding - this is the behavior we're testing
        String(decoding: data, as: UTF8.self)
    }

    // MARK: - SRT String Conversion Tests

    func testConvertBasicSRT() async throws {
        // We can't directly test the private method, but we can test through parsing
        // the converted result. First, let's test the SubtitleParser with known VTT.

        let vttContent = """
        WEBVTT

        00:00:01.000 --> 00:00:04.000
        Hello World

        00:00:05.000 --> 00:00:08.000
        Second subtitle
        """

        let cues = try SubtitleParser.shared.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 2)
        XCTAssertEqual(cues[0].text, "Hello World")
        XCTAssertEqual(cues[1].text, "Second subtitle")
    }

    func testSRTTimestampFormatDifference() throws {
        // SRT uses commas for milliseconds, VTT uses periods
        // This tests that our parser handles both formats

        // VTT format (period)
        let vttContent = """
        WEBVTT

        00:00:01.500 --> 00:00:04.750
        Test subtitle
        """

        let cues = try SubtitleParser.shared.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].startTime, 1.5)
        XCTAssertEqual(cues[0].endTime, 4.75)
    }

    func testConverterCacheDirectory() async throws {
        let converter = SRTtoVTTConverter.shared

        // Just verify the cache size method works (doesn't crash)
        let size = await converter.cacheSize()
        XCTAssertGreaterThanOrEqual(size, 0)
    }

    // MARK: - SubtitleFormat Tests for Conversion Need

    func testSRTRequiresConversion() {
        XCTAssertFalse(SubtitleFormat.srt.isNativelySupported)
    }

    func testVTTDoesNotRequireConversion() {
        XCTAssertTrue(SubtitleFormat.vtt.isNativelySupported)
        XCTAssertTrue(SubtitleFormat.webvtt.isNativelySupported)
    }

    // MARK: - Integration Tests

    func testSubtitleTrackConversionNeed() {
        let srtTrack = SubtitleTrack(
            filename: "movie.srt",
            format: .srt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/movie.srt")!
        )

        let vttTrack = SubtitleTrack(
            filename: "movie.vtt",
            format: .vtt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/movie.vtt")!
        )

        XCTAssertFalse(srtTrack.format.isNativelySupported, "SRT should require conversion")
        XCTAssertTrue(vttTrack.format.isNativelySupported, "VTT should be natively supported")
    }

    // MARK: - SubtitleConversionError Tests

    func testSubtitleConversionErrorCacheDirectoryUnavailable() {
        let error = SubtitleConversionError.cacheDirectoryUnavailable
        XCTAssertEqual(error.errorDescription, "Unable to access subtitle cache directory")
    }

    func testSubtitleConversionErrorDownloadFailed() {
        let error = SubtitleConversionError.downloadFailed
        XCTAssertEqual(error.errorDescription, "Failed to download subtitle file")
    }

    func testSubtitleConversionErrorInvalidSRTFormat() {
        let error = SubtitleConversionError.invalidSRTFormat
        XCTAssertEqual(error.errorDescription, "Invalid subtitle file format")
    }

    func testSubtitleConversionErrorConversionFailed() {
        let error = SubtitleConversionError.conversionFailed
        XCTAssertEqual(error.errorDescription, "Failed to convert subtitle format")
    }

    // MARK: - Converter Cache Tests

    func testClearCache() async throws {
        let converter = SRTtoVTTConverter.shared

        // Clear should not throw even if cache doesn't exist
        try await converter.clearCache()

        // Verify cache size is 0 after clear
        let size = await converter.cacheSize()
        XCTAssertEqual(size, 0)
    }

    func testCacheSizeWithEmptyCache() async {
        let converter = SRTtoVTTConverter.shared

        // Clear any existing cache
        try? await converter.clearCache()

        let size = await converter.cacheSize()
        XCTAssertEqual(size, 0)
    }

    // MARK: - VTT Track Passthrough Tests

    func testGetWebVTTURLForVTTTrack() async throws {
        let converter = SRTtoVTTConverter.shared

        let vttTrack = SubtitleTrack(
            filename: "movie.vtt",
            format: .vtt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/movie.vtt")!
        )

        // VTT tracks should return their original URL without conversion
        let resultURL = try await converter.getWebVTTURL(for: vttTrack)
        XCTAssertEqual(resultURL, vttTrack.url)
    }

    func testGetWebVTTURLForWebVTTTrack() async throws {
        let converter = SRTtoVTTConverter.shared

        let webvttTrack = SubtitleTrack(
            filename: "movie.webvtt",
            format: .webvtt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/movie.webvtt")!
        )

        // WebVTT tracks should return their original URL without conversion
        let resultURL = try await converter.getWebVTTURL(for: webvttTrack)
        XCTAssertEqual(resultURL, webvttTrack.url)
    }

    // MARK: - VTT Parsing Edge Cases

    func testParseVTTWithWindowsLineEndings() throws {
        let vttContent = "WEBVTT\r\n\r\n00:00:01.000 --> 00:00:04.000\r\nHello World\r\n"

        let cues = try SubtitleParser.shared.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues[0].text, "Hello World")
    }

    func testParseVTTWithMixedLineEndings() throws {
        let vttContent = "WEBVTT\n\n00:00:01.000 --> 00:00:04.000\r\nLine 1\nLine 2\r\n"

        let cues = try SubtitleParser.shared.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 1)
        XCTAssertTrue(cues[0].text.contains("Line 1"))
    }

    func testParseVTTWithMultipleBlankLines() throws {
        let vttContent = """
        WEBVTT


        00:00:01.000 --> 00:00:04.000
        First


        00:00:05.000 --> 00:00:08.000
        Second
        """

        let cues = try SubtitleParser.shared.parse(vttContent: vttContent)

        XCTAssertEqual(cues.count, 2)
    }

    // MARK: - Encoding Tests

    func testLossyUTF8DecodingPreservesValidText() {
        // Test that valid UTF-8 text is preserved when using lossy decoding
        let validUTF8 = "Hello World - Héllo Wörld - 你好世界"
        let data = Data(validUTF8.utf8)

        let decoded = decodeLossyUTF8(data)
        XCTAssertEqual(decoded, validUTF8)
    }

    func testLossyUTF8DecodingHandlesInvalidBytes() {
        // Create data with invalid UTF-8 sequence (0xFF is never valid in UTF-8)
        var data = Data("Hello ".utf8)
        data.append(contentsOf: [0xFF, 0xFE]) // Invalid UTF-8 bytes
        data.append(contentsOf: Data("World".utf8))

        // decodeLossyUTF8 replaces invalid bytes with replacement character (U+FFFD)
        // This is the behavior we want in SRTtoVTTConverter for subtitle files with mixed encodings
        let decoded = decodeLossyUTF8(data)

        XCTAssertTrue(decoded.contains("Hello"))
        XCTAssertTrue(decoded.contains("World"))
        XCTAssertTrue(decoded.contains("\u{FFFD}")) // Unicode replacement character
    }

    func testLossyUTF8DecodingDoesNotReturnEmpty() {
        // Even with entirely invalid UTF-8 data, lossy decoding produces replacement characters
        // This ensures subtitle files with encoding issues still display something
        let invalidData = Data([0xFF, 0xFE, 0x80, 0x81])

        let decoded = decodeLossyUTF8(invalidData)

        XCTAssertFalse(decoded.isEmpty)
    }
}

// MARK: - SRTConversionHelpers Tests

final class SRTConversionHelpersTests: XCTestCase {

    // MARK: - SRT to VTT Conversion Tests

    func testConvertSRTStringToVTT_basicConversion() {
        let srt = """
        1
        00:00:01,000 --> 00:00:04,000
        Hello World

        2
        00:00:05,000 --> 00:00:08,000
        Second subtitle
        """

        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)

        XCTAssertTrue(vtt.hasPrefix("WEBVTT"))
        XCTAssertTrue(vtt.contains("00:00:01.000 --> 00:00:04.000"))
        XCTAssertTrue(vtt.contains("Hello World"))
        XCTAssertTrue(vtt.contains("00:00:05.000 --> 00:00:08.000"))
        XCTAssertTrue(vtt.contains("Second subtitle"))
    }

    func testConvertSRTStringToVTT_convertsCommasToPeriods() {
        let srt = """
        1
        00:01:23,456 --> 00:02:34,789
        Test text
        """

        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)

        XCTAssertTrue(vtt.contains("00:01:23.456 --> 00:02:34.789"))
        XCTAssertFalse(vtt.contains(","))
    }

    func testConvertSRTStringToVTT_handlesWindowsLineEndings() {
        let srt = "1\r\n00:00:01,000 --> 00:00:02,000\r\nWindows line endings\r\n"

        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)

        XCTAssertTrue(vtt.contains("Windows line endings"))
    }

    func testConvertSRTStringToVTT_handlesMacLineEndings() {
        let srt = "1\r00:00:01,000 --> 00:00:02,000\rMac classic endings\r"

        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)

        XCTAssertTrue(vtt.contains("Mac classic endings"))
    }

    func testConvertSRTStringToVTT_multilineSubtitle() {
        let srt = """
        1
        00:00:01,000 --> 00:00:04,000
        Line one
        Line two
        Line three
        """

        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)

        XCTAssertTrue(vtt.contains("Line one"))
        XCTAssertTrue(vtt.contains("Line two"))
        XCTAssertTrue(vtt.contains("Line three"))
    }

    func testConvertSRTStringToVTT_emptyInput() {
        let vtt = SRTConversionHelpers.convertSRTStringToVTT("")

        XCTAssertTrue(vtt.hasPrefix("WEBVTT"))
        // Should only have header, no cues
        XCTAssertEqual(vtt.trimmingCharacters(in: .whitespacesAndNewlines), "WEBVTT")
    }

    func testConvertSRTStringToVTT_skipsMalformedBlocks() {
        let srt = """
        1
        00:00:01,000 --> 00:00:02,000
        Valid subtitle

        This is not a valid block
        Missing timing line

        2
        00:00:05,000 --> 00:00:06,000
        Another valid one
        """

        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)

        XCTAssertTrue(vtt.contains("Valid subtitle"))
        XCTAssertTrue(vtt.contains("Another valid one"))
        XCTAssertFalse(vtt.contains("Missing timing line"))
    }

    func testConvertSRTStringToVTT_skipsEmptyTextBlocks() {
        let srt = """
        1
        00:00:01,000 --> 00:00:02,000


        2
        00:00:03,000 --> 00:00:04,000
        Real subtitle
        """

        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)

        XCTAssertTrue(vtt.contains("Real subtitle"))
        // Should not have empty cue
        let cueCount = vtt.components(separatedBy: " --> ").count - 1
        XCTAssertEqual(cueCount, 1)
    }

    func testConvertSRTStringToVTT_preservesSpecialCharacters() {
        let srt = """
        1
        00:00:01,000 --> 00:00:02,000
        Special chars: é à ü ñ 中文 🎬
        """

        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)

        XCTAssertTrue(vtt.contains("é à ü ñ 中文 🎬"))
    }

    func testConvertSRTStringToVTT_preservesHTMLTags() {
        let srt = """
        1
        00:00:01,000 --> 00:00:02,000
        <i>Italic text</i> and <b>bold</b>
        """

        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)

        XCTAssertTrue(vtt.contains("<i>Italic text</i>"))
        XCTAssertTrue(vtt.contains("<b>bold</b>"))
    }

    // MARK: - Encoding Detection Tests

    func testDecodeSubtitleData_utf8() {
        let text = "Hello World - Héllo Wörld"
        let data = text.data(using: .utf8)!

        let decoded = SRTConversionHelpers.decodeSubtitleData(data)

        XCTAssertEqual(decoded, text)
    }

    func testDecodeSubtitleData_windowsCP1252() {
        // Windows-1252 specific characters: smart quotes and em-dash
        // These bytes represent: "Hello" smart quote char
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x93]) // "Hello" + left smart quote

        let decoded = SRTConversionHelpers.decodeSubtitleData(data)

        XCTAssertTrue(decoded.hasPrefix("Hello"))
        XCTAssertFalse(decoded.isEmpty)
    }

    func testDecodeSubtitleData_latin1Fallback() {
        // Latin-1 can decode any byte sequence
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F, 0xE9]) // "Hello" + é in Latin-1

        let decoded = SRTConversionHelpers.decodeSubtitleData(data)

        XCTAssertTrue(decoded.hasPrefix("Hello"))
    }

    func testDecodeSubtitleData_emptyData() {
        let decoded = SRTConversionHelpers.decodeSubtitleData(Data())
        XCTAssertEqual(decoded, "")
    }

    // MARK: - VTT Filename Generation Tests

    func testVttFilename_lowercaseSRT() {
        let result = SRTConversionHelpers.vttFilename(from: "movie.srt")
        XCTAssertEqual(result, "movie.vtt")
    }

    func testVttFilename_uppercaseSRT() {
        let result = SRTConversionHelpers.vttFilename(from: "movie.SRT")
        XCTAssertEqual(result, "movie.vtt")
    }

    func testVttFilename_mixedCaseSRT() {
        let result = SRTConversionHelpers.vttFilename(from: "movie.Srt")
        XCTAssertEqual(result, "movie.vtt")
    }

    func testVttFilename_noExtension() {
        let result = SRTConversionHelpers.vttFilename(from: "movie")
        XCTAssertEqual(result, "movie")
    }

    func testVttFilename_multipleDotsInName() {
        let result = SRTConversionHelpers.vttFilename(from: "movie.en.srt")
        XCTAssertEqual(result, "movie.en.vtt")
    }

    // MARK: - Timing Validation Tests

    func testIsTimingLine_validLine() {
        XCTAssertTrue(SRTConversionHelpers.isTimingLine("00:00:01,000 --> 00:00:04,000"))
        XCTAssertTrue(SRTConversionHelpers.isTimingLine("00:00:01.000 --> 00:00:04.000"))
    }

    func testIsTimingLine_invalidLine() {
        XCTAssertFalse(SRTConversionHelpers.isTimingLine("1"))
        XCTAssertFalse(SRTConversionHelpers.isTimingLine("Hello World"))
        XCTAssertFalse(SRTConversionHelpers.isTimingLine(""))
    }

    func testIsTimingLine_partialArrow() {
        XCTAssertFalse(SRTConversionHelpers.isTimingLine("00:00:01 -> 00:00:04"))
        XCTAssertFalse(SRTConversionHelpers.isTimingLine("00:00:01-->00:00:04")) // No spaces
    }

    // MARK: - Timestamp Conversion Tests

    func testConvertTimestamp_commaToDecimal() {
        let result = SRTConversionHelpers.convertTimestamp("00:01:23,456")
        XCTAssertEqual(result, "00:01:23.456")
    }

    func testConvertTimestamp_alreadyDecimal() {
        let result = SRTConversionHelpers.convertTimestamp("00:01:23.456")
        XCTAssertEqual(result, "00:01:23.456")
    }

    func testConvertTimestamp_noMilliseconds() {
        let result = SRTConversionHelpers.convertTimestamp("00:01:23")
        XCTAssertEqual(result, "00:01:23")
    }
}
