//
//  SubtitleSelectionViewControllerTests.swift
//  Internet ArchiveTests
//
//  Unit tests for SubtitleSelectionViewController and related subtitle models
//

import XCTest
@testable import Internet_Archive

@MainActor
final class SubtitleSelectionViewControllerTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeSubtitleTrack(
        filename: String = "subtitles.vtt",
        format: SubtitleFormat = .vtt,
        languageCode: String? = "en",
        languageDisplayName: String = "English",
        isDefault: Bool = false
    ) -> SubtitleTrack {
        let encodedFilename = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filename
        guard let url = URL(string: "https://archive.org/download/test/\(encodedFilename)") else {
            XCTFail("Failed to create test URL for subtitle track: \(filename)")
            fatalError("Invalid test URL")
        }
        return SubtitleTrack(
            filename: filename,
            format: format,
            languageCode: languageCode,
            languageDisplayName: languageDisplayName,
            isDefault: isDefault,
            url: url
        )
    }

    // MARK: - Initialization Tests

    func testSubtitleSelectionViewController_initWithTracks() {
        let tracks = [
            makeSubtitleTrack(languageCode: "en", languageDisplayName: "English"),
            makeSubtitleTrack(languageCode: "es", languageDisplayName: "Spanish")
        ]

        let viewController = SubtitleSelectionViewController(tracks: tracks, selectedTrack: nil)

        XCTAssertNotNil(viewController)
    }

    func testSubtitleSelectionViewController_initWithSelectedTrack() {
        let track = makeSubtitleTrack()
        let viewController = SubtitleSelectionViewController(tracks: [track], selectedTrack: track)

        XCTAssertNotNil(viewController)
    }

    func testSubtitleSelectionViewController_initWithEmptyTracks() {
        let viewController = SubtitleSelectionViewController(tracks: [], selectedTrack: nil)

        XCTAssertNotNil(viewController)
    }

    func testSubtitleSelectionViewController_initWithManyTracks() {
        var tracks: [SubtitleTrack] = []
        for index in 1...20 {
            tracks.append(makeSubtitleTrack(
                filename: "subtitle\(index).vtt",
                languageCode: "lang\(index)",
                languageDisplayName: "Language \(index)"
            ))
        }

        let viewController = SubtitleSelectionViewController(tracks: tracks, selectedTrack: nil)

        XCTAssertNotNil(viewController)
    }

    // MARK: - Modal Presentation Tests

    func testSubtitleSelectionViewController_modalPresentationStyle() {
        let viewController = SubtitleSelectionViewController(tracks: [], selectedTrack: nil)

        XCTAssertEqual(viewController.modalPresentationStyle, .overCurrentContext)
    }

    func testSubtitleSelectionViewController_modalTransitionStyle() {
        let viewController = SubtitleSelectionViewController(tracks: [], selectedTrack: nil)

        XCTAssertEqual(viewController.modalTransitionStyle, .crossDissolve)
    }

    // MARK: - View Lifecycle Tests

    func testSubtitleSelectionViewController_viewDidLoadSetsBackgroundColor() {
        let viewController = SubtitleSelectionViewController(tracks: [], selectedTrack: nil)

        viewController.loadViewIfNeeded()

        XCTAssertEqual(viewController.view.backgroundColor, UIColor.black.withAlphaComponent(0.5))
    }

    func testSubtitleSelectionViewController_viewIsModal() {
        let viewController = SubtitleSelectionViewController(tracks: [], selectedTrack: nil)

        viewController.loadViewIfNeeded()

        XCTAssertTrue(viewController.view.accessibilityViewIsModal)
    }

    // MARK: - TableView DataSource Tests

    func testSubtitleSelectionViewController_numberOfSections() {
        let tracks = [makeSubtitleTrack()]
        let viewController = SubtitleSelectionViewController(tracks: tracks, selectedTrack: nil)
        viewController.loadViewIfNeeded()

        let sections = viewController.numberOfSections(in: UITableView())

        XCTAssertEqual(sections, 1)
    }

    func testSubtitleSelectionViewController_numberOfRowsWithOffOption() {
        let tracks = [
            makeSubtitleTrack(languageCode: "en"),
            makeSubtitleTrack(languageCode: "es")
        ]
        let viewController = SubtitleSelectionViewController(tracks: tracks, selectedTrack: nil)
        viewController.loadViewIfNeeded()

        let rows = viewController.tableView(UITableView(), numberOfRowsInSection: 0)

        XCTAssertEqual(rows, 3)
    }

    func testSubtitleSelectionViewController_numberOfRowsWithEmptyTracks() {
        let viewController = SubtitleSelectionViewController(tracks: [], selectedTrack: nil)
        viewController.loadViewIfNeeded()

        let rows = viewController.tableView(UITableView(), numberOfRowsInSection: 0)

        XCTAssertEqual(rows, 1)
    }

    // MARK: - Focus Tests

    func testSubtitleSelectionViewController_preferredFocusEnvironmentsNotEmpty() {
        let viewController = SubtitleSelectionViewController(tracks: [], selectedTrack: nil)
        viewController.loadViewIfNeeded()

        XCTAssertFalse(viewController.preferredFocusEnvironments.isEmpty)
    }

    // MARK: - Delegate Tests

    func testSubtitleSelectionViewController_delegateCanBeSet() {
        class MockDelegate: SubtitleSelectionDelegate {
            var selectedTrack: SubtitleTrack?
            var didTurnOff = false

            func subtitleSelection(_ controller: SubtitleSelectionViewController, didSelect track: SubtitleTrack) {
                selectedTrack = track
            }

            func subtitleSelectionDidTurnOff(_ controller: SubtitleSelectionViewController) {
                didTurnOff = true
            }
        }

        let viewController = SubtitleSelectionViewController(tracks: [], selectedTrack: nil)
        let delegate = MockDelegate()

        viewController.delegate = delegate

        XCTAssertNotNil(viewController.delegate)
    }

    // MARK: - Edge Cases

    func testSubtitleSelectionViewController_trackWithNilLanguageCode() {
        let track = makeSubtitleTrack(languageCode: nil, languageDisplayName: "Unknown")
        let viewController = SubtitleSelectionViewController(tracks: [track], selectedTrack: nil)

        viewController.loadViewIfNeeded()

        XCTAssertNotNil(viewController)
    }

    func testSubtitleSelectionViewController_trackWithEmptyLanguageDisplayName() {
        let track = makeSubtitleTrack(languageDisplayName: "")
        let viewController = SubtitleSelectionViewController(tracks: [track], selectedTrack: nil)

        viewController.loadViewIfNeeded()

        XCTAssertNotNil(viewController)
    }

    func testSubtitleSelectionViewController_unicodeLanguageDisplayName() {
        let track = makeSubtitleTrack(languageCode: "ja", languageDisplayName: "日本語")
        let viewController = SubtitleSelectionViewController(tracks: [track], selectedTrack: nil)

        viewController.loadViewIfNeeded()

        XCTAssertNotNil(viewController)
    }
}

// MARK: - SubtitleTrack Tests

@MainActor
final class SubtitleTrackTests: XCTestCase {

    // MARK: - Initialization

    func testSubtitleTrack_init() {
        let track = SubtitleTrack(
            filename: "subtitles.vtt",
            format: .vtt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/subtitles.vtt")!
        )

        XCTAssertEqual(track.filename, "subtitles.vtt")
        XCTAssertEqual(track.format, .vtt)
        XCTAssertEqual(track.languageCode, "en")
        XCTAssertEqual(track.languageDisplayName, "English")
        XCTAssertFalse(track.isDefault)
    }

    // MARK: - Identifier Tests

    func testSubtitleTrack_identifier() {
        let track = SubtitleTrack(
            filename: "subtitles.vtt",
            format: .vtt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/subtitles.vtt")!
        )

        XCTAssertEqual(track.identifier, "subtitles.vtt_en")
    }

    func testSubtitleTrack_identifierWithNilLanguageCode() {
        let track = SubtitleTrack(
            filename: "subtitles.vtt",
            format: .vtt,
            languageCode: nil,
            languageDisplayName: "Unknown",
            isDefault: false,
            url: URL(string: "https://example.com/subtitles.vtt")!
        )

        XCTAssertEqual(track.identifier, "subtitles.vtt_unknown")
    }

    // MARK: - Equality Tests

    func testSubtitleTrack_equality() {
        let track1 = SubtitleTrack(
            filename: "subtitles.vtt",
            format: .vtt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/subtitles.vtt")!
        )

        let track2 = SubtitleTrack(
            filename: "subtitles.vtt",
            format: .vtt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/subtitles.vtt")!
        )

        XCTAssertEqual(track1, track2)
    }

    func testSubtitleTrack_inequality_differentFilename() {
        let track1 = SubtitleTrack(
            filename: "subtitles1.vtt",
            format: .vtt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/subtitles1.vtt")!
        )

        let track2 = SubtitleTrack(
            filename: "subtitles2.vtt",
            format: .vtt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/subtitles2.vtt")!
        )

        XCTAssertNotEqual(track1, track2)
    }

    // MARK: - Hashable Tests

    func testSubtitleTrack_hashable() {
        let track1 = SubtitleTrack(
            filename: "subtitles.vtt",
            format: .vtt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/subtitles.vtt")!
        )

        let track2 = SubtitleTrack(
            filename: "subtitles.vtt",
            format: .vtt,
            languageCode: "en",
            languageDisplayName: "English",
            isDefault: false,
            url: URL(string: "https://example.com/subtitles.vtt")!
        )

        var set: Set<SubtitleTrack> = []
        set.insert(track1)
        set.insert(track2)

        XCTAssertEqual(set.count, 1)
    }
}

// MARK: - SubtitleFormat Tests

@MainActor
final class SubtitleFormatTests: XCTestCase {

    // MARK: - File Extension Tests

    func testSubtitleFormat_srtExtension() {
        XCTAssertEqual(SubtitleFormat.srt.fileExtension, ".srt")
    }

    func testSubtitleFormat_vttExtension() {
        XCTAssertEqual(SubtitleFormat.vtt.fileExtension, ".vtt")
    }

    func testSubtitleFormat_webvttExtension() {
        XCTAssertEqual(SubtitleFormat.webvtt.fileExtension, ".webvtt")
    }

    // MARK: - Native Support Tests

    func testSubtitleFormat_srtNotNativelySupported() {
        XCTAssertFalse(SubtitleFormat.srt.isNativelySupported)
    }

    func testSubtitleFormat_vttNativelySupported() {
        XCTAssertTrue(SubtitleFormat.vtt.isNativelySupported)
    }

    func testSubtitleFormat_webvttNativelySupported() {
        XCTAssertTrue(SubtitleFormat.webvtt.isNativelySupported)
    }

    // MARK: - Filename Initialization Tests

    func testSubtitleFormat_initFromSrtFilename() {
        let format = SubtitleFormat(filename: "subtitles.srt")

        XCTAssertEqual(format, .srt)
    }

    func testSubtitleFormat_initFromVttFilename() {
        let format = SubtitleFormat(filename: "subtitles.vtt")

        XCTAssertEqual(format, .vtt)
    }

    func testSubtitleFormat_initFromWebvttFilename() {
        let format = SubtitleFormat(filename: "subtitles.webvtt")

        XCTAssertEqual(format, .webvtt)
    }

    func testSubtitleFormat_initFromUppercaseFilename() {
        let format = SubtitleFormat(filename: "SUBTITLES.SRT")

        XCTAssertEqual(format, .srt)
    }

    func testSubtitleFormat_initFromMixedCaseFilename() {
        let format = SubtitleFormat(filename: "Subtitles.VtT")

        XCTAssertEqual(format, .vtt)
    }

    func testSubtitleFormat_initFromInvalidFilename() {
        let format = SubtitleFormat(filename: "subtitles.txt")

        XCTAssertNil(format)
    }

    func testSubtitleFormat_initFromFilenameWithoutExtension() {
        let format = SubtitleFormat(filename: "subtitles")

        XCTAssertNil(format)
    }

    func testSubtitleFormat_initFromFilenameWithPath() {
        let format = SubtitleFormat(filename: "/path/to/subtitles.srt")

        XCTAssertEqual(format, .srt)
    }

    // MARK: - All Cases Tests

    func testSubtitleFormat_allCases() {
        XCTAssertEqual(SubtitleFormat.allCases.count, 3)
        XCTAssertTrue(SubtitleFormat.allCases.contains(.srt))
        XCTAssertTrue(SubtitleFormat.allCases.contains(.vtt))
        XCTAssertTrue(SubtitleFormat.allCases.contains(.webvtt))
    }
}

// MARK: - SubtitleLanguage Tests

@MainActor
final class SubtitleLanguageTests: XCTestCase {

    // MARK: - Display Name Tests

    func testSubtitleLanguage_englishDisplayName() {
        XCTAssertEqual(SubtitleLanguage.english.displayName, "English")
    }

    func testSubtitleLanguage_spanishDisplayName() {
        XCTAssertEqual(SubtitleLanguage.spanish.displayName, "Spanish")
    }

    func testSubtitleLanguage_japaneseDisplayName() {
        XCTAssertEqual(SubtitleLanguage.japanese.displayName, "Japanese")
    }

    func testSubtitleLanguage_chineseDisplayName() {
        XCTAssertEqual(SubtitleLanguage.chinese.displayName, "Chinese")
    }

    // MARK: - Raw Value Tests

    func testSubtitleLanguage_englishRawValue() {
        XCTAssertEqual(SubtitleLanguage.english.rawValue, "en")
    }

    func testSubtitleLanguage_spanishRawValue() {
        XCTAssertEqual(SubtitleLanguage.spanish.rawValue, "es")
    }

    func testSubtitleLanguage_frenchRawValue() {
        XCTAssertEqual(SubtitleLanguage.french.rawValue, "fr")
    }

    // MARK: - Filename Variations Tests

    func testSubtitleLanguage_englishFilenameVariations() {
        let variations = SubtitleLanguage.english.filenameVariations

        XCTAssertTrue(variations.contains("english"))
        XCTAssertTrue(variations.contains("eng"))
        XCTAssertTrue(variations.contains("en"))
        XCTAssertTrue(variations.contains("en-us"))
        XCTAssertTrue(variations.contains("en-gb"))
    }

    func testSubtitleLanguage_spanishFilenameVariations() {
        let variations = SubtitleLanguage.spanish.filenameVariations

        XCTAssertTrue(variations.contains("spanish"))
        XCTAssertTrue(variations.contains("español"))
        XCTAssertTrue(variations.contains("espanol"))
        XCTAssertTrue(variations.contains("spa"))
        XCTAssertTrue(variations.contains("es"))
    }

    // MARK: - From Filename Tests

    func testSubtitleLanguage_fromFilename_english() {
        XCTAssertEqual(SubtitleLanguage.fromFilename("english"), .english)
        XCTAssertEqual(SubtitleLanguage.fromFilename("eng"), .english)
        XCTAssertEqual(SubtitleLanguage.fromFilename("en"), .english)
        XCTAssertEqual(SubtitleLanguage.fromFilename("EN"), .english)
        XCTAssertEqual(SubtitleLanguage.fromFilename("English"), .english)
    }

    func testSubtitleLanguage_fromFilename_spanish() {
        XCTAssertEqual(SubtitleLanguage.fromFilename("spanish"), .spanish)
        XCTAssertEqual(SubtitleLanguage.fromFilename("es"), .spanish)
        XCTAssertEqual(SubtitleLanguage.fromFilename("español"), .spanish)
    }

    func testSubtitleLanguage_fromFilename_unknown() {
        XCTAssertNil(SubtitleLanguage.fromFilename("unknown"))
        XCTAssertNil(SubtitleLanguage.fromFilename("xyz"))
        XCTAssertNil(SubtitleLanguage.fromFilename(""))
    }

    // MARK: - All Cases Tests

    func testSubtitleLanguage_allCasesCount() {
        XCTAssertEqual(SubtitleLanguage.allCases.count, 28)
    }

    func testSubtitleLanguage_containsCommonLanguages() {
        XCTAssertTrue(SubtitleLanguage.allCases.contains(.english))
        XCTAssertTrue(SubtitleLanguage.allCases.contains(.spanish))
        XCTAssertTrue(SubtitleLanguage.allCases.contains(.french))
        XCTAssertTrue(SubtitleLanguage.allCases.contains(.german))
        XCTAssertTrue(SubtitleLanguage.allCases.contains(.japanese))
        XCTAssertTrue(SubtitleLanguage.allCases.contains(.chinese))
    }
}

// MARK: - SubtitlePreferences Tests

@MainActor
final class SubtitlePreferencesTests: XCTestCase {

    func testSubtitlePreferences_defaultValues() {
        let preferences = SubtitlePreferences.default

        XCTAssertFalse(preferences.subtitlesEnabled)
        XCTAssertNil(preferences.preferredLanguageCode)
    }

    func testSubtitlePreferences_customValues() {
        let preferences = SubtitlePreferences(
            subtitlesEnabled: true,
            preferredLanguageCode: "en"
        )

        XCTAssertTrue(preferences.subtitlesEnabled)
        XCTAssertEqual(preferences.preferredLanguageCode, "en")
    }

    func testSubtitlePreferences_codable() throws {
        let original = SubtitlePreferences(
            subtitlesEnabled: true,
            preferredLanguageCode: "es"
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SubtitlePreferences.self, from: encoded)

        XCTAssertEqual(original.subtitlesEnabled, decoded.subtitlesEnabled)
        XCTAssertEqual(original.preferredLanguageCode, decoded.preferredLanguageCode)
    }
}

// MARK: - SubtitleTrackCell Tests

@MainActor
final class SubtitleTrackCellTests: XCTestCase {

    func testSubtitleTrackCell_reuseIdentifier() {
        XCTAssertEqual(SubtitleTrackCell.reuseIdentifier, "SubtitleTrackCell")
    }

    func testSubtitleTrackCell_init() {
        let cell = SubtitleTrackCell(style: .default, reuseIdentifier: SubtitleTrackCell.reuseIdentifier)

        XCTAssertNotNil(cell)
        XCTAssertEqual(cell.backgroundColor, .clear)
    }

    func testSubtitleTrackCell_configureWithTitle() {
        let cell = SubtitleTrackCell(style: .default, reuseIdentifier: SubtitleTrackCell.reuseIdentifier)

        cell.configure(
            title: "English",
            subtitle: "VTT",
            isSelected: false,
            accessibilityHint: "Select English subtitles"
        )

        XCTAssertEqual(cell.accessibilityLabel, "English")
        XCTAssertNil(cell.accessibilityValue)
        XCTAssertEqual(cell.accessibilityHint, "Select English subtitles")
    }

    func testSubtitleTrackCell_configureAsSelected() {
        let cell = SubtitleTrackCell(style: .default, reuseIdentifier: SubtitleTrackCell.reuseIdentifier)

        cell.configure(
            title: "English",
            subtitle: "VTT",
            isSelected: true,
            accessibilityHint: "Selected"
        )

        XCTAssertEqual(cell.accessibilityValue, "Selected")
        XCTAssertTrue(cell.accessibilityTraits.contains(.selected))
    }

    func testSubtitleTrackCell_configureWithNilSubtitle() {
        let cell = SubtitleTrackCell(style: .default, reuseIdentifier: SubtitleTrackCell.reuseIdentifier)

        cell.configure(
            title: "Off",
            subtitle: nil,
            isSelected: true,
            accessibilityHint: "Turn off subtitles"
        )

        XCTAssertEqual(cell.accessibilityLabel, "Off")
    }

    func testSubtitleTrackCell_accessibilityTraits_notSelected() {
        let cell = SubtitleTrackCell(style: .default, reuseIdentifier: SubtitleTrackCell.reuseIdentifier)

        cell.configure(
            title: "English",
            subtitle: nil,
            isSelected: false,
            accessibilityHint: "Select"
        )

        XCTAssertTrue(cell.accessibilityTraits.contains(.button))
        XCTAssertFalse(cell.accessibilityTraits.contains(.selected))
    }
}
