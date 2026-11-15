//
//  SubtitleModels.swift
//  Internet Archive
//
//  Type-safe models for subtitle/closed caption support
//

import Foundation

/// Represents a subtitle track with language and URL information
struct SubtitleTrack: Sendable, Equatable, Hashable {
    /// The original filename of the subtitle file
    let filename: String

    /// The format of the subtitle file (.srt or .vtt)
    let format: SubtitleFormat

    /// The language code (e.g., "en", "es", "fr") if detected
    let languageCode: String?

    /// Human-readable language name (e.g., "English", "Spanish")
    let languageDisplayName: String

    /// Whether this is the default/primary subtitle track
    let isDefault: Bool

    /// The full URL to download the subtitle file
    let url: URL

    /// Unique identifier combining filename and language for deduplication
    var identifier: String {
        "\(filename)_\(languageCode ?? "unknown")"
    }
}

/// Supported subtitle file formats
enum SubtitleFormat: String, Sendable, CaseIterable {
    case srt
    case vtt
    case webvtt

    /// File extension including the dot
    var fileExtension: String {
        ".\(rawValue)"
    }

    /// Whether AVPlayer natively supports this format
    var isNativelySupported: Bool {
        switch self {
        case .vtt, .webvtt:
            return true
        case .srt:
            return false
        }
    }

    /// Initialize from a filename
    init?(filename: String) {
        let lowercased = filename.lowercased()
        if lowercased.hasSuffix(".srt") {
            self = .srt
        } else if lowercased.hasSuffix(".vtt") {
            self = .vtt
        } else if lowercased.hasSuffix(".webvtt") {
            self = .webvtt
        } else {
            return nil
        }
    }
}

/// Common language codes and their display names
enum SubtitleLanguage: String, CaseIterable, Sendable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case japanese = "ja"
    case korean = "ko"
    case chinese = "zh"
    case arabic = "ar"
    case hindi = "hi"
    case dutch = "nl"
    case polish = "pl"
    case swedish = "sv"
    case norwegian = "no"
    case danish = "da"
    case finnish = "fi"
    case turkish = "tr"
    case greek = "el"
    case hebrew = "he"
    case thai = "th"
    case vietnamese = "vi"
    case indonesian = "id"
    case czech = "cs"
    case hungarian = "hu"
    case romanian = "ro"
    case ukrainian = "uk"

    /// Human-readable display name for the language
    var displayName: String {
        Self.languageInfo[self]?.name ?? rawValue
    }

    /// Common variations of language names found in filenames
    var filenameVariations: [String] {
        Self.languageInfo[self]?.variations ?? [rawValue]
    }

    /// Display name and filename variations per language. A lookup table
    /// rather than two 28-case switches keeps cyclomatic complexity flat;
    /// `SubtitleLanguageTests` asserts every case has an entry.
    private static let languageInfo: [SubtitleLanguage: (name: String, variations: [String])] = [
        .english: ("English", ["english", "eng", "en", "en-us", "en-gb", "en_us", "en_gb"]),
        .spanish: ("Spanish", ["spanish", "español", "espanol", "spa", "es", "es-es", "es-mx", "es_es"]),
        .french: ("French", ["french", "français", "francais", "fra", "fre", "fr", "fr-fr"]),
        .german: ("German", ["german", "deutsch", "ger", "deu", "de", "de-de"]),
        .italian: ("Italian", ["italian", "italiano", "ita", "it", "it-it"]),
        .portuguese: ("Portuguese", ["portuguese", "português", "portugues", "por", "pt", "pt-br", "pt-pt"]),
        .russian: ("Russian", ["russian", "русский", "rus", "ru"]),
        .japanese: ("Japanese", ["japanese", "日本語", "jpn", "ja", "jp"]),
        .korean: ("Korean", ["korean", "한국어", "kor", "ko", "kr"]),
        .chinese: ("Chinese", ["chinese", "中文", "chi", "zho", "zh", "zh-cn", "zh-tw", "mandarin", "cantonese"]),
        .arabic: ("Arabic", ["arabic", "العربية", "ara", "ar"]),
        .hindi: ("Hindi", ["hindi", "हिन्दी", "hin", "hi"]),
        .dutch: ("Dutch", ["dutch", "nederlands", "nld", "dut", "nl"]),
        .polish: ("Polish", ["polish", "polski", "pol", "pl"]),
        .swedish: ("Swedish", ["swedish", "svenska", "swe", "sv"]),
        .norwegian: ("Norwegian", ["norwegian", "norsk", "nor", "no", "nb", "nn"]),
        .danish: ("Danish", ["danish", "dansk", "dan", "da"]),
        .finnish: ("Finnish", ["finnish", "suomi", "fin", "fi"]),
        .turkish: ("Turkish", ["turkish", "türkçe", "turkce", "tur", "tr"]),
        .greek: ("Greek", ["greek", "ελληνικά", "gre", "ell", "el"]),
        .hebrew: ("Hebrew", ["hebrew", "עברית", "heb", "he", "iw"]),
        .thai: ("Thai", ["thai", "ไทย", "tha", "th"]),
        .vietnamese: ("Vietnamese", ["vietnamese", "tiếng việt", "vie", "vi"]),
        .indonesian: ("Indonesian", ["indonesian", "bahasa indonesia", "ind", "id"]),
        .czech: ("Czech", ["czech", "čeština", "ces", "cze", "cs"]),
        .hungarian: ("Hungarian", ["hungarian", "magyar", "hun", "hu"]),
        .romanian: ("Romanian", ["romanian", "română", "ron", "rum", "ro"]),
        .ukrainian: ("Ukrainian", ["ukrainian", "українська", "ukr", "uk"])
    ]

    /// Initialize from a string found in a filename
    static func fromFilename(_ component: String) -> SubtitleLanguage? {
        let lowercased = component.lowercased()
        for language in SubtitleLanguage.allCases where language.filenameVariations.contains(lowercased) {
            return language
        }
        return nil
    }
}

/// User preferences for subtitle display
struct SubtitlePreferences: Codable, Sendable {
    /// Whether subtitles are enabled by default
    var subtitlesEnabled: Bool

    /// Preferred language code (nil means use first available)
    var preferredLanguageCode: String?

    /// Default preferences
    static let `default` = SubtitlePreferences(
        subtitlesEnabled: false,
        preferredLanguageCode: nil
    )
}

// MARK: - FileInfo Extension for Subtitle Detection

extension FileInfo {
    /// Whether this file is a subtitle file
    var isSubtitleFile: Bool {
        SubtitleFormat(filename: name) != nil
    }

    /// The subtitle format if this is a subtitle file
    var subtitleFormat: SubtitleFormat? {
        SubtitleFormat(filename: name)
    }
}
