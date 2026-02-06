//
//  SearchViewModelTests.swift
//  Internet ArchiveTests
//
//  Unit tests for SearchViewModel
//

import Testing
import Foundation
@testable import Internet_Archive

// MARK: - Mock Search Service

final class MockSearchService: SearchServiceProtocol, @unchecked Sendable {
    var searchCalled = false
    var lastQuery: String?
    var lastOptions: [String: String]?
    var mockResponse: SearchResponse?
    var errorToThrow: Error?

    func search(query: String, options: [String: String]) async throws -> SearchResponse {
        searchCalled = true
        lastQuery = query
        lastOptions = options

        if let error = errorToThrow {
            throw error
        }

        guard let response = mockResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

    func reset() {
        searchCalled = false
        lastQuery = nil
        lastOptions = nil
        mockResponse = nil
        errorToThrow = nil
    }
}

/// Mock service with configurable delay for testing concurrent operations
final class SlowMockSearchService: SearchServiceProtocol, @unchecked Sendable {
    var searchCallCount = 0
    var mockResponse: SearchResponse?
    var delayMilliseconds: UInt64 = 0

    func search(query: String, options: [String: String]) async throws -> SearchResponse {
        searchCallCount += 1

        if delayMilliseconds > 0 {
            try? await Task.sleep(nanoseconds: delayMilliseconds * 1_000_000)
        }

        guard let response = mockResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }
}

// MARK: - SearchViewModel Tests

@Suite("SearchViewModel Tests", .serialized)
@MainActor
struct SearchViewModelTests {

    var viewModel: SearchViewModel
    var mockService: MockSearchService

    init() {
        let service = MockSearchService()
        mockService = service
        viewModel = SearchViewModel(searchService: service, pageSize: 10)
    }

    // MARK: - Initial State Tests

    @Test func initialState() {
        #expect(!viewModel.state.isLoading)
        #expect(viewModel.state.results.isEmpty)
        #expect(viewModel.state.errorMessage == nil)
        #expect(viewModel.state.totalResults == 0)
        #expect(viewModel.state.currentPage == 0)
        #expect(!viewModel.state.hasMoreResults)
    }

    // MARK: - Search Tests

    @Test func searchWithValidQueryCallsService() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 5, docs: [
            TestFixtures.makeSearchResult(identifier: "1"),
            TestFixtures.makeSearchResult(identifier: "2")
        ])

        await viewModel.search(query: "test query")

        #expect(mockService.searchCalled)
        #expect(mockService.lastQuery == "test query")
    }

    @Test func searchWithValidQueryUpdatesState() async {
        let results = [
            TestFixtures.makeSearchResult(identifier: "1"),
            TestFixtures.makeSearchResult(identifier: "2"),
            TestFixtures.makeSearchResult(identifier: "3")
        ]
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 3, docs: results)

        await viewModel.search(query: "movies")

        #expect(!viewModel.state.isLoading)
        #expect(viewModel.state.results.count == 3)
        #expect(viewModel.state.totalResults == 3)
        #expect(viewModel.state.errorMessage == nil)
    }

    @Test func searchWithEmptyQueryClearsResults() async {
        // First do a search
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        await viewModel.search(query: "test")

        // Then search with empty query
        mockService.reset()
        await viewModel.search(query: "")

        #expect(!mockService.searchCalled)
        #expect(viewModel.state.results.isEmpty)
    }

    @Test func searchWithWhitespaceQueryClearsResults() async {
        await viewModel.search(query: "   ")

        #expect(!mockService.searchCalled)
        #expect(viewModel.state.results.isEmpty)
    }

    @Test func searchWithWhitespaceQueryResetsToInitialState() async {
        // First perform a valid search to populate state
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        await viewModel.search(query: "test")
        #expect(!viewModel.state.results.isEmpty)
        #expect(viewModel.state.hasMoreResults)
        #expect(viewModel.state.totalResults == 100)

        // Now search with whitespace-only - should reset to initial state
        await viewModel.search(query: "   ")

        // Verify full state reset (matches SearchViewState.initial)
        #expect(!viewModel.state.isLoading)
        #expect(viewModel.state.results.isEmpty)
        #expect(viewModel.state.errorMessage == nil)
        #expect(viewModel.state.totalResults == 0)
        #expect(viewModel.state.currentPage == 0)
        #expect(!viewModel.state.hasMoreResults)
    }

    @Test func searchWithErrorSetsErrorMessage() async {
        mockService.errorToThrow = NetworkError.timeout

        await viewModel.search(query: "test")

        #expect(!viewModel.state.isLoading)
        #expect(viewModel.state.errorMessage != nil)
        #expect(viewModel.state.results.isEmpty)
    }

    @Test func searchWithNetworkErrorShowsUserFriendlyMessage() async {
        mockService.errorToThrow = NetworkError.noConnection

        await viewModel.search(query: "test")

        #expect(viewModel.state.errorMessage != nil)
        #expect(viewModel.state.errorMessage?.contains("internet") ?? false)
    }

    // MARK: - Pagination Tests

    @Test func searchSetsHasMoreResultsWhenMoreAvailable() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])

        await viewModel.search(query: "test")

        #expect(viewModel.state.hasMoreResults)
    }

    @Test func searchSetsHasMoreResultsFalseWhenAllLoaded() async {
        let results = [TestFixtures.makeSearchResult(identifier: "1")]
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: results)

        await viewModel.search(query: "test")

        #expect(!viewModel.state.hasMoreResults)
    }

    @Test func loadNextPageAppendsResults() async {
        // Initial search
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 20, docs: [
            TestFixtures.makeSearchResult(identifier: "1"),
            TestFixtures.makeSearchResult(identifier: "2")
        ])
        await viewModel.search(query: "test")

        // Load next page
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 20, docs: [
            TestFixtures.makeSearchResult(identifier: "3"),
            TestFixtures.makeSearchResult(identifier: "4")
        ])
        await viewModel.loadNextPage(query: "test")

        #expect(viewModel.state.results.count == 4)
        #expect(viewModel.state.currentPage == 1)
    }

    @Test func loadNextPageDoesNotLoadWhenNoMoreResults() async {
        let results = [TestFixtures.makeSearchResult(identifier: "1")]
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: results)
        await viewModel.search(query: "test")

        mockService.reset()
        await viewModel.loadNextPage(query: "test")

        #expect(!mockService.searchCalled)
    }

    // MARK: - Clear Results Tests

    @Test func clearResultsResetsState() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 5, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        await viewModel.search(query: "test")

        viewModel.clearResults()

        #expect(viewModel.state.results.isEmpty)
        #expect(viewModel.state.totalResults == 0)
        #expect(viewModel.state.currentPage == 0)
    }

    // MARK: - Search Options Tests

    @Test func searchIncludesCorrectOptions() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 0, docs: [])

        await viewModel.search(query: "test")

        #expect(mockService.lastOptions?["rows"] == "10")
        #expect(mockService.lastOptions?["page"] == "1")
        #expect(mockService.lastOptions?["fl[]"] != nil)
    }

    // MARK: - Error Type Tests

    @Test func searchWithServerErrorShowsAppropriateMessage() async {
        mockService.errorToThrow = NetworkError.serverError(statusCode: 500)

        await viewModel.search(query: "test")

        #expect(viewModel.state.errorMessage != nil)
        #expect(viewModel.state.errorMessage?.lowercased().contains("server") ?? false ||
                      viewModel.state.errorMessage?.lowercased().contains("archive") ?? false)
    }

    @Test func searchWithTimeoutErrorShowsAppropriateMessage() async {
        mockService.errorToThrow = NetworkError.timeout

        await viewModel.search(query: "test")

        #expect(viewModel.state.errorMessage != nil)
        #expect(viewModel.state.errorMessage?.lowercased().contains("long") ?? false ||
                      viewModel.state.errorMessage?.lowercased().contains("connection") ?? false)
    }

    @Test func searchWithGenericErrorShowsDefaultMessage() async {
        mockService.errorToThrow = NSError(domain: "test", code: 123, userInfo: nil)

        await viewModel.search(query: "test")

        #expect(viewModel.state.errorMessage != nil)
        #expect(viewModel.state.errorMessage?.contains("unexpected") ?? false)
    }

    // MARK: - Sequential Search Tests

    @Test func sequentialSearchesLastSearchResultsShown() async {
        // First search
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 5, docs: [
            TestFixtures.makeSearchResult(identifier: "first1")
        ])
        await viewModel.search(query: "first")

        // Second search
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 3, docs: [
            TestFixtures.makeSearchResult(identifier: "second1"),
            TestFixtures.makeSearchResult(identifier: "second2")
        ])
        await viewModel.search(query: "second")

        // Results should be from second search
        #expect(viewModel.state.results.count == 2)
        #expect(viewModel.state.results.first?.identifier == "second1")
    }

    // MARK: - Search Options Edge Cases

    @Test func searchWithSpecialCharactersInQuery() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 0, docs: [])

        await viewModel.search(query: "test & special <chars>")

        #expect(mockService.searchCalled)
        #expect(mockService.lastQuery == "test & special <chars>")
    }

    @Test func searchWithUnicodeQuery() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 0, docs: [])

        await viewModel.search(query: "测试 日本語 한국어")

        #expect(mockService.searchCalled)
    }

    @Test func searchWithVeryLongQuery() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 0, docs: [])
        let longQuery = String(repeating: "test ", count: 100)

        await viewModel.search(query: longQuery)

        #expect(mockService.searchCalled)
    }

    // MARK: - Pagination Edge Cases

    @Test func loadNextPageWithErrorPreservesExistingResults() async {
        // Initial search
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 20, docs: [
            TestFixtures.makeSearchResult(identifier: "1"),
            TestFixtures.makeSearchResult(identifier: "2")
        ])
        await viewModel.search(query: "test")
        #expect(viewModel.state.results.count == 2)

        // Load next page with error
        mockService.errorToThrow = NetworkError.timeout
        await viewModel.loadNextPage(query: "test")

        // Original results should be preserved
        #expect(viewModel.state.results.count == 2)
        #expect(viewModel.state.errorMessage != nil)
    }

    @Test func loadNextPageWhileLoadingDoesNothing() async {
        // Create slow mock service for this test
        let slowMockService = SlowMockSearchService()
        slowMockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        let slowViewModel = SearchViewModel(searchService: slowMockService, pageSize: 10)

        // First search to establish state
        await slowViewModel.search(query: "test")

        // Reset counter and set delay for next operation
        slowMockService.searchCallCount = 0
        slowMockService.delayMilliseconds = 500

        // Start a slow loadNextPage in background
        let task = Task {
            await slowViewModel.loadNextPage(query: "test")
        }

        // Wait for loading to start (bounded to avoid hanging CI)
        let start = ContinuousClock.now
        while !slowViewModel.state.isLoading {
            if ContinuousClock.now - start > .seconds(2) {
                Issue.record("Timed out waiting for isLoading")
                break
            }
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }

        // Try to call loadNextPage while the first is still running - should be a no-op
        await slowViewModel.loadNextPage(query: "test")

        await task.value

        // Only one call should have actually executed
        #expect(slowMockService.searchCallCount == 1, "Only one loadNextPage should have executed")
    }

    // MARK: - Page Size Tests

    @Test func customPageSize() async {
        let customViewModel = SearchViewModel(searchService: mockService, pageSize: 25)
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 0, docs: [])

        await customViewModel.search(query: "test")

        #expect(mockService.lastOptions?["rows"] == "25")
    }

    // MARK: - SearchMoviesAndMusic Tests

    @Test func searchMoviesAndMusicCombinesMediaTypes() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 4, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "music1", mediatype: "etree"),
            TestFixtures.makeSearchResult(identifier: "movie2", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "audio")
        ])

        await viewModel.searchMoviesAndMusic(query: "concert")

        #expect(viewModel.state.results.count == 4)
        #expect(viewModel.state.videoResults.count == 2)
        #expect(viewModel.state.musicResults.count == 2)
    }

    @Test func searchMoviesAndMusicWithEmptyQueryClearsResults() async {
        // First do a search
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        await viewModel.searchMoviesAndMusic(query: "test")

        // Search with empty query
        await viewModel.searchMoviesAndMusic(query: "")

        #expect(viewModel.state.results.isEmpty)
    }

    @Test func searchMoviesAndMusicWithWhitespaceQueryClearsResults() async {
        await viewModel.searchMoviesAndMusic(query: "   ")

        #expect(viewModel.state.results.isEmpty)
    }

    @Test func searchMoviesAndMusicSetsHasMoreResultsFalse() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])

        await viewModel.searchMoviesAndMusic(query: "test")

        // Single page search doesn't support pagination
        #expect(!viewModel.state.hasMoreResults)
    }

    @Test func searchMoviesAndMusicWithErrorSetsErrorMessage() async {
        mockService.errorToThrow = NetworkError.timeout

        await viewModel.searchMoviesAndMusic(query: "test")

        #expect(viewModel.state.errorMessage != nil)
        #expect(viewModel.state.results.isEmpty)
    }

    @Test func searchMoviesAndMusicCallsServiceWithCombinedQuery() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 0, docs: [])

        await viewModel.searchMoviesAndMusic(query: "grateful dead")

        #expect(mockService.searchCalled)
        #expect(mockService.lastQuery?.contains("grateful dead") ?? false)
        #expect(mockService.lastQuery?.contains("mediatype:(etree OR movies)") ?? false)
    }
}

// MARK: - SearchViewState Tests

@Suite("SearchViewState Tests")
struct SearchViewStateTests {

    @Test func initialState() {
        let state = SearchViewState.initial

        #expect(!state.isLoading)
        #expect(state.results.isEmpty)
        #expect(state.errorMessage == nil)
        #expect(state.totalResults == 0)
        #expect(state.currentPage == 0)
        #expect(!state.hasMoreResults)
    }

    @Test func initialStateCanBeModified() {
        var state = SearchViewState.initial
        state.isLoading = true
        state.totalResults = 100

        #expect(state.isLoading)
        #expect(state.totalResults == 100)
    }

    @Test func stateResultsCanBeAppended() {
        var state = SearchViewState.initial
        state.results = [TestFixtures.makeSearchResult(identifier: "1")]
        state.results.append(TestFixtures.makeSearchResult(identifier: "2"))

        #expect(state.results.count == 2)
    }

    @Test func stateErrorMessageCanBeCleared() {
        var state = SearchViewState.initial
        state.errorMessage = "Some error"
        state.errorMessage = nil

        #expect(state.errorMessage == nil)
    }

    @Test func stateAllPropertiesCanBeSet() {
        var state = SearchViewState.initial
        state.isLoading = true
        state.results = [TestFixtures.makeSearchResult(identifier: "1")]
        state.errorMessage = "Error"
        state.totalResults = 50
        state.currentPage = 2
        state.hasMoreResults = true

        #expect(state.isLoading)
        #expect(state.results.count == 1)
        #expect(state.errorMessage == "Error")
        #expect(state.totalResults == 50)
        #expect(state.currentPage == 2)
        #expect(state.hasMoreResults)
    }

    // MARK: - Media Type Filtering Tests

    @Test func videoResultsFiltersMovies() {
        var state = SearchViewState.initial
        state.results = [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "music1", mediatype: "etree"),
            TestFixtures.makeSearchResult(identifier: "movie2", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "audio")
        ]

        #expect(state.videoResults.count == 2)
        #expect(state.videoResults.allSatisfy { $0.safeMediaType == "movies" })
    }

    @Test func musicResultsFiltersEtreeAndAudio() {
        var state = SearchViewState.initial
        state.results = [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "music1", mediatype: "etree"),
            TestFixtures.makeSearchResult(identifier: "movie2", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "audio")
        ]

        #expect(state.musicResults.count == 2)
        #expect(state.musicResults.allSatisfy {
            $0.safeMediaType == "etree" || $0.safeMediaType == "audio"
        })
    }

    @Test func filterByMediaTypeCustomType() {
        var state = SearchViewState.initial
        state.results = [
            TestFixtures.makeSearchResult(identifier: "book1", mediatype: "texts"),
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "book2", mediatype: "texts")
        ]

        let textResults = state.filterByMediaType("texts")
        #expect(textResults.count == 2)
    }

    @Test func videoResultsEmptyWhenNoMovies() {
        var state = SearchViewState.initial
        state.results = [
            TestFixtures.makeSearchResult(identifier: "music1", mediatype: "etree"),
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "audio")
        ]

        #expect(state.videoResults.isEmpty)
    }

    @Test func musicResultsEmptyWhenNoMusic() {
        var state = SearchViewState.initial
        state.results = [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "movie2", mediatype: "movies")
        ]

        #expect(state.musicResults.isEmpty)
    }
}

// MARK: - Pagination and Filter Switching Tests

@Suite("Search Pagination Filter Tests", .serialized)
@MainActor
struct SearchPaginationFilterTests {

    var viewModel: SearchViewModel
    var mockService: MockSearchService

    init() {
        let service = MockSearchService()
        mockService = service
        viewModel = SearchViewModel(searchService: service, pageSize: 10)
    }

    // MARK: - Filter Switching Tests

    @Test func searchSwitchingQueriesResetsPage() async {
        // First search
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "first1")
        ])
        await viewModel.search(query: "first query")
        await viewModel.loadNextPage(query: "first query")

        #expect(viewModel.state.currentPage == 1)

        // Switch to new query - should reset pagination
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 50, docs: [
            TestFixtures.makeSearchResult(identifier: "second1")
        ])
        await viewModel.search(query: "second query")

        #expect(viewModel.state.currentPage == 0)
        #expect(viewModel.state.results.count == 1)
        #expect(viewModel.state.results.first?.identifier == "second1")
    }

    @Test func searchSwitchingQueriesClearsPreviousResults() async {
        // First search with movies
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 5, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "movie2", mediatype: "movies")
        ])
        await viewModel.search(query: "movies")
        #expect(viewModel.state.results.count == 2)

        // Switch to music query
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 3, docs: [
            TestFixtures.makeSearchResult(identifier: "music1", mediatype: "etree")
        ])
        await viewModel.search(query: "music")

        // Old results should be replaced
        #expect(viewModel.state.results.count == 1)
        #expect(viewModel.state.results.first?.safeMediaType == "etree")
    }

    @Test func searchMoviesAndMusicFilterSwitchFromRegularSearch() async {
        // First do a regular search
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 10, docs: [
            TestFixtures.makeSearchResult(identifier: "item1", mediatype: "texts")
        ])
        await viewModel.search(query: "books")
        #expect(viewModel.state.results.first?.safeMediaType == "texts")

        // Switch to movies and music filter
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 5, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "music1", mediatype: "etree")
        ])
        await viewModel.searchMoviesAndMusic(query: "entertainment")

        // Results should only include movies/music types
        #expect(viewModel.state.results.count == 2)
        #expect(viewModel.state.videoResults.count == 1)
        #expect(viewModel.state.musicResults.count == 1)
    }

    // MARK: - Pagination with Filter Changes

    @Test func loadNextPageAfterFilterChangeUsesNewFilter() async {
        // Initial search
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "1"),
            TestFixtures.makeSearchResult(identifier: "2")
        ])
        await viewModel.search(query: "test")

        // Load page 2 with same query
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "3"),
            TestFixtures.makeSearchResult(identifier: "4")
        ])
        await viewModel.loadNextPage(query: "test")

        #expect(viewModel.state.results.count == 4)
        #expect(viewModel.state.currentPage == 1)

        // Now change query and verify options are reset
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 50, docs: [
            TestFixtures.makeSearchResult(identifier: "new1")
        ])
        await viewModel.search(query: "different")

        #expect(mockService.lastOptions?["page"] == "1")
    }

    @Test func loadNextPageIncrementsPageCorrectly() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        await viewModel.search(query: "test")
        #expect(mockService.lastOptions?["page"] == "1")

        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "2")
        ])
        await viewModel.loadNextPage(query: "test")
        #expect(mockService.lastOptions?["page"] == "2")

        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "3")
        ])
        await viewModel.loadNextPage(query: "test")
        #expect(mockService.lastOptions?["page"] == "3")
    }

    // MARK: - Rapid Filter Switching Tests

    @Test func rapidSearchesLastResultsWin() async {
        // This tests that rapid searches don't cause race conditions
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "final")
        ])

        // Perform multiple searches quickly
        await viewModel.search(query: "first")
        await viewModel.search(query: "second")
        await viewModel.search(query: "third")

        // The last search's results should be shown
        #expect(viewModel.state.results.count == 1)
        #expect(mockService.lastQuery == "third")
    }

    @Test func searchClearsErrorOnNewSearch() async {
        // First search with error
        mockService.errorToThrow = NetworkError.timeout
        await viewModel.search(query: "error test")
        #expect(viewModel.state.errorMessage != nil)

        // New search should clear error
        mockService.errorToThrow = nil
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        await viewModel.search(query: "success")

        #expect(viewModel.state.errorMessage == nil)
        #expect(viewModel.state.results.count == 1)
    }
}
