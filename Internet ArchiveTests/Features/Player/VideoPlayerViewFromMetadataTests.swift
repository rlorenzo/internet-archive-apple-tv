//
//  VideoPlayerViewFromMetadataTests.swift
//  Internet ArchiveTests
//
//  Tests for VideoPlayerView.fromMetadata() - the static factory that builds
//  a VideoPlayerView from item metadata (video file selection, URL building,
//  subtitle extraction, and property pass-through).
//

import Testing
import Foundation
@testable import Internet_Archive

@Suite("VideoPlayerView fromMetadata Tests")
@MainActor
struct VideoPlayerViewFromMetadataTests {

    // MARK: - Basic Success / Nil Cases

    @Test("Returns non-nil when mp4 file present")
    func fromMetadata_withMp4File_returnsView() {
        let item = TestFixtures.makeSearchResult(identifier: "test-video", title: "Test Video")
        let files = [
            FileInfo(name: "movie.mp4", source: "original", format: "h.264"),
            FileInfo(name: "cover.jpg", source: "derivative", format: "JPEG")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = VideoPlayerView.fromMetadata(item: item, metadata: metadata)

        #expect(view != nil)
    }

    @Test("Returns nil when no video files are present")
    func fromMetadata_noVideoFiles_returnsNil() {
        let item = TestFixtures.makeSearchResult(identifier: "test-audio", title: "Test Audio")
        let files = [
            FileInfo(name: "track01.mp3", source: "original", format: "MP3"),
            FileInfo(name: "cover.jpg", source: "derivative", format: "JPEG"),
            FileInfo(name: "meta.xml", source: "original", format: "Metadata")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = VideoPlayerView.fromMetadata(item: item, metadata: metadata)

        #expect(view == nil)
    }

    @Test("Returns nil when files is nil")
    func fromMetadata_nilFiles_returnsNil() {
        let item = TestFixtures.makeSearchResult(identifier: "test-empty")
        let metadata = ItemMetadataResponse(files: nil)

        let view = VideoPlayerView.fromMetadata(item: item, metadata: metadata)

        #expect(view == nil)
    }

    @Test("Returns nil when files array is empty")
    func fromMetadata_emptyFiles_returnsNil() {
        let item = TestFixtures.makeSearchResult(identifier: "test-empty")
        let metadata = ItemMetadataResponse(files: [])

        let view = VideoPlayerView.fromMetadata(item: item, metadata: metadata)

        #expect(view == nil)
    }

    // MARK: - URL Building

    @Test("Sets correct video URL with identifier and filename")
    func fromMetadata_setsCorrectVideoURL() throws {
        let item = TestFixtures.makeSearchResult(identifier: "my-movie", title: "My Movie")
        let files = [
            FileInfo(name: "feature.mp4", source: "original", format: "h.264")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = try #require(VideoPlayerView.fromMetadata(item: item, metadata: metadata))

        let expectedURL = "https://archive.org/download/my-movie/feature.mp4"
        #expect(view.videoURL.absoluteString == expectedURL)
    }

    @Test("Sets correct thumbnail URL from identifier")
    func fromMetadata_setsCorrectThumbnailURL() throws {
        let item = TestFixtures.makeSearchResult(identifier: "my-movie", title: "My Movie")
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "h.264")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = try #require(VideoPlayerView.fromMetadata(item: item, metadata: metadata))

        #expect(view.thumbnailURL == "https://archive.org/services/img/my-movie")
    }

    // MARK: - Property Pass-Through

    @Test("Passes resume time through to the view")
    func fromMetadata_passesResumeTime() throws {
        let item = TestFixtures.makeSearchResult(identifier: "resume-test", title: "Resume Test")
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "h.264")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = try #require(
            VideoPlayerView.fromMetadata(item: item, metadata: metadata, resumeTime: 95.5)
        )

        #expect(view.resumeTime == 95.5)
    }

    @Test("Sets nil resume time when not provided")
    func fromMetadata_nilResumeTimeByDefault() throws {
        let item = TestFixtures.makeSearchResult(identifier: "test", title: "Test")
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "h.264")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = try #require(VideoPlayerView.fromMetadata(item: item, metadata: metadata))

        #expect(view.resumeTime == nil)
    }

    @Test("Sets identifier correctly from search result")
    func fromMetadata_setsIdentifier() throws {
        let item = TestFixtures.makeSearchResult(identifier: "archive-item-123", title: "Archive Item")
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "h.264")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = try #require(VideoPlayerView.fromMetadata(item: item, metadata: metadata))

        #expect(view.identifier == "archive-item-123")
    }

    @Test("Sets filename correctly from selected video file")
    func fromMetadata_setsFilename() throws {
        let item = TestFixtures.makeSearchResult(identifier: "test-item", title: "Test")
        let files = [
            FileInfo(name: "best-quality.mp4", source: "original", format: "h.264")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = try #require(VideoPlayerView.fromMetadata(item: item, metadata: metadata))

        #expect(view.filename == "best-quality.mp4")
    }

    @Test("Sets title from item safeTitle")
    func fromMetadata_setsTitleFromSafeTitle() throws {
        let item = TestFixtures.makeSearchResult(identifier: "titled-video", title: "My Great Film")
        let files = [
            FileInfo(name: "film.mp4", source: "original", format: "h.264")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = try #require(VideoPlayerView.fromMetadata(item: item, metadata: metadata))

        #expect(view.title == "My Great Film")
    }

    @Test("Sets title to Untitled when item has no title")
    func fromMetadata_untitledFallback() throws {
        let item = TestFixtures.makeSearchResult(identifier: "no-title", title: nil)
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "h.264")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = try #require(VideoPlayerView.fromMetadata(item: item, metadata: metadata))

        #expect(view.title == "Untitled")
    }

    @Test("Subtitle tracks are set (may be empty when no subtitle files)")
    func fromMetadata_subtitleTracksPresent() throws {
        let item = TestFixtures.makeSearchResult(identifier: "sub-test", title: "Subtitle Test")
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "h.264")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = try #require(VideoPlayerView.fromMetadata(item: item, metadata: metadata))

        // With no .srt or .vtt files, subtitle tracks should be empty
        #expect(view.subtitleTracks.isEmpty)
    }

    @Test("Subtitle tracks populated when SRT files present")
    func fromMetadata_extractsSubtitleTracks() throws {
        let item = TestFixtures.makeSearchResult(identifier: "sub-video", title: "Video With Subs")
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "h.264"),
            FileInfo(name: "video.en.srt", source: "original", format: "SubRip")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = try #require(VideoPlayerView.fromMetadata(item: item, metadata: metadata))

        // SubtitleManager should extract the .srt file as a subtitle track
        #expect(view.subtitleTracks.count == 1)
    }

    // MARK: - URL Encoding Edge Cases

    @Test("Handles filename with spaces in URL path")
    func fromMetadata_filenameWithSpaces() throws {
        let item = TestFixtures.makeSearchResult(identifier: "space-test", title: "Space Test")
        let files = [
            FileInfo(name: "my video file.mp4", source: "original", format: "h.264")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = try #require(VideoPlayerView.fromMetadata(item: item, metadata: metadata))

        // URL should percent-encode the space in the filename
        #expect(view.videoURL.absoluteString.contains("my%20video%20file.mp4"))
        #expect(view.filename == "my video file.mp4")
    }

    // MARK: - Format Priority

    @Test("Prefers H.264 format over lower-priority formats")
    func fromMetadata_prefersH264OverOgvAndWebm() throws {
        let item = TestFixtures.makeSearchResult(identifier: "priority-test", title: "Priority Test")
        let files = [
            FileInfo(name: "fallback.ogv", source: "original", format: "Ogg Video"),
            FileInfo(name: "backup.webm", source: "original", format: "WebM"),
            FileInfo(name: "best.mp4", source: "original", format: "h.264")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = try #require(VideoPlayerView.fromMetadata(item: item, metadata: metadata))

        #expect(view.filename == "best.mp4")
        #expect(view.videoURL.lastPathComponent == "best.mp4")
    }

    @Test("Falls back to lower-priority format when no H.264 available")
    func fromMetadata_fallsBackToLowerPriorityFormat() throws {
        let item = TestFixtures.makeSearchResult(identifier: "fallback-test", title: "Fallback Test")
        let files = [
            FileInfo(name: "video.ogv", source: "original", format: "Ogg Video"),
            FileInfo(name: "cover.jpg", source: "derivative", format: "JPEG")
        ]
        let metadata = ItemMetadataResponse(files: files)

        let view = try #require(VideoPlayerView.fromMetadata(item: item, metadata: metadata))

        #expect(view.filename == "video.ogv")
    }
}
