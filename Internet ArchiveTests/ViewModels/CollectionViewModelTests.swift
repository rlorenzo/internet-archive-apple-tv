//
//  CollectionViewModelTests.swift
//  Internet ArchiveTests
//
//  Unit tests for CollectionViewModel
//

import XCTest
@testable import Internet_Archive

// MARK: - Mock Collection Service

final class MockCollectionService: CollectionServiceProtocol, @unchecked Sendable {
    var getCollectionsCalled = false
    var getMetadataCalled = false
    var lastCollection: String?
    var lastResultType: String?
    var lastIdentifier: String?
    var mockCollectionsResponse: (collection: String, results: [SearchResult])?
    var mockMetadataResponse: ItemMetadataResponse?
    var errorToThrow: Error?

    func getCollections(collection: String, resultType: String, limit: Int?) async throws -> (collection: String, results: [SearchResult]) {
        getCollectionsCalled = true
        lastCollection = collection
        lastResultType = resultType

        if let error = errorToThrow {
            throw error
        }

        guard let response = mockCollectionsResponse else {
            return (collection, [])
        }

        return response
    }

    func getMetadata(identifier: String) async throws -> ItemMetadataResponse {
        getMetadataCalled = true
        lastIdentifier = identifier

        if let error = errorToThrow {
            throw error
        }

        guard let response = mockMetadataResponse else {
            throw NetworkError.resourceNotFound
        }

        return response
    }

    func reset() {
        getCollectionsCalled = false
        getMetadataCalled = false
        lastCollection = nil
        lastResultType = nil
        lastIdentifier = nil
        mockCollectionsResponse = nil
        mockMetadataResponse = nil
        errorToThrow = nil
    }
}

// MARK: - CollectionViewModel Tests

@MainActor
final class CollectionViewModelTests: XCTestCase {

    nonisolated(unsafe) var viewModel: CollectionViewModel!
    nonisolated(unsafe) var mockService: MockCollectionService!

    override func setUp() {
        super.setUp()
        let (newMockService, newViewModel) = MainActor.assumeIsolated {
            let service = MockCollectionService()
            let vm = CollectionViewModel(collectionService: service)
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
        XCTAssertTrue(viewModel.state.items.isEmpty)
        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertEqual(viewModel.state.collectionName, "")
    }

    // MARK: - Load Collection Tests

    func testLoadCollection_callsService() async {
        mockService.mockCollectionsResponse = ("test_collection", [])

        await viewModel.loadCollection(name: "test_collection", mediaType: "movies")

        XCTAssertTrue(mockService.getCollectionsCalled)
        XCTAssertEqual(mockService.lastCollection, "test_collection")
        XCTAssertEqual(mockService.lastResultType, "movies")
    }

    func testLoadCollection_updatesState() async {
        let items = [
            TestFixtures.makeSearchResult(identifier: "1"),
            TestFixtures.makeSearchResult(identifier: "2")
        ]
        mockService.mockCollectionsResponse = ("test_collection", items)

        await viewModel.loadCollection(name: "test_collection", mediaType: "movies")

        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertEqual(viewModel.state.items.count, 2)
        XCTAssertEqual(viewModel.state.collectionName, "test_collection")
        XCTAssertNil(viewModel.state.errorMessage)
    }

    func testLoadCollection_withError_setsErrorMessage() async {
        mockService.errorToThrow = NetworkError.timeout

        await viewModel.loadCollection(name: "test", mediaType: "movies")

        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.items.isEmpty)
    }

    // MARK: - Load Metadata Tests

    func testLoadItemMetadata_callsService() async {
        mockService.mockMetadataResponse = TestFixtures.movieMetadataResponse

        _ = await viewModel.loadItemMetadata(identifier: "test_item")

        XCTAssertTrue(mockService.getMetadataCalled)
        XCTAssertEqual(mockService.lastIdentifier, "test_item")
    }

    func testLoadItemMetadata_returnsResponse() async {
        mockService.mockMetadataResponse = TestFixtures.movieMetadataResponse

        let result = await viewModel.loadItemMetadata(identifier: "test_item")

        XCTAssertNotNil(result)
    }

    func testLoadItemMetadata_withError_returnsNil() async {
        mockService.errorToThrow = NetworkError.resourceNotFound

        let result = await viewModel.loadItemMetadata(identifier: "nonexistent")

        XCTAssertNil(result)
        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    // MARK: - Clear Items Tests

    func testClearItems_resetsState() async {
        mockService.mockCollectionsResponse = ("test", [
            TestFixtures.makeSearchResult(identifier: "1")
        ])
        await viewModel.loadCollection(name: "test", mediaType: "movies")

        viewModel.clearItems()

        XCTAssertTrue(viewModel.state.items.isEmpty)
        XCTAssertEqual(viewModel.state.collectionName, "")
    }

    // MARK: - Filter Tests

    func testFilterItems_byMediaType() async {
        let items = [
            TestFixtures.makeSearchResult(identifier: "1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "2", mediatype: "audio"),
            TestFixtures.makeSearchResult(identifier: "3", mediatype: "movies")
        ]
        mockService.mockCollectionsResponse = ("test", items)
        await viewModel.loadCollection(name: "test", mediaType: "movies")

        let filtered = viewModel.filterItems(by: "movies")

        XCTAssertEqual(filtered.count, 2)
    }

    func testFilterItems_emptyType_returnsAll() async {
        let items = [
            TestFixtures.makeSearchResult(identifier: "1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "2", mediatype: "audio")
        ]
        mockService.mockCollectionsResponse = ("test", items)
        await viewModel.loadCollection(name: "test", mediaType: "movies")

        let filtered = viewModel.filterItems(by: "")

        XCTAssertEqual(filtered.count, 2)
    }

    // MARK: - Sort Tests

    func testSortItems_byTitle() async {
        let items = [
            TestFixtures.makeSearchResult(identifier: "1", title: "Zebra"),
            TestFixtures.makeSearchResult(identifier: "2", title: "Apple"),
            TestFixtures.makeSearchResult(identifier: "3", title: "Mango")
        ]
        mockService.mockCollectionsResponse = ("test", items)
        await viewModel.loadCollection(name: "test", mediaType: "movies")

        let sorted = viewModel.sortItems(by: .title)

        XCTAssertEqual(sorted[0].title, "Apple")
        XCTAssertEqual(sorted[1].title, "Mango")
        XCTAssertEqual(sorted[2].title, "Zebra")
    }

    func testSortItems_byDownloads() async {
        let items = [
            TestFixtures.makeSearchResult(identifier: "1", downloads: 100),
            TestFixtures.makeSearchResult(identifier: "2", downloads: 500),
            TestFixtures.makeSearchResult(identifier: "3", downloads: 200)
        ]
        mockService.mockCollectionsResponse = ("test", items)
        await viewModel.loadCollection(name: "test", mediaType: "movies")

        let sorted = viewModel.sortItems(by: .downloads)

        XCTAssertEqual(sorted[0].downloads, 500)
        XCTAssertEqual(sorted[1].downloads, 200)
        XCTAssertEqual(sorted[2].downloads, 100)
    }

    func testSortItems_byDate() async {
        let items = [
            TestFixtures.makeSearchResult(identifier: "1", date: "2020-01-01"),
            TestFixtures.makeSearchResult(identifier: "2", date: "2023-06-15"),
            TestFixtures.makeSearchResult(identifier: "3", date: "2021-12-31")
        ]
        mockService.mockCollectionsResponse = ("test", items)
        await viewModel.loadCollection(name: "test", mediaType: "movies")

        let sorted = viewModel.sortItems(by: .date)

        // Date sorts descending (most recent first)
        XCTAssertEqual(sorted[0].date, "2023-06-15")
        XCTAssertEqual(sorted[1].date, "2021-12-31")
        XCTAssertEqual(sorted[2].date, "2020-01-01")
    }

    func testSortItems_byYear() async {
        let items = [
            TestFixtures.makeSearchResult(identifier: "1", year: "2018"),
            TestFixtures.makeSearchResult(identifier: "2", year: "2023"),
            TestFixtures.makeSearchResult(identifier: "3", year: "2020")
        ]
        mockService.mockCollectionsResponse = ("test", items)
        await viewModel.loadCollection(name: "test", mediaType: "movies")

        let sorted = viewModel.sortItems(by: .year)

        // Year sorts descending (most recent first)
        XCTAssertEqual(sorted[0].year, "2023")
        XCTAssertEqual(sorted[1].year, "2020")
        XCTAssertEqual(sorted[2].year, "2018")
    }

    func testSortItems_handlesNilValues() async {
        let items = [
            TestFixtures.makeSearchResult(identifier: "1", title: nil),
            TestFixtures.makeSearchResult(identifier: "2", title: "Beta"),
            TestFixtures.makeSearchResult(identifier: "3", title: "Alpha")
        ]
        mockService.mockCollectionsResponse = ("test", items)
        await viewModel.loadCollection(name: "test", mediaType: "movies")

        let sorted = viewModel.sortItems(by: .title)

        // Nil titles treated as empty strings, sorted first
        XCTAssertEqual(sorted[0].title, nil)
        XCTAssertEqual(sorted[1].title, "Alpha")
        XCTAssertEqual(sorted[2].title, "Beta")
    }

    func testFilterItems_nonMatchingType_returnsEmpty() async {
        let items = [
            TestFixtures.makeSearchResult(identifier: "1", mediatype: "movies"),
            TestFixtures.makeSearchResult(identifier: "2", mediatype: "movies")
        ]
        mockService.mockCollectionsResponse = ("test", items)
        await viewModel.loadCollection(name: "test", mediaType: "movies")

        let filtered = viewModel.filterItems(by: "audio")

        XCTAssertTrue(filtered.isEmpty)
    }

    // MARK: - Clear Error Tests

    func testLoadCollection_clearsErrorOnSuccess() async {
        // First cause an error
        mockService.errorToThrow = NetworkError.timeout
        await viewModel.loadCollection(name: "test", mediaType: "movies")
        XCTAssertNotNil(viewModel.state.errorMessage)

        // Now succeed
        mockService.errorToThrow = nil
        mockService.mockCollectionsResponse = ("test", [])
        await viewModel.loadCollection(name: "test", mediaType: "movies")

        XCTAssertNil(viewModel.state.errorMessage)
    }
}

// MARK: - CollectionViewState Tests

final class CollectionViewStateTests: XCTestCase {

    func testInitialState() {
        let state = CollectionViewState.initial

        XCTAssertFalse(state.isLoading)
        XCTAssertTrue(state.items.isEmpty)
        XCTAssertNil(state.errorMessage)
        XCTAssertEqual(state.collectionName, "")
    }
}

// MARK: - SortCriteria Tests

final class SortCriteriaTests: XCTestCase {

    func testAllCases() {
        let allCases = SortCriteria.allCases

        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.title))
        XCTAssertTrue(allCases.contains(.date))
        XCTAssertTrue(allCases.contains(.downloads))
        XCTAssertTrue(allCases.contains(.year))
    }

    func testRawValues() {
        XCTAssertEqual(SortCriteria.title.rawValue, "Title")
        XCTAssertEqual(SortCriteria.date.rawValue, "Date")
        XCTAssertEqual(SortCriteria.downloads.rawValue, "Downloads")
        XCTAssertEqual(SortCriteria.year.rawValue, "Year")
    }
}
