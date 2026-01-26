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
