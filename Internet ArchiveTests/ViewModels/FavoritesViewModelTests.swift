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

    // MARK: - Case-Insensitive Media Type Tests

    func testLoadFavorites_caseInsensitive_uppercaseMovies() async {
        let item = FavoriteItem(identifier: "movie1", mediatype: "Movies", title: "Test")
        mockService.mockResponse = FavoritesResponse(members: [item])

        await viewModel.loadFavorites(username: "testuser")

        XCTAssertEqual(viewModel.state.movieItems.count, 1)
        XCTAssertEqual(viewModel.state.movieItems.first?.identifier, "movie1")
    }

    func testLoadFavorites_caseInsensitive_uppercaseETREE() async {
        let item = FavoriteItem(identifier: "concert1", mediatype: "ETREE", title: "Test")
        mockService.mockResponse = FavoritesResponse(members: [item])

        await viewModel.loadFavorites(username: "testuser")

        XCTAssertEqual(viewModel.state.musicItems.count, 1)
        XCTAssertEqual(viewModel.state.musicItems.first?.identifier, "concert1")
    }

    func testLoadFavorites_caseInsensitive_mixedCaseVideo() async {
        let item = FavoriteItem(identifier: "video1", mediatype: "Video", title: "Test")
        mockService.mockResponse = FavoritesResponse(members: [item])

        await viewModel.loadFavorites(username: "testuser")

        // "video" should be treated as movie type
        XCTAssertEqual(viewModel.state.movieItems.count, 1)
        XCTAssertEqual(viewModel.state.movieItems.first?.identifier, "video1")
    }

    func testLoadFavorites_caseInsensitive_uppercaseAUDIO() async {
        let item = FavoriteItem(identifier: "audio1", mediatype: "AUDIO", title: "Test")
        mockService.mockResponse = FavoritesResponse(members: [item])

        await viewModel.loadFavorites(username: "testuser")

        XCTAssertEqual(viewModel.state.musicItems.count, 1)
        XCTAssertEqual(viewModel.state.musicItems.first?.identifier, "audio1")
    }

    func testLoadFavorites_videoTreatedAsMovie() async {
        let videoItem = FavoriteItem(identifier: "video1", mediatype: "video", title: "Video Item")
        let movieItem = FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie Item")
        mockService.mockResponse = FavoritesResponse(members: [videoItem, movieItem])

        await viewModel.loadFavorites(username: "testuser")

        // Both video and movies should be in movieItems
        XCTAssertEqual(viewModel.state.movieItems.count, 2)
        XCTAssertTrue(viewModel.state.musicItems.isEmpty)
    }

    // MARK: - Unsupported Media Types Only Tests

    func testLoadFavoritesWithDetails_onlyUnsupportedTypes_skipsSearch() async {
        // All favorites have unsupported media types
        let textItem = FavoriteItem(identifier: "text1", mediatype: "texts", title: "Text")
        let imageItem = FavoriteItem(identifier: "image1", mediatype: "image", title: "Image")
        let webItem = FavoriteItem(identifier: "web1", mediatype: "web", title: "Web")
        mockService.mockResponse = FavoritesResponse(members: [textItem, imageItem, webItem])

        let mockSearchService = MockSearchService()

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        // Search should NOT be called when no supported types
        XCTAssertFalse(mockSearchService.searchCalled)

        // All state should be cleared/reset
        XCTAssertTrue(viewModel.state.allItems.isEmpty, "allItems should be cleared")
        XCTAssertTrue(viewModel.state.movieResults.isEmpty)
        XCTAssertTrue(viewModel.state.musicResults.isEmpty)
        XCTAssertTrue(viewModel.state.peopleResults.isEmpty)
        XCTAssertFalse(viewModel.state.isLoading)
    }

    func testLoadFavoritesWithDetails_nilMediaTypes_skipsSearch() async {
        // All favorites have nil media types
        let item1 = FavoriteItem(identifier: "item1", mediatype: nil, title: "Item 1")
        let item2 = FavoriteItem(identifier: "item2", mediatype: nil, title: "Item 2")
        mockService.mockResponse = FavoritesResponse(members: [item1, item2])

        let mockSearchService = MockSearchService()

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        // Search should NOT be called when no supported types
        XCTAssertFalse(mockSearchService.searchCalled)

        // All state should be cleared/reset
        XCTAssertTrue(viewModel.state.allItems.isEmpty, "allItems should be cleared")
        XCTAssertTrue(viewModel.state.movieResults.isEmpty)
        XCTAssertTrue(viewModel.state.musicResults.isEmpty)
        XCTAssertTrue(viewModel.state.peopleResults.isEmpty)
    }

    func testLoadFavoritesWithDetails_mixedSupportedAndUnsupported_onlyQueriesSupported() async {
        // Mix of supported and unsupported media types
        let movieItem = FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie")
        let textItem = FavoriteItem(identifier: "text1", mediatype: "texts", title: "Text")
        let audioItem = FavoriteItem(identifier: "audio1", mediatype: "audio", title: "Audio")
        mockService.mockResponse = FavoritesResponse(members: [movieItem, textItem, audioItem])

        let mockSearchService = MockSearchService()
        mockSearchService.mockResponse = TestFixtures.makeSearchResponse(numFound: 2, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "audio")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        // Search should be called
        XCTAssertTrue(mockSearchService.searchCalled)

        // Query should include supported types but not unsupported
        XCTAssertTrue(mockSearchService.lastQuery?.contains("movie1") ?? false)
        XCTAssertTrue(mockSearchService.lastQuery?.contains("audio1") ?? false)
        XCTAssertFalse(mockSearchService.lastQuery?.contains("text1") ?? true)
    }

    // MARK: - Case-Insensitive loadFavoritesWithDetails Tests

    func testLoadFavoritesWithDetails_caseInsensitive_uppercaseMOVIES() async {
        let item = FavoriteItem(identifier: "movie1", mediatype: "MOVIES", title: "Test")
        mockService.mockResponse = FavoritesResponse(members: [item])

        let mockSearchService = MockSearchService()
        mockSearchService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "MOVIES")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        // Should include the uppercase MOVIES item
        XCTAssertTrue(mockSearchService.searchCalled)
        XCTAssertTrue(mockSearchService.lastQuery?.contains("movie1") ?? false)
        XCTAssertEqual(viewModel.state.movieResults.count, 1)
    }

    func testLoadFavoritesWithDetails_caseInsensitive_mixedCaseVideo() async {
        let item = FavoriteItem(identifier: "video1", mediatype: "Video", title: "Test")
        mockService.mockResponse = FavoritesResponse(members: [item])

        let mockSearchService = MockSearchService()
        mockSearchService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "video1", mediatype: "Video")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        // "Video" should be treated as movies (case-insensitive)
        XCTAssertTrue(mockSearchService.searchCalled)
        XCTAssertTrue(mockSearchService.lastQuery?.contains("video1") ?? false)
        XCTAssertEqual(viewModel.state.movieResults.count, 1)
    }

    func testLoadFavoritesWithDetails_caseInsensitive_uppercaseETREE() async {
        let item = FavoriteItem(identifier: "concert1", mediatype: "ETREE", title: "Test")
        mockService.mockResponse = FavoritesResponse(members: [item])

        let mockSearchService = MockSearchService()
        mockSearchService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "concert1", mediatype: "ETREE")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        // "ETREE" should be treated as music (case-insensitive)
        XCTAssertTrue(mockSearchService.searchCalled)
        XCTAssertTrue(mockSearchService.lastQuery?.contains("concert1") ?? false)
        XCTAssertEqual(viewModel.state.musicResults.count, 1)
    }

    func testLoadFavoritesWithDetails_caseInsensitive_uppercaseAUDIO() async {
        let item = FavoriteItem(identifier: "audio1", mediatype: "AUDIO", title: "Test")
        mockService.mockResponse = FavoritesResponse(members: [item])

        let mockSearchService = MockSearchService()
        mockSearchService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "AUDIO")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        // "AUDIO" should be treated as music (case-insensitive)
        XCTAssertTrue(mockSearchService.searchCalled)
        XCTAssertTrue(mockSearchService.lastQuery?.contains("audio1") ?? false)
        XCTAssertEqual(viewModel.state.musicResults.count, 1)
    }

    func testLoadFavoritesWithDetails_caseInsensitive_uppercaseACCOUNT() async {
        let item = FavoriteItem(identifier: "person1", mediatype: "ACCOUNT", title: "Test Person")
        mockService.mockResponse = FavoritesResponse(members: [item])

        let mockSearchService = MockSearchService()
        mockSearchService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "person1", mediatype: "ACCOUNT")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        // "ACCOUNT" should be categorized into peopleResults (case-insensitive)
        XCTAssertTrue(mockSearchService.searchCalled)
        XCTAssertTrue(mockSearchService.lastQuery?.contains("person1") ?? false)
        XCTAssertEqual(viewModel.state.peopleResults.count, 1)
    }

    func testLoadFavoritesWithDetails_videoAndEtreeTypesIncluded() async {
        // Test that "video" and "etree" types are included as supported types
        let videoItem = FavoriteItem(identifier: "video1", mediatype: "video", title: "Video Item")
        let etreeItem = FavoriteItem(identifier: "etree1", mediatype: "etree", title: "Etree Item")
        mockService.mockResponse = FavoritesResponse(members: [videoItem, etreeItem])

        let mockSearchService = MockSearchService()
        mockSearchService.mockResponse = TestFixtures.makeSearchResponse(numFound: 2, docs: [
            TestFixtures.makeSearchResult(identifier: "video1", mediatype: "video"),
            TestFixtures.makeSearchResult(identifier: "etree1", mediatype: "etree")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        // Both should be queried
        XCTAssertTrue(mockSearchService.searchCalled)
        XCTAssertTrue(mockSearchService.lastQuery?.contains("video1") ?? false)
        XCTAssertTrue(mockSearchService.lastQuery?.contains("etree1") ?? false)

        // video categorized as movies, etree categorized as music
        XCTAssertEqual(viewModel.state.movieResults.count, 1)
        XCTAssertEqual(viewModel.state.musicResults.count, 1)
    }

    func testLoadFavoritesWithDetails_unknownMediatypeIgnored() async {
        // Test that unknown mediatypes from API are ignored (guards against future API changes)
        let movieItem = FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie")
        let unknownItem = FavoriteItem(identifier: "unknown1", mediatype: "software", title: "Software Item")
        let anotherUnknown = FavoriteItem(identifier: "unknown2", mediatype: "web", title: "Web Archive")
        mockService.mockResponse = FavoritesResponse(members: [movieItem, unknownItem, anotherUnknown])

        let mockSearchService = MockSearchService()
        // Simulate API returning results including unknown types
        mockSearchService.mockResponse = TestFixtures.makeSearchResponse(numFound: 3, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "unknown1", mediatype: "software"),
            TestFixtures.makeSearchResult(identifier: "unknown2", mediatype: "web")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        // Only the known mediatype should be queried (unknown types filtered out during query construction)
        XCTAssertTrue(mockSearchService.searchCalled)
        XCTAssertTrue(mockSearchService.lastQuery?.contains("movie1") ?? false)
        XCTAssertFalse(mockSearchService.lastQuery?.contains("unknown1") ?? true)
        XCTAssertFalse(mockSearchService.lastQuery?.contains("unknown2") ?? true)

        // Only the movie should be categorized
        XCTAssertEqual(viewModel.state.movieResults.count, 1)
        XCTAssertEqual(viewModel.state.musicResults.count, 0)
        XCTAssertEqual(viewModel.state.peopleResults.count, 0)

        // Verify the movie is the correct one
        XCTAssertEqual(viewModel.state.movieResults.first?.identifier, "movie1")
    }

    // MARK: - State Reset Between Calls Tests

    func testLoadFavoritesWithDetails_resetsStateBetweenCalls() async {
        // First call with movies
        let movieItem = FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie")
        mockService.mockResponse = FavoritesResponse(members: [movieItem])

        let mockSearchService1 = MockSearchService()
        mockSearchService1.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService1
        )

        XCTAssertEqual(viewModel.state.movieResults.count, 1)
        XCTAssertEqual(viewModel.state.musicResults.count, 0)

        // Second call with only music (no movies)
        let musicItem = FavoriteItem(identifier: "music1", mediatype: "etree", title: "Music")
        mockService.mockResponse = FavoritesResponse(members: [musicItem])

        let mockSearchService2 = MockSearchService()
        mockSearchService2.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "music1", mediatype: "etree")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService2
        )

        // Movie results should be cleared from previous call
        XCTAssertEqual(viewModel.state.movieResults.count, 0)
        XCTAssertEqual(viewModel.state.musicResults.count, 1)
    }

    func testLoadFavoritesWithDetails_clearsErrorOnNewCall() async {
        // First call with error
        mockService.errorToThrow = NetworkError.timeout

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: MockSearchService()
        )

        XCTAssertNotNil(viewModel.state.errorMessage)

        // Second call succeeds
        mockService.errorToThrow = nil
        let movieItem = FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie")
        mockService.mockResponse = FavoritesResponse(members: [movieItem])

        let mockSearchService = MockSearchService()
        mockSearchService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        // Error should be cleared
        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertEqual(viewModel.state.movieResults.count, 1)
    }

    func testLoadFavoritesWithDetails_emptyResponse_clearsAllResults() async {
        // First call with results
        let movieItem = FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie")
        mockService.mockResponse = FavoritesResponse(members: [movieItem])

        let mockSearchService1 = MockSearchService()
        mockSearchService1.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService1
        )

        XCTAssertEqual(viewModel.state.movieResults.count, 1)

        // Second call with empty favorites
        mockService.mockResponse = FavoritesResponse(members: [])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: MockSearchService()
        )

        // All results should be cleared
        XCTAssertEqual(viewModel.state.movieResults.count, 0)
        XCTAssertEqual(viewModel.state.musicResults.count, 0)
        XCTAssertEqual(viewModel.state.peopleResults.count, 0)
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
