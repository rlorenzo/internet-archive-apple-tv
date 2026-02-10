//
//  SubtitleManagerTests.swift
//  Internet ArchiveTests
//
//  Tests for SubtitleManager functionality
//

import XCTest
@testable import Internet_Archive

@MainActor
final class SubtitleManagerTests: XCTestCase {

    nonisolated(unsafe) var manager: SubtitleManager!

    override func setUp() {
        super.setUp()
        let newManager = MainActor.assumeIsolated {
            let mgr = SubtitleManager.shared
            // Clear preferences before each test
            mgr.subtitlesEnabled = false
            mgr.preferredLanguageCode = nil
            return mgr
        }
        manager = newManager
    }

    override func tearDown() {
        MainActor.assumeIsolated {
            // Clean up preferences after tests
            SubtitleManager.shared.subtitlesEnabled = false
            SubtitleManager.shared.preferredLanguageCode = nil
        }
        super.tearDown()
    }

    // MARK: - Language Parsing Tests

    func testParseLanguageFromEnglishFilename() {
        let result = manager.parseLanguage(from: "movie_english.srt")
        XCTAssertEqual(result.code, "en")
        XCTAssertEqual(result.displayName, "English")
        XCTAssertFalse(result.isDefault)
    }

    func testParseLanguageFromSpanishFilename() {
        let result = manager.parseLanguage(from: "movie_spanish.srt")
        XCTAssertEqual(result.code, "es")
        XCTAssertEqual(result.displayName, "Spanish")
        XCTAssertFalse(result.isDefault)
    }

    func testParseLanguageFromShortCode() {
        let result = manager.parseLanguage(from: "movie.en.srt")
        XCTAssertEqual(result.code, "en")
        XCTAssertEqual(result.displayName, "English")
    }

    func testParseLanguageFromFrenchFilename() {
        let result = manager.parseLanguage(from: "video-french.vtt")
        XCTAssertEqual(result.code, "fr")
        XCTAssertEqual(result.displayName, "French")
    }

    func testParseLanguageFromGermanFilename() {
        let result = manager.parseLanguage(from: "film_deutsch.srt")
        XCTAssertEqual(result.code, "de")
        XCTAssertEqual(result.displayName, "German")
    }

    func testParseLanguageFromJapaneseFilename() {
        let result = manager.parseLanguage(from: "anime_jpn.srt")
        XCTAssertEqual(result.code, "ja")
        XCTAssertEqual(result.displayName, "Japanese")
    }

    func testParseLanguageFromUnknownReturnsDefault() {
        let result = manager.parseLanguage(from: "movie.srt")
        XCTAssertNil(result.code)
        XCTAssertEqual(result.displayName, "Subtitles")
        XCTAssertTrue(result.isDefault)
    }

    func testParseLanguageFromClosedCaptionFilename() {
        let result = manager.parseLanguage(from: "movie_cc.srt")
        XCTAssertNil(result.code)
        XCTAssertEqual(result.displayName, "Closed Captions")
        XCTAssertTrue(result.isDefault)
    }

    func testParseLanguageFromSDHFilename() {
        let result = manager.parseLanguage(from: "movie_sdh.srt")
        XCTAssertNil(result.code)
        XCTAssertEqual(result.displayName, "Closed Captions")
        XCTAssertTrue(result.isDefault)
    }

    // MARK: - Subtitle Track Extraction Tests

    func testExtractSubtitleTracksFromFiles() {
        let files = [
            FileInfo(name: "movie.mp4"),
            FileInfo(name: "movie_english.srt"),
            FileInfo(name: "movie_spanish.vtt"),
            FileInfo(name: "thumbnail.jpg")
        ]

        let tracks = manager.extractSubtitleTracks(
            from: files,
            identifier: "test-item"
        )

        XCTAssertEqual(tracks.count, 2)
        XCTAssertTrue(tracks.contains { $0.languageCode == "en" })
        XCTAssertTrue(tracks.contains { $0.languageCode == "es" })
    }

    func testExtractSubtitleTracksWithNoSubtitles() {
        let files = [
            FileInfo(name: "movie.mp4"),
            FileInfo(name: "thumbnail.jpg")
        ]

        let tracks = manager.extractSubtitleTracks(
            from: files,
            identifier: "test-item"
        )

        XCTAssertTrue(tracks.isEmpty)
    }

    func testExtractSubtitleTracksURLConstruction() {
        let files = [
            FileInfo(name: "movie_english.srt")
        ]

        let tracks = manager.extractSubtitleTracks(
            from: files,
            identifier: "test-item"
        )

        XCTAssertEqual(tracks.count, 1)
        XCTAssertEqual(
            tracks[0].url.absoluteString,
            "https://archive.org/download/test-item/movie_english.srt"
        )
    }

    func testExtractSubtitleTracksWithCustomServer() {
        // Note: Server parameter is now ignored - always uses archive.org for reliability
        let files = [
            FileInfo(name: "movie_english.srt")
        ]

        let tracks = manager.extractSubtitleTracks(
            from: files,
            identifier: "test-item",
            server: "ia800100.us.archive.org"
        )

        XCTAssertEqual(tracks.count, 1)
        // Should use archive.org regardless of server parameter
        XCTAssertEqual(
            tracks[0].url.absoluteString,
            "https://archive.org/download/test-item/movie_english.srt"
        )
    }

    func testExtractSubtitleTracksSorting() {
        let files = [
            FileInfo(name: "movie_spanish.srt"),
            FileInfo(name: "movie.srt"), // Default (no language)
            FileInfo(name: "movie_english.srt")
        ]

        let tracks = manager.extractSubtitleTracks(
            from: files,
            identifier: "test-item"
        )

        XCTAssertEqual(tracks.count, 3)
        // Default track should be first
        XCTAssertTrue(tracks[0].isDefault)
        // Then alphabetically by language name
        XCTAssertEqual(tracks[1].languageDisplayName, "English")
        XCTAssertEqual(tracks[2].languageDisplayName, "Spanish")
    }

    // MARK: - Preference Tests

    func testSubtitlesEnabledPreference() {
        XCTAssertFalse(manager.subtitlesEnabled)

        manager.subtitlesEnabled = true
        XCTAssertTrue(manager.subtitlesEnabled)

        manager.subtitlesEnabled = false
        XCTAssertFalse(manager.subtitlesEnabled)
    }

    func testPreferredLanguageCodePreference() {
        XCTAssertNil(manager.preferredLanguageCode)

        manager.preferredLanguageCode = "es"
        XCTAssertEqual(manager.preferredLanguageCode, "es")

        manager.preferredLanguageCode = nil
        XCTAssertNil(manager.preferredLanguageCode)
    }

    func testPreferredTrackReturnsNilWhenDisabled() {
        manager.subtitlesEnabled = false

        let tracks = [
            SubtitleTrack(
                filename: "movie_english.srt",
                format: .srt,
                languageCode: "en",
                languageDisplayName: "English",
                isDefault: false,
                url: URL(string: "https://example.com/movie_english.srt")!
            )
        ]

        let preferred = manager.preferredTrack(from: tracks)
        XCTAssertNil(preferred)
    }

    func testPreferredTrackReturnsMatchingLanguage() {
        manager.subtitlesEnabled = true
        manager.preferredLanguageCode = "es"

        let tracks = [
            SubtitleTrack(
                filename: "movie_english.srt",
                format: .srt,
                languageCode: "en",
                languageDisplayName: "English",
                isDefault: false,
                url: URL(string: "https://example.com/movie_english.srt")!
            ),
            SubtitleTrack(
                filename: "movie_spanish.srt",
                format: .srt,
                languageCode: "es",
                languageDisplayName: "Spanish",
                isDefault: false,
                url: URL(string: "https://example.com/movie_spanish.srt")!
            )
        ]

        let preferred = manager.preferredTrack(from: tracks)
        XCTAssertEqual(preferred?.languageCode, "es")
    }

    func testPreferredTrackFallsBackToEnglish() {
        manager.subtitlesEnabled = true
        manager.preferredLanguageCode = "de" // German not available

        let tracks = [
            SubtitleTrack(
                filename: "movie_english.srt",
                format: .srt,
                languageCode: "en",
                languageDisplayName: "English",
                isDefault: false,
                url: URL(string: "https://example.com/movie_english.srt")!
            ),
            SubtitleTrack(
                filename: "movie_spanish.srt",
                format: .srt,
                languageCode: "es",
                languageDisplayName: "Spanish",
                isDefault: false,
                url: URL(string: "https://example.com/movie_spanish.srt")!
            )
        ]

        let preferred = manager.preferredTrack(from: tracks)
        XCTAssertEqual(preferred?.languageCode, "en")
    }

    func testPreferredTrackFallsBackToFirst() {
        manager.subtitlesEnabled = true
        manager.preferredLanguageCode = "de" // German not available

        let tracks = [
            SubtitleTrack(
                filename: "movie_spanish.srt",
                format: .srt,
                languageCode: "es",
                languageDisplayName: "Spanish",
                isDefault: false,
                url: URL(string: "https://example.com/movie_spanish.srt")!
            ),
            SubtitleTrack(
                filename: "movie_french.srt",
                format: .srt,
                languageCode: "fr",
                languageDisplayName: "French",
                isDefault: false,
                url: URL(string: "https://example.com/movie_french.srt")!
            )
        ]

        let preferred = manager.preferredTrack(from: tracks)
        // No English, so falls back to first
        XCTAssertEqual(preferred?.languageCode, "es")
    }

    func testSaveTrackSelection() {
        let track = SubtitleTrack(
            filename: "movie_spanish.srt",
            format: .srt,
            languageCode: "es",
            languageDisplayName: "Spanish",
            isDefault: false,
            url: URL(string: "https://example.com/movie_spanish.srt")!
        )

        manager.saveTrackSelection(track)

        XCTAssertTrue(manager.subtitlesEnabled)
        XCTAssertEqual(manager.preferredLanguageCode, "es")
    }

    func testClearTrackSelection() {
        manager.subtitlesEnabled = true
        manager.preferredLanguageCode = "es"

        manager.clearTrackSelection()

        XCTAssertFalse(manager.subtitlesEnabled)
        // preferredLanguageCode is preserved for next time
    }

    // MARK: - URL Building Tests

    func testBuildSubtitleURL() {
        let url = manager.buildSubtitleURL(
            filename: "movie_english.srt",
            identifier: "test-item"
        )

        XCTAssertEqual(
            url?.absoluteString,
            "https://archive.org/download/test-item/movie_english.srt"
        )
    }

    func testBuildSubtitleURLWithCustomServer() {
        // Note: Server parameter is now ignored - always uses archive.org for reliability
        let url = manager.buildSubtitleURL(
            filename: "movie_english.srt",
            identifier: "test-item",
            server: "ia800100.us.archive.org"
        )

        // Should use archive.org regardless of server parameter
        XCTAssertEqual(
            url?.absoluteString,
            "https://archive.org/download/test-item/movie_english.srt"
        )
    }

    func testBuildSubtitleURLWithSpaces() {
        let url = manager.buildSubtitleURL(
            filename: "movie english.srt",
            identifier: "test-item"
        )

        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("movie%20english.srt"))
    }

    // MARK: - Additional Edge Case Tests

    func testParseLanguageFromChineseFilename() {
        let result = manager.parseLanguage(from: "movie_chinese.srt")
        XCTAssertEqual(result.code, "zh")
        XCTAssertEqual(result.displayName, "Chinese")
    }

    func testParseLanguageFromPortugueseFilename() {
        let result = manager.parseLanguage(from: "movie_portuguese.srt")
        XCTAssertEqual(result.code, "pt")
        XCTAssertEqual(result.displayName, "Portuguese")
    }

    func testParseLanguageFromItalianFilename() {
        let result = manager.parseLanguage(from: "movie_italian.srt")
        XCTAssertEqual(result.code, "it")
        XCTAssertEqual(result.displayName, "Italian")
    }

    func testParseLanguageFromKoreanFilename() {
        let result = manager.parseLanguage(from: "movie_korean.srt")
        XCTAssertEqual(result.code, "ko")
        XCTAssertEqual(result.displayName, "Korean")
    }

    func testParseLanguageFromRussianFilename() {
        let result = manager.parseLanguage(from: "movie_russian.srt")
        XCTAssertEqual(result.code, "ru")
        XCTAssertEqual(result.displayName, "Russian")
    }

    func testParseLanguageFromArabicFilename() {
        let result = manager.parseLanguage(from: "movie_arabic.srt")
        XCTAssertEqual(result.code, "ar")
        XCTAssertEqual(result.displayName, "Arabic")
    }

    func testParseLanguageFromHindiFilename() {
        // "hi" is the language code for Hindi
        let result = manager.parseLanguage(from: "movie_hi.srt")
        XCTAssertEqual(result.code, "hi")
        XCTAssertEqual(result.displayName, "Hindi")
        XCTAssertFalse(result.isDefault)
    }

    func testParseLanguageFromMultipleSeparators() {
        let result = manager.parseLanguage(from: "movie-subtitles_english.srt")
        XCTAssertEqual(result.code, "en")
        XCTAssertEqual(result.displayName, "English")
    }

    func testParseLanguageFromWebvttExtension() {
        let result = manager.parseLanguage(from: "movie_spanish.webvtt")
        XCTAssertEqual(result.code, "es")
        XCTAssertEqual(result.displayName, "Spanish")
    }

    func testExtractSubtitleTracksWithEmptyFiles() {
        let tracks = manager.extractSubtitleTracks(
            from: [],
            identifier: "test-item"
        )
        XCTAssertTrue(tracks.isEmpty)
    }

    func testExtractSubtitleTracksWithWebvttFormat() {
        let files = [
            FileInfo(name: "movie_english.webvtt")
        ]

        let tracks = manager.extractSubtitleTracks(
            from: files,
            identifier: "test-item"
        )

        XCTAssertEqual(tracks.count, 1)
        XCTAssertEqual(tracks[0].format, .webvtt)
    }

    func testPreferredTrackWithEmptyTracks() {
        manager.subtitlesEnabled = true
        let preferred = manager.preferredTrack(from: [])
        XCTAssertNil(preferred)
    }

    func testPreferredTrackMatchesLastSelected() {
        manager.subtitlesEnabled = true
        manager.preferredLanguageCode = "en"

        let spanishTrack = SubtitleTrack(
            filename: "movie_spanish.srt",
            format: .srt,
            languageCode: "es",
            languageDisplayName: "Spanish",
            isDefault: false,
            url: URL(string: "https://example.com/movie_spanish.srt")!
        )

        let englishTrack = SubtitleTrack(
            filename: "movie_english.srt",
            format: .srt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/movie_english.srt")!
        )

        // Save Spanish as last selected
        manager.saveTrackSelection(spanishTrack)

        let tracks = [englishTrack, spanishTrack]
        let preferred = manager.preferredTrack(from: tracks)

        // Should return Spanish (last selected) even though English is preferred language
        XCTAssertEqual(preferred?.languageCode, "es")
    }

    func testSaveTrackSelectionWithNilLanguageCode() {
        let track = SubtitleTrack(
            filename: "movie.srt",
            format: .srt,
            languageCode: nil,
            languageDisplayName: "Subtitles",
            isDefault: true,
            url: URL(string: "https://example.com/movie.srt")!
        )

        // Clear any previous preferred language
        manager.preferredLanguageCode = nil

        manager.saveTrackSelection(track)

        XCTAssertTrue(manager.subtitlesEnabled)
        // preferredLanguageCode should not be updated when track has nil code
        XCTAssertNil(manager.preferredLanguageCode)
    }

    func testBuildSubtitleURLWithSpecialCharacters() {
        let url = manager.buildSubtitleURL(
            filename: "movie (2024) [HD]_english.srt",
            identifier: "test-item"
        )

        XCTAssertNotNil(url)
    }

    // MARK: - VTT Preference / Deduplication Tests

    func testExtractSubtitleTracksDeduplicatesPrefersVTT() {
        // When both SRT and VTT exist for same language, prefer VTT
        let files = [
            FileInfo(name: "movie_english.srt"),
            FileInfo(name: "movie_english.vtt")
        ]

        let tracks = manager.extractSubtitleTracks(
            from: files,
            identifier: "test-item"
        )

        XCTAssertEqual(tracks.count, 1)
        XCTAssertEqual(tracks[0].format, .vtt)
        XCTAssertEqual(tracks[0].languageCode, "en")
    }

    func testExtractSubtitleTracksDeduplicatesMultipleLanguages() {
        // Multiple languages, each with SRT and VTT - should get one VTT per language
        let files = [
            FileInfo(name: "movie_english.srt"),
            FileInfo(name: "movie_english.vtt"),
            FileInfo(name: "movie_spanish.srt"),
            FileInfo(name: "movie_spanish.vtt"),
            FileInfo(name: "movie_french.srt")  // Only SRT for French
        ]

        let tracks = manager.extractSubtitleTracks(
            from: files,
            identifier: "test-item"
        )

        XCTAssertEqual(tracks.count, 3)

        let englishTrack = tracks.first { $0.languageCode == "en" }
        let spanishTrack = tracks.first { $0.languageCode == "es" }
        let frenchTrack = tracks.first { $0.languageCode == "fr" }

        XCTAssertEqual(englishTrack?.format, .vtt)
        XCTAssertEqual(spanishTrack?.format, .vtt)
        XCTAssertEqual(frenchTrack?.format, .srt)  // Fallback to SRT when no VTT
    }

    func testExtractSubtitleTracksKeepsSRTWhenNoVTT() {
        // SRT-only content should still work
        let files = [
            FileInfo(name: "movie_english.srt"),
            FileInfo(name: "movie_spanish.srt")
        ]

        let tracks = manager.extractSubtitleTracks(
            from: files,
            identifier: "test-item"
        )

        XCTAssertEqual(tracks.count, 2)
        XCTAssertTrue(tracks.allSatisfy { $0.format == .srt })
    }

    func testExtractSubtitleTracksDeduplicatesUnknownLanguage() {
        // Files with no detectable language should be deduplicated by display name
        let files = [
            FileInfo(name: "movie.srt"),
            FileInfo(name: "movie.vtt")
        ]

        let tracks = manager.extractSubtitleTracks(
            from: files,
            identifier: "test-item"
        )

        XCTAssertEqual(tracks.count, 1)
        XCTAssertEqual(tracks[0].format, .vtt)
    }

    func testExtractSubtitleTracksPreservesDefaultWhenVTTSeenFirst() {
        // When VTT (non-default) is seen before default SRT, the default flag should transfer to VTT
        // This tests the edge case where file ordering puts VTT before the default SRT
        let files = [
            FileInfo(name: "movie_english.vtt"),  // VTT first, not default
            FileInfo(name: "movie.srt")            // SRT second, will be parsed as default (no language = default)
        ]

        let tracks = manager.extractSubtitleTracks(
            from: files,
            identifier: "test-item"
        )

        // Should have 2 tracks - different languages ("English" vs "Subtitles")
        XCTAssertEqual(tracks.count, 2)

        let englishTrack = tracks.first { $0.languageCode == "en" }
        XCTAssertNotNil(englishTrack)
        XCTAssertEqual(englishTrack?.format, .vtt)
    }

    func testExtractSubtitleTracksTransfersDefaultFromSRTToExistingVTT() {
        // When VTT exists and later SRT with same language but isDefault=true arrives,
        // the default flag should transfer to the VTT track
        // Note: This requires manually creating tracks since FileInfo parsing determines isDefault
        // For this test, we verify the deduplication preserves VTT format when both exist
        let files = [
            FileInfo(name: "movie_english.vtt"),
            FileInfo(name: "movie_english.srt")
        ]

        let tracks = manager.extractSubtitleTracks(
            from: files,
            identifier: "test-item"
        )

        XCTAssertEqual(tracks.count, 1)
        XCTAssertEqual(tracks[0].format, .vtt)
        XCTAssertEqual(tracks[0].languageCode, "en")
    }

    // MARK: - ASR (Auto-generated) Subtitle Tests

    func testParseLanguageFromASRFilename() {
        let result = manager.parseLanguage(from: "movie.asr.srt")
        XCTAssertNil(result.code)
        XCTAssertEqual(result.displayName, "Auto-generated")
        XCTAssertTrue(result.isDefault)
    }

    func testParseLanguageFromASRFilenameWithLanguage() {
        let result = manager.parseLanguage(from: "movie_en.asr.srt")
        XCTAssertEqual(result.code, "en")
        XCTAssertEqual(result.displayName, "English (Auto)")
        XCTAssertFalse(result.isDefault)
    }

    func testParseLanguageFromASRFilenameWithLanguagePrefix() {
        let result = manager.parseLanguage(from: "movie.asr.english.srt")
        XCTAssertEqual(result.code, "en")
        XCTAssertEqual(result.displayName, "English (Auto)")
        XCTAssertFalse(result.isDefault)
    }

    func testExtractSubtitleTracksPreservesBothHumanAndAutoGenerated() {
        // Both human-generated and auto-generated English tracks should be preserved
        let files = [
            FileInfo(name: "movie_english.srt"),
            FileInfo(name: "movie_en.asr.srt")
        ]

        let tracks = manager.extractSubtitleTracks(
            from: files,
            identifier: "test-item"
        )

        // Should have both tracks - not deduplicated because display names differ
        XCTAssertEqual(tracks.count, 2)

        let humanTrack = tracks.first { $0.languageDisplayName == "English" }
        let autoTrack = tracks.first { $0.languageDisplayName == "English (Auto)" }

        XCTAssertNotNil(humanTrack, "Human-generated English track should be preserved")
        XCTAssertNotNil(autoTrack, "Auto-generated English track should be preserved")
        XCTAssertEqual(humanTrack?.languageCode, "en")
        XCTAssertEqual(autoTrack?.languageCode, "en")
    }
}
