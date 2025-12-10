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
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .italian: return "Italian"
        case .portuguese: return "Portuguese"
        case .russian: return "Russian"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .chinese: return "Chinese"
        case .arabic: return "Arabic"
        case .hindi: return "Hindi"
        case .dutch: return "Dutch"
        case .polish: return "Polish"
        case .swedish: return "Swedish"
        case .norwegian: return "Norwegian"
        case .danish: return "Danish"
        case .finnish: return "Finnish"
        case .turkish: return "Turkish"
        case .greek: return "Greek"
        case .hebrew: return "Hebrew"
        case .thai: return "Thai"
        case .vietnamese: return "Vietnamese"
        case .indonesian: return "Indonesian"
        case .czech: return "Czech"
        case .hungarian: return "Hungarian"
        case .romanian: return "Romanian"
        case .ukrainian: return "Ukrainian"
        }
    }

    /// Common variations of language names found in filenames
    var filenameVariations: [String] {
        switch self {
        case .english: return ["english", "eng", "en", "en-us", "en-gb", "en_us", "en_gb"]
        case .spanish: return ["spanish", "español", "espanol", "spa", "es", "es-es", "es-mx", "es_es"]
        case .french: return ["french", "français", "francais", "fra", "fre", "fr", "fr-fr"]
        case .german: return ["german", "deutsch", "ger", "deu", "de", "de-de"]
        case .italian: return ["italian", "italiano", "ita", "it", "it-it"]
        case .portuguese: return ["portuguese", "português", "portugues", "por", "pt", "pt-br", "pt-pt"]
        case .russian: return ["russian", "русский", "rus", "ru"]
        case .japanese: return ["japanese", "日本語", "jpn", "ja", "jp"]
        case .korean: return ["korean", "한국어", "kor", "ko", "kr"]
        case .chinese: return ["chinese", "中文", "chi", "zho", "zh", "zh-cn", "zh-tw", "mandarin", "cantonese"]
        case .arabic: return ["arabic", "العربية", "ara", "ar"]
        case .hindi: return ["hindi", "हिन्दी", "hin", "hi"]
        case .dutch: return ["dutch", "nederlands", "nld", "dut", "nl"]
        case .polish: return ["polish", "polski", "pol", "pl"]
        case .swedish: return ["swedish", "svenska", "swe", "sv"]
        case .norwegian: return ["norwegian", "norsk", "nor", "no", "nb", "nn"]
        case .danish: return ["danish", "dansk", "dan", "da"]
        case .finnish: return ["finnish", "suomi", "fin", "fi"]
        case .turkish: return ["turkish", "türkçe", "turkce", "tur", "tr"]
        case .greek: return ["greek", "ελληνικά", "gre", "ell", "el"]
        case .hebrew: return ["hebrew", "עברית", "heb", "he", "iw"]
        case .thai: return ["thai", "ไทย", "tha", "th"]
        case .vietnamese: return ["vietnamese", "tiếng việt", "vie", "vi"]
        case .indonesian: return ["indonesian", "bahasa indonesia", "ind", "id"]
        case .czech: return ["czech", "čeština", "ces", "cze", "cs"]
        case .hungarian: return ["hungarian", "magyar", "hun", "hu"]
        case .romanian: return ["romanian", "română", "ron", "rum", "ro"]
        case .ukrainian: return ["ukrainian", "українська", "ukr", "uk"]
        }
    }

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
