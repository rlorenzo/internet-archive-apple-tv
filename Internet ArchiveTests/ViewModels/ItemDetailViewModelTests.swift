//
//  ItemDetailViewModelTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ItemDetailViewModel
//

import Testing
import Foundation
@testable import Internet_Archive

// MARK: - Mock Metadata Service

final class MockMetadataService: MetadataServiceProtocol, @unchecked Sendable {
    var getMetadataCalled = false
    var lastIdentifier: String?
    var mockResponse: ItemMetadataResponse?
    var errorToThrow: Error?

    func getMetadata(identifier: String) async throws -> ItemMetadataResponse {
        getMetadataCalled = true
        lastIdentifier = identifier

        if let error = errorToThrow {
            throw error
        }

        guard let response = mockResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

    func reset() {
        getMetadataCalled = false
        lastIdentifier = nil
        mockResponse = nil
        errorToThrow = nil
    }
}

// MARK: - ItemDetailViewModel Tests

@Suite("ItemDetailViewModel Tests", .serialized)
@MainActor
struct ItemDetailViewModelTests {

    var viewModel: ItemDetailViewModel
    var mockService: MockMetadataService

    init() {
        let service = MockMetadataService()
        mockService = service
        viewModel = ItemDetailViewModel(metadataService: service)
        Global.resetFavoriteData()
    }

    // MARK: - Test Helpers

    private func makeConfig(
        identifier: String = "test",
        title: String = "",
        archivedBy: String = "",
        date: String = "",
        description: String = "",
        mediaType: String = "movies",
        imageURL: URL? = nil
    ) -> ItemConfiguration {
        ItemConfiguration(
            identifier: identifier,
            title: title,
            archivedBy: archivedBy,
            date: date,
            description: description,
            mediaType: mediaType,
            imageURL: imageURL
        )
    }

    // MARK: - Initial State Tests

    @Test func initialState() {
        #expect(!viewModel.state.isLoading)
        #expect(viewModel.state.identifier.isEmpty)
        #expect(viewModel.state.title.isEmpty)
        #expect(!viewModel.state.isFavorite)
        #expect(!viewModel.state.isPlaying)
        #expect(viewModel.state.errorMessage == nil)
    }

    // MARK: - Configure Tests

    @Test func configureSetsAllProperties() {
        let imageURL = URL(string: "https://archive.org/services/img/test")
        let config = makeConfig(
            identifier: "test_item",
            title: "Test Title",
            archivedBy: "Test Creator",
            date: "2025-01-01",
            description: "Test Description",
            mediaType: "movies",
            imageURL: imageURL
        )

        viewModel.configure(with: config)

        #expect(viewModel.state.identifier == "test_item")
        #expect(viewModel.state.title == "Test Title")
        #expect(viewModel.state.archivedBy == "Test Creator")
        #expect(viewModel.state.date == "2025-01-01")
        #expect(viewModel.state.description == "Test Description")
        #expect(viewModel.state.mediaType == "movies")
        #expect(viewModel.state.imageURL == imageURL)
    }

    @Test func configureUpdatesFavoriteStatus() {
        Global.saveFavoriteData(identifier: "favorite_item")
        viewModel.configure(with: makeConfig(identifier: "favorite_item", title: "Favorite"))
        #expect(viewModel.state.isFavorite)
        Global.resetFavoriteData()
    }

    // MARK: - Formatted Properties Tests

    @Test func formattedArchivedBy() {
        viewModel.configure(with: makeConfig(archivedBy: "John Doe"))
        #expect(viewModel.state.formattedArchivedBy == "Archived By:  John Doe")
    }

    @Test func formattedDate() {
        viewModel.configure(with: makeConfig(date: "2025-01-15"))
        #expect(viewModel.state.formattedDate == "Date:  2025-01-15")
    }

    // MARK: - Media Type Tests

    @Test func isVideoForMovies() {
        viewModel.configure(with: makeConfig(mediaType: "movies"))
        #expect(viewModel.state.isVideo)
        #expect(!viewModel.state.isAudio)
    }

    @Test func isAudioForEtree() {
        viewModel.configure(with: makeConfig(mediaType: "etree"))
        #expect(!viewModel.state.isVideo)
        #expect(viewModel.state.isAudio)
    }

    @Test func isAudioForAudio() {
        viewModel.configure(with: makeConfig(mediaType: "audio"))
        #expect(!viewModel.state.isVideo)
        #expect(viewModel.state.isAudio)
    }

    // MARK: - Favorite Tests

    @Test func toggleFavoriteAddsFavorite() {
        viewModel.configure(with: makeConfig(identifier: "toggle_test", title: "Test"))
        let result = viewModel.toggleFavorite()
        #expect(result)
        #expect(viewModel.state.isFavorite)
        Global.resetFavoriteData()
    }

    @Test func toggleFavoriteRemovesFavorite() {
        Global.saveFavoriteData(identifier: "toggle_test")
        viewModel.configure(with: makeConfig(identifier: "toggle_test", title: "Test"))
        let result = viewModel.toggleFavorite()
        #expect(!result)
        #expect(!viewModel.state.isFavorite)
        Global.resetFavoriteData()
    }

    @Test func toggleFavoriteEmptyIdentifierReturnsFalse() {
        let result = viewModel.toggleFavorite()
        #expect(!result)
    }

    // MARK: - Load Media Tests

    @Test func loadMediaForPlaybackWithEmptyIdentifierSetsError() async {
        let result = await viewModel.loadMediaForPlayback()
        #expect(result == nil)
        #expect(viewModel.state.errorMessage != nil)
    }

    @Test func loadMediaForPlaybackCallsService() async {
        viewModel.configure(with: makeConfig(identifier: "test_item", title: "Test"))
        mockService.mockResponse = TestFixtures.itemMetadataResponse
        _ = await viewModel.loadMediaForPlayback()
        #expect(mockService.getMetadataCalled)
        #expect(mockService.lastIdentifier == "test_item")
    }

    @Test func loadMediaForPlaybackWithErrorSetsErrorMessage() async {
        viewModel.configure(with: makeConfig(identifier: "test_item", title: "Test"))
        mockService.errorToThrow = NetworkError.timeout
        let result = await viewModel.loadMediaForPlayback()
        #expect(result == nil)
        #expect(viewModel.state.errorMessage != nil)
        #expect(!viewModel.state.isLoading)
    }

    // MARK: - Filter Playable Files Tests

    @Test func filterPlayableFilesForVideo() {
        viewModel.configure(with: makeConfig(mediaType: "movies"))
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "MPEG4", size: "1000"),
            FileInfo(name: "audio.mp3", source: "original", format: "MP3", size: "500"),
            FileInfo(name: "subtitle.srt", source: "original", format: "SRT", size: "10")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.count == 1)
        #expect(playable[0].name == "video.mp4")
    }

    @Test func filterPlayableFilesForAudio() {
        viewModel.configure(with: makeConfig(mediaType: "etree"))
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "MPEG4", size: "1000"),
            FileInfo(name: "track1.mp3", source: "original", format: "MP3", size: "500"),
            FileInfo(name: "track2.mp3", source: "original", format: "MP3", size: "600")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.count == 2)
        #expect(playable.allSatisfy { $0.name.hasSuffix(".mp3") })
    }

    // MARK: - Build Media URL Tests

    @Test func buildMediaURLReturnsValidURL() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "video.mp4")
        #expect(url != nil)
        #expect(url?.absoluteString == "https://archive.org/download/test_item/video.mp4")
    }

    @Test func buildMediaURLEncodesSpecialCharacters() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "video file.mp4")
        #expect(url != nil)
        #expect(url?.absoluteString.contains("video%20file.mp4") ?? false)
    }

    // MARK: - Format Time Tests

    @Test func formatTimePositiveTime() {
        #expect(viewModel.formatTime(0) == "0:00")
        #expect(viewModel.formatTime(30) == "0:30")
        #expect(viewModel.formatTime(60) == "1:00")
        #expect(viewModel.formatTime(90) == "1:30")
        #expect(viewModel.formatTime(3661) == "61:01")
    }

    @Test func formatTimeNegativeTime() {
        #expect(viewModel.formatTime(-30) == "-0:30")
        #expect(viewModel.formatTime(-90) == "-1:30")
    }

    // MARK: - Set Playing Tests

    @Test func setPlayingUpdatesState() {
        viewModel.configure(with: makeConfig())
        viewModel.setPlaying(true)
        #expect(viewModel.state.isPlaying)
        viewModel.setPlaying(false)
        #expect(!viewModel.state.isPlaying)
    }

    // MARK: - Helper Property Tests

    @Test func canManageFavorites() {
        _ = viewModel.canManageFavorites
    }

    @Test func isLoggedIn() {
        _ = viewModel.isLoggedIn
    }
}

// MARK: - ItemDetailViewState Tests

@Suite("ItemDetailViewState Tests")
struct ItemDetailViewStateTests {

    @Test func initialState() {
        let state = ItemDetailViewState.initial

        #expect(!state.isLoading)
        #expect(state.identifier.isEmpty)
        #expect(!state.isFavorite)
        #expect(!state.isPlaying)
        #expect(state.errorMessage == nil)
    }

    @Test func setImageFromIdentifier() {
        var state = ItemDetailViewState.initial
        state.setImageFromIdentifier("test_item")

        #expect(
            state.imageURL?.absoluteString ==
            "https://archive.org/services/get-item-image.php?identifier=test_item"
        )
    }

    @Test func isVideoMovies() {
        var state = ItemDetailViewState.initial
        state.mediaType = "movies"

        #expect(state.isVideo)
        #expect(!state.isAudio)
    }

    @Test func isAudioEtree() {
        var state = ItemDetailViewState.initial
        state.mediaType = "etree"

        #expect(!state.isVideo)
        #expect(state.isAudio)
    }

    @Test func isAudioAudio() {
        var state = ItemDetailViewState.initial
        state.mediaType = "audio"

        #expect(!state.isVideo)
        #expect(state.isAudio)
    }

    @Test func formattedProperties() {
        var state = ItemDetailViewState.initial
        state.archivedBy = "Test Creator"
        state.date = "2025-01-01"

        #expect(state.formattedArchivedBy == "Archived By:  Test Creator")
        #expect(state.formattedDate == "Date:  2025-01-01")
    }
}

// MARK: - URL Encoding Edge Case Tests

@Suite("ItemDetail URL Encoding Tests")
@MainActor
struct ItemDetailURLEncodingTests {

    var viewModel: ItemDetailViewModel

    init() {
        viewModel = ItemDetailViewModel(metadataService: MockMetadataService())
    }

    // MARK: - Special Character Encoding Tests

    @Test func buildMediaURLEncodesHashSymbol() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "track#1.mp3")
        #expect(url != nil)
        #expect(url?.absoluteString.contains("%23") ?? false)
    }

    @Test func buildMediaURLEncodesQuestionMark() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "what?.mp4")
        #expect(url != nil)
        #expect(url?.absoluteString.contains("what%3F.mp4") ?? false)
        #expect(!(url?.absoluteString.contains("what?.mp4") ?? true))
    }

    @Test func buildMediaURLEncodesAmpersand() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "rock&roll.mp3")
        #expect(url != nil)
        #expect(url?.absoluteString.contains("rock%26roll.mp3") ?? false)
        #expect(!(url?.absoluteString.contains("rock&roll.mp3") ?? true))
    }

    @Test func buildMediaURLEncodesPlus() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "c++tutorial.mp4")
        #expect(url != nil)
        #expect(url?.absoluteString.contains("c%2B%2Btutorial.mp4") ?? false)
    }

    @Test func buildMediaURLEncodesParentheses() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "video (1).mp4")
        #expect(url != nil)
        #expect(url?.absoluteString.contains("video%20%281%29.mp4") ?? false)
    }

    @Test func buildMediaURLEncodesUnicodeCharacters() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "日本語.mp3")
        #expect(url != nil)
        #expect(url?.absoluteString.contains("%") ?? false)
    }

    @Test func buildMediaURLEncodesEmojiInFilename() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "🎵music.mp3")
        #expect(url != nil)
        #expect(url?.absoluteString.contains("%") ?? false)
    }

    @Test func buildMediaURLEncodesMultipleSpaces() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "file   with   spaces.mp4")
        #expect(url != nil)
        #expect(url?.absoluteString.contains("%20") ?? false)
    }

    @Test func buildMediaURLHandlesEmptyFilename() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "")
        #expect(url != nil)
        #expect(url?.absoluteString == "https://archive.org/download/test_item/")
    }

    @Test func buildMediaURLHandlesPathTraversal() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "../../../etc/passwd")
        #expect(url != nil)
        #expect(url?.absoluteString.contains("test_item") ?? false)
    }

    // MARK: - Identifier Tests

    @Test func buildMediaURLIdentifierWithSpacesProperlyEncoded() {
        let url = viewModel.buildMediaURL(identifier: "test item", filename: "video.mp4")
        #expect(url != nil)
        #expect(url?.absoluteString.contains("test%20item") ?? false)
    }

    @Test func buildMediaURLPreservesHyphensAndUnderscores() {
        let url = viewModel.buildMediaURL(identifier: "test-item_123", filename: "video.mp4")
        #expect(url != nil)
        #expect(url?.absoluteString.contains("test-item_123") ?? false)
    }

    @Test func buildMediaURLValidIdentifierFormats() {
        let patterns = [
            "simple_identifier",
            "identifier-with-dashes",
            "MixedCase_Identifier",
            "item123",
            "2025-01-01_concert"
        ]

        for identifier in patterns {
            let url = viewModel.buildMediaURL(identifier: identifier, filename: "video.mp4")
            #expect(url != nil, "Expected valid URL for identifier: \(identifier)")
            #expect(url?.absoluteString.contains(identifier) ?? false)
        }
    }

    // MARK: - Combined Edge Cases

    @Test func buildMediaURLComplexFilename() {
        let url = viewModel.buildMediaURL(
            identifier: "concert-2025",
            filename: "Track #1 - Artist & Friends (Live).mp3"
        )
        #expect(url != nil)
        #expect(url?.absoluteString.hasPrefix("https://archive.org/download/concert-2025/") ?? false)
        #expect(url?.absoluteString.contains("%23") ?? false) // # encoded
        #expect(url?.absoluteString.contains("%26") ?? false) // & encoded
        #expect(url?.absoluteString.contains("%28") ?? false) // ( encoded
        #expect(url?.absoluteString.contains("%29") ?? false) // ) encoded
    }
}

// MARK: - File Filtering Edge Case Tests

@Suite("ItemDetail File Filtering Tests")
@MainActor
struct ItemDetailFileFilteringTests {

    var viewModel: ItemDetailViewModel

    init() {
        viewModel = ItemDetailViewModel(metadataService: MockMetadataService())
    }

    // MARK: - Video Filtering Tests

    @Test func filterPlayableFilesVideoIncludesMp4() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "MPEG4", size: "1000")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.count == 1)
    }

    @Test func filterPlayableFilesVideoIncludesMovAndM4v() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        let files = [
            FileInfo(name: "video.mov", source: "original", format: "QuickTime", size: "1000"),
            FileInfo(name: "video.m4v", source: "original", format: "MPEG4", size: "1000")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.count == 2)
    }

    @Test func filterPlayableFilesVideoExcludesUnsupportedFormats() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        let files = [
            FileInfo(name: "video.avi", source: "original", format: "AVI", size: "1000"),
            FileInfo(name: "video.ogv", source: "original", format: "Ogg Video", size: "1000"),
            FileInfo(name: "video.mkv", source: "original", format: "Matroska", size: "1000"),
            FileInfo(name: "video.webm", source: "original", format: "WebM", size: "1000")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.count == 0)
    }

    @Test func filterPlayableFilesVideoExcludesMetadataFiles() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "MPEG4", size: "1000"),
            FileInfo(name: "test_meta.xml", source: "original", format: "Metadata", size: "10"),
            FileInfo(name: "test_files.xml", source: "original", format: "Metadata", size: "10")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.count == 1)
        #expect(playable[0].name == "video.mp4")
    }

    @Test func filterPlayableFilesVideoExcludesImageFiles() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "MPEG4", size: "1000"),
            FileInfo(name: "thumbnail.jpg", source: "original", format: "JPEG", size: "100"),
            FileInfo(name: "poster.png", source: "original", format: "PNG", size: "200")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.count == 1)
    }

    // MARK: - Audio Filtering Tests

    @Test func filterPlayableFilesAudioIncludesMp3() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "etree", imageURL: nil
        ))
        let files = [
            FileInfo(name: "track1.mp3", source: "original", format: "MP3", size: "5000")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.count == 1)
    }

    @Test func filterPlayableFilesAudioIncludesM4aAndAac() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "audio", imageURL: nil
        ))
        let files = [
            FileInfo(name: "track1.m4a", source: "original", format: "AAC", size: "5000"),
            FileInfo(name: "track1.aac", source: "original", format: "AAC", size: "3000")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.count == 2)
    }

    @Test func filterPlayableFilesAudioExcludesUnsupportedFormats() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "audio", imageURL: nil
        ))
        let files = [
            FileInfo(name: "track1.flac", source: "original", format: "Flac", size: "5000"),
            FileInfo(name: "track1.ogg", source: "original", format: "Ogg Vorbis", size: "3000"),
            FileInfo(name: "track1.wav", source: "original", format: "WAV", size: "8000")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.count == 0)
    }

    @Test func filterPlayableFilesAudioExcludesTextFiles() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "etree", imageURL: nil
        ))
        let files = [
            FileInfo(name: "track1.mp3", source: "original", format: "MP3", size: "5000"),
            FileInfo(name: "info.txt", source: "original", format: "Text", size: "100"),
            FileInfo(name: "setlist.txt", source: "original", format: "Text", size: "50")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.count == 1)
        #expect(playable[0].name == "track1.mp3")
    }

    // MARK: - Empty/Edge Case Tests

    @Test func filterPlayableFilesEmptyArray() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        let playable = viewModel.filterPlayableFiles(files: [])
        #expect(playable.isEmpty)
    }

    @Test func filterPlayableFilesNoMatchingFiles() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        let files = [
            FileInfo(name: "document.pdf", source: "original", format: "PDF", size: "1000"),
            FileInfo(name: "image.jpg", source: "original", format: "JPEG", size: "500")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.isEmpty)
    }

    @Test func filterPlayableFilesMixedFormatsOnlySupportedIncluded() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "MPEG4", size: "1000"),
            FileInfo(name: "video.mov", source: "original", format: "QuickTime", size: "1100"),
            FileInfo(name: "video.ogv", source: "original", format: "Ogg Video", size: "900"),
            FileInfo(name: "video.avi", source: "original", format: "AVI", size: "1100")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.count == 2)
        let names = playable.map { $0.name }
        #expect(names.contains("video.mp4"))
        #expect(names.contains("video.mov"))
    }

    @Test func filterPlayableFilesUppercaseExtensionsHandledCaseInsensitively() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        let files = [
            FileInfo(name: "VIDEO.MP4", source: "original", format: "MPEG4", size: "1000"),
            FileInfo(name: "Movie.MOV", source: "original", format: "QuickTime", size: "1100"),
            FileInfo(name: "clip.M4V", source: "original", format: "MPEG4", size: "900")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.count == 3, "Should match uppercase extensions case-insensitively")
    }

    @Test func filterPlayableFilesAudioUppercaseExtensions() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "etree", imageURL: nil
        ))
        let files = [
            FileInfo(name: "TRACK1.MP3", source: "original", format: "MP3", size: "5000"),
            FileInfo(name: "Track2.M4A", source: "original", format: "AAC", size: "4000"),
            FileInfo(name: "song.AAC", source: "original", format: "AAC", size: "3000")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        #expect(playable.count == 3, "Should match uppercase audio extensions case-insensitively")
    }
}

// MARK: - Load Media Error Path Tests

@Suite("ItemDetail Load Media Error Tests", .serialized)
@MainActor
struct ItemDetailLoadMediaErrorTests {

    var viewModel: ItemDetailViewModel
    var mockService: MockMetadataService

    init() {
        let service = MockMetadataService()
        mockService = service
        viewModel = ItemDetailViewModel(metadataService: service)
    }

    @Test func loadMediaForPlaybackNoFilesInResponseSetsError() async {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test_item", title: "Test", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        mockService.mockResponse = ItemMetadataResponse(
            files: nil,
            metadata: nil
        )

        let result = await viewModel.loadMediaForPlayback()

        #expect(result == nil)
        #expect(viewModel.state.errorMessage == "No files available")
        #expect(viewModel.state.currentMediaURL == nil)
    }

    @Test func loadMediaForPlaybackEmptyFilesArraySetsError() async {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test_item", title: "Test", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        mockService.mockResponse = ItemMetadataResponse(
            files: [],
            metadata: nil
        )

        let result = await viewModel.loadMediaForPlayback()

        #expect(result == nil)
        #expect(viewModel.state.errorMessage == "No playable files found")
    }

    @Test func loadMediaForPlaybackNoPlayableFilesSetsError() async {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test_item", title: "Test", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        mockService.mockResponse = ItemMetadataResponse(
            files: [
                FileInfo(name: "document.pdf", source: "original", format: "PDF", size: "1000"),
                FileInfo(name: "image.jpg", source: "original", format: "JPEG", size: "500")
            ],
            metadata: nil
        )

        let result = await viewModel.loadMediaForPlayback()

        #expect(result == nil)
        #expect(viewModel.state.errorMessage == "No playable files found")
        #expect(viewModel.state.currentMediaURL == nil)
    }

    @Test func loadMediaForPlaybackNetworkErrorSetsUserFriendlyMessage() async {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test_item", title: "Test", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        mockService.errorToThrow = NetworkError.noConnection

        let result = await viewModel.loadMediaForPlayback()

        #expect(result == nil)
        #expect(viewModel.state.errorMessage != nil)
        #expect(!viewModel.state.isLoading)
    }

    @Test func loadMediaForPlaybackServerErrorSetsErrorMessage() async {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test_item", title: "Test", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        mockService.errorToThrow = NetworkError.serverError(statusCode: 503)

        let result = await viewModel.loadMediaForPlayback()

        #expect(result == nil)
        #expect(viewModel.state.errorMessage != nil)
    }

    @Test func loadMediaForPlaybackClearsLoadingOnError() async {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test_item", title: "Test", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        mockService.errorToThrow = NetworkError.timeout

        _ = await viewModel.loadMediaForPlayback()

        #expect(!viewModel.state.isLoading)
    }

    @Test func loadMediaForPlaybackSuccessSetsCurrentMediaURL() async {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test_item", title: "Test", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        mockService.mockResponse = ItemMetadataResponse(
            files: [
                FileInfo(name: "video.mp4", source: "original", format: "MPEG4", size: "1000")
            ],
            metadata: nil
        )

        let result = await viewModel.loadMediaForPlayback()

        #expect(result != nil)
        #expect(viewModel.state.currentMediaURL != nil)
        #expect(viewModel.state.errorMessage == nil)
        #expect(viewModel.state.playableFiles.count == 1)
    }

    @Test func loadMediaForPlaybackSuccessClearsLoading() async {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test_item", title: "Test", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        mockService.mockResponse = ItemMetadataResponse(
            files: [
                FileInfo(name: "video.mp4", source: "original", format: "MPEG4", size: "1000")
            ],
            metadata: nil
        )

        _ = await viewModel.loadMediaForPlayback()

        #expect(!viewModel.state.isLoading)
    }
}

// MARK: - buildMediaURL Returns Nil Path Tests

/// Test coverage notes:
/// The "Invalid file URL" error path in loadMediaForPlayback is triggered when buildMediaURL returns nil.
/// This is difficult to test directly because buildMediaURL uses addingPercentEncoding which
/// rarely fails. The error path is kept for defensive coding but the primary URL encoding edge
/// cases are thoroughly tested in ItemDetailURLEncodingTests above.
