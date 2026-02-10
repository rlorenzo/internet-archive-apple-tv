//
//  PeopleViewModelTests.swift
//  Internet ArchiveTests
//
//  Unit tests for PeopleViewModel
//

import XCTest
@testable import Internet_Archive

// MARK: - Mock People Favorites Service

final class MockPeopleFavoritesService: PeopleFavoritesServiceProtocol, @unchecked Sendable {
    var getFavoriteItemsCalled = false
    var searchCalled = false
    var lastUsername: String?
    var lastQuery: String?
    var lastOptions: [String: String]?
    var mockFavoritesResponse: FavoritesResponse?
    var mockSearchResponse: SearchResponse?
    var errorToThrow: Error?

    func getFavoriteItems(username: String) async throws -> FavoritesResponse {
        getFavoriteItemsCalled = true
        lastUsername = username

        if let error = errorToThrow {
            throw error
        }

        guard let response = mockFavoritesResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

    func search(query: String, options: [String: String]) async throws -> SearchResponse {
        searchCalled = true
        lastQuery = query
        lastOptions = options

        if let error = errorToThrow {
            throw error
        }

        guard let response = mockSearchResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

    func reset() {
        getFavoriteItemsCalled = false
        searchCalled = false
        lastUsername = nil
        lastQuery = nil
        lastOptions = nil
        mockFavoritesResponse = nil
        mockSearchResponse = nil
        errorToThrow = nil
    }
}

// MARK: - PeopleViewModel Tests

@MainActor
final class PeopleViewModelTests: XCTestCase {

    nonisolated(unsafe) var viewModel: PeopleViewModel!
    nonisolated(unsafe) var mockService: MockPeopleFavoritesService!

    override func setUp() {
        super.setUp()
        let (newMockService, newViewModel) = MainActor.assumeIsolated {
            let service = MockPeopleFavoritesService()
            let vm = PeopleViewModel(favoritesService: service)
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

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertTrue(viewModel.state.identifier.isEmpty)
        XCTAssertTrue(viewModel.state.name.isEmpty)
        XCTAssertTrue(viewModel.state.movieItems.isEmpty)
        XCTAssertTrue(viewModel.state.musicItems.isEmpty)
        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertFalse(viewModel.state.hasItems)
        XCTAssertEqual(viewModel.state.totalItemCount, 0)
    }

    // MARK: - Configure Tests

    func testConfigure() {
        viewModel.configure(identifier: "@testuser", name: "Test User")

        XCTAssertEqual(viewModel.state.identifier, "@testuser")
        XCTAssertEqual(viewModel.state.name, "Test User")
    }

    // MARK: - Username Extraction Tests

    func testUsername_withAtPrefix() {
        viewModel.configure(identifier: "@testuser", name: "Test")
        XCTAssertEqual(viewModel.state.username, "testuser")
    }

    func testUsername_withoutAtPrefix() {
        viewModel.configure(identifier: "testuser", name: "Test")
        XCTAssertEqual(viewModel.state.username, "testuser")
    }

    func testUsername_empty() {
        XCTAssertEqual(viewModel.state.username, "")
    }

    // MARK: - Load Favorites Tests

    func testLoadFavorites_emptyIdentifier_setsError() async {
        await viewModel.loadFavorites()

        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.errorMessage?.contains("Missing") ?? false)
    }

    func testLoadFavorites_callsService() async {
        viewModel.configure(identifier: "@testuser", name: "Test")
        mockService.mockFavoritesResponse = FavoritesResponse(members: [])

        await viewModel.loadFavorites()

        XCTAssertTrue(mockService.getFavoriteItemsCalled)
        XCTAssertEqual(mockService.lastUsername, "testuser")
    }

    func testLoadFavorites_emptyFavorites_returnsEarly() async {
        viewModel.configure(identifier: "@testuser", name: "Test")
        mockService.mockFavoritesResponse = FavoritesResponse(members: [])

        await viewModel.loadFavorites()

        XCTAssertTrue(mockService.getFavoriteItemsCalled)
        XCTAssertFalse(mockService.searchCalled) // Should not call search
        XCTAssertFalse(viewModel.state.isLoading)
    }

    func testLoadFavorites_noSupportedMediaTypes_returnsEarly() async {
        viewModel.configure(identifier: "@testuser", name: "Test")
        mockService.mockFavoritesResponse = FavoritesResponse(members: [
            FavoriteItem(identifier: "text1", mediatype: "texts", title: "Text Item")
        ])

        await viewModel.loadFavorites()

        XCTAssertTrue(mockService.getFavoriteItemsCalled)
        XCTAssertFalse(mockService.searchCalled) // Should not call search
    }

    func testLoadFavorites_categorizesByMediaType() async {
        viewModel.configure(identifier: "@testuser", name: "Test")

        mockService.mockFavoritesResponse = FavoritesResponse(members: [
            FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie"),
            FavoriteItem(identifier: "audio1", mediatype: "audio", title: "Audio")
        ])

        mockService.mockSearchResponse = TestFixtures.makeSearchResponse(numFound: 2, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "audio")
        ])

        await viewModel.loadFavorites()

        XCTAssertEqual(viewModel.state.movieItems.count, 1)
        XCTAssertEqual(viewModel.state.musicItems.count, 1)
    }

    func testLoadFavorites_withError_setsErrorMessage() async {
        viewModel.configure(identifier: "@testuser", name: "Test")
        mockService.errorToThrow = NetworkError.timeout

        await viewModel.loadFavorites()

        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    // MARK: - Filter Supported Identifiers Tests

    func testFilterSupportedIdentifiers_moviesAndAudio() {
        let favorites = [
            FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie"),
            FavoriteItem(identifier: "audio1", mediatype: "audio", title: "Audio"),
            FavoriteItem(identifier: "text1", mediatype: "texts", title: "Text")
        ]

        let result = viewModel.filterSupportedIdentifiers(favorites)

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains("movie1"))
        XCTAssertTrue(result.contains("audio1"))
        XCTAssertFalse(result.contains("text1"))
    }

    func testFilterSupportedIdentifiers_emptyArray() {
        let result = viewModel.filterSupportedIdentifiers([])
        XCTAssertTrue(result.isEmpty)
    }

    func testFilterSupportedIdentifiers_noSupportedTypes() {
        let favorites = [
            FavoriteItem(identifier: "text1", mediatype: "texts", title: "Text"),
            FavoriteItem(identifier: "image1", mediatype: "image", title: "Image")
        ]

        let result = viewModel.filterSupportedIdentifiers(favorites)
        XCTAssertTrue(result.isEmpty)
    }

    func testFilterSupportedIdentifiers_nilMediaType() {
        let favorites = [
            FavoriteItem(identifier: "nil1", mediatype: nil, title: "No Type")
        ]

        let result = viewModel.filterSupportedIdentifiers(favorites)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Categorize By Media Type Tests

    func testCategorizeByMediaType_separatesCorrectly() {
        let items = [
            TestFixtures.makeSearchResult(identifier: "m1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "m2", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "a1", mediatype: "audio")
        ]

        let result = viewModel.categorizeByMediaType(items)

        XCTAssertEqual(result.movies.count, 2)
        XCTAssertEqual(result.music.count, 1)
    }

    func testCategorizeByMediaType_ignoresOtherTypes() {
        let items = [
            TestFixtures.makeSearchResult(identifier: "m1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "t1", mediatype: "texts")
        ]

        let result = viewModel.categorizeByMediaType(items)

        XCTAssertEqual(result.movies.count, 1)
        XCTAssertEqual(result.music.count, 0)
    }

    func testCategorizeByMediaType_emptyArray() {
        let result = viewModel.categorizeByMediaType([])

        XCTAssertTrue(result.movies.isEmpty)
        XCTAssertTrue(result.music.isEmpty)
    }

    // MARK: - Item Access Tests

    func testMovieItemAtIndex_valid() async {
        viewModel.configure(identifier: "@testuser", name: "Test")

        mockService.mockFavoritesResponse = FavoritesResponse(members: [
            FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie")
        ])

        mockService.mockSearchResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies")
        ])

        await viewModel.loadFavorites()

        let item = viewModel.movieItem(at: 0)
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.identifier, "movie1")
    }

    func testMovieItemAtIndex_invalid() {
        XCTAssertNil(viewModel.movieItem(at: 0))
        XCTAssertNil(viewModel.movieItem(at: -1))
    }

    func testMusicItemAtIndex_valid() async {
        viewModel.configure(identifier: "@testuser", name: "Test")

        mockService.mockFavoritesResponse = FavoritesResponse(members: [
            FavoriteItem(identifier: "audio1", mediatype: "audio", title: "Audio")
        ])

        mockService.mockSearchResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "audio")
        ])

        await viewModel.loadFavorites()

        let item = viewModel.musicItem(at: 0)
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.identifier, "audio1")
    }

    func testMusicItemAtIndex_invalid() {
        XCTAssertNil(viewModel.musicItem(at: 0))
        XCTAssertNil(viewModel.musicItem(at: -1))
    }

    // MARK: - Build Navigation Data Tests

    func testBuildItemNavigationData() {
        let item = TestFixtures.makeSearchResult(
            identifier: "test_nav",
            title: "Test Title",
            mediatype: "movies",
            creator: "Test Creator"
        )

        let navData = viewModel.buildItemNavigationData(for: item)

        XCTAssertEqual(navData.identifier, "test_nav")
        XCTAssertEqual(navData.title, "Test Title")
        XCTAssertEqual(navData.archivedBy, "Test Creator")
        XCTAssertEqual(navData.mediaType, "movies")
        XCTAssertNotNil(navData.imageURL)
        XCTAssertTrue(navData.imageURL?.absoluteString.contains("test_nav") ?? false)
    }

    func testBuildItemNavigationData_withNilValues() {
        let item = TestFixtures.makeSearchResult(
            identifier: "test",
            title: nil,
            mediatype: nil,
            creator: nil
        )

        let navData = viewModel.buildItemNavigationData(for: item)

        XCTAssertEqual(navData.identifier, "test")
        XCTAssertEqual(navData.title, "")
        XCTAssertEqual(navData.archivedBy, "")
        XCTAssertEqual(navData.mediaType, "")
    }

    // MARK: - Clear Error Tests

    func testClearError() async {
        viewModel.configure(identifier: "@testuser", name: "Test")
        mockService.errorToThrow = NetworkError.timeout
        await viewModel.loadFavorites()

        XCTAssertNotNil(viewModel.state.errorMessage)

        viewModel.clearError()

        XCTAssertNil(viewModel.state.errorMessage)
    }
}

// MARK: - PeopleViewState Tests

final class PeopleViewStateTests: XCTestCase {

    func testInitialState() {
        let state = PeopleViewState.initial

        XCTAssertFalse(state.isLoading)
        XCTAssertTrue(state.identifier.isEmpty)
        XCTAssertTrue(state.name.isEmpty)
        XCTAssertTrue(state.movieItems.isEmpty)
        XCTAssertTrue(state.musicItems.isEmpty)
        XCTAssertNil(state.errorMessage)
    }

    func testHasItems_whenEmpty() {
        let state = PeopleViewState.initial
        XCTAssertFalse(state.hasItems)
    }

    func testHasItems_whenHasMovies() {
        var state = PeopleViewState.initial
        state.movieItems = [TestFixtures.makeSearchResult(identifier: "m1")]
        XCTAssertTrue(state.hasItems)
    }

    func testHasItems_whenHasMusic() {
        var state = PeopleViewState.initial
        state.musicItems = [TestFixtures.makeSearchResult(identifier: "a1")]
        XCTAssertTrue(state.hasItems)
    }

    func testTotalItemCount() {
        var state = PeopleViewState.initial
        state.movieItems = [
            TestFixtures.makeSearchResult(identifier: "m1"),
            TestFixtures.makeSearchResult(identifier: "m2")
        ]
        state.musicItems = [
            TestFixtures.makeSearchResult(identifier: "a1")
        ]

        XCTAssertEqual(state.totalItemCount, 3)
    }

    func testUsername_withAtPrefix() {
        var state = PeopleViewState.initial
        state.identifier = "@testuser"
        XCTAssertEqual(state.username, "testuser")
    }

    func testUsername_withoutAtPrefix() {
        var state = PeopleViewState.initial
        state.identifier = "testuser"
        XCTAssertEqual(state.username, "testuser")
    }

    func testUsername_empty() {
        let state = PeopleViewState.initial
        XCTAssertEqual(state.username, "")
    }
}
