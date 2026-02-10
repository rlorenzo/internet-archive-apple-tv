//
//  SRTtoVTTConverterTests.swift
//  Internet ArchiveTests
//
//  Tests for SRT to WebVTT conversion, encoding detection, and cache management
//  Migrated to Swift Testing for Sprint 2
//

import Testing
import Foundation
@testable import Internet_Archive

// MARK: - SRTConversionHelpers Tests

@Suite("SRTConversionHelpers Tests")
struct SRTConversionHelpersTests {

    // MARK: - SRT to VTT Conversion

    @Test("Basic SRT to VTT conversion")
    func basicConversion() {
        let srt = """
        1
        00:00:01,000 --> 00:00:04,000
        Hello World

        2
        00:00:05,000 --> 00:00:08,000
        Second subtitle
        """
        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)

        #expect(vtt.hasPrefix("WEBVTT"))
        #expect(vtt.contains("00:00:01.000 --> 00:00:04.000"))
        #expect(vtt.contains("Hello World"))
        #expect(vtt.contains("00:00:05.000 --> 00:00:08.000"))
        #expect(vtt.contains("Second subtitle"))
    }

    @Test("Converts commas to periods in timestamps")
    func convertsCommasToPeriods() {
        let srt = """
        1
        00:01:23,456 --> 00:02:34,789
        Test text
        """
        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)

        #expect(vtt.contains("00:01:23.456 --> 00:02:34.789"))
        #expect(!vtt.contains(","))
    }

    @Test("Handles Windows line endings")
    func handlesWindowsLineEndings() {
        let srt = "1\r\n00:00:01,000 --> 00:00:02,000\r\nWindows line endings\r\n"
        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)
        #expect(vtt.contains("Windows line endings"))
    }

    @Test("Handles Mac classic line endings")
    func handlesMacLineEndings() {
        let srt = "1\r00:00:01,000 --> 00:00:02,000\rMac classic endings\r"
        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)
        #expect(vtt.contains("Mac classic endings"))
    }

    @Test("Preserves multiline subtitles")
    func multilineSubtitle() {
        let srt = """
        1
        00:00:01,000 --> 00:00:04,000
        Line one
        Line two
        Line three
        """
        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)

        #expect(vtt.contains("Line one"))
        #expect(vtt.contains("Line two"))
        #expect(vtt.contains("Line three"))
    }

    @Test("Empty input produces only WEBVTT header")
    func emptyInput() {
        let vtt = SRTConversionHelpers.convertSRTStringToVTT("")
        #expect(vtt.hasPrefix("WEBVTT"))
        #expect(vtt.trimmingCharacters(in: .whitespacesAndNewlines) == "WEBVTT")
    }

    @Test("Skips malformed blocks without timing lines")
    func skipsMalformedBlocks() {
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

        #expect(vtt.contains("Valid subtitle"))
        #expect(vtt.contains("Another valid one"))
        #expect(!vtt.contains("Missing timing line"))
    }

    @Test("Skips blocks with empty text")
    func skipsEmptyTextBlocks() {
        let srt = """
        1
        00:00:01,000 --> 00:00:02,000


        2
        00:00:03,000 --> 00:00:04,000
        Real subtitle
        """
        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)

        #expect(vtt.contains("Real subtitle"))
        let cueCount = vtt.components(separatedBy: " --> ").count - 1
        #expect(cueCount == 1)
    }

    @Test("Preserves special characters and unicode")
    func preservesSpecialCharacters() {
        let srt = """
        1
        00:00:01,000 --> 00:00:02,000
        Special chars: é à ü ñ 中文 🎬
        """
        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)
        #expect(vtt.contains("é à ü ñ 中文 🎬"))
    }

    @Test("Preserves HTML/styling tags")
    func preservesHTMLTags() {
        let srt = """
        1
        00:00:01,000 --> 00:00:02,000
        <i>Italic text</i> and <b>bold</b>
        """
        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)
        #expect(vtt.contains("<i>Italic text</i>"))
        #expect(vtt.contains("<b>bold</b>"))
    }

    @Test("Handles many cues efficiently")
    func manyCues() {
        var srt = ""
        for i in 1...100 {
            srt += "\(i)\n00:00:\(String(format: "%02d", i)),000 --> 00:00:\(String(format: "%02d", i + 1)),000\nCue \(i)\n\n"
        }
        let vtt = SRTConversionHelpers.convertSRTStringToVTT(srt)
        #expect(vtt.hasPrefix("WEBVTT"))
        #expect(vtt.contains("Cue 1"))
        #expect(vtt.contains("Cue 100"))
    }

    // MARK: - Encoding Detection

    @Test("Decodes UTF-8 correctly")
    func decodeUTF8() {
        let text = "Hello World - Héllo Wörld"
        let data = text.data(using: .utf8)!
        let decoded = SRTConversionHelpers.decodeSubtitleData(data)
        #expect(decoded == text)
    }

    @Test("Decodes Windows CP1252")
    func decodeWindowsCP1252() {
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x93]) // "Hello" + left smart quote
        let decoded = SRTConversionHelpers.decodeSubtitleData(data)
        #expect(decoded.hasPrefix("Hello"))
        #expect(!decoded.isEmpty)
    }

    @Test("Falls back to Latin-1 for unknown encoding")
    func decodeLatin1Fallback() {
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F, 0xE9]) // "Hello" + é in Latin-1
        let decoded = SRTConversionHelpers.decodeSubtitleData(data)
        #expect(decoded.hasPrefix("Hello"))
    }

    @Test("Empty data returns empty string")
    func decodeEmptyData() {
        let decoded = SRTConversionHelpers.decodeSubtitleData(Data())
        #expect(decoded == "")
    }

    @Test("Pure ASCII decoded correctly")
    func decodePureASCII() {
        let text = "Simple ASCII text 123"
        let data = text.data(using: .ascii)!
        let decoded = SRTConversionHelpers.decodeSubtitleData(data)
        #expect(decoded == text)
    }

    // MARK: - VTT Filename Generation

    @Test("Converts lowercase .srt to .vtt")
    func vttFilenameLowercase() {
        #expect(SRTConversionHelpers.vttFilename(from: "movie.srt") == "movie.vtt")
    }

    @Test("Converts uppercase .SRT to .vtt")
    func vttFilenameUppercase() {
        #expect(SRTConversionHelpers.vttFilename(from: "movie.SRT") == "movie.vtt")
    }

    @Test("Converts mixed case .Srt to .vtt")
    func vttFilenameMixedCase() {
        #expect(SRTConversionHelpers.vttFilename(from: "movie.Srt") == "movie.vtt")
    }

    @Test("No extension unchanged")
    func vttFilenameNoExtension() {
        #expect(SRTConversionHelpers.vttFilename(from: "movie") == "movie")
    }

    @Test("Multiple dots in name - only last .srt replaced")
    func vttFilenameMultipleDots() {
        #expect(SRTConversionHelpers.vttFilename(from: "movie.en.srt") == "movie.en.vtt")
    }

    @Test("Language code in filename preserved",
          arguments: [
            ("movie.en.srt", "movie.en.vtt"),
            ("movie.es.srt", "movie.es.vtt"),
            ("movie.fr.srt", "movie.fr.vtt")
          ])
    func vttFilenameWithLanguage(input: String, expected: String) {
        #expect(SRTConversionHelpers.vttFilename(from: input) == expected)
    }

    // MARK: - Timing Validation

    @Test("Valid timing lines detected",
          arguments: [
            "00:00:01,000 --> 00:00:04,000",
            "00:00:01.000 --> 00:00:04.000",
            "01:23:45,678 --> 02:34:56,789"
          ])
    func isTimingLineValid(line: String) {
        #expect(SRTConversionHelpers.isTimingLine(line))
    }

    @Test("Invalid timing lines rejected",
          arguments: [
            "1",
            "Hello World",
            "",
            "00:00:01 -> 00:00:04",
            "00:00:01-->00:00:04"
          ])
    func isTimingLineInvalid(line: String) {
        #expect(!SRTConversionHelpers.isTimingLine(line))
    }

    // MARK: - Timestamp Conversion

    @Test("Timestamp conversion",
          arguments: [
            ("00:01:23,456", "00:01:23.456"),
            ("00:01:23.456", "00:01:23.456"),
            ("00:01:23", "00:01:23"),
            ("01:00:00,000", "01:00:00.000"),
            ("00:00:05,123", "00:00:05.123")
          ])
    func convertTimestamp(input: String, expected: String) {
        #expect(SRTConversionHelpers.convertTimestamp(input) == expected)
    }
}

// MARK: - SRTtoVTTConverter Actor Tests

@Suite("SRTtoVTTConverter Tests")
struct SRTtoVTTConverterActorTests {

    @Test("VTT parsing - basic content")
    func parseBasicVTT() throws {
        let vttContent = """
        WEBVTT

        00:00:01.000 --> 00:00:04.000
        Hello World

        00:00:05.000 --> 00:00:08.000
        Second subtitle
        """
        let cues = try SubtitleParser.shared.parse(vttContent: vttContent)
        #expect(cues.count == 2)
        #expect(cues[0].text == "Hello World")
        #expect(cues[1].text == "Second subtitle")
    }

    @Test("VTT timestamps parsed correctly")
    func vttTimestampsParsed() throws {
        let vttContent = """
        WEBVTT

        00:00:01.500 --> 00:00:04.750
        Test subtitle
        """
        let cues = try SubtitleParser.shared.parse(vttContent: vttContent)
        #expect(cues.count == 1)
        #expect(cues[0].startTime == 1.5)
        #expect(cues[0].endTime == 4.75)
    }

    @Test("Cache size returns non-negative value")
    func cacheSizeNonNegative() async {
        let converter = SRTtoVTTConverter.shared
        let size = await converter.cacheSize()
        #expect(size >= 0)
    }

    @Test("Clear cache succeeds")
    func clearCacheSucceeds() async throws {
        let converter = SRTtoVTTConverter.shared
        try await converter.clearCache()
        let size = await converter.cacheSize()
        #expect(size == 0)
    }

    // MARK: - Subtitle Format Tests

    @Test("SRT requires conversion")
    func srtRequiresConversion() {
        #expect(!SubtitleFormat.srt.isNativelySupported)
    }

    @Test("VTT does not require conversion")
    func vttNativelySupported() {
        #expect(SubtitleFormat.vtt.isNativelySupported)
        #expect(SubtitleFormat.webvtt.isNativelySupported)
    }

    // MARK: - SubtitleTrack Conversion Need

    @Test("SRT track needs conversion, VTT does not")
    func subtitleTrackConversionNeed() {
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

        #expect(!srtTrack.format.isNativelySupported)
        #expect(vttTrack.format.isNativelySupported)
    }

    // MARK: - VTT Track Passthrough

    @Test("VTT track returns original URL without conversion")
    func vttTrackPassthrough() async throws {
        let converter = SRTtoVTTConverter.shared
        let vttTrack = SubtitleTrack(
            filename: "movie.vtt",
            format: .vtt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/movie.vtt")!
        )
        let resultURL = try await converter.getWebVTTURL(for: vttTrack)
        #expect(resultURL == vttTrack.url)
    }

    @Test("WebVTT track returns original URL without conversion")
    func webvttTrackPassthrough() async throws {
        let converter = SRTtoVTTConverter.shared
        let webvttTrack = SubtitleTrack(
            filename: "movie.webvtt",
            format: .webvtt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/movie.webvtt")!
        )
        let resultURL = try await converter.getWebVTTURL(for: webvttTrack)
        #expect(resultURL == webvttTrack.url)
    }

    // MARK: - SubtitleConversionError Tests

    @Test("Error descriptions",
          arguments: [
            (SubtitleConversionError.cacheDirectoryUnavailable, "Unable to access subtitle cache directory"),
            (SubtitleConversionError.downloadFailed, "Failed to download subtitle file"),
            (SubtitleConversionError.invalidSRTFormat, "Invalid subtitle file format"),
            (SubtitleConversionError.conversionFailed, "Failed to convert subtitle format")
          ])
    func errorDescriptions(error: SubtitleConversionError, expected: String) {
        #expect(error.errorDescription == expected)
    }

    // MARK: - VTT Parsing Edge Cases

    @Test("Parses VTT with Windows line endings")
    func parseVTTWindowsLineEndings() throws {
        let vttContent = "WEBVTT\r\n\r\n00:00:01.000 --> 00:00:04.000\r\nHello World\r\n"
        let cues = try SubtitleParser.shared.parse(vttContent: vttContent)
        #expect(cues.count == 1)
        #expect(cues[0].text == "Hello World")
    }

    @Test("Parses VTT with mixed line endings")
    func parseVTTMixedLineEndings() throws {
        let vttContent = "WEBVTT\n\n00:00:01.000 --> 00:00:04.000\r\nLine 1\nLine 2\r\n"
        let cues = try SubtitleParser.shared.parse(vttContent: vttContent)
        #expect(cues.count == 1)
        #expect(cues[0].text.contains("Line 1"))
    }

    @Test("Parses VTT with multiple blank lines")
    func parseVTTMultipleBlankLines() throws {
        let vttContent = """
        WEBVTT


        00:00:01.000 --> 00:00:04.000
        First


        00:00:05.000 --> 00:00:08.000
        Second
        """
        let cues = try SubtitleParser.shared.parse(vttContent: vttContent)
        #expect(cues.count == 2)
    }
}
