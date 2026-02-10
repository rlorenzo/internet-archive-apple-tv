//
//  SearchHelpersTests.swift
//  Internet ArchiveTests
//
//  Tests for SearchHelpers - content filters, search state, query building
//

import XCTest
@testable import Internet_Archive

// MARK: - SearchContentFilter Tests

final class SearchContentFilterTests: XCTestCase {

    // MARK: - Display Name Tests

    func testDisplayName_all_returnsAll() {
        XCTAssertEqual(SearchContentFilter.all.displayName, "All")
    }

    func testDisplayName_videos_returnsVideos() {
        XCTAssertEqual(SearchContentFilter.videos.displayName, "Videos")
    }

    func testDisplayName_music_returnsMusic() {
        XCTAssertEqual(SearchContentFilter.music.displayName, "Music")
    }

    // MARK: - API Media Type Tests

    func testApiMediaType_all_includesAllTypes() {
        let mediaType = SearchContentFilter.all.apiMediaType
        XCTAssertTrue(mediaType.contains("movies"))
        XCTAssertTrue(mediaType.contains("etree"))
        XCTAssertTrue(mediaType.contains("audio"))
    }

    func testApiMediaType_videos_includesOnlyMovies() {
        let mediaType = SearchContentFilter.videos.apiMediaType
        XCTAssertEqual(mediaType, "movies")
    }

    func testApiMediaType_music_includesMusicTypes() {
        let mediaType = SearchContentFilter.music.apiMediaType
        XCTAssertTrue(mediaType.contains("etree"))
        XCTAssertTrue(mediaType.contains("audio"))
        XCTAssertFalse(mediaType.contains("movies"))
    }

    // MARK: - Includes Tests

    func testIncludesVideos_all_returnsTrue() {
        XCTAssertTrue(SearchContentFilter.all.includesVideos)
    }

    func testIncludesVideos_videos_returnsTrue() {
        XCTAssertTrue(SearchContentFilter.videos.includesVideos)
    }

    func testIncludesVideos_music_returnsFalse() {
        XCTAssertFalse(SearchContentFilter.music.includesVideos)
    }

    func testIncludesMusic_all_returnsTrue() {
        XCTAssertTrue(SearchContentFilter.all.includesMusic)
    }

    func testIncludesMusic_music_returnsTrue() {
        XCTAssertTrue(SearchContentFilter.music.includesMusic)
    }

    func testIncludesMusic_videos_returnsFalse() {
        XCTAssertFalse(SearchContentFilter.videos.includesMusic)
    }

    // MARK: - Identifiable Tests

    func testId_matchesRawValue() {
        XCTAssertEqual(SearchContentFilter.all.id, "all")
        XCTAssertEqual(SearchContentFilter.videos.id, "videos")
        XCTAssertEqual(SearchContentFilter.music.id, "music")
    }

    // MARK: - CaseIterable Tests

    func testAllCases_containsThreeCases() {
        XCTAssertEqual(SearchContentFilter.allCases.count, 3)
        XCTAssertTrue(SearchContentFilter.allCases.contains(.all))
        XCTAssertTrue(SearchContentFilter.allCases.contains(.videos))
        XCTAssertTrue(SearchContentFilter.allCases.contains(.music))
    }
}

// Note: SearchResultsDestination tests are in SearchViewTests.swift

// MARK: - SearchContentState Tests

final class SearchContentStateTests: XCTestCase {

    func testDetermine_emptySearchText_returnsEmpty() {
        let state = SearchContentState.determine(
            searchText: "",
            isSearching: false,
            hasError: false,
            videoResultsCount: 0,
            musicResultsCount: 0
        )

        XCTAssertEqual(state, .empty)
    }

    func testDetermine_emptySearchText_evenWithResults_returnsEmpty() {
        let state = SearchContentState.determine(
            searchText: "",
            isSearching: false,
            hasError: false,
            videoResultsCount: 10,
            musicResultsCount: 5
        )

        XCTAssertEqual(state, .empty)
    }

    func testDetermine_searchingNoResults_returnsLoading() {
        let state = SearchContentState.determine(
            searchText: "cats",
            isSearching: true,
            hasError: false,
            videoResultsCount: 0,
            musicResultsCount: 0
        )

        XCTAssertEqual(state, .loading)
    }

    func testDetermine_searchingWithResults_returnsResults() {
        // When searching but already have results (pagination), show results
        let state = SearchContentState.determine(
            searchText: "cats",
            isSearching: true,
            hasError: false,
            videoResultsCount: 10,
            musicResultsCount: 0
        )

        XCTAssertEqual(state, .results)
    }

    func testDetermine_hasError_returnsError() {
        let state = SearchContentState.determine(
            searchText: "cats",
            isSearching: false,
            hasError: true,
            videoResultsCount: 0,
            musicResultsCount: 0
        )

        XCTAssertEqual(state, .error)
    }

    func testDetermine_notSearchingNoResults_returnsNoResults() {
        let state = SearchContentState.determine(
            searchText: "xyzabc123",
            isSearching: false,
            hasError: false,
            videoResultsCount: 0,
            musicResultsCount: 0
        )

        XCTAssertEqual(state, .noResults)
    }

    func testDetermine_hasVideoResults_returnsResults() {
        let state = SearchContentState.determine(
            searchText: "cats",
            isSearching: false,
            hasError: false,
            videoResultsCount: 10,
            musicResultsCount: 0
        )

        XCTAssertEqual(state, .results)
    }

    func testDetermine_hasMusicResults_returnsResults() {
        let state = SearchContentState.determine(
            searchText: "grateful dead",
            isSearching: false,
            hasError: false,
            videoResultsCount: 0,
            musicResultsCount: 15
        )

        XCTAssertEqual(state, .results)
    }

    func testDetermine_hasBothResults_returnsResults() {
        let state = SearchContentState.determine(
            searchText: "concert",
            isSearching: false,
            hasError: false,
            videoResultsCount: 5,
            musicResultsCount: 10
        )

        XCTAssertEqual(state, .results)
    }
}

// MARK: - SearchQueryBuilder Tests

final class SearchQueryBuilderTests: XCTestCase {

    func testBuildQuery_combinesTextAndMediaType() {
        let query = SearchQueryBuilder.buildQuery(
            searchText: "cats",
            mediaType: "movies"
        )

        XCTAssertEqual(query, "cats AND mediatype:(movies)")
    }

    func testBuildQuery_complexMediaType() {
        let query = SearchQueryBuilder.buildQuery(
            searchText: "music",
            mediaType: "etree OR audio"
        )

        XCTAssertEqual(query, "music AND mediatype:(etree OR audio)")
    }

    func testBuildQuery_preservesSearchText() {
        let query = SearchQueryBuilder.buildQuery(
            searchText: "grateful dead 1977",
            mediaType: "etree"
        )

        XCTAssertTrue(query.contains("grateful dead 1977"))
    }

    func testBuildOptions_defaultSort() {
        let options = SearchQueryBuilder.buildOptions(pageSize: 20, page: 0)

        XCTAssertEqual(options["rows"], "20")
        XCTAssertEqual(options["page"], "1")  // 0-based to 1-based
        XCTAssertEqual(options["sort[]"], "downloads desc")
        XCTAssertTrue(options["fl[]"]?.contains("identifier") ?? false)
    }

    func testBuildOptions_customSort() {
        let options = SearchQueryBuilder.buildOptions(
            pageSize: 50,
            page: 2,
            sortField: "date",
            sortDirection: "asc"
        )

        XCTAssertEqual(options["rows"], "50")
        XCTAssertEqual(options["page"], "3")  // page 2 becomes 3 (1-based)
        XCTAssertEqual(options["sort[]"], "date asc")
    }

    func testBuildOptions_includesRequiredFields() {
        let options = SearchQueryBuilder.buildOptions(pageSize: 20, page: 0)
        let fields = options["fl[]"] ?? ""

        XCTAssertTrue(fields.contains("identifier"))
        XCTAssertTrue(fields.contains("title"))
        XCTAssertTrue(fields.contains("mediatype"))
        XCTAssertTrue(fields.contains("creator"))
        XCTAssertTrue(fields.contains("description"))
    }

    func testHasMoreResults_fullPage_belowTotal_returnsTrue() {
        let hasMore = SearchQueryBuilder.hasMoreResults(
            currentResultCount: 20,
            pageSize: 20,
            currentPage: 0,
            totalResults: 100
        )

        XCTAssertTrue(hasMore)
    }

    func testHasMoreResults_partialPage_returnsFalse() {
        let hasMore = SearchQueryBuilder.hasMoreResults(
            currentResultCount: 15,
            pageSize: 20,
            currentPage: 0,
            totalResults: 100
        )

        XCTAssertFalse(hasMore)
    }

    func testHasMoreResults_atTotal_returnsFalse() {
        let hasMore = SearchQueryBuilder.hasMoreResults(
            currentResultCount: 20,
            pageSize: 20,
            currentPage: 4,
            totalResults: 100  // 5 pages of 20 = 100
        )

        XCTAssertFalse(hasMore)
    }

    func testHasMoreResults_pastTotal_returnsFalse() {
        let hasMore = SearchQueryBuilder.hasMoreResults(
            currentResultCount: 20,
            pageSize: 20,
            currentPage: 5,
            totalResults: 100
        )

        XCTAssertFalse(hasMore)
    }
}

// MARK: - PaginationState Tests

final class PaginationStateTests: XCTestCase {

    func testInit_defaultValues() {
        let state = PaginationState()

        XCTAssertEqual(state.currentPage, 0)
        XCTAssertFalse(state.hasMore)
        XCTAssertFalse(state.isLoading)
    }

    func testReset_resetsAllValues() {
        var state = PaginationState()
        state.currentPage = 5
        state.hasMore = true
        state.isLoading = true

        state.reset()

        XCTAssertEqual(state.currentPage, 0)
        XCTAssertFalse(state.hasMore)
        XCTAssertFalse(state.isLoading)
    }

    func testAdvancePage_incrementsPage() {
        var state = PaginationState()
        state.advancePage()

        XCTAssertEqual(state.currentPage, 1)

        state.advancePage()
        XCTAssertEqual(state.currentPage, 2)
    }

    func testShouldLoadMore_atThreshold_returnsTrue() {
        var state = PaginationState()
        state.hasMore = true
        state.isLoading = false

        // With 10 items and threshold of 3, index 7+ should trigger load
        XCTAssertTrue(state.shouldLoadMore(itemIndex: 7, totalItems: 10))
        XCTAssertTrue(state.shouldLoadMore(itemIndex: 8, totalItems: 10))
        XCTAssertTrue(state.shouldLoadMore(itemIndex: 9, totalItems: 10))
    }

    func testShouldLoadMore_belowThreshold_returnsFalse() {
        var state = PaginationState()
        state.hasMore = true
        state.isLoading = false

        XCTAssertFalse(state.shouldLoadMore(itemIndex: 5, totalItems: 10))
        XCTAssertFalse(state.shouldLoadMore(itemIndex: 0, totalItems: 10))
    }

    func testShouldLoadMore_noMore_returnsFalse() {
        var state = PaginationState()
        state.hasMore = false
        state.isLoading = false

        XCTAssertFalse(state.shouldLoadMore(itemIndex: 9, totalItems: 10))
    }

    func testShouldLoadMore_isLoading_returnsFalse() {
        var state = PaginationState()
        state.hasMore = true
        state.isLoading = true

        XCTAssertFalse(state.shouldLoadMore(itemIndex: 9, totalItems: 10))
    }

    func testShouldLoadMore_customThreshold() {
        var state = PaginationState()
        state.hasMore = true
        state.isLoading = false

        // With threshold of 5, index 5+ should trigger (10 - 5 = 5)
        XCTAssertTrue(state.shouldLoadMore(itemIndex: 5, totalItems: 10, threshold: 5))
        XCTAssertFalse(state.shouldLoadMore(itemIndex: 4, totalItems: 10, threshold: 5))
    }

    func testEquatable() {
        let state1 = PaginationState()
        var state2 = PaginationState()

        XCTAssertEqual(state1, state2)

        state2.currentPage = 1
        XCTAssertNotEqual(state1, state2)
    }
}
