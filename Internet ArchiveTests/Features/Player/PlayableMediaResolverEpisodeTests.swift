//
//  PlayableMediaResolverEpisodeTests.swift
//  Internet ArchiveTests
//
//  Tests for multi-episode resolution. Fixtures mirror real Internet
//  Archive layouts: Bonanza_pd (MP4 originals + Ogg derivatives) and
//  GreenAcresCompleteSeries (MPEG-1/AVI originals in season folders with
//  h.264 + Ogg derivatives).
//

import Testing
import Foundation
@testable import Internet_Archive

@Suite("PlayableMediaResolver Episode Tests")
struct PlayableMediaResolverEpisodeTests {

    // MARK: - Grouping and Format Choice

    @Test("MP4 originals with Ogg derivatives yield one MP4 episode each")
    func mp4OriginalsWithOggDerivatives() {
        func ogg(_ original: String, _ length: String) -> FileInfo {
            FileInfo(
                name: original.replacingOccurrences(of: ".mp4", with: ".ogv"),
                source: "derivative",
                format: "Ogg Video",
                original: original,
                length: length
            )
        }
        let files = [
            FileInfo(name: "Bonanza s01e20.mp4", source: "original", format: "MPEG4", length: "2894.16"),
            ogg("Bonanza s01e20.mp4", "2894.16"),
            FileInfo(name: "Bonanza s01e19.mp4", source: "original", format: "MPEG4", length: "2896.11"),
            ogg("Bonanza s01e19.mp4", "2896.11"),
            FileInfo(name: "__ia_thumb.jpg", source: "original", format: "Item Tile")
        ]

        let episodes = PlayableMediaResolver.resolveEpisodes(in: files)

        #expect(episodes.map(\.filename) == ["Bonanza s01e19.mp4", "Bonanza s01e20.mp4"])
        #expect(episodes.map(\.title) == ["Bonanza s01e19", "Bonanza s01e20"])
        #expect(episodes.first?.duration == 2896.11)
    }

    @Test("Unstreamable originals resolve to their h.264 derivative")
    func unstreamableOriginalsUseH264Derivative() {
        let ep1 = "Green Acres Season 1/Green Acres - 001 - Oliver Buys A Farm"
        let ep2 = "Green Acres Season 1/Green Acres - 002 - Lisa's First Day on the Farm"
        let files = [
            FileInfo(name: "\(ep1).mpg", source: "original", format: "MPEG1"),
            FileInfo(name: "\(ep1).mp4", source: "derivative", format: "h.264", original: "\(ep1).mpg"),
            FileInfo(name: "\(ep1).ogv", source: "derivative", format: "Ogg Video", original: "\(ep1).mpg"),
            FileInfo(name: "\(ep2).avi", source: "original", format: "Cinepack"),
            FileInfo(name: "\(ep2).mp4", source: "derivative", format: "h.264", original: "\(ep2).avi"),
            FileInfo(name: "\(ep2).ogv", source: "derivative", format: "Ogg Video", original: "\(ep2).avi")
        ]

        let episodes = PlayableMediaResolver.resolveEpisodes(in: files)

        #expect(episodes.map(\.filename) == ["\(ep1).mp4", "\(ep2).mp4"])
        #expect(episodes.map(\.title) == [
            "Green Acres - 001 - Oliver Buys A Farm",
            "Green Acres - 002 - Lisa's First Day on the Farm"
        ])
    }

    @Test("Prefers h.264 over a lower-quality MPEG4 rendition of the same episode")
    func prefersH264AmongRenditions() {
        let files = [
            FileInfo(name: "ep1.mpeg", source: "original", format: "MPEG2"),
            FileInfo(name: "ep1_512kb.mp4", source: "derivative", format: "512Kb MPEG4", original: "ep1.mpeg"),
            FileInfo(name: "ep1.mp4", source: "derivative", format: "h.264", original: "ep1.mpeg")
        ]

        let episodes = PlayableMediaResolver.resolveEpisodes(in: files)

        #expect(episodes.map(\.filename) == ["ep1.mp4"])
    }

    // MARK: - Ordering and Titles

    @Test("Sorts episodes naturally across season folders")
    func naturalSortOrder() {
        let files = ["Season 10/ep 1.mp4", "Season 2/ep 10.mp4", "Season 2/ep 2.mp4", "Season 1/ep 1.mp4"]
            .map { FileInfo(name: $0, source: "original", format: "h.264") }

        let episodes = PlayableMediaResolver.resolveEpisodes(in: files)

        #expect(episodes.map(\.filename) == [
            "Season 1/ep 1.mp4", "Season 2/ep 2.mp4", "Season 2/ep 10.mp4", "Season 10/ep 1.mp4"
        ])
    }

    @Test("Uses the file's title metadata when present")
    func usesTitleMetadata() {
        let files = [FileInfo(name: "s01e01.mp4", source: "original", format: "h.264", title: "  Pilot  ")]

        #expect(PlayableMediaResolver.resolveEpisodes(in: files).first?.title == "Pilot")
    }

    // MARK: - Edge Cases

    @Test("Single-video item yields one episode")
    func singleVideo() {
        let files = [FileInfo(name: "movie.mp4", source: "original", format: "h.264")]

        #expect(PlayableMediaResolver.resolveEpisodes(in: files).count == 1)
    }

    @Test("Returns no episodes when nothing is streamable")
    func nothingStreamable() {
        let files = [
            FileInfo(name: "movie.ogv", source: "original", format: "Ogg Video"),
            FileInfo(name: "movie.avi", source: "original", format: "Cinepack")
        ]

        #expect(PlayableMediaResolver.resolveEpisodes(in: files).isEmpty)
    }

    @Test("Parses IA duration formats", arguments: [
        ("1520.14", 1520.14), ("25:20", 1520.0), ("1:02:03", 3723.0)
    ])
    func parsesDurations(input: String, expected: Double) {
        #expect(PlayableMediaResolver.parseDuration(input) == expected)
    }

    @Test("Rejects empty or invalid durations", arguments: ["", "0", "abc", "1:x", "1:2:3:4"])
    func rejectsInvalidDurations(input: String) {
        #expect(PlayableMediaResolver.parseDuration(input) == nil)
    }

    // MARK: - resolveVideo(filename:)

    @Test("resolveVideo plays the requested episode")
    @MainActor
    func resolveVideoPlaysRequestedEpisode() {
        let item = TestFixtures.makeSearchResult(identifier: "series", title: "Series")
        let metadata = ItemMetadataResponse(files: [
            FileInfo(name: "e1.mp4", source: "original", format: "h.264"),
            FileInfo(name: "e2.mp4", source: "original", format: "h.264")
        ])

        let video = PlayableMediaResolver.resolveVideo(item: item, metadata: metadata, filename: "e2.mp4")

        #expect(video?.filename == "e2.mp4")
        #expect(video?.url.lastPathComponent == "e2.mp4")
    }

    @Test("resolveVideo titles episodes as 'Series – Episode'")
    @MainActor
    func resolveVideoEpisodeTitle() {
        let item = TestFixtures.makeSearchResult(identifier: "series", title: "Bonanza")
        let metadata = ItemMetadataResponse(files: [
            FileInfo(name: "s01e01.mp4", source: "original", format: "h.264"),
            FileInfo(name: "s01e02.mp4", source: "original", format: "h.264")
        ])

        let video = PlayableMediaResolver.resolveVideo(item: item, metadata: metadata, filename: "s01e02.mp4")

        #expect(video?.title == "Bonanza – s01e02")
    }

    @Test("resolveVideo keeps the item title for a single video")
    @MainActor
    func resolveVideoSingleTitle() {
        let item = TestFixtures.makeSearchResult(identifier: "film", title: "Film")
        let metadata = ItemMetadataResponse(files: [FileInfo(name: "film.mp4", source: "original", format: "h.264")])

        #expect(PlayableMediaResolver.resolveVideo(item: item, metadata: metadata)?.title == "Film")
    }

    // MARK: - nextEpisode

    @Test("nextEpisode returns the following episode, nil after the last")
    func nextEpisode() {
        let files = ["e1.mp4", "e2.mp4", "e3.mp4"].map { FileInfo(name: $0, source: "original", format: "h.264") }

        #expect(PlayableMediaResolver.nextEpisode(after: "e1.mp4", in: files)?.filename == "e2.mp4")
        #expect(PlayableMediaResolver.nextEpisode(after: "e3.mp4", in: files) == nil)
        #expect(PlayableMediaResolver.nextEpisode(after: "missing.mp4", in: files) == nil)
    }

    // MARK: - EpisodeListHelpers

    @Test("Formats episode durations", arguments: [
        (20.0, "<1 min"), (2_640.0, "44 min"), (3_600.0, "1 hr"), (3_900.0, "1 hr 5 min")
    ])
    func formatsEpisodeDurations(seconds: Double, expected: String) {
        #expect(EpisodeListHelpers.formatDuration(seconds) == expected)
    }

    @Test("Episode accessibility label includes number, title and length")
    func episodeAccessibilityLabel() {
        let episode = VideoEpisode(filename: "e1.mp4", title: "Pilot", duration: 2_640)

        #expect(EpisodeListHelpers.accessibilityLabel(number: 1, episode: episode, progress: nil)
            == "Episode 1, Pilot, 44 min")
    }

    @Test("resolveVideo falls back to the best video for an unknown filename")
    @MainActor
    func resolveVideoFallsBackForUnknownFilename() {
        let item = TestFixtures.makeSearchResult(identifier: "series", title: "Series")
        let metadata = ItemMetadataResponse(files: [FileInfo(name: "e1.mp4", source: "original", format: "h.264")])

        let video = PlayableMediaResolver.resolveVideo(item: item, metadata: metadata, filename: "gone.mp4")

        #expect(video?.filename == "e1.mp4")
    }
}
