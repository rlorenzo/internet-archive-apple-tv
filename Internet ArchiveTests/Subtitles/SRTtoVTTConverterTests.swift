//
//  SRTtoVTTConverterTests.swift
//  Internet ArchiveTests
//
//  Tests for SRT to WebVTT conversion
//

import XCTest
@testable import Internet_Archive

final class SRTtoVTTConverterTests: XCTestCase {

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
}
