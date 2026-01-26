//
//  FavoritesViewModelTests.swift
//  Internet ArchiveTests
//
//  Unit tests for FavoritesViewModel
//

import XCTest
@testable import Internet_Archive

// MARK: - Mock Favorites Service

final class MockFavoritesService: FavoritesServiceProtocol, @unchecked Sendable {
    var getFavoriteItemsCalled = false
    var lastUsername: String?
    var mockResponse: FavoritesResponse?
    var errorToThrow: Error?

    func getFavoriteItems(username: String) async throws -> FavoritesResponse {
        getFavoriteItemsCalled = true
        lastUsername = username

        if let error = errorToThrow {
            throw error
        }

        guard let response = mockResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

    func reset() {
        getFavoriteItemsCalled = false
        lastUsername = nil
        mockResponse = nil
        errorToThrow = nil
    }
}

// MARK: - FavoritesViewModel Tests

@MainActor
final class FavoritesViewModelTests: XCTestCase {

    nonisolated(unsafe) var viewModel: FavoritesViewModel!
    nonisolated(unsafe) var mockService: MockFavoritesService!

    override func setUp() {
        super.setUp()
        let (newMockService, newViewModel) = MainActor.assumeIsolated {
            let service = MockFavoritesService()
            let vm = FavoritesViewModel(favoritesService: service)
            // Clean up favorites
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

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertTrue(viewModel.state.allItems.isEmpty)
        XCTAssertTrue(viewModel.state.movieItems.isEmpty)
        XCTAssertTrue(viewModel.state.musicItems.isEmpty)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    // MARK: - Load Favorites Tests

    func testLoadFavorites_callsService() async {
        mockService.mockResponse = TestFixtures.favoritesResponse

        await viewModel.loadFavorites(username: "testuser")

        XCTAssertTrue(mockService.getFavoriteItemsCalled)
        XCTAssertEqual(mockService.lastUsername, "testuser")
    }

    func testLoadFavorites_updatesState() async {
        mockService.mockResponse = TestFixtures.favoritesResponse

        await viewModel.loadFavorites(username: "testuser")

        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertFalse(viewModel.state.allItems.isEmpty)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    func testLoadFavorites_emptyUsername_setsError() async {
        await viewModel.loadFavorites(username: "")

        XCTAssertFalse(mockService.getFavoriteItemsCalled)
        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.errorMessage?.contains("log in") ?? false)
    }

    func testLoadFavorites_withError_setsErrorMessage() async {
        mockService.errorToThrow = NetworkError.timeout

        await viewModel.loadFavorites(username: "testuser")

        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    func testLoadFavorites_filtersMovies() async {
        let movieItem = FavoriteItem(
            identifier: "movie1",
            mediatype: "movies",
            title: "Test Movie"
        )
        let audioItem = FavoriteItem(
            identifier: "audio1",
            mediatype: "audio",
            title: "Test Audio"
        )
        mockService.mockResponse = FavoritesResponse(members: [movieItem, audioItem])

        await viewModel.loadFavorites(username: "testuser")

        XCTAssertEqual(viewModel.state.movieItems.count, 1)
        XCTAssertEqual(viewModel.state.movieItems.first?.identifier, "movie1")
    }

    func testLoadFavorites_filtersMusic() async {
        let audioItem = FavoriteItem(
            identifier: "audio1",
            mediatype: "audio",
            title: "Test Audio"
        )
        let etreeItem = FavoriteItem(
            identifier: "etree1",
            mediatype: "etree",
            title: "Live Concert"
        )
        mockService.mockResponse = FavoritesResponse(members: [audioItem, etreeItem])

        await viewModel.loadFavorites(username: "testuser")

        XCTAssertEqual(viewModel.state.musicItems.count, 2)
    }

    // MARK: - Favorite Management Tests

    func testIsFavorite_whenNotFavorite() {
        let result = viewModel.isFavorite(identifier: "unknown_item")
        XCTAssertFalse(result)
    }

    func testAddFavorite() {
        viewModel.addFavorite(identifier: "test_item")

        XCTAssertTrue(viewModel.isFavorite(identifier: "test_item"))
    }

    func testRemoveFavorite() {
        viewModel.addFavorite(identifier: "test_item")
        viewModel.removeFavorite(identifier: "test_item")

        XCTAssertFalse(viewModel.isFavorite(identifier: "test_item"))
    }

    func testToggleFavorite_addsWhenNotFavorite() {
        let result = viewModel.toggleFavorite(identifier: "toggle_item")

        XCTAssertTrue(result)
        XCTAssertTrue(viewModel.isFavorite(identifier: "toggle_item"))
    }

    func testToggleFavorite_removesWhenFavorite() {
        viewModel.addFavorite(identifier: "toggle_item")

        let result = viewModel.toggleFavorite(identifier: "toggle_item")

        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.isFavorite(identifier: "toggle_item"))
    }

    // MARK: - Clear Favorites Tests

    func testClearFavorites() {
        viewModel.addFavorite(identifier: "item1")
        viewModel.addFavorite(identifier: "item2")

        viewModel.clearFavorites()

        XCTAssertEqual(viewModel.favoritesCount, 0)
    }

    // MARK: - Count Tests

    func testFavoritesCount() {
        viewModel.addFavorite(identifier: "item1")
        viewModel.addFavorite(identifier: "item2")
        viewModel.addFavorite(identifier: "item3")

        XCTAssertEqual(viewModel.favoritesCount, 3)
    }

    func testMovieFavoritesCount() async {
        let movieItem = FavoriteItem(
            identifier: "movie1",
            mediatype: "movies",
            title: "Test Movie"
        )
        mockService.mockResponse = FavoritesResponse(members: [movieItem])

        await viewModel.loadFavorites(username: "testuser")

        XCTAssertEqual(viewModel.movieFavoritesCount, 1)
    }

    func testMusicFavoritesCount() async {
        let audioItem = FavoriteItem(
            identifier: "audio1",
            mediatype: "audio",
            title: "Test Audio"
        )
        mockService.mockResponse = FavoritesResponse(members: [audioItem])

        await viewModel.loadFavorites(username: "testuser")

        XCTAssertEqual(viewModel.musicFavoritesCount, 1)
    }

    // MARK: - Load Favorites With Details Tests

    func testLoadFavoritesWithDetails_callsServicesInOrder() async {
        let movieFavorite = FavoriteItem(
            identifier: "movie1",
            mediatype: "movies",
            title: "Test Movie"
        )
        mockService.mockResponse = FavoritesResponse(members: [movieFavorite])

        let mockSearchService = MockSearchService()
        mockSearchService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        XCTAssertTrue(mockService.getFavoriteItemsCalled)
        XCTAssertTrue(mockSearchService.searchCalled)
    }

    func testLoadFavoritesWithDetails_categorizesByMediaType() async {
        let movieFavorite = FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie")
        let audioFavorite = FavoriteItem(identifier: "audio1", mediatype: "audio", title: "Audio")
        let accountFavorite = FavoriteItem(identifier: "person1", mediatype: "account", title: "Person")

        mockService.mockResponse = FavoritesResponse(members: [movieFavorite, audioFavorite, accountFavorite])

        let mockSearchService = MockSearchService()
        mockSearchService.mockResponse = TestFixtures.makeSearchResponse(numFound: 3, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "audio"),
            TestFixtures.makeSearchResult(identifier: "person1", mediatype: "account")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        XCTAssertEqual(viewModel.state.movieResults.count, 1)
        XCTAssertEqual(viewModel.state.musicResults.count, 1)
        XCTAssertEqual(viewModel.state.peopleResults.count, 1)
    }

    func testLoadFavoritesWithDetails_emptyUsername_setsError() async {
        let mockSearchService = MockSearchService()

        await viewModel.loadFavoritesWithDetails(
            username: "",
            searchService: mockSearchService
        )

        XCTAssertFalse(mockService.getFavoriteItemsCalled)
        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    func testLoadFavoritesWithDetails_emptyFavorites_returnsEarly() async {
        mockService.mockResponse = FavoritesResponse(members: [])

        let mockSearchService = MockSearchService()

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        XCTAssertTrue(mockService.getFavoriteItemsCalled)
        XCTAssertFalse(mockSearchService.searchCalled)
        XCTAssertFalse(viewModel.state.isLoading)
    }

    func testLoadFavoritesWithDetails_filtersSupportedMediaTypes() async {
        let movieFavorite = FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie")
        let textFavorite = FavoriteItem(identifier: "text1", mediatype: "texts", title: "Text") // Not supported
        let imageFavorite = FavoriteItem(identifier: "image1", mediatype: "image", title: "Image") // Not supported

        mockService.mockResponse = FavoritesResponse(members: [movieFavorite, textFavorite, imageFavorite])

        let mockSearchService = MockSearchService()
        mockSearchService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        // Should only query for supported media types
        XCTAssertTrue(mockSearchService.lastQuery?.contains("movie1") ?? false)
        XCTAssertFalse(mockSearchService.lastQuery?.contains("text1") ?? true)
    }

    func testLoadFavoritesWithDetails_withError_setsErrorMessage() async {
        mockService.errorToThrow = NetworkError.timeout

        let mockSearchService = MockSearchService()

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertFalse(viewModel.state.isLoading)
    }

    func testPeopleFavoritesCount() async {
        let accountItem = FavoriteItem(
            identifier: "person1",
            mediatype: "account",
            title: "Test Person"
        )
        mockService.mockResponse = FavoritesResponse(members: [accountItem])

        let mockSearchService = MockSearchService()
        mockSearchService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "person1", mediatype: "account")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        XCTAssertEqual(viewModel.peopleFavoritesCount, 1)
    }
}

// MARK: - FavoritesViewState Tests

final class FavoritesViewStateTests: XCTestCase {

    func testInitialState() {
        let state = FavoritesViewState.initial

        XCTAssertFalse(state.isLoading)
        XCTAssertTrue(state.allItems.isEmpty)
        XCTAssertTrue(state.movieItems.isEmpty)
        XCTAssertTrue(state.musicItems.isEmpty)
        XCTAssertNil(state.errorMessage)
    }

    func testHasResults_whenEmpty() {
        let state = FavoritesViewState.initial
        XCTAssertFalse(state.hasResults)
    }

    func testHasResults_whenHasMovies() {
        var state = FavoritesViewState.initial
        state.movieResults = [TestFixtures.makeSearchResult(identifier: "1")]
        XCTAssertTrue(state.hasResults)
    }

    func testHasResults_whenHasMusic() {
        var state = FavoritesViewState.initial
        state.musicResults = [TestFixtures.makeSearchResult(identifier: "1")]
        XCTAssertTrue(state.hasResults)
    }

    func testHasResults_whenHasPeople() {
        var state = FavoritesViewState.initial
        state.peopleResults = [TestFixtures.makeSearchResult(identifier: "1")]
        XCTAssertTrue(state.hasResults)
    }
}
