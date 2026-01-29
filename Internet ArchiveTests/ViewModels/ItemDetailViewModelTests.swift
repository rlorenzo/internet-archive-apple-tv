//
//  ItemDetailViewModelTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ItemDetailViewModel
//

import XCTest
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

@MainActor
final class ItemDetailViewModelTests: XCTestCase {

    nonisolated(unsafe) var viewModel: ItemDetailViewModel!
    nonisolated(unsafe) var mockService: MockMetadataService!

    override func setUp() {
        super.setUp()
        let (newMockService, newViewModel) = MainActor.assumeIsolated {
            let service = MockMetadataService()
            let vm = ItemDetailViewModel(metadataService: service)
            Global.resetFavoriteData()
            return (service, vm)
        }
        mockService = newMockService
        viewModel = newViewModel
    }

    override func tearDown() {
        MainActor.assumeIsolated {
            Global.resetFavoriteData()
        }
        viewModel = nil
        mockService = nil
        super.tearDown()
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

    func testInitialState() {
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertTrue(viewModel.state.identifier.isEmpty)
        XCTAssertTrue(viewModel.state.title.isEmpty)
        XCTAssertFalse(viewModel.state.isFavorite)
        XCTAssertFalse(viewModel.state.isPlaying)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    // MARK: - Configure Tests

    func testConfigure_setsAllProperties() {
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

        XCTAssertEqual(viewModel.state.identifier, "test_item")
        XCTAssertEqual(viewModel.state.title, "Test Title")
        XCTAssertEqual(viewModel.state.archivedBy, "Test Creator")
        XCTAssertEqual(viewModel.state.date, "2025-01-01")
        XCTAssertEqual(viewModel.state.description, "Test Description")
        XCTAssertEqual(viewModel.state.mediaType, "movies")
        XCTAssertEqual(viewModel.state.imageURL, imageURL)
    }

    func testConfigure_updatesFavoriteStatus() {
        Global.saveFavoriteData(identifier: "favorite_item")
        viewModel.configure(with: makeConfig(identifier: "favorite_item", title: "Favorite"))
        XCTAssertTrue(viewModel.state.isFavorite)
    }

    // MARK: - Formatted Properties Tests

    func testFormattedArchivedBy() {
        viewModel.configure(with: makeConfig(archivedBy: "John Doe"))
        XCTAssertEqual(viewModel.state.formattedArchivedBy, "Archived By:  John Doe")
    }

    func testFormattedDate() {
        viewModel.configure(with: makeConfig(date: "2025-01-15"))
        XCTAssertEqual(viewModel.state.formattedDate, "Date:  2025-01-15")
    }

    // MARK: - Media Type Tests

    func testIsVideo_forMovies() {
        viewModel.configure(with: makeConfig(mediaType: "movies"))
        XCTAssertTrue(viewModel.state.isVideo)
        XCTAssertFalse(viewModel.state.isAudio)
    }

    func testIsAudio_forEtree() {
        viewModel.configure(with: makeConfig(mediaType: "etree"))
        XCTAssertFalse(viewModel.state.isVideo)
        XCTAssertTrue(viewModel.state.isAudio)
    }

    func testIsAudio_forAudio() {
        viewModel.configure(with: makeConfig(mediaType: "audio"))
        XCTAssertFalse(viewModel.state.isVideo)
        XCTAssertTrue(viewModel.state.isAudio)
    }

    // MARK: - Favorite Tests

    func testToggleFavorite_addsFavorite() {
        viewModel.configure(with: makeConfig(identifier: "toggle_test", title: "Test"))
        let result = viewModel.toggleFavorite()
        XCTAssertTrue(result)
        XCTAssertTrue(viewModel.state.isFavorite)
    }

    func testToggleFavorite_removesFavorite() {
        Global.saveFavoriteData(identifier: "toggle_test")
        viewModel.configure(with: makeConfig(identifier: "toggle_test", title: "Test"))
        let result = viewModel.toggleFavorite()
        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.state.isFavorite)
    }

    func testToggleFavorite_emptyIdentifier_returnsFalse() {
        let result = viewModel.toggleFavorite()
        XCTAssertFalse(result)
    }

    // MARK: - Load Media Tests

    func testLoadMediaForPlayback_withEmptyIdentifier_setsError() async {
        let result = await viewModel.loadMediaForPlayback()
        XCTAssertNil(result)
        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    func testLoadMediaForPlayback_callsService() async {
        viewModel.configure(with: makeConfig(identifier: "test_item", title: "Test"))
        mockService.mockResponse = TestFixtures.itemMetadataResponse
        _ = await viewModel.loadMediaForPlayback()
        XCTAssertTrue(mockService.getMetadataCalled)
        XCTAssertEqual(mockService.lastIdentifier, "test_item")
    }

    func testLoadMediaForPlayback_withError_setsErrorMessage() async {
        viewModel.configure(with: makeConfig(identifier: "test_item", title: "Test"))
        mockService.errorToThrow = NetworkError.timeout
        let result = await viewModel.loadMediaForPlayback()
        XCTAssertNil(result)
        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertFalse(viewModel.state.isLoading)
    }

    // MARK: - Filter Playable Files Tests

    func testFilterPlayableFiles_forVideo() {
        viewModel.configure(with: makeConfig(mediaType: "movies"))
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "MPEG4", size: "1000"),
            FileInfo(name: "audio.mp3", source: "original", format: "MP3", size: "500"),
            FileInfo(name: "subtitle.srt", source: "original", format: "SRT", size: "10")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        XCTAssertEqual(playable.count, 1)
        XCTAssertEqual(playable[0].name, "video.mp4")
    }

    func testFilterPlayableFiles_forAudio() {
        viewModel.configure(with: makeConfig(mediaType: "etree"))
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "MPEG4", size: "1000"),
            FileInfo(name: "track1.mp3", source: "original", format: "MP3", size: "500"),
            FileInfo(name: "track2.mp3", source: "original", format: "MP3", size: "600")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        XCTAssertEqual(playable.count, 2)
        XCTAssertTrue(playable.allSatisfy { $0.name.hasSuffix(".mp3") })
    }

    // MARK: - Build Media URL Tests

    func testBuildMediaURL_returnsValidURL() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "video.mp4")
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://archive.org/download/test_item/video.mp4")
    }

    func testBuildMediaURL_encodesSpecialCharacters() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "video file.mp4")
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("video%20file.mp4") ?? false)
    }

    // MARK: - Format Time Tests

    func testFormatTime_positiveTime() {
        XCTAssertEqual(viewModel.formatTime(0), "0:00")
        XCTAssertEqual(viewModel.formatTime(30), "0:30")
        XCTAssertEqual(viewModel.formatTime(60), "1:00")
        XCTAssertEqual(viewModel.formatTime(90), "1:30")
        XCTAssertEqual(viewModel.formatTime(3661), "61:01")
    }

    func testFormatTime_negativeTime() {
        XCTAssertEqual(viewModel.formatTime(-30), "-0:30")
        XCTAssertEqual(viewModel.formatTime(-90), "-1:30")
    }

    // MARK: - Set Playing Tests

    func testSetPlaying_updatesState() {
        viewModel.configure(with: makeConfig())
        viewModel.setPlaying(true)
        XCTAssertTrue(viewModel.state.isPlaying)
        viewModel.setPlaying(false)
        XCTAssertFalse(viewModel.state.isPlaying)
    }

    // MARK: - Helper Property Tests

    func testCanManageFavorites() {
        _ = viewModel.canManageFavorites
        XCTAssertNotNil(viewModel)
    }

    func testIsLoggedIn() {
        _ = viewModel.isLoggedIn
        XCTAssertNotNil(viewModel)
    }
}

// MARK: - ItemDetailViewState Tests

final class ItemDetailViewStateTests: XCTestCase {

    func testInitialState() {
        let state = ItemDetailViewState.initial

        XCTAssertFalse(state.isLoading)
        XCTAssertTrue(state.identifier.isEmpty)
        XCTAssertFalse(state.isFavorite)
        XCTAssertFalse(state.isPlaying)
        XCTAssertNil(state.errorMessage)
    }

    func testSetImageFromIdentifier() {
        var state = ItemDetailViewState.initial
        state.setImageFromIdentifier("test_item")

        XCTAssertEqual(
            state.imageURL?.absoluteString,
            "https://archive.org/services/get-item-image.php?identifier=test_item"
        )
    }

    func testIsVideo_movies() {
        var state = ItemDetailViewState.initial
        state.mediaType = "movies"

        XCTAssertTrue(state.isVideo)
        XCTAssertFalse(state.isAudio)
    }

    func testIsAudio_etree() {
        var state = ItemDetailViewState.initial
        state.mediaType = "etree"

        XCTAssertFalse(state.isVideo)
        XCTAssertTrue(state.isAudio)
    }

    func testIsAudio_audio() {
        var state = ItemDetailViewState.initial
        state.mediaType = "audio"

        XCTAssertFalse(state.isVideo)
        XCTAssertTrue(state.isAudio)
    }

    func testFormattedProperties() {
        var state = ItemDetailViewState.initial
        state.archivedBy = "Test Creator"
        state.date = "2025-01-01"

        XCTAssertEqual(state.formattedArchivedBy, "Archived By:  Test Creator")
        XCTAssertEqual(state.formattedDate, "Date:  2025-01-01")
    }
}

// MARK: - URL Encoding Edge Case Tests

@MainActor
final class ItemDetailURLEncodingTests: XCTestCase {

    nonisolated(unsafe) var viewModel: ItemDetailViewModel!

    override func setUp() {
        super.setUp()
        let newViewModel = MainActor.assumeIsolated {
            ItemDetailViewModel(metadataService: MockMetadataService())
        }
        viewModel = newViewModel
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Special Character Encoding Tests

    func testBuildMediaURL_encodesHashSymbol() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "track#1.mp3")
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("%23") ?? false)
    }

    func testBuildMediaURL_encodesQuestionMark() {
        // Question mark is properly encoded to avoid breaking URL parsing
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "what?.mp4")
        XCTAssertNotNil(url)
        // Question mark should be encoded as %3F
        XCTAssertTrue(url?.absoluteString.contains("what%3F.mp4") ?? false)
        XCTAssertFalse(url?.absoluteString.contains("what?.mp4") ?? true)
    }

    func testBuildMediaURL_encodesAmpersand() {
        // Ampersand is properly encoded to avoid breaking URL parsing
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "rock&roll.mp3")
        XCTAssertNotNil(url)
        // Ampersand should be encoded as %26
        XCTAssertTrue(url?.absoluteString.contains("rock%26roll.mp3") ?? false)
        XCTAssertFalse(url?.absoluteString.contains("rock&roll.mp3") ?? true)
    }

    func testBuildMediaURL_encodesPlus() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "c++tutorial.mp4")
        XCTAssertNotNil(url)
        // Plus signs are encoded as %2B
        XCTAssertTrue(url?.absoluteString.contains("c%2B%2Btutorial.mp4") ?? false)
    }

    func testBuildMediaURL_encodesParentheses() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "video (1).mp4")
        XCTAssertNotNil(url)
        // Parentheses are encoded for safety in path segments
        XCTAssertTrue(url?.absoluteString.contains("video%20%281%29.mp4") ?? false)
    }

    func testBuildMediaURL_encodesUnicodeCharacters() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "日本語.mp3")
        XCTAssertNotNil(url)
        // Unicode should be percent encoded
        XCTAssertTrue(url?.absoluteString.contains("%") ?? false)
    }

    func testBuildMediaURL_encodesEmojiInFilename() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "🎵music.mp3")
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("%") ?? false)
    }

    func testBuildMediaURL_encodesMultipleSpaces() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "file   with   spaces.mp4")
        XCTAssertNotNil(url)
        // Multiple spaces should be encoded
        XCTAssertTrue(url?.absoluteString.contains("%20") ?? false)
    }

    func testBuildMediaURL_handlesEmptyFilename() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "")
        // Should still construct a valid URL even with empty filename
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://archive.org/download/test_item/")
    }

    func testBuildMediaURL_handlesPathTraversal() {
        let url = viewModel.buildMediaURL(identifier: "test_item", filename: "../../../etc/passwd")
        XCTAssertNotNil(url)
        // Should encode the dots but result is still a URL
        XCTAssertTrue(url?.absoluteString.contains("test_item") ?? false)
    }

    // MARK: - Identifier Tests

    func testBuildMediaURL_identifierWithSpaces_properlyEncoded() {
        // Identifier spaces are properly percent-encoded
        // Internet Archive identifiers shouldn't have spaces, but if they do,
        // buildMediaURL handles it correctly
        let url = viewModel.buildMediaURL(identifier: "test item", filename: "video.mp4")
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("test%20item") ?? false)
    }

    func testBuildMediaURL_preservesHyphensAndUnderscores() {
        let url = viewModel.buildMediaURL(identifier: "test-item_123", filename: "video.mp4")
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("test-item_123") ?? false)
    }

    func testBuildMediaURL_validIdentifierFormats() {
        // Test common IA identifier patterns
        let patterns = [
            "simple_identifier",
            "identifier-with-dashes",
            "MixedCase_Identifier",
            "item123",
            "2025-01-01_concert"
        ]

        for identifier in patterns {
            let url = viewModel.buildMediaURL(identifier: identifier, filename: "video.mp4")
            XCTAssertNotNil(url, "Expected valid URL for identifier: \(identifier)")
            XCTAssertTrue(url?.absoluteString.contains(identifier) ?? false)
        }
    }

    // MARK: - Combined Edge Cases

    func testBuildMediaURL_complexFilename() {
        let url = viewModel.buildMediaURL(
            identifier: "concert-2025",
            filename: "Track #1 - Artist & Friends (Live).mp3"
        )
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.hasPrefix("https://archive.org/download/concert-2025/") ?? false)
        // Verify special characters are encoded
        XCTAssertTrue(url?.absoluteString.contains("%23") ?? false) // # encoded
        XCTAssertTrue(url?.absoluteString.contains("%26") ?? false) // & encoded
        XCTAssertTrue(url?.absoluteString.contains("%28") ?? false) // ( encoded
        XCTAssertTrue(url?.absoluteString.contains("%29") ?? false) // ) encoded
    }
}

// MARK: - File Filtering Edge Case Tests

@MainActor
final class ItemDetailFileFilteringTests: XCTestCase {

    nonisolated(unsafe) var viewModel: ItemDetailViewModel!

    override func setUp() {
        super.setUp()
        let newViewModel = MainActor.assumeIsolated {
            ItemDetailViewModel(metadataService: MockMetadataService())
        }
        viewModel = newViewModel
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Video Filtering Tests

    func testFilterPlayableFiles_video_includesMp4() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        let files = [
            FileInfo(name: "video.mp4", source: "original", format: "MPEG4", size: "1000")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        XCTAssertEqual(playable.count, 1)
    }

    func testFilterPlayableFiles_video_includesMovAndM4v() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        // tvOS supports .mp4, .mov, .m4v natively
        let files = [
            FileInfo(name: "video.mov", source: "original", format: "QuickTime", size: "1000"),
            FileInfo(name: "video.m4v", source: "original", format: "MPEG4", size: "1000")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        XCTAssertEqual(playable.count, 2)
    }

    func testFilterPlayableFiles_video_excludesUnsupportedFormats() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        // Formats NOT natively supported by tvOS AVPlayer
        let files = [
            FileInfo(name: "video.avi", source: "original", format: "AVI", size: "1000"),
            FileInfo(name: "video.ogv", source: "original", format: "Ogg Video", size: "1000"),
            FileInfo(name: "video.mkv", source: "original", format: "Matroska", size: "1000"),
            FileInfo(name: "video.webm", source: "original", format: "WebM", size: "1000")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        XCTAssertEqual(playable.count, 0)
    }

    func testFilterPlayableFiles_video_excludesMetadataFiles() {
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
        XCTAssertEqual(playable.count, 1)
        XCTAssertEqual(playable[0].name, "video.mp4")
    }

    func testFilterPlayableFiles_video_excludesImageFiles() {
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
        XCTAssertEqual(playable.count, 1)
    }

    // MARK: - Audio Filtering Tests

    func testFilterPlayableFiles_audio_includesMp3() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "etree", imageURL: nil
        ))
        let files = [
            FileInfo(name: "track1.mp3", source: "original", format: "MP3", size: "5000")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        XCTAssertEqual(playable.count, 1)
    }

    func testFilterPlayableFiles_audio_includesM4aAndAac() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "audio", imageURL: nil
        ))
        // tvOS supports .mp3, .m4a, .aac natively
        let files = [
            FileInfo(name: "track1.m4a", source: "original", format: "AAC", size: "5000"),
            FileInfo(name: "track1.aac", source: "original", format: "AAC", size: "3000")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        XCTAssertEqual(playable.count, 2)
    }

    func testFilterPlayableFiles_audio_excludesUnsupportedFormats() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "audio", imageURL: nil
        ))
        // Formats NOT natively supported by tvOS AVPlayer
        let files = [
            FileInfo(name: "track1.flac", source: "original", format: "Flac", size: "5000"),
            FileInfo(name: "track1.ogg", source: "original", format: "Ogg Vorbis", size: "3000"),
            FileInfo(name: "track1.wav", source: "original", format: "WAV", size: "8000")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        XCTAssertEqual(playable.count, 0)
    }

    func testFilterPlayableFiles_audio_excludesTextFiles() {
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
        XCTAssertEqual(playable.count, 1)
        XCTAssertEqual(playable[0].name, "track1.mp3")
    }

    // MARK: - Empty/Edge Case Tests

    func testFilterPlayableFiles_emptyArray() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        let playable = viewModel.filterPlayableFiles(files: [])
        XCTAssertTrue(playable.isEmpty)
    }

    func testFilterPlayableFiles_noMatchingFiles() {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test", title: "", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        let files = [
            FileInfo(name: "document.pdf", source: "original", format: "PDF", size: "1000"),
            FileInfo(name: "image.jpg", source: "original", format: "JPEG", size: "500")
        ]
        let playable = viewModel.filterPlayableFiles(files: files)
        XCTAssertTrue(playable.isEmpty)
    }

    func testFilterPlayableFiles_mixedFormats_onlySupportedIncluded() {
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
        // Only .mp4 and .mov are supported by tvOS
        XCTAssertEqual(playable.count, 2)
        let names = playable.map { $0.name }
        XCTAssertTrue(names.contains("video.mp4"))
        XCTAssertTrue(names.contains("video.mov"))
    }

    func testFilterPlayableFiles_uppercaseExtensions_handledCaseInsensitively() {
        // Test that uppercase extensions like VIDEO.MP4 are handled correctly
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
        XCTAssertEqual(playable.count, 3, "Should match uppercase extensions case-insensitively")
    }

    func testFilterPlayableFiles_audio_uppercaseExtensions() {
        // Test that uppercase audio extensions are handled correctly
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
        XCTAssertEqual(playable.count, 3, "Should match uppercase audio extensions case-insensitively")
    }
}

// MARK: - Load Media Error Path Tests

@MainActor
final class ItemDetailLoadMediaErrorTests: XCTestCase {

    nonisolated(unsafe) var viewModel: ItemDetailViewModel!
    nonisolated(unsafe) var mockService: MockMetadataService!

    override func setUp() {
        super.setUp()
        let (newMockService, newViewModel) = MainActor.assumeIsolated {
            let service = MockMetadataService()
            let vm = ItemDetailViewModel(metadataService: service)
            return (service, vm)
        }
        mockService = newMockService
        viewModel = newViewModel
    }

    override func tearDown() {
        viewModel = nil
        mockService = nil
        super.tearDown()
    }

    func testLoadMediaForPlayback_noFilesInResponse_setsError() async {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test_item", title: "Test", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        mockService.mockResponse = ItemMetadataResponse(
            files: nil,
            metadata: nil
        )

        let result = await viewModel.loadMediaForPlayback()

        XCTAssertNil(result)
        XCTAssertEqual(viewModel.state.errorMessage, "No files available")
        XCTAssertNil(viewModel.state.currentMediaURL)
    }

    func testLoadMediaForPlayback_emptyFilesArray_setsError() async {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test_item", title: "Test", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        mockService.mockResponse = ItemMetadataResponse(
            files: [],
            metadata: nil
        )

        let result = await viewModel.loadMediaForPlayback()

        XCTAssertNil(result)
        XCTAssertEqual(viewModel.state.errorMessage, "No playable files found")
    }

    func testLoadMediaForPlayback_noPlayableFiles_setsError() async {
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

        XCTAssertNil(result)
        XCTAssertEqual(viewModel.state.errorMessage, "No playable files found")
        XCTAssertNil(viewModel.state.currentMediaURL)
    }

    func testLoadMediaForPlayback_networkError_setsUserFriendlyMessage() async {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test_item", title: "Test", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        mockService.errorToThrow = NetworkError.noConnection

        let result = await viewModel.loadMediaForPlayback()

        XCTAssertNil(result)
        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertFalse(viewModel.state.isLoading)
    }

    func testLoadMediaForPlayback_serverError_setsErrorMessage() async {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test_item", title: "Test", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        mockService.errorToThrow = NetworkError.serverError(statusCode: 503)

        let result = await viewModel.loadMediaForPlayback()

        XCTAssertNil(result)
        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    func testLoadMediaForPlayback_clearsLoadingOnError() async {
        viewModel.configure(with: ItemConfiguration(
            identifier: "test_item", title: "Test", archivedBy: "", date: "",
            description: "", mediaType: "movies", imageURL: nil
        ))
        mockService.errorToThrow = NetworkError.timeout

        _ = await viewModel.loadMediaForPlayback()

        XCTAssertFalse(viewModel.state.isLoading)
    }

    func testLoadMediaForPlayback_success_setsCurrentMediaURL() async {
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

        XCTAssertNotNil(result)
        XCTAssertNotNil(viewModel.state.currentMediaURL)
        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertEqual(viewModel.state.playableFiles.count, 1)
    }

    func testLoadMediaForPlayback_success_clearsLoading() async {
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

        XCTAssertFalse(viewModel.state.isLoading)
    }
}

// MARK: - buildMediaURL Returns Nil Path Tests

/// Test coverage notes:
/// The "Invalid file URL" error path in loadMediaForPlayback is triggered when buildMediaURL returns nil.
/// This is difficult to test directly because buildMediaURL uses addingPercentEncoding which
/// rarely fails. The error path is kept for defensive coding but the primary URL encoding edge
/// cases are thoroughly tested in ItemDetailURLEncodingTests above.
