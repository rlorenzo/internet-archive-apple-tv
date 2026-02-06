//
//  FavoritesViewModelTests.swift
//  Internet ArchiveTests
//
//  Unit tests for FavoritesViewModel
//

import Testing
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

@Suite("FavoritesViewModel Tests", .serialized)
@MainActor
struct FavoritesViewModelTests {

    var viewModel: FavoritesViewModel
    var mockService: MockFavoritesService

    init() {
        let service = MockFavoritesService()
        mockService = service
        viewModel = FavoritesViewModel(favoritesService: service)
        Global.resetFavoriteData()
    }

    // MARK: - Initial State Tests

    @Test func initialState() {
        #expect(!viewModel.state.isLoading)
        #expect(viewModel.state.allItems.isEmpty)
        #expect(viewModel.state.movieItems.isEmpty)
        #expect(viewModel.state.musicItems.isEmpty)
        #expect(viewModel.state.errorMessage == nil)
    }

    // MARK: - Load Favorites Tests

    @Test func loadFavoritesCallsService() async {
        mockService.mockResponse = TestFixtures.favoritesResponse

        await viewModel.loadFavorites(username: "testuser")

        #expect(mockService.getFavoriteItemsCalled)
        #expect(mockService.lastUsername == "testuser")
    }

    @Test func loadFavoritesUpdatesState() async {
        mockService.mockResponse = TestFixtures.favoritesResponse

        await viewModel.loadFavorites(username: "testuser")

        #expect(!viewModel.state.isLoading)
        #expect(!viewModel.state.allItems.isEmpty)
        #expect(viewModel.state.errorMessage == nil)
    }

    @Test func loadFavoritesEmptyUsernameSetsError() async {
        await viewModel.loadFavorites(username: "")

        #expect(!mockService.getFavoriteItemsCalled)
        #expect(viewModel.state.errorMessage != nil)
        #expect(viewModel.state.errorMessage?.contains("log in") ?? false)
    }

    @Test func loadFavoritesWithErrorSetsErrorMessage() async {
        mockService.errorToThrow = NetworkError.timeout

        await viewModel.loadFavorites(username: "testuser")

        #expect(!viewModel.state.isLoading)
        #expect(viewModel.state.errorMessage != nil)
    }

    @Test func loadFavoritesFiltersMovies() async {
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

        #expect(viewModel.state.movieItems.count == 1)
        #expect(viewModel.state.movieItems.first?.identifier == "movie1")
    }

    @Test func loadFavoritesFiltersMusic() async {
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

        #expect(viewModel.state.musicItems.count == 2)
    }

    // MARK: - Favorite Management Tests

    @Test func isFavoriteWhenNotFavorite() {
        let result = viewModel.isFavorite(identifier: "unknown_item")
        #expect(!result)
    }

    @Test func addFavorite() {
        viewModel.addFavorite(identifier: "test_item")

        #expect(viewModel.isFavorite(identifier: "test_item"))
        Global.resetFavoriteData()
    }

    @Test func removeFavorite() {
        viewModel.addFavorite(identifier: "test_item")
        viewModel.removeFavorite(identifier: "test_item")

        #expect(!viewModel.isFavorite(identifier: "test_item"))
        Global.resetFavoriteData()
    }

    @Test func toggleFavoriteAddsWhenNotFavorite() {
        let result = viewModel.toggleFavorite(identifier: "toggle_item")

        #expect(result)
        #expect(viewModel.isFavorite(identifier: "toggle_item"))
        Global.resetFavoriteData()
    }

    @Test func toggleFavoriteRemovesWhenFavorite() {
        viewModel.addFavorite(identifier: "toggle_item")

        let result = viewModel.toggleFavorite(identifier: "toggle_item")

        #expect(!result)
        #expect(!viewModel.isFavorite(identifier: "toggle_item"))
        Global.resetFavoriteData()
    }

    // MARK: - Clear Favorites Tests

    @Test func clearFavorites() {
        viewModel.addFavorite(identifier: "item1")
        viewModel.addFavorite(identifier: "item2")

        viewModel.clearFavorites()

        #expect(viewModel.favoritesCount == 0)
        Global.resetFavoriteData()
    }

    // MARK: - Count Tests

    @Test func favoritesCount() {
        viewModel.addFavorite(identifier: "item1")
        viewModel.addFavorite(identifier: "item2")
        viewModel.addFavorite(identifier: "item3")

        #expect(viewModel.favoritesCount == 3)
        Global.resetFavoriteData()
    }

    @Test func movieFavoritesCount() async {
        let movieItem = FavoriteItem(
            identifier: "movie1",
            mediatype: "movies",
            title: "Test Movie"
        )
        mockService.mockResponse = FavoritesResponse(members: [movieItem])

        await viewModel.loadFavorites(username: "testuser")

        #expect(viewModel.movieFavoritesCount == 1)
    }

    @Test func musicFavoritesCount() async {
        let audioItem = FavoriteItem(
            identifier: "audio1",
            mediatype: "audio",
            title: "Test Audio"
        )
        mockService.mockResponse = FavoritesResponse(members: [audioItem])

        await viewModel.loadFavorites(username: "testuser")

        #expect(viewModel.musicFavoritesCount == 1)
    }

    // MARK: - Load Favorites With Details Tests

    @Test func loadFavoritesWithDetailsCallsServicesInOrder() async {
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

        #expect(mockService.getFavoriteItemsCalled)
        #expect(mockSearchService.searchCalled)
    }

    @Test func loadFavoritesWithDetailsCategorizesByMediaType() async {
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

        #expect(viewModel.state.movieResults.count == 1)
        #expect(viewModel.state.musicResults.count == 1)
        #expect(viewModel.state.peopleResults.count == 1)
    }

    @Test func loadFavoritesWithDetailsEmptyUsernameSetsError() async {
        let mockSearchService = MockSearchService()

        await viewModel.loadFavoritesWithDetails(
            username: "",
            searchService: mockSearchService
        )

        #expect(!mockService.getFavoriteItemsCalled)
        #expect(viewModel.state.errorMessage != nil)
    }

    @Test func loadFavoritesWithDetailsEmptyFavoritesReturnsEarly() async {
        mockService.mockResponse = FavoritesResponse(members: [])

        let mockSearchService = MockSearchService()

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        #expect(mockService.getFavoriteItemsCalled)
        #expect(!mockSearchService.searchCalled)
        #expect(!viewModel.state.isLoading)
    }

    @Test func loadFavoritesWithDetailsFiltersSupportedMediaTypes() async {
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
        #expect(mockSearchService.lastQuery?.contains("movie1") ?? false)
        #expect(!(mockSearchService.lastQuery?.contains("text1") ?? true))
    }

    @Test func loadFavoritesWithDetailsWithErrorSetsErrorMessage() async {
        mockService.errorToThrow = NetworkError.timeout

        let mockSearchService = MockSearchService()

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        #expect(viewModel.state.errorMessage != nil)
        #expect(!viewModel.state.isLoading)
    }

    @Test func peopleFavoritesCount() async {
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

        #expect(viewModel.peopleFavoritesCount == 1)
    }

    // MARK: - Case-Insensitive Media Type Tests

    @Test func loadFavoritesCaseInsensitiveUppercaseMovies() async {
        let item = FavoriteItem(identifier: "movie1", mediatype: "Movies", title: "Test")
        mockService.mockResponse = FavoritesResponse(members: [item])

        await viewModel.loadFavorites(username: "testuser")

        #expect(viewModel.state.movieItems.count == 1)
        #expect(viewModel.state.movieItems.first?.identifier == "movie1")
    }

    @Test func loadFavoritesCaseInsensitiveUppercaseETREE() async {
        let item = FavoriteItem(identifier: "concert1", mediatype: "ETREE", title: "Test")
        mockService.mockResponse = FavoritesResponse(members: [item])

        await viewModel.loadFavorites(username: "testuser")

        #expect(viewModel.state.musicItems.count == 1)
        #expect(viewModel.state.musicItems.first?.identifier == "concert1")
    }

    @Test func loadFavoritesCaseInsensitiveMixedCaseVideo() async {
        let item = FavoriteItem(identifier: "video1", mediatype: "Video", title: "Test")
        mockService.mockResponse = FavoritesResponse(members: [item])

        await viewModel.loadFavorites(username: "testuser")

        #expect(viewModel.state.movieItems.count == 1)
        #expect(viewModel.state.movieItems.first?.identifier == "video1")
    }

    @Test func loadFavoritesCaseInsensitiveUppercaseAUDIO() async {
        let item = FavoriteItem(identifier: "audio1", mediatype: "AUDIO", title: "Test")
        mockService.mockResponse = FavoritesResponse(members: [item])

        await viewModel.loadFavorites(username: "testuser")

        #expect(viewModel.state.musicItems.count == 1)
        #expect(viewModel.state.musicItems.first?.identifier == "audio1")
    }

    @Test func loadFavoritesVideoTreatedAsMovie() async {
        let videoItem = FavoriteItem(identifier: "video1", mediatype: "video", title: "Video Item")
        let movieItem = FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie Item")
        mockService.mockResponse = FavoritesResponse(members: [videoItem, movieItem])

        await viewModel.loadFavorites(username: "testuser")

        // Both video and movies should be in movieItems
        #expect(viewModel.state.movieItems.count == 2)
        #expect(viewModel.state.musicItems.isEmpty)
    }

    // MARK: - Unsupported Media Types Only Tests

    @Test func loadFavoritesWithDetailsOnlyUnsupportedTypesSkipsSearch() async {
        let textItem = FavoriteItem(identifier: "text1", mediatype: "texts", title: "Text")
        let imageItem = FavoriteItem(identifier: "image1", mediatype: "image", title: "Image")
        let webItem = FavoriteItem(identifier: "web1", mediatype: "web", title: "Web")
        mockService.mockResponse = FavoritesResponse(members: [textItem, imageItem, webItem])

        let mockSearchService = MockSearchService()

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        #expect(!mockSearchService.searchCalled)
        #expect(viewModel.state.allItems.isEmpty, "allItems should be cleared")
        #expect(viewModel.state.movieResults.isEmpty)
        #expect(viewModel.state.musicResults.isEmpty)
        #expect(viewModel.state.peopleResults.isEmpty)
        #expect(!viewModel.state.isLoading)
    }

    @Test func loadFavoritesWithDetailsNilMediaTypesSkipsSearch() async {
        let item1 = FavoriteItem(identifier: "item1", mediatype: nil, title: "Item 1")
        let item2 = FavoriteItem(identifier: "item2", mediatype: nil, title: "Item 2")
        mockService.mockResponse = FavoritesResponse(members: [item1, item2])

        let mockSearchService = MockSearchService()

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        #expect(!mockSearchService.searchCalled)
        #expect(viewModel.state.allItems.isEmpty, "allItems should be cleared")
        #expect(viewModel.state.movieResults.isEmpty)
        #expect(viewModel.state.musicResults.isEmpty)
        #expect(viewModel.state.peopleResults.isEmpty)
    }

    @Test func loadFavoritesWithDetailsMixedSupportedAndUnsupportedOnlyQueriesSupported() async {
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

        #expect(mockSearchService.searchCalled)
        #expect(mockSearchService.lastQuery?.contains("movie1") ?? false)
        #expect(mockSearchService.lastQuery?.contains("audio1") ?? false)
        #expect(!(mockSearchService.lastQuery?.contains("text1") ?? true))
    }

    // MARK: - Case-Insensitive loadFavoritesWithDetails Tests

    @Test func loadFavoritesWithDetailsCaseInsensitiveUppercaseMOVIES() async {
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

        #expect(mockSearchService.searchCalled)
        #expect(mockSearchService.lastQuery?.contains("movie1") ?? false)
        #expect(viewModel.state.movieResults.count == 1)
    }

    @Test func loadFavoritesWithDetailsCaseInsensitiveMixedCaseVideo() async {
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

        #expect(mockSearchService.searchCalled)
        #expect(mockSearchService.lastQuery?.contains("video1") ?? false)
        #expect(viewModel.state.movieResults.count == 1)
    }

    @Test func loadFavoritesWithDetailsCaseInsensitiveUppercaseETREE() async {
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

        #expect(mockSearchService.searchCalled)
        #expect(mockSearchService.lastQuery?.contains("concert1") ?? false)
        #expect(viewModel.state.musicResults.count == 1)
    }

    @Test func loadFavoritesWithDetailsCaseInsensitiveUppercaseAUDIO() async {
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

        #expect(mockSearchService.searchCalled)
        #expect(mockSearchService.lastQuery?.contains("audio1") ?? false)
        #expect(viewModel.state.musicResults.count == 1)
    }

    @Test func loadFavoritesWithDetailsCaseInsensitiveUppercaseACCOUNT() async {
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

        #expect(mockSearchService.searchCalled)
        #expect(mockSearchService.lastQuery?.contains("person1") ?? false)
        #expect(viewModel.state.peopleResults.count == 1)
    }

    @Test func loadFavoritesWithDetailsVideoAndEtreeTypesIncluded() async {
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

        #expect(mockSearchService.searchCalled)
        #expect(mockSearchService.lastQuery?.contains("video1") ?? false)
        #expect(mockSearchService.lastQuery?.contains("etree1") ?? false)
        #expect(viewModel.state.movieResults.count == 1)
        #expect(viewModel.state.musicResults.count == 1)
    }

    @Test func loadFavoritesWithDetailsUnknownMediatypeIgnored() async {
        let movieItem = FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie")
        let unknownItem = FavoriteItem(identifier: "unknown1", mediatype: "software", title: "Software Item")
        let anotherUnknown = FavoriteItem(identifier: "unknown2", mediatype: "web", title: "Web Archive")
        mockService.mockResponse = FavoritesResponse(members: [movieItem, unknownItem, anotherUnknown])

        let mockSearchService = MockSearchService()
        mockSearchService.mockResponse = TestFixtures.makeSearchResponse(numFound: 3, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "unknown1", mediatype: "software"),
            TestFixtures.makeSearchResult(identifier: "unknown2", mediatype: "web")
        ])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: mockSearchService
        )

        #expect(mockSearchService.searchCalled)
        #expect(mockSearchService.lastQuery?.contains("movie1") ?? false)
        #expect(!(mockSearchService.lastQuery?.contains("unknown1") ?? true))
        #expect(!(mockSearchService.lastQuery?.contains("unknown2") ?? true))
        #expect(viewModel.state.movieResults.count == 1)
        #expect(viewModel.state.musicResults.count == 0)
        #expect(viewModel.state.peopleResults.count == 0)
        #expect(viewModel.state.movieResults.first?.identifier == "movie1")
    }

    // MARK: - State Reset Between Calls Tests

    @Test func loadFavoritesWithDetailsResetsStateBetweenCalls() async {
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

        #expect(viewModel.state.movieResults.count == 1)
        #expect(viewModel.state.musicResults.count == 0)

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
        #expect(viewModel.state.movieResults.count == 0)
        #expect(viewModel.state.musicResults.count == 1)
    }

    @Test func loadFavoritesWithDetailsClearsErrorOnNewCall() async {
        // First call with error
        mockService.errorToThrow = NetworkError.timeout

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: MockSearchService()
        )

        #expect(viewModel.state.errorMessage != nil)

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
        #expect(viewModel.state.errorMessage == nil)
        #expect(viewModel.state.movieResults.count == 1)
    }

    @Test func loadFavoritesWithDetailsEmptyResponseClearsAllResults() async {
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

        #expect(viewModel.state.movieResults.count == 1)

        // Second call with empty favorites
        mockService.mockResponse = FavoritesResponse(members: [])

        await viewModel.loadFavoritesWithDetails(
            username: "testuser",
            searchService: MockSearchService()
        )

        // All results should be cleared
        #expect(viewModel.state.movieResults.count == 0)
        #expect(viewModel.state.musicResults.count == 0)
        #expect(viewModel.state.peopleResults.count == 0)
    }
}

// MARK: - FavoritesViewState Tests

@Suite("FavoritesViewState Tests")
struct FavoritesViewStateTests {

    @Test func initialState() {
        let state = FavoritesViewState.initial

        #expect(!state.isLoading)
        #expect(state.allItems.isEmpty)
        #expect(state.movieItems.isEmpty)
        #expect(state.musicItems.isEmpty)
        #expect(state.errorMessage == nil)
    }

    @Test func hasResultsWhenEmpty() {
        let state = FavoritesViewState.initial
        #expect(!state.hasResults)
    }

    @Test func hasResultsWhenHasMovies() {
        var state = FavoritesViewState.initial
        state.movieResults = [TestFixtures.makeSearchResult(identifier: "1")]
        #expect(state.hasResults)
    }

    @Test func hasResultsWhenHasMusic() {
        var state = FavoritesViewState.initial
        state.musicResults = [TestFixtures.makeSearchResult(identifier: "1")]
        #expect(state.hasResults)
    }

    @Test func hasResultsWhenHasPeople() {
        var state = FavoritesViewState.initial
        state.peopleResults = [TestFixtures.makeSearchResult(identifier: "1")]
        #expect(state.hasResults)
    }
}
