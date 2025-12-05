//
//  SubtitleModelsTests.swift
//  Internet ArchiveTests
//
//  Tests for subtitle models and parsing
//

import XCTest
@testable import Internet_Archive

final class SubtitleModelsTests: XCTestCase {

    // MARK: - SubtitleFormat Tests

    func testSubtitleFormatFromSRTFilename() {
        let format = SubtitleFormat(filename: "movie.srt")
        XCTAssertEqual(format, .srt)
    }

    func testSubtitleFormatFromVTTFilename() {
        let format = SubtitleFormat(filename: "movie.vtt")
        XCTAssertEqual(format, .vtt)
    }

    func testSubtitleFormatFromWebVTTFilename() {
        let format = SubtitleFormat(filename: "movie.webvtt")
        XCTAssertEqual(format, .webvtt)
    }

    func testSubtitleFormatFromUppercaseFilename() {
        let format = SubtitleFormat(filename: "MOVIE.SRT")
        XCTAssertEqual(format, .srt)
    }

    func testSubtitleFormatFromNonSubtitleFile() {
        let format = SubtitleFormat(filename: "movie.mp4")
        XCTAssertNil(format)
    }

    func testSubtitleFormatIsNativelySupported() {
        XCTAssertTrue(SubtitleFormat.vtt.isNativelySupported)
        XCTAssertTrue(SubtitleFormat.webvtt.isNativelySupported)
        XCTAssertFalse(SubtitleFormat.srt.isNativelySupported)
    }

    // MARK: - SubtitleLanguage Tests

    func testSubtitleLanguageFromEnglish() {
        let language = SubtitleLanguage.fromFilename("english")
        XCTAssertEqual(language, .english)
    }

    func testSubtitleLanguageFromEng() {
        let language = SubtitleLanguage.fromFilename("eng")
        XCTAssertEqual(language, .english)
    }

    func testSubtitleLanguageFromEn() {
        let language = SubtitleLanguage.fromFilename("en")
        XCTAssertEqual(language, .english)
    }

    func testSubtitleLanguageFromSpanish() {
        let language = SubtitleLanguage.fromFilename("spanish")
        XCTAssertEqual(language, .spanish)
    }

    func testSubtitleLanguageFromEspañol() {
        let language = SubtitleLanguage.fromFilename("español")
        XCTAssertEqual(language, .spanish)
    }

    func testSubtitleLanguageFromFrench() {
        let language = SubtitleLanguage.fromFilename("french")
        XCTAssertEqual(language, .french)
    }

    func testSubtitleLanguageFromGerman() {
        let language = SubtitleLanguage.fromFilename("deutsch")
        XCTAssertEqual(language, .german)
    }

    func testSubtitleLanguageFromJapanese() {
        let language = SubtitleLanguage.fromFilename("jpn")
        XCTAssertEqual(language, .japanese)
    }

    func testSubtitleLanguageFromUnknown() {
        let language = SubtitleLanguage.fromFilename("klingon")
        XCTAssertNil(language)
    }

    func testSubtitleLanguageDisplayName() {
        XCTAssertEqual(SubtitleLanguage.english.displayName, "English")
        XCTAssertEqual(SubtitleLanguage.spanish.displayName, "Spanish")
        XCTAssertEqual(SubtitleLanguage.french.displayName, "French")
        XCTAssertEqual(SubtitleLanguage.german.displayName, "German")
        XCTAssertEqual(SubtitleLanguage.japanese.displayName, "Japanese")
    }

    // MARK: - SubtitleTrack Tests

    func testSubtitleTrackIdentifier() {
        let track = SubtitleTrack(
            filename: "movie_english.srt",
            format: .srt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://archive.org/download/test/movie_english.srt")!
        )
        XCTAssertEqual(track.identifier, "movie_english.srt_en")
    }

    func testSubtitleTrackEquality() {
        let track1 = SubtitleTrack(
            filename: "movie_english.srt",
            format: .srt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://archive.org/download/test/movie_english.srt")!
        )
        let track2 = SubtitleTrack(
            filename: "movie_english.srt",
            format: .srt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://archive.org/download/test/movie_english.srt")!
        )
        XCTAssertEqual(track1, track2)
    }

    // MARK: - SubtitleCue Tests

    func testSubtitleCueIsActiveAtTime() {
        let cue = SubtitleCue(startTime: 1.0, endTime: 5.0, text: "Hello World")

        XCTAssertFalse(cue.isActive(at: 0.5))
        XCTAssertTrue(cue.isActive(at: 1.0))
        XCTAssertTrue(cue.isActive(at: 3.0))
        XCTAssertTrue(cue.isActive(at: 4.999))
        XCTAssertFalse(cue.isActive(at: 5.0))
        XCTAssertFalse(cue.isActive(at: 6.0))
    }

    // MARK: - FileInfo Extension Tests

    func testFileInfoIsSubtitleFile() {
        let srtFile = FileInfo(name: "movie.srt")
        let vttFile = FileInfo(name: "movie.vtt")
        let mp4File = FileInfo(name: "movie.mp4")

        XCTAssertTrue(srtFile.isSubtitleFile)
        XCTAssertTrue(vttFile.isSubtitleFile)
        XCTAssertFalse(mp4File.isSubtitleFile)
    }

    func testFileInfoSubtitleFormat() {
        let srtFile = FileInfo(name: "movie.srt")
        let vttFile = FileInfo(name: "movie.vtt")
        let mp4File = FileInfo(name: "movie.mp4")

        XCTAssertEqual(srtFile.subtitleFormat, .srt)
        XCTAssertEqual(vttFile.subtitleFormat, .vtt)
        XCTAssertNil(mp4File.subtitleFormat)
    }

    func testFileInfoIsSubtitleFile_webvtt() {
        let webvttFile = FileInfo(name: "movie.webvtt")
        XCTAssertTrue(webvttFile.isSubtitleFile)
        XCTAssertEqual(webvttFile.subtitleFormat, .webvtt)
    }

    func testFileInfoIsSubtitleFile_caseInsensitive() {
        let upperSRT = FileInfo(name: "MOVIE.SRT")
        let mixedVTT = FileInfo(name: "Movie.VtT")

        XCTAssertTrue(upperSRT.isSubtitleFile)
        XCTAssertTrue(mixedVTT.isSubtitleFile)
    }

    func testFileInfoIsSubtitleFile_mp3() {
        let mp3File = FileInfo(name: "audio.mp3")
        XCTAssertFalse(mp3File.isSubtitleFile)
        XCTAssertNil(mp3File.subtitleFormat)
    }

    func testFileInfoIsSubtitleFile_noExtension() {
        let noExtFile = FileInfo(name: "movie")
        XCTAssertFalse(noExtFile.isSubtitleFile)
        XCTAssertNil(noExtFile.subtitleFormat)
    }

    func testFileInfoIsSubtitleFile_emptyName() {
        let emptyFile = FileInfo(name: "")
        XCTAssertFalse(emptyFile.isSubtitleFile)
        XCTAssertNil(emptyFile.subtitleFormat)
    }

    func testFileInfoIsSubtitleFile_hiddenFile() {
        let hiddenSRT = FileInfo(name: ".hidden.srt")
        XCTAssertTrue(hiddenSRT.isSubtitleFile)
    }

    func testFileInfoIsSubtitleFile_pathWithDirectory() {
        let pathFile = FileInfo(name: "subtitles/english/movie.srt")
        XCTAssertTrue(pathFile.isSubtitleFile)
    }

    // MARK: - SubtitleCue Edge Cases

    func testSubtitleCueIsActive_atExactStartTime() {
        let cue = SubtitleCue(startTime: 10.0, endTime: 20.0, text: "Test")
        XCTAssertTrue(cue.isActive(at: 10.0))
    }

    func testSubtitleCueIsActive_justBeforeEndTime() {
        let cue = SubtitleCue(startTime: 10.0, endTime: 20.0, text: "Test")
        XCTAssertTrue(cue.isActive(at: 19.999))
    }

    func testSubtitleCueIsActive_atExactEndTime() {
        let cue = SubtitleCue(startTime: 10.0, endTime: 20.0, text: "Test")
        XCTAssertFalse(cue.isActive(at: 20.0))
    }

    func testSubtitleCueIsActive_negativeTime() {
        let cue = SubtitleCue(startTime: 0.0, endTime: 5.0, text: "Test")
        XCTAssertFalse(cue.isActive(at: -1.0))
    }

    func testSubtitleCueIsActive_zeroDuration() {
        let cue = SubtitleCue(startTime: 5.0, endTime: 5.0, text: "Test")
        XCTAssertFalse(cue.isActive(at: 5.0))
    }

    func testSubtitleCueEquality() {
        let cue1 = SubtitleCue(startTime: 1.0, endTime: 5.0, text: "Hello")
        let cue2 = SubtitleCue(startTime: 1.0, endTime: 5.0, text: "Hello")
        XCTAssertEqual(cue1, cue2)
    }

    func testSubtitleCueInequality_differentText() {
        let cue1 = SubtitleCue(startTime: 1.0, endTime: 5.0, text: "Hello")
        let cue2 = SubtitleCue(startTime: 1.0, endTime: 5.0, text: "World")
        XCTAssertNotEqual(cue1, cue2)
    }

    func testSubtitleCueInequality_differentTimes() {
        let cue1 = SubtitleCue(startTime: 1.0, endTime: 5.0, text: "Hello")
        let cue2 = SubtitleCue(startTime: 2.0, endTime: 5.0, text: "Hello")
        XCTAssertNotEqual(cue1, cue2)
    }

    // MARK: - SubtitleLanguage Edge Cases

    func testSubtitleLanguageFromFilename_caseInsensitive() {
        XCTAssertEqual(SubtitleLanguage.fromFilename("ENGLISH"), .english)
        XCTAssertEqual(SubtitleLanguage.fromFilename("English"), .english)
        XCTAssertEqual(SubtitleLanguage.fromFilename("eNgLiSh"), .english)
    }

    func testSubtitleLanguageFromFilename_chinese() {
        XCTAssertEqual(SubtitleLanguage.fromFilename("chinese"), .chinese)
        XCTAssertEqual(SubtitleLanguage.fromFilename("zh"), .chinese)
        XCTAssertEqual(SubtitleLanguage.fromFilename("zho"), .chinese)
    }

    func testSubtitleLanguageFromFilename_portuguese() {
        XCTAssertEqual(SubtitleLanguage.fromFilename("portuguese"), .portuguese)
        XCTAssertEqual(SubtitleLanguage.fromFilename("pt"), .portuguese)
        XCTAssertEqual(SubtitleLanguage.fromFilename("por"), .portuguese)
    }

    func testSubtitleLanguageFromFilename_italian() {
        XCTAssertEqual(SubtitleLanguage.fromFilename("italian"), .italian)
        XCTAssertEqual(SubtitleLanguage.fromFilename("it"), .italian)
        XCTAssertEqual(SubtitleLanguage.fromFilename("ita"), .italian)
    }

    func testSubtitleLanguageFromFilename_emptyString() {
        XCTAssertNil(SubtitleLanguage.fromFilename(""))
    }
}
