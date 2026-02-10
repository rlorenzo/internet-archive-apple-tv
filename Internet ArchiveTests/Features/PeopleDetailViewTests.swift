//
//  PeopleDetailViewTests.swift
//  Internet ArchiveTests
//
//  Tests for PeopleDetailView types, logic, and ViewModel integration
//  using Swift Testing framework
//

import Foundation
import Testing
@testable import Internet_Archive

// MARK: - Mock People Favorites Service for Detail View Tests

/// A lightweight mock service for PeopleDetailView tests.
/// Uses a different name from the XCTest mock in PeopleViewModelTests to avoid conflicts.
private final class DetailViewMockFavoritesService: PeopleFavoritesServiceProtocol, @unchecked Sendable {
    var favoriteItems: [FavoriteItem] = []
    var searchResults: [SearchResult] = []
    var shouldThrowError: Bool = false
    var errorToThrow: Error = NetworkError.timeout

    var getFavoriteItemsCallCount = 0
    var searchCallCount = 0
    var lastUsername: String?
    var lastQuery: String?

    func getFavoriteItems(username: String) async throws -> FavoritesResponse {
        getFavoriteItemsCallCount += 1
        lastUsername = username

        if shouldThrowError {
            throw errorToThrow
        }
        return FavoritesResponse(members: favoriteItems)
    }

    func search(query: String, options: [String: String]) async throws -> SearchResponse {
        searchCallCount += 1
        lastQuery = query

        if shouldThrowError {
            throw errorToThrow
        }
        return TestFixtures.makeSearchResponse(docs: searchResults)
    }
}

// MARK: - Avatar URL Tests

@Suite("PeopleDetailView Avatar URL Tests")
struct PeopleDetailViewAvatarURLTests {

    @Test func avatarURLConstructedFromIdentifier() {
        let identifier = "@brewster"
        let expectedURL = URL(string: "https://archive.org/services/img/@brewster")
        let url = URL(string: "https://archive.org/services/img/\(identifier)")
        #expect(url == expectedURL)
    }

    @Test func avatarURLWithSimpleUsername() {
        let identifier = "brewster_kahle"
        let url = URL(string: "https://archive.org/services/img/\(identifier)")
        #expect(url != nil)
        #expect(url?.absoluteString == "https://archive.org/services/img/brewster_kahle")
    }

    @Test func avatarURLWithSpecialCharsInIdentifier() {
        let identifier = "@user_123"
        let url = URL(string: "https://archive.org/services/img/\(identifier)")
        #expect(url != nil)
        #expect(url?.absoluteString == "https://archive.org/services/img/@user_123")
    }

    @Test func avatarURLWithSpacesPercentEncodes() {
        // Modern Foundation percent-encodes spaces in URL(string:)
        let identifier = "user with spaces"
        let url = URL(string: "https://archive.org/services/img/\(identifier)")
        #expect(url != nil)
        #expect(url?.absoluteString.contains("%20") == true)
    }

    @Test func avatarURLWithEmptyIdentifier() {
        let identifier = ""
        let url = URL(string: "https://archive.org/services/img/\(identifier)")
        #expect(url != nil)
        #expect(url?.absoluteString == "https://archive.org/services/img/")
    }

    @Test func avatarURLWithAtSignOnly() {
        let identifier = "@"
        let url = URL(string: "https://archive.org/services/img/\(identifier)")
        #expect(url != nil)
        #expect(url?.absoluteString == "https://archive.org/services/img/@")
    }
}

// MARK: - PeopleViewState Tests (via Swift Testing)

@Suite("PeopleViewState Tests")
struct PeopleViewStateSwiftTests {

    @Test func initialStateIsEmpty() {
        let state = PeopleViewState.initial

        #expect(state.identifier == "")
        #expect(state.name == "")
        #expect(state.movieItems.isEmpty)
        #expect(state.musicItems.isEmpty)
        #expect(!state.isLoading)
        #expect(state.errorMessage == nil)
    }

    @Test func hasItemsFalseWhenEmpty() {
        let state = PeopleViewState.initial
        #expect(!state.hasItems)
    }

    @Test func hasItemsTrueWithMovies() {
        var state = PeopleViewState.initial
        state.movieItems = [TestFixtures.makeSearchResult(identifier: "m1", mediatype: "movies")]
        #expect(state.hasItems)
    }

    @Test func hasItemsTrueWithMusic() {
        var state = PeopleViewState.initial
        state.musicItems = [TestFixtures.makeSearchResult(identifier: "a1", mediatype: "audio")]
        #expect(state.hasItems)
    }

    @Test func hasItemsTrueWithBoth() {
        var state = PeopleViewState.initial
        state.movieItems = [TestFixtures.makeSearchResult(identifier: "m1", mediatype: "movies")]
        state.musicItems = [TestFixtures.makeSearchResult(identifier: "a1", mediatype: "audio")]
        #expect(state.hasItems)
    }

    @Test func totalItemCountIsZeroWhenEmpty() {
        let state = PeopleViewState.initial
        #expect(state.totalItemCount == 0)
    }

    @Test func totalItemCountCombinesMoviesAndMusic() {
        var state = PeopleViewState.initial
        state.movieItems = [
            TestFixtures.makeSearchResult(identifier: "m1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "m2", mediatype: "movies")
        ]
        state.musicItems = [
            TestFixtures.makeSearchResult(identifier: "a1", mediatype: "audio")
        ]
        #expect(state.totalItemCount == 3)
    }

    @Test func usernameStripsAtPrefix() {
        var state = PeopleViewState.initial
        state.identifier = "@brewster"
        #expect(state.username == "brewster")
    }

    @Test func usernameWithoutAtPrefixUnchanged() {
        var state = PeopleViewState.initial
        state.identifier = "brewster"
        #expect(state.username == "brewster")
    }

    @Test func usernameEmptyWhenIdentifierEmpty() {
        let state = PeopleViewState.initial
        #expect(state.username == "")
    }

    @Test func usernameWithOnlyAtSign() {
        var state = PeopleViewState.initial
        state.identifier = "@"
        #expect(state.username == "")
    }
}

// MARK: - ViewModel Initial State and Configure Tests

@Suite("PeopleViewModel State Tests")
struct PeopleViewModelStateTests {

    @Test @MainActor func viewModelInitialState() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        #expect(viewModel.state.identifier == "")
        #expect(viewModel.state.name == "")
        #expect(!viewModel.state.hasItems)
        #expect(viewModel.state.totalItemCount == 0)
        #expect(!viewModel.state.isLoading)
        #expect(viewModel.state.errorMessage == nil)
    }

    @Test @MainActor func configureSetsIdentifierAndName() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        viewModel.configure(identifier: "@testuser", name: "Test User")

        #expect(viewModel.state.identifier == "@testuser")
        #expect(viewModel.state.name == "Test User")
    }

    @Test @MainActor func configureWithEmptyValues() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        viewModel.configure(identifier: "", name: "")

        #expect(viewModel.state.identifier == "")
        #expect(viewModel.state.name == "")
    }

    @Test @MainActor func configureCanBeCalledMultipleTimes() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        viewModel.configure(identifier: "@first", name: "First")
        viewModel.configure(identifier: "@second", name: "Second")

        #expect(viewModel.state.identifier == "@second")
        #expect(viewModel.state.name == "Second")
    }
}

// MARK: - ViewModel Load Favorites Tests

@Suite("PeopleViewModel Load Favorites Tests")
struct PeopleViewModelLoadFavoritesTests {

    @Test @MainActor func loadFavoritesWithEmptyIdentifierSetsError() async {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)
        // Do not configure - identifier is empty

        await viewModel.loadFavorites()

        #expect(viewModel.state.errorMessage != nil)
        #expect(viewModel.state.errorMessage?.contains("Missing") == true)
        #expect(service.getFavoriteItemsCallCount == 0)
    }

    @Test @MainActor func loadFavoritesCallsServiceWithUsername() async {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)
        viewModel.configure(identifier: "@brewster", name: "Brewster")

        await viewModel.loadFavorites()

        #expect(service.getFavoriteItemsCallCount == 1)
        #expect(service.lastUsername == "brewster")
    }

    @Test @MainActor func loadFavoritesWithEmptyMembersDoesNotSearch() async {
        let service = DetailViewMockFavoritesService()
        service.favoriteItems = []
        let viewModel = PeopleViewModel(favoritesService: service)
        viewModel.configure(identifier: "@testuser", name: "Test")

        await viewModel.loadFavorites()

        #expect(service.getFavoriteItemsCallCount == 1)
        #expect(service.searchCallCount == 0)
        #expect(!viewModel.state.isLoading)
    }

    @Test @MainActor func loadFavoritesWithUnsupportedMediaTypesDoesNotSearch() async {
        let service = DetailViewMockFavoritesService()
        service.favoriteItems = [
            FavoriteItem(identifier: "text1", mediatype: "texts", title: "A Book"),
            FavoriteItem(identifier: "image1", mediatype: "image", title: "A Photo")
        ]
        let viewModel = PeopleViewModel(favoritesService: service)
        viewModel.configure(identifier: "@testuser", name: "Test")

        await viewModel.loadFavorites()

        #expect(service.getFavoriteItemsCallCount == 1)
        #expect(service.searchCallCount == 0)
        #expect(!viewModel.state.isLoading)
    }

    @Test @MainActor func loadFavoritesPopulatesMovieItems() async {
        let service = DetailViewMockFavoritesService()
        service.favoriteItems = [
            FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Test Movie")
        ]
        service.searchResults = [
            TestFixtures.makeSearchResult(identifier: "movie1", title: "Test Movie", mediatype: "movies")
        ]
        let viewModel = PeopleViewModel(favoritesService: service)
        viewModel.configure(identifier: "@testuser", name: "Test")

        await viewModel.loadFavorites()

        #expect(viewModel.state.movieItems.count == 1)
        #expect(viewModel.state.movieItems.first?.identifier == "movie1")
        #expect(!viewModel.state.isLoading)
    }

    @Test @MainActor func loadFavoritesPopulatesMusicItems() async {
        let service = DetailViewMockFavoritesService()
        service.favoriteItems = [
            FavoriteItem(identifier: "audio1", mediatype: "audio", title: "Test Audio")
        ]
        service.searchResults = [
            TestFixtures.makeSearchResult(identifier: "audio1", title: "Test Audio", mediatype: "audio")
        ]
        let viewModel = PeopleViewModel(favoritesService: service)
        viewModel.configure(identifier: "@testuser", name: "Test")

        await viewModel.loadFavorites()

        #expect(viewModel.state.musicItems.count == 1)
        #expect(viewModel.state.musicItems.first?.identifier == "audio1")
    }

    @Test @MainActor func loadFavoritesCategorizesMixedItems() async {
        let service = DetailViewMockFavoritesService()
        service.favoriteItems = [
            FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie"),
            FavoriteItem(identifier: "audio1", mediatype: "audio", title: "Audio")
        ]
        service.searchResults = [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "audio")
        ]
        let viewModel = PeopleViewModel(favoritesService: service)
        viewModel.configure(identifier: "@testuser", name: "Test")

        await viewModel.loadFavorites()

        #expect(viewModel.state.movieItems.count == 1)
        #expect(viewModel.state.musicItems.count == 1)
        #expect(viewModel.state.hasItems)
        #expect(viewModel.state.totalItemCount == 2)
    }

    @Test @MainActor func loadFavoritesHandlesError() async {
        let service = DetailViewMockFavoritesService()
        service.shouldThrowError = true
        service.errorToThrow = NetworkError.timeout
        let viewModel = PeopleViewModel(favoritesService: service)
        viewModel.configure(identifier: "@testuser", name: "Test")

        await viewModel.loadFavorites()

        #expect(viewModel.state.errorMessage != nil)
        #expect(!viewModel.state.isLoading)
        #expect(!viewModel.state.hasItems)
    }

    @Test @MainActor func loadFavoritesHandlesNoConnectionError() async {
        let service = DetailViewMockFavoritesService()
        service.shouldThrowError = true
        service.errorToThrow = NetworkError.noConnection
        let viewModel = PeopleViewModel(favoritesService: service)
        viewModel.configure(identifier: "@testuser", name: "Test")

        await viewModel.loadFavorites()

        #expect(viewModel.state.errorMessage != nil)
        #expect(!viewModel.state.isLoading)
    }

    @Test @MainActor func loadFavoritesHandlesInvalidResponseError() async {
        let service = DetailViewMockFavoritesService()
        service.shouldThrowError = true
        service.errorToThrow = NetworkError.invalidResponse
        let viewModel = PeopleViewModel(favoritesService: service)
        viewModel.configure(identifier: "@testuser", name: "Test")

        await viewModel.loadFavorites()

        #expect(viewModel.state.errorMessage != nil)
        #expect(!viewModel.state.isLoading)
    }

    @Test @MainActor func emptyFavoritesResultsInNoItems() async {
        let service = DetailViewMockFavoritesService()
        service.favoriteItems = []
        let viewModel = PeopleViewModel(favoritesService: service)
        viewModel.configure(identifier: "@testuser", name: "Test")

        await viewModel.loadFavorites()

        #expect(!viewModel.state.hasItems)
        #expect(viewModel.state.totalItemCount == 0)
        #expect(viewModel.state.movieItems.isEmpty)
        #expect(viewModel.state.musicItems.isEmpty)
    }
}

// MARK: - ViewModel Helper Method Tests

@Suite("PeopleViewModel Helper Methods Tests")
struct PeopleViewModelHelperTests {

    @Test @MainActor func filterSupportedIdentifiersIncludesMoviesAndAudio() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        let favorites = [
            FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie"),
            FavoriteItem(identifier: "audio1", mediatype: "audio", title: "Audio"),
            FavoriteItem(identifier: "text1", mediatype: "texts", title: "Text")
        ]

        let result = viewModel.filterSupportedIdentifiers(favorites)

        #expect(result.count == 2)
        #expect(result.contains("movie1"))
        #expect(result.contains("audio1"))
        #expect(!result.contains("text1"))
    }

    @Test @MainActor func filterSupportedIdentifiersExcludesNilMediaType() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        let favorites = [
            FavoriteItem(identifier: "unknown1", mediatype: nil, title: "No Type")
        ]

        let result = viewModel.filterSupportedIdentifiers(favorites)

        #expect(result.isEmpty)
    }

    @Test @MainActor func filterSupportedIdentifiersHandlesEmptyArray() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        let result = viewModel.filterSupportedIdentifiers([])

        #expect(result.isEmpty)
    }

    @Test @MainActor func categorizeByMediaTypeSeparatesCorrectly() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        let items = [
            TestFixtures.makeSearchResult(identifier: "m1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "m2", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "a1", mediatype: "audio")
        ]

        let result = viewModel.categorizeByMediaType(items)

        #expect(result.movies.count == 2)
        #expect(result.music.count == 1)
    }

    @Test @MainActor func categorizeByMediaTypeIgnoresUnsupportedTypes() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        let items = [
            TestFixtures.makeSearchResult(identifier: "m1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "t1", mediatype: "texts"),
            TestFixtures.makeSearchResult(identifier: "i1", mediatype: "image")
        ]

        let result = viewModel.categorizeByMediaType(items)

        #expect(result.movies.count == 1)
        #expect(result.music.count == 0)
    }

    @Test @MainActor func categorizeByMediaTypeHandlesEmptyArray() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        let result = viewModel.categorizeByMediaType([])

        #expect(result.movies.isEmpty)
        #expect(result.music.isEmpty)
    }

    @Test @MainActor func movieItemAtValidIndex() async {
        let service = DetailViewMockFavoritesService()
        service.favoriteItems = [
            FavoriteItem(identifier: "movie1", mediatype: "movies", title: "Movie")
        ]
        service.searchResults = [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies")
        ]
        let viewModel = PeopleViewModel(favoritesService: service)
        viewModel.configure(identifier: "@testuser", name: "Test")
        await viewModel.loadFavorites()

        let item = viewModel.movieItem(at: 0)

        #expect(item != nil)
        #expect(item?.identifier == "movie1")
    }

    @Test @MainActor func movieItemAtInvalidIndexReturnsNil() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        #expect(viewModel.movieItem(at: 0) == nil)
        #expect(viewModel.movieItem(at: -1) == nil)
        #expect(viewModel.movieItem(at: 99) == nil)
    }

    @Test @MainActor func musicItemAtValidIndex() async {
        let service = DetailViewMockFavoritesService()
        service.favoriteItems = [
            FavoriteItem(identifier: "audio1", mediatype: "audio", title: "Audio")
        ]
        service.searchResults = [
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "audio")
        ]
        let viewModel = PeopleViewModel(favoritesService: service)
        viewModel.configure(identifier: "@testuser", name: "Test")
        await viewModel.loadFavorites()

        let item = viewModel.musicItem(at: 0)

        #expect(item != nil)
        #expect(item?.identifier == "audio1")
    }

    @Test @MainActor func musicItemAtInvalidIndexReturnsNil() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        #expect(viewModel.musicItem(at: 0) == nil)
        #expect(viewModel.musicItem(at: -1) == nil)
    }

    @Test @MainActor func clearErrorResetsErrorMessage() async {
        let service = DetailViewMockFavoritesService()
        service.shouldThrowError = true
        let viewModel = PeopleViewModel(favoritesService: service)
        viewModel.configure(identifier: "@testuser", name: "Test")

        await viewModel.loadFavorites()
        #expect(viewModel.state.errorMessage != nil)

        viewModel.clearError()
        #expect(viewModel.state.errorMessage == nil)
    }
}

// MARK: - Navigation Data Tests

@Suite("PeopleViewModel Navigation Data Tests")
struct PeopleViewModelNavigationTests {

    @Test @MainActor func buildItemNavigationDataWithAllFields() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        let item = TestFixtures.makeSearchResult(
            identifier: "test_nav",
            title: "Test Title",
            mediatype: "movies",
            creator: "Test Creator",
            description: "Test description",
            date: "2025-01-15"
        )

        let navData = viewModel.buildItemNavigationData(for: item)

        #expect(navData.identifier == "test_nav")
        #expect(navData.title == "Test Title")
        #expect(navData.archivedBy == "Test Creator")
        #expect(navData.date == "2025-01-15")
        #expect(navData.description == "Test description")
        #expect(navData.mediaType == "movies")
        #expect(navData.imageURL != nil)
        #expect(navData.imageURL?.absoluteString.contains("test_nav") == true)
    }

    @Test @MainActor func buildItemNavigationDataWithNilFields() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        let item = TestFixtures.makeSearchResult(
            identifier: "minimal",
            title: nil,
            mediatype: nil,
            creator: nil,
            description: nil,
            date: nil
        )

        let navData = viewModel.buildItemNavigationData(for: item)

        #expect(navData.identifier == "minimal")
        #expect(navData.title == "")
        #expect(navData.archivedBy == "")
        #expect(navData.date == "")
        #expect(navData.description == "")
        #expect(navData.mediaType == "")
    }

    @Test @MainActor func buildItemNavigationDataImageURLFormat() {
        let service = DetailViewMockFavoritesService()
        let viewModel = PeopleViewModel(favoritesService: service)

        let item = TestFixtures.makeSearchResult(identifier: "my_item_123")

        let navData = viewModel.buildItemNavigationData(for: item)

        let expectedURL = "https://archive.org/services/get-item-image.php?identifier=my_item_123"
        #expect(navData.imageURL?.absoluteString == expectedURL)
    }
}
