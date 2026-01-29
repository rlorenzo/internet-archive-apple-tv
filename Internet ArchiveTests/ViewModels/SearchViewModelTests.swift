//
//  SearchViewModelTests.swift
//  Internet ArchiveTests
//
//  Unit tests for SearchViewModel
//

import XCTest
import Combine
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

@MainActor
final class SearchViewModelTests: XCTestCase {

    nonisolated(unsafe) var viewModel: SearchViewModel!
    nonisolated(unsafe) var mockService: MockSearchService!
    nonisolated(unsafe) var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        let (newMockService, newViewModel) = MainActor.assumeIsolated {
            let service = MockSearchService()
            let vm = SearchViewModel(searchService: service, pageSize: 10)
            return (service, vm)
        }
        mockService = newMockService
        viewModel = newViewModel
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        viewModel = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertTrue(viewModel.state.results.isEmpty)
        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertEqual(viewModel.state.totalResults, 0)
        XCTAssertEqual(viewModel.state.currentPage, 0)
        XCTAssertFalse(viewModel.state.hasMoreResults)
    }

    // MARK: - Search Tests

    func testSearch_withValidQuery_callsService() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 5, docs: [
            TestFixtures.makeSearchResult(identifier: "1"),
            TestFixtures.makeSearchResult(identifier: "2")
        ])

        await viewModel.search(query: "test query")

        XCTAssertTrue(mockService.searchCalled)
        XCTAssertEqual(mockService.lastQuery, "test query")
    }

    func testSearch_withValidQuery_updatesState() async {
        let results = [
            TestFixtures.makeSearchResult(identifier: "1"),
            TestFixtures.makeSearchResult(identifier: "2"),
            TestFixtures.makeSearchResult(identifier: "3")
        ]
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 3, docs: results)

        await viewModel.search(query: "movies")

        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertEqual(viewModel.state.results.count, 3)
        XCTAssertEqual(viewModel.state.totalResults, 3)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    func testSearch_withEmptyQuery_clearsResults() async {
        // First do a search
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        await viewModel.search(query: "test")

        // Then search with empty query
        mockService.reset()
        await viewModel.search(query: "")

        XCTAssertFalse(mockService.searchCalled)
        XCTAssertTrue(viewModel.state.results.isEmpty)
    }

    func testSearch_withWhitespaceQuery_clearsResults() async {
        await viewModel.search(query: "   ")

        XCTAssertFalse(mockService.searchCalled)
        XCTAssertTrue(viewModel.state.results.isEmpty)
    }

    func testSearch_withWhitespaceQuery_resetsToInitialState() async {
        // First perform a valid search to populate state
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        await viewModel.search(query: "test")
        XCTAssertFalse(viewModel.state.results.isEmpty)
        XCTAssertTrue(viewModel.state.hasMoreResults)
        XCTAssertEqual(viewModel.state.totalResults, 100)

        // Now search with whitespace-only - should reset to initial state
        await viewModel.search(query: "   ")

        // Verify full state reset (matches SearchViewState.initial)
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertTrue(viewModel.state.results.isEmpty)
        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertEqual(viewModel.state.totalResults, 0)
        XCTAssertEqual(viewModel.state.currentPage, 0)
        XCTAssertFalse(viewModel.state.hasMoreResults)
    }

    func testSearch_withError_setsErrorMessage() async {
        mockService.errorToThrow = NetworkError.timeout

        await viewModel.search(query: "test")

        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.results.isEmpty)
    }

    func testSearch_withNetworkError_showsUserFriendlyMessage() async {
        mockService.errorToThrow = NetworkError.noConnection

        await viewModel.search(query: "test")

        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.errorMessage?.contains("internet") ?? false)
    }

    // MARK: - Pagination Tests

    func testSearch_setsHasMoreResults_whenMoreAvailable() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])

        await viewModel.search(query: "test")

        XCTAssertTrue(viewModel.state.hasMoreResults)
    }

    func testSearch_setsHasMoreResults_false_whenAllLoaded() async {
        let results = [TestFixtures.makeSearchResult(identifier: "1")]
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: results)

        await viewModel.search(query: "test")

        XCTAssertFalse(viewModel.state.hasMoreResults)
    }

    func testLoadNextPage_appendsResults() async {
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

        XCTAssertEqual(viewModel.state.results.count, 4)
        XCTAssertEqual(viewModel.state.currentPage, 1)
    }

    func testLoadNextPage_doesNotLoad_whenNoMoreResults() async {
        let results = [TestFixtures.makeSearchResult(identifier: "1")]
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: results)
        await viewModel.search(query: "test")

        mockService.reset()
        await viewModel.loadNextPage(query: "test")

        XCTAssertFalse(mockService.searchCalled)
    }

    // MARK: - Clear Results Tests

    func testClearResults_resetsState() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 5, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        await viewModel.search(query: "test")

        viewModel.clearResults()

        XCTAssertTrue(viewModel.state.results.isEmpty)
        XCTAssertEqual(viewModel.state.totalResults, 0)
        XCTAssertEqual(viewModel.state.currentPage, 0)
    }

    // MARK: - Search Options Tests

    func testSearch_includesCorrectOptions() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 0, docs: [])

        await viewModel.search(query: "test")

        XCTAssertEqual(mockService.lastOptions?["rows"], "10")
        XCTAssertEqual(mockService.lastOptions?["page"], "1")
        XCTAssertNotNil(mockService.lastOptions?["fl[]"])
    }

    // MARK: - Error Type Tests

    func testSearch_withServerError_showsAppropriateMessage() async {
        mockService.errorToThrow = NetworkError.serverError(statusCode: 500)

        await viewModel.search(query: "test")

        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.errorMessage?.lowercased().contains("server") ?? false ||
                      viewModel.state.errorMessage?.lowercased().contains("archive") ?? false)
    }

    func testSearch_withTimeoutError_showsAppropriateMessage() async {
        mockService.errorToThrow = NetworkError.timeout

        await viewModel.search(query: "test")

        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.errorMessage?.lowercased().contains("long") ?? false ||
                      viewModel.state.errorMessage?.lowercased().contains("connection") ?? false)
    }

    func testSearch_withGenericError_showsDefaultMessage() async {
        mockService.errorToThrow = NSError(domain: "test", code: 123, userInfo: nil)

        await viewModel.search(query: "test")

        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.errorMessage?.contains("unexpected") ?? false)
    }

    // MARK: - Sequential Search Tests

    func testSequentialSearches_lastSearchResultsShown() async {
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
        XCTAssertEqual(viewModel.state.results.count, 2)
        XCTAssertEqual(viewModel.state.results.first?.identifier, "second1")
    }

    // MARK: - Search Options Edge Cases

    func testSearch_withSpecialCharactersInQuery() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 0, docs: [])

        await viewModel.search(query: "test & special <chars>")

        XCTAssertTrue(mockService.searchCalled)
        XCTAssertEqual(mockService.lastQuery, "test & special <chars>")
    }

    func testSearch_withUnicodeQuery() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 0, docs: [])

        await viewModel.search(query: "测试 日本語 한국어")

        XCTAssertTrue(mockService.searchCalled)
    }

    func testSearch_withVeryLongQuery() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 0, docs: [])
        let longQuery = String(repeating: "test ", count: 100)

        await viewModel.search(query: longQuery)

        XCTAssertTrue(mockService.searchCalled)
    }

    // MARK: - Pagination Edge Cases

    func testLoadNextPage_withError_preservesExistingResults() async {
        // Initial search
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 20, docs: [
            TestFixtures.makeSearchResult(identifier: "1"),
            TestFixtures.makeSearchResult(identifier: "2")
        ])
        await viewModel.search(query: "test")
        XCTAssertEqual(viewModel.state.results.count, 2)

        // Load next page with error
        mockService.errorToThrow = NetworkError.timeout
        await viewModel.loadNextPage(query: "test")

        // Original results should be preserved
        XCTAssertEqual(viewModel.state.results.count, 2)
        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    func testLoadNextPage_whileLoading_doesNothing() async {
        // Configure mock with a delay to keep isLoading true
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        await viewModel.search(query: "test")
        XCTAssertTrue(viewModel.state.hasMoreResults)

        // Now configure mock with a longer delay for the next operation
        let slowMockService = SlowMockSearchService()
        slowMockService.delayMilliseconds = 500
        slowMockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "2")
        ])

        // Create a new viewModel that uses the slow service
        let slowViewModel = SearchViewModel(searchService: slowMockService, pageSize: 10)
        slowMockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])

        // First search to establish state
        await slowViewModel.search(query: "test")

        // Reset call counter and start a slow operation
        slowMockService.searchCallCount = 0
        slowMockService.delayMilliseconds = 500

        // Use expectation to wait for isLoading to become true
        let loadingStarted = expectation(description: "Loading should start")
        loadingStarted.assertForOverFulfill = false

        slowViewModel.$state
            .map(\.isLoading)
            .dropFirst()
            .sink { isLoading in
                if isLoading {
                    loadingStarted.fulfill()
                }
            }
            .store(in: &cancellables)

        let task = Task {
            await slowViewModel.loadNextPage(query: "test")
        }

        // Wait for loading to start (deterministic, not timing-based)
        await fulfillment(of: [loadingStarted], timeout: 2.0)

        // Now try to call loadNextPage while the first is still running
        // This should be a no-op due to isLoading guard
        await slowViewModel.loadNextPage(query: "test")

        await task.value

        // Only one call should have actually executed (the second should have been blocked)
        // The search call count includes both search() and loadNextPage() calls
        XCTAssertEqual(slowMockService.searchCallCount, 1, "Only one loadNextPage should have executed")
    }

    // MARK: - Page Size Tests

    func testCustomPageSize() async {
        let customViewModel = SearchViewModel(searchService: mockService, pageSize: 25)
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 0, docs: [])

        await customViewModel.search(query: "test")

        XCTAssertEqual(mockService.lastOptions?["rows"], "25")
    }

    // MARK: - SearchMoviesAndMusic Tests

    func testSearchMoviesAndMusic_combinesMediaTypes() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 4, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "music1", mediatype: "etree"),
            TestFixtures.makeSearchResult(identifier: "movie2", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "audio")
        ])

        await viewModel.searchMoviesAndMusic(query: "concert")

        XCTAssertEqual(viewModel.state.results.count, 4)
        XCTAssertEqual(viewModel.state.videoResults.count, 2)
        XCTAssertEqual(viewModel.state.musicResults.count, 2)
    }

    func testSearchMoviesAndMusic_withEmptyQuery_clearsResults() async {
        // First do a search
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        await viewModel.searchMoviesAndMusic(query: "test")

        // Search with empty query
        await viewModel.searchMoviesAndMusic(query: "")

        XCTAssertTrue(viewModel.state.results.isEmpty)
    }

    func testSearchMoviesAndMusic_withWhitespaceQuery_clearsResults() async {
        await viewModel.searchMoviesAndMusic(query: "   ")

        XCTAssertTrue(viewModel.state.results.isEmpty)
    }

    func testSearchMoviesAndMusic_setsHasMoreResultsFalse() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])

        await viewModel.searchMoviesAndMusic(query: "test")

        // Single page search doesn't support pagination
        XCTAssertFalse(viewModel.state.hasMoreResults)
    }

    func testSearchMoviesAndMusic_withError_setsErrorMessage() async {
        mockService.errorToThrow = NetworkError.timeout

        await viewModel.searchMoviesAndMusic(query: "test")

        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.results.isEmpty)
    }

    func testSearchMoviesAndMusic_callsServiceWithCombinedQuery() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 0, docs: [])

        await viewModel.searchMoviesAndMusic(query: "grateful dead")

        XCTAssertTrue(mockService.searchCalled)
        XCTAssertTrue(mockService.lastQuery?.contains("grateful dead") ?? false)
        XCTAssertTrue(mockService.lastQuery?.contains("mediatype:(etree OR movies)") ?? false)
    }
}

// MARK: - SearchViewState Tests

final class SearchViewStateTests: XCTestCase {

    func testInitialState() {
        let state = SearchViewState.initial

        XCTAssertFalse(state.isLoading)
        XCTAssertTrue(state.results.isEmpty)
        XCTAssertNil(state.errorMessage)
        XCTAssertEqual(state.totalResults, 0)
        XCTAssertEqual(state.currentPage, 0)
        XCTAssertFalse(state.hasMoreResults)
    }

    func testInitialState_canBeModified() {
        var state = SearchViewState.initial
        state.isLoading = true
        state.totalResults = 100

        XCTAssertTrue(state.isLoading)
        XCTAssertEqual(state.totalResults, 100)
    }

    func testState_resultsCanBeAppended() {
        var state = SearchViewState.initial
        state.results = [TestFixtures.makeSearchResult(identifier: "1")]
        state.results.append(TestFixtures.makeSearchResult(identifier: "2"))

        XCTAssertEqual(state.results.count, 2)
    }

    func testState_errorMessageCanBeCleared() {
        var state = SearchViewState.initial
        state.errorMessage = "Some error"
        state.errorMessage = nil

        XCTAssertNil(state.errorMessage)
    }

    func testState_allPropertiesCanBeSet() {
        var state = SearchViewState.initial
        state.isLoading = true
        state.results = [TestFixtures.makeSearchResult(identifier: "1")]
        state.errorMessage = "Error"
        state.totalResults = 50
        state.currentPage = 2
        state.hasMoreResults = true

        XCTAssertTrue(state.isLoading)
        XCTAssertEqual(state.results.count, 1)
        XCTAssertEqual(state.errorMessage, "Error")
        XCTAssertEqual(state.totalResults, 50)
        XCTAssertEqual(state.currentPage, 2)
        XCTAssertTrue(state.hasMoreResults)
    }

    // MARK: - Media Type Filtering Tests

    func testVideoResults_filtersMovies() {
        var state = SearchViewState.initial
        state.results = [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "music1", mediatype: "etree"),
            TestFixtures.makeSearchResult(identifier: "movie2", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "audio")
        ]

        XCTAssertEqual(state.videoResults.count, 2)
        XCTAssertTrue(state.videoResults.allSatisfy { $0.safeMediaType == "movies" })
    }

    func testMusicResults_filtersEtreeAndAudio() {
        var state = SearchViewState.initial
        state.results = [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "music1", mediatype: "etree"),
            TestFixtures.makeSearchResult(identifier: "movie2", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "audio")
        ]

        XCTAssertEqual(state.musicResults.count, 2)
        XCTAssertTrue(state.musicResults.allSatisfy {
            $0.safeMediaType == "etree" || $0.safeMediaType == "audio"
        })
    }

    func testFilterByMediaType_customType() {
        var state = SearchViewState.initial
        state.results = [
            TestFixtures.makeSearchResult(identifier: "book1", mediatype: "texts"),
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "book2", mediatype: "texts")
        ]

        let textResults = state.filterByMediaType("texts")
        XCTAssertEqual(textResults.count, 2)
    }

    func testVideoResults_emptyWhenNoMovies() {
        var state = SearchViewState.initial
        state.results = [
            TestFixtures.makeSearchResult(identifier: "music1", mediatype: "etree"),
            TestFixtures.makeSearchResult(identifier: "audio1", mediatype: "audio")
        ]

        XCTAssertTrue(state.videoResults.isEmpty)
    }

    func testMusicResults_emptyWhenNoMusic() {
        var state = SearchViewState.initial
        state.results = [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "movie2", mediatype: "movies")
        ]

        XCTAssertTrue(state.musicResults.isEmpty)
    }
}

// MARK: - Pagination and Filter Switching Tests

@MainActor
final class SearchPaginationFilterTests: XCTestCase {

    nonisolated(unsafe) var viewModel: SearchViewModel!
    nonisolated(unsafe) var mockService: MockSearchService!

    override func setUp() {
        super.setUp()
        let (newMockService, newViewModel) = MainActor.assumeIsolated {
            let service = MockSearchService()
            let vm = SearchViewModel(searchService: service, pageSize: 10)
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

    // MARK: - Filter Switching Tests

    func testSearch_switchingQueries_resetsPage() async {
        // First search
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "first1")
        ])
        await viewModel.search(query: "first query")
        await viewModel.loadNextPage(query: "first query")

        XCTAssertEqual(viewModel.state.currentPage, 1)

        // Switch to new query - should reset pagination
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 50, docs: [
            TestFixtures.makeSearchResult(identifier: "second1")
        ])
        await viewModel.search(query: "second query")

        XCTAssertEqual(viewModel.state.currentPage, 0)
        XCTAssertEqual(viewModel.state.results.count, 1)
        XCTAssertEqual(viewModel.state.results.first?.identifier, "second1")
    }

    func testSearch_switchingQueries_clearsPreviousResults() async {
        // First search with movies
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 5, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "movie2", mediatype: "movies")
        ])
        await viewModel.search(query: "movies")
        XCTAssertEqual(viewModel.state.results.count, 2)

        // Switch to music query
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 3, docs: [
            TestFixtures.makeSearchResult(identifier: "music1", mediatype: "etree")
        ])
        await viewModel.search(query: "music")

        // Old results should be replaced
        XCTAssertEqual(viewModel.state.results.count, 1)
        XCTAssertEqual(viewModel.state.results.first?.safeMediaType, "etree")
    }

    func testSearchMoviesAndMusic_filterSwitchFromRegularSearch() async {
        // First do a regular search
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 10, docs: [
            TestFixtures.makeSearchResult(identifier: "item1", mediatype: "texts")
        ])
        await viewModel.search(query: "books")
        XCTAssertEqual(viewModel.state.results.first?.safeMediaType, "texts")

        // Switch to movies and music filter
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 5, docs: [
            TestFixtures.makeSearchResult(identifier: "movie1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "music1", mediatype: "etree")
        ])
        await viewModel.searchMoviesAndMusic(query: "entertainment")

        // Results should only include movies/music types
        XCTAssertEqual(viewModel.state.results.count, 2)
        XCTAssertEqual(viewModel.state.videoResults.count, 1)
        XCTAssertEqual(viewModel.state.musicResults.count, 1)
    }

    // MARK: - Pagination with Filter Changes

    func testLoadNextPage_afterFilterChange_usesNewFilter() async {
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

        XCTAssertEqual(viewModel.state.results.count, 4)
        XCTAssertEqual(viewModel.state.currentPage, 1)

        // Now change query and verify options are reset
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 50, docs: [
            TestFixtures.makeSearchResult(identifier: "new1")
        ])
        await viewModel.search(query: "different")

        XCTAssertEqual(mockService.lastOptions?["page"], "1")
    }

    func testLoadNextPage_incrementsPageCorrectly() async {
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        await viewModel.search(query: "test")
        XCTAssertEqual(mockService.lastOptions?["page"], "1")

        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "2")
        ])
        await viewModel.loadNextPage(query: "test")
        XCTAssertEqual(mockService.lastOptions?["page"], "2")

        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 100, docs: [
            TestFixtures.makeSearchResult(identifier: "3")
        ])
        await viewModel.loadNextPage(query: "test")
        XCTAssertEqual(mockService.lastOptions?["page"], "3")
    }

    // MARK: - Rapid Filter Switching Tests

    func testRapidSearches_lastResultsWin() async {
        // This tests that rapid searches don't cause race conditions
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "final")
        ])

        // Perform multiple searches quickly
        await viewModel.search(query: "first")
        await viewModel.search(query: "second")
        await viewModel.search(query: "third")

        // The last search's results should be shown
        XCTAssertEqual(viewModel.state.results.count, 1)
        XCTAssertEqual(mockService.lastQuery, "third")
    }

    func testSearch_clearsErrorOnNewSearch() async {
        // First search with error
        mockService.errorToThrow = NetworkError.timeout
        await viewModel.search(query: "error test")
        XCTAssertNotNil(viewModel.state.errorMessage)

        // New search should clear error
        mockService.errorToThrow = nil
        mockService.mockResponse = TestFixtures.makeSearchResponse(numFound: 1, docs: [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        await viewModel.search(query: "success")

        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertEqual(viewModel.state.results.count, 1)
    }
}

