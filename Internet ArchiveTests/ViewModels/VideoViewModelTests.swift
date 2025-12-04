//
//  VideoViewModelTests.swift
//  Internet ArchiveTests
//
//  Unit tests for VideoViewModel
//

import XCTest
@testable import Internet_Archive

// Note: Uses MockCollectionService defined in CollectionViewModelTests.swift

// MARK: - VideoViewModel Tests

@MainActor
final class VideoViewModelTests: XCTestCase {

    var viewModel: VideoViewModel!
    var mockService: MockCollectionService!

    override func setUp() {
        super.setUp()
        mockService = MockCollectionService()
        viewModel = VideoViewModel(collectionService: mockService)
    }

    override func tearDown() {
        viewModel = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertEqual(viewModel.state.collection, "movies")
        XCTAssertTrue(viewModel.state.items.isEmpty)
        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertFalse(viewModel.state.hasItems)
        XCTAssertEqual(viewModel.state.itemCount, 0)
    }

    func testInitWithCollection() {
        let vm = VideoViewModel(collectionService: mockService, collection: "documentaries")
        XCTAssertEqual(vm.state.collection, "documentaries")
    }

    // MARK: - Set Collection Tests

    func testSetCollection() {
        viewModel.setCollection("animation")
        XCTAssertEqual(viewModel.state.collection, "animation")
    }

    // MARK: - Load Collection Tests

    func testLoadCollection_callsService() async {
        mockService.mockCollectionsResponse = (
            collection: "movies",
            results: [TestFixtures.makeSearchResult(identifier: "test1")]
        )

        await viewModel.loadCollection()

        XCTAssertTrue(mockService.getCollectionsCalled)
        XCTAssertEqual(mockService.lastCollection, "movies")
        XCTAssertEqual(mockService.lastResultType, "collection")
    }

    func testLoadCollection_updatesItems() async {
        let testResults = [
            TestFixtures.makeSearchResult(identifier: "test1", downloads: 100),
            TestFixtures.makeSearchResult(identifier: "test2", downloads: 200)
        ]
        mockService.mockCollectionsResponse = (collection: "movies", results: testResults)

        await viewModel.loadCollection()

        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertEqual(viewModel.state.items.count, 2)
        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.hasItems)
    }

    func testLoadCollection_updatesCollectionName() async {
        mockService.mockCollectionsResponse = (
            collection: "documentaries",
            results: [TestFixtures.makeSearchResult(identifier: "test1")]
        )

        await viewModel.loadCollection()

        XCTAssertEqual(viewModel.state.collection, "documentaries")
    }

    func testLoadCollection_sortsResultsByDownloads() async {
        let testResults = [
            TestFixtures.makeSearchResult(identifier: "low", downloads: 50),
            TestFixtures.makeSearchResult(identifier: "high", downloads: 500),
            TestFixtures.makeSearchResult(identifier: "medium", downloads: 200)
        ]
        mockService.mockCollectionsResponse = (collection: "movies", results: testResults)

        await viewModel.loadCollection()

        XCTAssertEqual(viewModel.state.items[0].identifier, "high")
        XCTAssertEqual(viewModel.state.items[1].identifier, "medium")
        XCTAssertEqual(viewModel.state.items[2].identifier, "low")
    }

    func testLoadCollection_withError_setsErrorMessage() async {
        mockService.errorToThrow = NetworkError.timeout

        await viewModel.loadCollection()

        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.items.isEmpty)
    }

    func testLoadCollection_withNoConnection_setsErrorMessage() async {
        mockService.errorToThrow = NetworkError.noConnection

        await viewModel.loadCollection()

        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.errorMessage?.contains("internet") ?? false)
    }

    func testLoadCollection_withEmptyResults() async {
        mockService.mockCollectionsResponse = (collection: "movies", results: [])

        await viewModel.loadCollection()

        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertTrue(viewModel.state.items.isEmpty)
        XCTAssertFalse(viewModel.state.hasItems)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    // MARK: - Sort By Downloads Tests

    func testSortByDownloads_descendingOrder() {
        let items = [
            TestFixtures.makeSearchResult(identifier: "a", downloads: 10),
            TestFixtures.makeSearchResult(identifier: "b", downloads: 100),
            TestFixtures.makeSearchResult(identifier: "c", downloads: 50)
        ]

        let sorted = viewModel.sortByDownloads(items)

        XCTAssertEqual(sorted[0].identifier, "b")
        XCTAssertEqual(sorted[1].identifier, "c")
        XCTAssertEqual(sorted[2].identifier, "a")
    }

    func testSortByDownloads_withNilDownloads() {
        let items = [
            TestFixtures.makeSearchResult(identifier: "a", downloads: nil),
            TestFixtures.makeSearchResult(identifier: "b", downloads: 100),
            TestFixtures.makeSearchResult(identifier: "c", downloads: nil)
        ]

        let sorted = viewModel.sortByDownloads(items)

        // Nil downloads treated as 0, so b should be first
        XCTAssertEqual(sorted[0].identifier, "b")
    }

    func testSortByDownloads_emptyArray() {
        let sorted = viewModel.sortByDownloads([])
        XCTAssertTrue(sorted.isEmpty)
    }

    func testSortByDownloads_singleItem() {
        let items = [TestFixtures.makeSearchResult(identifier: "single", downloads: 50)]
        let sorted = viewModel.sortByDownloads(items)
        XCTAssertEqual(sorted.count, 1)
        XCTAssertEqual(sorted[0].identifier, "single")
    }

    // MARK: - Item Access Tests

    func testItemAtIndex_validIndex() async {
        mockService.mockCollectionsResponse = (
            collection: "movies",
            results: [
                TestFixtures.makeSearchResult(identifier: "test1"),
                TestFixtures.makeSearchResult(identifier: "test2")
            ]
        )

        await viewModel.loadCollection()

        let item = viewModel.item(at: 0)
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.identifier, "test1")
    }

    func testItemAtIndex_invalidIndex() {
        XCTAssertNil(viewModel.item(at: 0))
        XCTAssertNil(viewModel.item(at: -1))
        XCTAssertNil(viewModel.item(at: 100))
    }

    func testItemAtIndex_boundaryConditions() async {
        mockService.mockCollectionsResponse = (
            collection: "movies",
            results: [
                TestFixtures.makeSearchResult(identifier: "test1"),
                TestFixtures.makeSearchResult(identifier: "test2")
            ]
        )

        await viewModel.loadCollection()

        XCTAssertNotNil(viewModel.item(at: 0))
        XCTAssertNotNil(viewModel.item(at: 1))
        XCTAssertNil(viewModel.item(at: 2))
    }

    // MARK: - Navigation Data Tests

    func testNavigationData_validIndex() async {
        mockService.mockCollectionsResponse = (
            collection: "documentaries",
            results: [TestFixtures.makeSearchResult(identifier: "doc1", title: "Nature Documentary")]
        )

        await viewModel.loadCollection()

        let navData = viewModel.navigationData(for: 0)
        XCTAssertNotNil(navData)
        XCTAssertEqual(navData?.collection, "documentaries")
        XCTAssertEqual(navData?.name, "Nature Documentary")
        XCTAssertEqual(navData?.identifier, "doc1")
    }

    func testNavigationData_usesIdentifierWhenNoTitle() async {
        mockService.mockCollectionsResponse = (
            collection: "movies",
            results: [TestFixtures.makeSearchResult(identifier: "no_title_item", title: nil)]
        )

        await viewModel.loadCollection()

        let navData = viewModel.navigationData(for: 0)
        XCTAssertEqual(navData?.name, "no_title_item")
    }

    func testNavigationData_invalidIndex() {
        let navData = viewModel.navigationData(for: 0)
        XCTAssertNil(navData)
    }

    // MARK: - Clear Error Tests

    func testClearError() async {
        mockService.errorToThrow = NetworkError.timeout
        await viewModel.loadCollection()

        XCTAssertNotNil(viewModel.state.errorMessage)

        viewModel.clearError()

        XCTAssertNil(viewModel.state.errorMessage)
    }

    // MARK: - Loading State Tests

    func testLoadingStateTransitions() async {
        mockService.mockCollectionsResponse = (
            collection: "movies",
            results: [TestFixtures.makeSearchResult(identifier: "test1")]
        )

        // Before loading
        XCTAssertFalse(viewModel.state.isLoading)

        // After loading completes
        await viewModel.loadCollection()
        XCTAssertFalse(viewModel.state.isLoading)
    }
}

// MARK: - VideoViewState Tests

final class VideoViewStateTests: XCTestCase {

    func testInitialState() {
        let state = VideoViewState.initial

        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(state.collection, "movies")
        XCTAssertTrue(state.items.isEmpty)
        XCTAssertNil(state.errorMessage)
    }

    func testHasItems_whenEmpty() {
        let state = VideoViewState.initial
        XCTAssertFalse(state.hasItems)
    }

    func testHasItems_whenNotEmpty() {
        var state = VideoViewState.initial
        state.items = [TestFixtures.makeSearchResult(identifier: "test1")]
        XCTAssertTrue(state.hasItems)
    }

    func testItemCount() {
        var state = VideoViewState.initial
        XCTAssertEqual(state.itemCount, 0)

        state.items = [
            TestFixtures.makeSearchResult(identifier: "test1"),
            TestFixtures.makeSearchResult(identifier: "test2"),
            TestFixtures.makeSearchResult(identifier: "test3")
        ]
        XCTAssertEqual(state.itemCount, 3)
    }
}
