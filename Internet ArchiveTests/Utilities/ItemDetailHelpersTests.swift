//
//  ItemDetailHelpersTests.swift
//  Internet ArchiveTests
//
//  Tests for ItemDetailHelpers - subtitle parsing, date formatting, URL building
//

import XCTest
@testable import Internet_Archive

// MARK: - SubtitleHelpers Tests

final class SubtitleHelpersTests: XCTestCase {

    // MARK: - isSubtitleFile Tests

    func testIsSubtitleFile_srtExtension_returnsTrue() {
        XCTAssertTrue(SubtitleHelpers.isSubtitleFile("movie_english.srt"))
    }

    func testIsSubtitleFile_vttExtension_returnsTrue() {
        XCTAssertTrue(SubtitleHelpers.isSubtitleFile("subtitle.vtt"))
    }

    func testIsSubtitleFile_webvttExtension_returnsTrue() {
        XCTAssertTrue(SubtitleHelpers.isSubtitleFile("captions.webvtt"))
    }

    func testIsSubtitleFile_uppercaseExtension_returnsTrue() {
        XCTAssertTrue(SubtitleHelpers.isSubtitleFile("MOVIE.SRT"))
    }

    func testIsSubtitleFile_mixedCaseExtension_returnsTrue() {
        XCTAssertTrue(SubtitleHelpers.isSubtitleFile("Movie.Srt"))
    }

    func testIsSubtitleFile_mp4Extension_returnsFalse() {
        XCTAssertFalse(SubtitleHelpers.isSubtitleFile("movie.mp4"))
    }

    func testIsSubtitleFile_mp3Extension_returnsFalse() {
        XCTAssertFalse(SubtitleHelpers.isSubtitleFile("track.mp3"))
    }

    func testIsSubtitleFile_txtExtension_returnsFalse() {
        XCTAssertFalse(SubtitleHelpers.isSubtitleFile("readme.txt"))
    }

    func testIsSubtitleFile_noExtension_returnsFalse() {
        XCTAssertFalse(SubtitleHelpers.isSubtitleFile("filename"))
    }

    // MARK: - extractLanguage Tests

    func testExtractLanguage_englishSuffix_returnsEnglish() {
        let result = SubtitleHelpers.extractLanguage(from: "movie_english.srt")
        XCTAssertEqual(result, "English")
    }

    func testExtractLanguage_spanishSuffix_returnsSpanish() {
        let result = SubtitleHelpers.extractLanguage(from: "video_spanish.vtt")
        XCTAssertEqual(result, "Spanish")
    }

    func testExtractLanguage_lowercaseLanguage_capitalizes() {
        let result = SubtitleHelpers.extractLanguage(from: "film_french.srt")
        XCTAssertEqual(result, "French")
    }

    func testExtractLanguage_uppercaseLanguage_capitalizes() {
        let result = SubtitleHelpers.extractLanguage(from: "movie_GERMAN.srt")
        XCTAssertEqual(result, "German")
    }

    func testExtractLanguage_noUnderscore_returnsNil() {
        let result = SubtitleHelpers.extractLanguage(from: "movieenglish.srt")
        XCTAssertNil(result)
    }

    func testExtractLanguage_multipleUnderscores_usesLast() {
        let result = SubtitleHelpers.extractLanguage(from: "my_movie_title_portuguese.srt")
        XCTAssertEqual(result, "Portuguese")
    }

    func testExtractLanguage_numberSuffix_returnsNil() {
        let result = SubtitleHelpers.extractLanguage(from: "movie_001.srt")
        XCTAssertNil(result)
    }

    func testExtractLanguage_singleCharSuffix_returnsNil() {
        let result = SubtitleHelpers.extractLanguage(from: "movie_a.srt")
        XCTAssertNil(result)
    }

    func testExtractLanguage_twoCharLanguageCode_returns() {
        let result = SubtitleHelpers.extractLanguage(from: "movie_en.srt")
        XCTAssertEqual(result, "En")
    }

    // MARK: - filterSubtitleFiles Tests

    func testFilterSubtitleFiles_mixedFiles_returnsOnlySubtitles() {
        let files = [
            FileInfo(name: "movie.mp4", source: "original", format: "MPEG4"),
            FileInfo(name: "movie_english.srt", source: "original", format: "SubRip"),
            FileInfo(name: "movie_spanish.vtt", source: "original", format: "WebVTT"),
            FileInfo(name: "thumbnail.jpg", source: "derivative", format: "JPEG")
        ]

        let result = SubtitleHelpers.filterSubtitleFiles(files)

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.name == "movie_english.srt" })
        XCTAssertTrue(result.contains { $0.name == "movie_spanish.vtt" })
    }

    func testFilterSubtitleFiles_noSubtitles_returnsEmpty() {
        let files = [
            FileInfo(name: "movie.mp4", source: "original", format: "MPEG4"),
            FileInfo(name: "thumbnail.jpg", source: "derivative", format: "JPEG")
        ]

        let result = SubtitleHelpers.filterSubtitleFiles(files)

        XCTAssertTrue(result.isEmpty)
    }

    func testFilterSubtitleFiles_allSubtitles_returnsAll() {
        let files = [
            FileInfo(name: "movie_english.srt", source: "original", format: "SubRip"),
            FileInfo(name: "movie_spanish.srt", source: "original", format: "SubRip"),
            FileInfo(name: "movie_french.vtt", source: "original", format: "WebVTT")
        ]

        let result = SubtitleHelpers.filterSubtitleFiles(files)

        XCTAssertEqual(result.count, 3)
    }

    func testFilterSubtitleFiles_emptyInput_returnsEmpty() {
        let result = SubtitleHelpers.filterSubtitleFiles([])
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - extractLanguages Tests

    func testExtractLanguages_multipleLanguages_returnsSorted() {
        let files = [
            FileInfo(name: "movie_spanish.srt", source: "original", format: "SubRip"),
            FileInfo(name: "movie_english.srt", source: "original", format: "SubRip"),
            FileInfo(name: "movie_french.srt", source: "original", format: "SubRip")
        ]

        let result = SubtitleHelpers.extractLanguages(from: files)

        XCTAssertEqual(result, ["English", "French", "Spanish"])
    }

    func testExtractLanguages_duplicateLanguages_returnsUnique() {
        let files = [
            FileInfo(name: "movie_english.srt", source: "original", format: "SubRip"),
            FileInfo(name: "movie_english.vtt", source: "original", format: "WebVTT")
        ]

        let result = SubtitleHelpers.extractLanguages(from: files)

        XCTAssertEqual(result, ["English"])
    }

    func testExtractLanguages_noExtractableLanguages_returnsEmpty() {
        let files = [
            FileInfo(name: "subtitle1.srt", source: "original", format: "SubRip"),
            FileInfo(name: "subtitle2.srt", source: "original", format: "SubRip")
        ]

        let result = SubtitleHelpers.extractLanguages(from: files)

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - formatSubtitleInfo Tests

    func testFormatSubtitleInfo_withLanguages_formatsCorrectly() {
        let files = [
            FileInfo(name: "movie.mp4", source: "original", format: "MPEG4"),
            FileInfo(name: "movie_english.srt", source: "original", format: "SubRip"),
            FileInfo(name: "movie_spanish.srt", source: "original", format: "SubRip")
        ]

        let result = SubtitleHelpers.formatSubtitleInfo(files: files)

        XCTAssertEqual(result, "Subtitles: English, Spanish")
    }

    func testFormatSubtitleInfo_singleSubtitleNoLanguage_formatsSingular() {
        let files = [
            FileInfo(name: "movie.mp4", source: "original", format: "MPEG4"),
            FileInfo(name: "subtitle.srt", source: "original", format: "SubRip")
        ]

        let result = SubtitleHelpers.formatSubtitleInfo(files: files)

        XCTAssertEqual(result, "1 subtitle track available")
    }

    func testFormatSubtitleInfo_multipleSubtitlesNoLanguage_formatsPlural() {
        let files = [
            FileInfo(name: "sub1.srt", source: "original", format: "SubRip"),
            FileInfo(name: "sub2.srt", source: "original", format: "SubRip"),
            FileInfo(name: "sub3.vtt", source: "original", format: "WebVTT")
        ]

        let result = SubtitleHelpers.formatSubtitleInfo(files: files)

        XCTAssertEqual(result, "3 subtitle tracks available")
    }

    func testFormatSubtitleInfo_noSubtitles_returnsNil() {
        let files = [
            FileInfo(name: "movie.mp4", source: "original", format: "MPEG4"),
            FileInfo(name: "thumbnail.jpg", source: "derivative", format: "JPEG")
        ]

        let result = SubtitleHelpers.formatSubtitleInfo(files: files)

        XCTAssertNil(result)
    }

    func testFormatSubtitleInfo_emptyFiles_returnsNil() {
        let result = SubtitleHelpers.formatSubtitleInfo(files: [])
        XCTAssertNil(result)
    }
}

// MARK: - DateFormattingHelpers Tests

final class DateFormattingHelpersTests: XCTestCase {

    func testFormatDateWithLicense_dateOnly_formatsDate() {
        let result = DateFormattingHelpers.formatDateWithLicense(
            dateString: "2024-01-15",
            formattedDate: "Jan 15, 2024",
            licenseType: nil
        )

        XCTAssertNotNil(result)
        XCTAssertTrue(result!.hasPrefix("Date:"))
        XCTAssertTrue(result!.contains("Jan 15, 2024"))
        XCTAssertFalse(result!.contains("License"))
    }

    func testFormatDateWithLicense_withLicense_includesLicense() {
        let result = DateFormattingHelpers.formatDateWithLicense(
            dateString: "2024-01-15",
            formattedDate: "Jan 15, 2024",
            licenseType: "CC BY"
        )

        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("Date:"))
        XCTAssertTrue(result!.contains("License:"))
        XCTAssertTrue(result!.contains("CC BY"))
        XCTAssertTrue(result!.contains("\u{2022}"))  // Bullet separator
    }

    func testFormatDateWithLicense_nilDate_returnsNil() {
        let result = DateFormattingHelpers.formatDateWithLicense(
            dateString: nil,
            formattedDate: nil,
            licenseType: "CC BY"
        )

        XCTAssertNil(result)
    }

    func testFormatDateWithLicense_noFormattedDate_usesRaw() {
        let result = DateFormattingHelpers.formatDateWithLicense(
            dateString: "2024-01-15",
            formattedDate: nil,
            licenseType: nil
        )

        XCTAssertNotNil(result)
        XCTAssertEqual(result, "Date: 2024-01-15")
    }

    // MARK: - formatDateString Tests

    func testFormatDateString_isoFormat_formats() {
        let result = DateFormattingHelpers.formatDateString("2024-01-15")
        // Should format to medium date style
        XCTAssertFalse(result.contains("-"))  // Should not be raw format
    }

    func testFormatDateString_slashFormat_formats() {
        let result = DateFormattingHelpers.formatDateString("2024/06/20")
        XCTAssertFalse(result.contains("/"))  // Should not be raw format
    }

    func testFormatDateString_yearOnly_returnsAsIs() {
        let result = DateFormattingHelpers.formatDateString("2024")
        XCTAssertEqual(result, "2024")
    }

    func testFormatDateString_invalidFormat_returnsAsIs() {
        let result = DateFormattingHelpers.formatDateString("not a date")
        XCTAssertEqual(result, "not a date")
    }

    // MARK: - extractLicenseType Tests

    func testExtractLicenseType_publicDomain() {
        let result = DateFormattingHelpers.extractLicenseType(
            from: "https://creativecommons.org/publicdomain/mark/1.0/"
        )
        XCTAssertEqual(result, "Public Domain")
    }

    func testExtractLicenseType_ccBy() {
        let result = DateFormattingHelpers.extractLicenseType(
            from: "https://creativecommons.org/licenses/by/4.0/"
        )
        XCTAssertEqual(result, "CC BY")
    }

    func testExtractLicenseType_ccBySa() {
        let result = DateFormattingHelpers.extractLicenseType(
            from: "https://creativecommons.org/licenses/by-sa/4.0/"
        )
        XCTAssertEqual(result, "CC BY-SA")
    }

    func testExtractLicenseType_ccByNc() {
        let result = DateFormattingHelpers.extractLicenseType(
            from: "https://creativecommons.org/licenses/by-nc/4.0/"
        )
        XCTAssertEqual(result, "CC BY-NC")
    }

    func testExtractLicenseType_ccByNcSa() {
        let result = DateFormattingHelpers.extractLicenseType(
            from: "https://creativecommons.org/licenses/by-nc-sa/4.0/"
        )
        XCTAssertEqual(result, "CC BY-NC-SA")
    }

    func testExtractLicenseType_ccByNd() {
        let result = DateFormattingHelpers.extractLicenseType(
            from: "https://creativecommons.org/licenses/by-nd/4.0/"
        )
        XCTAssertEqual(result, "CC BY-ND")
    }

    func testExtractLicenseType_ccByNcNd() {
        let result = DateFormattingHelpers.extractLicenseType(
            from: "https://creativecommons.org/licenses/by-nc-nd/4.0/"
        )
        XCTAssertEqual(result, "CC BY-NC-ND")
    }

    func testExtractLicenseType_cc0() {
        let result = DateFormattingHelpers.extractLicenseType(
            from: "https://creativecommons.org/publicdomain/zero/1.0/"
        )
        XCTAssertEqual(result, "CC0")
    }

    func testExtractLicenseType_genericCC() {
        let result = DateFormattingHelpers.extractLicenseType(
            from: "https://creativecommons.org/licenses/unknown/4.0/"
        )
        XCTAssertEqual(result, "Creative Commons")
    }

    func testExtractLicenseType_unknownLicense() {
        let result = DateFormattingHelpers.extractLicenseType(
            from: "https://example.com/some-license"
        )
        XCTAssertEqual(result, "See License")
    }

    func testExtractLicenseType_caseInsensitive() {
        let result = DateFormattingHelpers.extractLicenseType(
            from: "HTTPS://CREATIVECOMMONS.ORG/LICENSES/BY/4.0/"
        )
        XCTAssertEqual(result, "CC BY")
    }
}

// MARK: - IAURLHelpers Tests

final class IAURLHelpersTests: XCTestCase {

    func testThumbnailURL_validIdentifier_buildsCorrectURL() {
        let url = IAURLHelpers.thumbnailURL(for: "test-item-123")

        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://archive.org/services/img/test-item-123")
    }

    func testThumbnailURL_identifierWithUnderscore_buildsCorrectURL() {
        let url = IAURLHelpers.thumbnailURL(for: "test_item_456")

        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://archive.org/services/img/test_item_456")
    }

    func testDownloadURL_simpleFilename_buildsCorrectURL() {
        let url = IAURLHelpers.downloadURL(identifier: "my-item", filename: "video.mp4")

        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://archive.org/download/my-item/video.mp4")
    }

    func testDownloadURL_filenameWithSpaces_encodesSpaces() {
        let url = IAURLHelpers.downloadURL(identifier: "my-item", filename: "my video.mp4")

        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("%20"))
    }

    func testDownloadURL_filenameWithSpecialChars_encodes() {
        let url = IAURLHelpers.downloadURL(identifier: "item", filename: "file?name#test.mp4")

        XCTAssertNotNil(url)
        // ? and # should be encoded
        XCTAssertTrue(url!.absoluteString.contains("%3F"))  // encoded ?
        XCTAssertTrue(url!.absoluteString.contains("%23"))  // encoded #
    }

    func testDownloadURL_identifierWithSpaces_encodesSpaces() {
        let url = IAURLHelpers.downloadURL(identifier: "my item", filename: "video.mp4")

        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("%20"))
    }

    func testDownloadURL_preservesSafeChars() {
        let url = IAURLHelpers.downloadURL(identifier: "my-item_123", filename: "video-1_final.mp4")

        XCTAssertNotNil(url)
        // Hyphens, underscores, dots should not be encoded
        XCTAssertTrue(url!.absoluteString.contains("-"))
        XCTAssertTrue(url!.absoluteString.contains("_"))
        XCTAssertTrue(url!.absoluteString.contains("."))
    }
}

// MARK: - PlayableFileHelpers Tests

final class PlayableFileHelpersTests: XCTestCase {

    // MARK: - Video Tests

    func testIsPlayableVideo_mp4_returnsTrue() {
        XCTAssertTrue(PlayableFileHelpers.isPlayableVideo("movie.mp4"))
    }

    func testIsPlayableVideo_mov_returnsTrue() {
        XCTAssertTrue(PlayableFileHelpers.isPlayableVideo("movie.mov"))
    }

    func testIsPlayableVideo_m4v_returnsTrue() {
        XCTAssertTrue(PlayableFileHelpers.isPlayableVideo("movie.m4v"))
    }

    func testIsPlayableVideo_uppercaseMP4_returnsTrue() {
        XCTAssertTrue(PlayableFileHelpers.isPlayableVideo("MOVIE.MP4"))
    }

    func testIsPlayableVideo_avi_returnsFalse() {
        XCTAssertFalse(PlayableFileHelpers.isPlayableVideo("movie.avi"))
    }

    func testIsPlayableVideo_mkv_returnsFalse() {
        XCTAssertFalse(PlayableFileHelpers.isPlayableVideo("movie.mkv"))
    }

    func testIsPlayableVideo_webm_returnsFalse() {
        XCTAssertFalse(PlayableFileHelpers.isPlayableVideo("movie.webm"))
    }

    // MARK: - Audio Tests

    func testIsPlayableAudio_mp3_returnsTrue() {
        XCTAssertTrue(PlayableFileHelpers.isPlayableAudio("track.mp3"))
    }

    func testIsPlayableAudio_m4a_returnsTrue() {
        XCTAssertTrue(PlayableFileHelpers.isPlayableAudio("track.m4a"))
    }

    func testIsPlayableAudio_aac_returnsTrue() {
        XCTAssertTrue(PlayableFileHelpers.isPlayableAudio("track.aac"))
    }

    func testIsPlayableAudio_uppercaseMP3_returnsTrue() {
        XCTAssertTrue(PlayableFileHelpers.isPlayableAudio("TRACK.MP3"))
    }

    func testIsPlayableAudio_flac_returnsFalse() {
        XCTAssertFalse(PlayableFileHelpers.isPlayableAudio("track.flac"))
    }

    func testIsPlayableAudio_ogg_returnsFalse() {
        XCTAssertFalse(PlayableFileHelpers.isPlayableAudio("track.ogg"))
    }

    func testIsPlayableAudio_wav_returnsFalse() {
        XCTAssertFalse(PlayableFileHelpers.isPlayableAudio("track.wav"))
    }

    // MARK: - Filter Tests

    func testFilterPlayableVideos_mixedFiles_returnsOnlyVideos() {
        let files = [
            FileInfo(name: "movie.mp4", source: "original", format: "MPEG4"),
            FileInfo(name: "movie.mov", source: "original", format: "QuickTime"),
            FileInfo(name: "movie.avi", source: "original", format: "AVI"),
            FileInfo(name: "track.mp3", source: "original", format: "MP3")
        ]

        let result = PlayableFileHelpers.filterPlayableVideos(files)

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.name.hasSuffix(".mp4") || $0.name.hasSuffix(".mov") })
    }

    func testFilterPlayableAudio_mixedFiles_returnsOnlyAudio() {
        let files = [
            FileInfo(name: "movie.mp4", source: "original", format: "MPEG4"),
            FileInfo(name: "track.mp3", source: "original", format: "MP3"),
            FileInfo(name: "track.m4a", source: "original", format: "AAC"),
            FileInfo(name: "track.flac", source: "original", format: "FLAC")
        ]

        let result = PlayableFileHelpers.filterPlayableAudio(files)

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.name.hasSuffix(".mp3") || $0.name.hasSuffix(".m4a") })
    }

    func testFilterPlayableVideos_noPlayable_returnsEmpty() {
        let files = [
            FileInfo(name: "movie.avi", source: "original", format: "AVI"),
            FileInfo(name: "movie.mkv", source: "original", format: "Matroska")
        ]

        let result = PlayableFileHelpers.filterPlayableVideos(files)

        XCTAssertTrue(result.isEmpty)
    }

    func testFilterPlayableAudio_noPlayable_returnsEmpty() {
        let files = [
            FileInfo(name: "track.flac", source: "original", format: "FLAC"),
            FileInfo(name: "track.ogg", source: "original", format: "Vorbis")
        ]

        let result = PlayableFileHelpers.filterPlayableAudio(files)

        XCTAssertTrue(result.isEmpty)
    }
}
