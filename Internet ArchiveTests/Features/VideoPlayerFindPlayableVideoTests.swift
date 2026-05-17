//
//  VideoPlayerFindPlayableVideoTests.swift
//  Internet ArchiveTests
//
//  Unit tests for VideoPlayerView.findPlayableVideo — the pure format-priority
//  logic that chooses which file in an item's metadata the player should open.
//

import Testing
@testable import Internet_Archive

@MainActor
@Suite("VideoPlayerView.findPlayableVideo")
struct VideoPlayerFindPlayableVideoTests {

    // MARK: - Helpers

    private static func file(name: String, format: String? = nil) -> FileInfo {
        FileInfo(name: name, format: format)
    }

    // MARK: - Empty / no-match cases

    @Test("returns nil for empty files list")
    func emptyList() {
        #expect(VideoPlayerView.findPlayableVideo(in: []) == nil)
    }

    @Test("returns nil when no file matches any video format")
    func noVideoFiles() {
        let files = [
            Self.file(name: "metadata.xml", format: "Metadata"),
            Self.file(name: "thumb.jpg", format: "JPEG Thumb")
        ]
        #expect(VideoPlayerView.findPlayableVideo(in: files) == nil)
    }

    // MARK: - Primary formats (h.264 / mp4 / mpeg4 / mov / m4v)

    @Test("matches h.264 format")
    func matchesH264() {
        let files = [Self.file(name: "movie.mp4", format: "h.264")]
        #expect(VideoPlayerView.findPlayableVideo(in: files)?.name == "movie.mp4")
    }

    @Test("matches mp4 by format string")
    func matchesMP4Format() {
        let files = [Self.file(name: "trailer.bin", format: "MP4")]
        #expect(VideoPlayerView.findPlayableVideo(in: files)?.name == "trailer.bin")
    }

    @Test("matches mov by extension when format is missing")
    func matchesMovByExtension() {
        let files = [Self.file(name: "clip.mov", format: nil)]
        #expect(VideoPlayerView.findPlayableVideo(in: files)?.name == "clip.mov")
    }

    @Test("matches m4v")
    func matchesM4V() {
        let files = [Self.file(name: "show.m4v", format: "m4v")]
        #expect(VideoPlayerView.findPlayableVideo(in: files)?.name == "show.m4v")
    }

    @Test("matches mpeg4")
    func matchesMpeg4() {
        let files = [Self.file(name: "video.mp4", format: "MPEG4")]
        #expect(VideoPlayerView.findPlayableVideo(in: files)?.name == "video.mp4")
    }

    @Test("is case-insensitive on format")
    func formatCaseInsensitive() {
        let files = [Self.file(name: "a.bin", format: "MOV")]
        #expect(VideoPlayerView.findPlayableVideo(in: files)?.name == "a.bin")
    }

    @Test("is case-insensitive on filename suffix")
    func suffixCaseInsensitive() {
        let files = [Self.file(name: "MOVIE.MP4", format: nil)]
        #expect(VideoPlayerView.findPlayableVideo(in: files)?.name == "MOVIE.MP4")
    }

    // MARK: - Format priority

    @Test("prefers h.264 over mp4 when both are present")
    func prefersH264OverMP4() {
        let files = [
            Self.file(name: "fallback.mp4", format: "mp4"),
            Self.file(name: "preferred.mp4", format: "h.264")
        ]
        // Iteration is in `videoFormats` order: h.264 first.
        #expect(VideoPlayerView.findPlayableVideo(in: files)?.format == "h.264")
    }

    @Test("prefers any primary format over lower-priority webm")
    func prefersPrimaryOverWebm() {
        let files = [
            Self.file(name: "webm.webm", format: "WebM"),
            Self.file(name: "video.mp4", format: "MP4")
        ]
        #expect(VideoPlayerView.findPlayableVideo(in: files)?.format == "MP4")
    }

    // MARK: - Lower-priority fallback formats

    @Test("falls back to ogv when no primary format present")
    func fallsBackToOGV() {
        let files = [Self.file(name: "old.ogv", format: "Ogg Video")]
        // No format match, but extension match (.ogv).
        #expect(VideoPlayerView.findPlayableVideo(in: files)?.name == "old.ogv")
    }

    @Test("falls back to webm")
    func fallsBackToWebM() {
        let files = [Self.file(name: "clip.webm", format: "webm")]
        #expect(VideoPlayerView.findPlayableVideo(in: files)?.name == "clip.webm")
    }

    @Test("prefers ogv over webm (iteration order)")
    func prefersOGVOverWebM() {
        let files = [
            Self.file(name: "b.webm", format: "webm"),
            Self.file(name: "a.ogv", format: "ogv")
        ]
        #expect(VideoPlayerView.findPlayableVideo(in: files)?.format == "ogv")
    }

    // MARK: - Last-resort "video" substring match

    @Test("matches any format containing 'video' as final fallback")
    func lastResortVideoSubstring() {
        let files = [Self.file(name: "weird.bin", format: "Exotic Video Container")]
        #expect(VideoPlayerView.findPlayableVideo(in: files)?.name == "weird.bin")
    }

    @Test("last-resort search is case-insensitive on format")
    func lastResortCaseInsensitive() {
        let files = [Self.file(name: "weird.bin", format: "EXOTIC VIDEO")]
        #expect(VideoPlayerView.findPlayableVideo(in: files)?.name == "weird.bin")
    }

    @Test("does not match files with no format when nothing else matches")
    func noFormatNoMatch() {
        let files = [Self.file(name: "unknown.bin", format: nil)]
        #expect(VideoPlayerView.findPlayableVideo(in: files) == nil)
    }
}
