//
//  SearchResultsHelpersTests.swift
//  Internet ArchiveTests
//
//  Unit tests for SearchResultsGridHelpers
//

import XCTest
import SwiftUI
@testable import Internet_Archive

final class SearchResultsHelpersTests: XCTestCase {

    // MARK: - Constants Tests

    func testDefaultPageSize() {
        XCTAssertEqual(SearchResultsGridHelpers.defaultPageSize, 30)
    }

    func testLoadMoreThreshold() {
        XCTAssertEqual(SearchResultsGridHelpers.loadMoreThreshold, 6)
    }

    // MARK: - Grid Columns Tests

    func testGridColumns_video() {
        let columns = SearchResultsGridHelpers.gridColumns(for: .video)
        XCTAssertEqual(columns.count, 1) // Adaptive layout uses single column definition
    }

    func testGridColumns_music() {
        let columns = SearchResultsGridHelpers.gridColumns(for: .music)
        XCTAssertEqual(columns.count, 1)
    }

    // MARK: - Skeleton Card Count Tests

    func testSkeletonCardCount_video() {
        let count = SearchResultsGridHelpers.skeletonCardCount(for: .video)
        XCTAssertEqual(count, 4)
    }

    func testSkeletonCardCount_music() {
        let count = SearchResultsGridHelpers.skeletonCardCount(for: .music)
        XCTAssertEqual(count, 6)
    }

    // MARK: - Skeleton Columns Tests

    func testSkeletonColumns_video() {
        let columns = SearchResultsGridHelpers.skeletonColumns(for: .video)
        XCTAssertEqual(columns, 4)
    }

    func testSkeletonColumns_music() {
        let columns = SearchResultsGridHelpers.skeletonColumns(for: .music)
        XCTAssertEqual(columns, 6)
    }

    // MARK: - Should Load More Tests

    func testShouldLoadMore_atThreshold() {
        // 30 items total, item at index 24 (6 from end) should trigger load
        let result = SearchResultsGridHelpers.shouldLoadMore(
            itemIndex: 24,
            totalItems: 30,
            hasMore: true,
            isLoadingMore: false
        )
        XCTAssertTrue(result)
    }

    func testShouldLoadMore_beyondThreshold() {
        // Item at index 25 (5 from end) should also trigger
        let result = SearchResultsGridHelpers.shouldLoadMore(
            itemIndex: 25,
            totalItems: 30,
            hasMore: true,
            isLoadingMore: false
        )
        XCTAssertTrue(result)
    }

    func testShouldLoadMore_beforeThreshold() {
        // Item at index 20 (10 from end) should not trigger
        let result = SearchResultsGridHelpers.shouldLoadMore(
            itemIndex: 20,
            totalItems: 30,
            hasMore: true,
            isLoadingMore: false
        )
        XCTAssertFalse(result)
    }

    func testShouldLoadMore_noMoreResults() {
        let result = SearchResultsGridHelpers.shouldLoadMore(
            itemIndex: 24,
            totalItems: 30,
            hasMore: false,
            isLoadingMore: false
        )
        XCTAssertFalse(result)
    }

    func testShouldLoadMore_alreadyLoading() {
        let result = SearchResultsGridHelpers.shouldLoadMore(
            itemIndex: 24,
            totalItems: 30,
            hasMore: true,
            isLoadingMore: true
        )
        XCTAssertFalse(result)
    }

    func testShouldLoadMore_smallList() {
        // 5 items total, all should trigger if hasMore
        let result = SearchResultsGridHelpers.shouldLoadMore(
            itemIndex: 0,
            totalItems: 5,
            hasMore: true,
            isLoadingMore: false
        )
        XCTAssertTrue(result)
    }

    // MARK: - Has More Pages Tests

    func testHasMorePages_fullPageMoreAvailable() {
        // Page 0, loaded 30, total 100
        let result = SearchResultsGridHelpers.hasMorePages(
            currentPage: 0,
            pageSize: 30,
            itemsLoaded: 30,
            totalFound: 100
        )
        XCTAssertTrue(result)
    }

    func testHasMorePages_partialPage() {
        // Partial page means no more results
        let result = SearchResultsGridHelpers.hasMorePages(
            currentPage: 0,
            pageSize: 30,
            itemsLoaded: 25,
            totalFound: 100
        )
        XCTAssertFalse(result)
    }

    func testHasMorePages_lastPage() {
        // Page 2 (3rd page), loaded 30, total 90 = exactly done
        let result = SearchResultsGridHelpers.hasMorePages(
            currentPage: 2,
            pageSize: 30,
            itemsLoaded: 30,
            totalFound: 90
        )
        XCTAssertFalse(result)
    }

    func testHasMorePages_pastTotal() {
        // Page 3 would exceed total
        let result = SearchResultsGridHelpers.hasMorePages(
            currentPage: 3,
            pageSize: 30,
            itemsLoaded: 30,
            totalFound: 100
        )
        XCTAssertFalse(result)
    }

    func testHasMorePages_zeroTotal() {
        let result = SearchResultsGridHelpers.hasMorePages(
            currentPage: 0,
            pageSize: 30,
            itemsLoaded: 0,
            totalFound: 0
        )
        XCTAssertFalse(result)
    }

    // MARK: - API Query Building Tests

    func testBuildMediaTypeQuery() {
        let query = SearchResultsGridHelpers.buildMediaTypeQuery(
            baseQuery: "nature",
            apiMediaType: "movies"
        )
        XCTAssertEqual(query, "nature AND mediatype:(movies)")
    }

    func testBuildMediaTypeQuery_complexBase() {
        let query = SearchResultsGridHelpers.buildMediaTypeQuery(
            baseQuery: "nature AND year:2024",
            apiMediaType: "audio"
        )
        XCTAssertEqual(query, "nature AND year:2024 AND mediatype:(audio)")
    }

    func testBuildSearchOptions_firstPage() {
        let options = SearchResultsGridHelpers.buildSearchOptions(pageSize: 30, page: 0)

        XCTAssertEqual(options["rows"], "30")
        XCTAssertEqual(options["page"], "1") // API uses 1-indexed
        XCTAssertEqual(options["sort[]"], "downloads desc")
        XCTAssertNotNil(options["fl[]"])
    }

    func testBuildSearchOptions_laterPage() {
        let options = SearchResultsGridHelpers.buildSearchOptions(pageSize: 30, page: 3)

        XCTAssertEqual(options["rows"], "30")
        XCTAssertEqual(options["page"], "4") // page 3 (0-indexed) = page 4 (1-indexed)
    }

    func testBuildSearchOptions_customPageSize() {
        let options = SearchResultsGridHelpers.buildSearchOptions(pageSize: 50, page: 0)

        XCTAssertEqual(options["rows"], "50")
    }

    func testBuildSearchOptions_containsRequiredFields() {
        let options = SearchResultsGridHelpers.buildSearchOptions(pageSize: 30, page: 0)

        // Verify fl[] contains the required fields
        let fields = options["fl[]"] ?? ""
        XCTAssertTrue(fields.contains("identifier"))
        XCTAssertTrue(fields.contains("title"))
        XCTAssertTrue(fields.contains("mediatype"))
        XCTAssertTrue(fields.contains("creator"))
        XCTAssertTrue(fields.contains("downloads"))
    }

    // MARK: - Loading State Tests

    func testShouldShowInitialLoading_loadingNoResults() {
        let result = SearchResultsGridHelpers.shouldShowInitialLoading(
            isLoading: true,
            resultsCount: 0
        )
        XCTAssertTrue(result)
    }

    func testShouldShowInitialLoading_loadingWithResults() {
        let result = SearchResultsGridHelpers.shouldShowInitialLoading(
            isLoading: true,
            resultsCount: 10
        )
        XCTAssertFalse(result)
    }

    func testShouldShowInitialLoading_notLoadingNoResults() {
        let result = SearchResultsGridHelpers.shouldShowInitialLoading(
            isLoading: false,
            resultsCount: 0
        )
        XCTAssertFalse(result)
    }

    func testShouldShowError_hasErrorNoResults() {
        let result = SearchResultsGridHelpers.shouldShowError(
            errorMessage: "Some error",
            resultsCount: 0
        )
        XCTAssertTrue(result)
    }

    func testShouldShowError_hasErrorWithResults() {
        let result = SearchResultsGridHelpers.shouldShowError(
            errorMessage: "Some error",
            resultsCount: 10
        )
        XCTAssertFalse(result)
    }

    func testShouldShowError_noError() {
        let result = SearchResultsGridHelpers.shouldShowError(
            errorMessage: nil,
            resultsCount: 0
        )
        XCTAssertFalse(result)
    }

    func testShouldShowEmpty_noResultsNotLoading() {
        let result = SearchResultsGridHelpers.shouldShowEmpty(
            resultsCount: 0,
            isLoading: false
        )
        XCTAssertTrue(result)
    }

    func testShouldShowEmpty_noResultsStillLoading() {
        let result = SearchResultsGridHelpers.shouldShowEmpty(
            resultsCount: 0,
            isLoading: true
        )
        XCTAssertFalse(result)
    }

    func testShouldShowEmpty_hasResults() {
        let result = SearchResultsGridHelpers.shouldShowEmpty(
            resultsCount: 10,
            isLoading: false
        )
        XCTAssertFalse(result)
    }
}
