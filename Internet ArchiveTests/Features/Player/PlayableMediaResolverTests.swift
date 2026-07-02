//
//  PlayableMediaResolverTests.swift
//  Internet ArchiveTests
//
//  Tests for PlayableMediaResolver covering logic not already exercised
//  by the fromMetadata factory tests: the originals-vs-derivatives audio
//  preference and track-number ordering of the resolved queue.
//

import Testing
import Foundation
@testable import Internet_Archive

@Suite("PlayableMediaResolver Tests")
struct PlayableMediaResolverTests {

    // MARK: - Originals vs Derivatives

    @Test("Prefers original audio files over derivatives")
    func audioQueue_prefersOriginalsOverDerivatives() {
        let item = TestFixtures.makeSearchResult(identifier: "album", title: "Album")
        let files = [
            FileInfo(name: "track01.flac", source: "original", format: "Flac"),
            FileInfo(name: "track01.mp3", source: "derivative", format: "VBR MP3"),
            FileInfo(name: "track01.ogg", source: "derivative", format: "Ogg Vorbis")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let queue = PlayableMediaResolver.resolveAudioQueue(item: item, metadata: metadata)

        #expect(queue?.tracks.count == 1)
        #expect(queue?.tracks.first?.filename == "track01.flac")
    }

    @Test("Falls back to derivative audio when no originals exist")
    func audioQueue_fallsBackToDerivatives() {
        let item = TestFixtures.makeSearchResult(identifier: "album", title: "Album")
        let files = [
            FileInfo(name: "track01.mp3", source: "derivative", format: "VBR MP3"),
            FileInfo(name: "track02.mp3", source: "derivative", format: "VBR MP3")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let queue = PlayableMediaResolver.resolveAudioQueue(item: item, metadata: metadata)

        #expect(queue?.tracks.count == 2)
    }

    // MARK: - Track Ordering

    @Test("Sorts resolved tracks by track number")
    func audioQueue_sortsTracksByTrackNumber() {
        let item = TestFixtures.makeSearchResult(identifier: "album", title: "Album")
        let files = [
            FileInfo(name: "closer.mp3", source: "original", format: "MP3", track: "3"),
            FileInfo(name: "opener.mp3", source: "original", format: "MP3", track: "1"),
            FileInfo(name: "middle.mp3", source: "original", format: "MP3", track: "2")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let queue = PlayableMediaResolver.resolveAudioQueue(item: item, metadata: metadata)

        #expect(queue?.tracks.map(\.filename) == ["opener.mp3", "middle.mp3", "closer.mp3"])
    }

    // MARK: - Defaults

    @Test("Starts at first track with no resume time when no saved progress")
    func audioQueue_defaultStartWithoutProgress() {
        let item = TestFixtures.makeSearchResult(identifier: "album", title: "Album")
        let files = [
            FileInfo(name: "track01.mp3", source: "original", format: "MP3"),
            FileInfo(name: "track02.mp3", source: "original", format: "MP3")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let queue = PlayableMediaResolver.resolveAudioQueue(item: item, metadata: metadata)

        #expect(queue?.startIndex == 0)
        #expect(queue?.resumeTime == nil)
    }
}
