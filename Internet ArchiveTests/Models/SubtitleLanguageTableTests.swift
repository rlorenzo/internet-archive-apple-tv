//
//  SubtitleLanguageTableTests.swift
//  Internet ArchiveTests
//
//  Guards the SubtitleLanguage lookup table: a dictionary has no
//  compile-time exhaustiveness check, so every case must be verified here.
//

import Testing
@testable import Internet_Archive

struct SubtitleLanguageTableTests {

    @Test(arguments: SubtitleLanguage.allCases)
    func everyLanguageHasADisplayName(_ language: SubtitleLanguage) {
        // The fallback is the raw code; a real entry is always a full name.
        #expect(language.displayName != language.rawValue)
        #expect(language.displayName.first?.isUppercase == true)
    }

    @Test(arguments: SubtitleLanguage.allCases)
    func everyLanguageHasFilenameVariations(_ language: SubtitleLanguage) {
        let variations = language.filenameVariations
        // The fallback is just [rawValue]; real entries list several spellings.
        #expect(variations.count > 1)
        #expect(variations.contains(language.rawValue))
        #expect(variations.allSatisfy { $0 == $0.lowercased() })
    }

    @Test(arguments: SubtitleLanguage.allCases)
    func fromFilenameRoundTrips(_ language: SubtitleLanguage) {
        #expect(SubtitleLanguage.fromFilename(language.displayName) == language)
    }
}
