//
//  MusicViewModelTests.swift
//  Internet ArchiveTests
//
//  Unit tests for MusicViewModel
//

import XCTest
@testable import Internet_Archive

// Note: Uses MockCollectionService defined in CollectionViewModelTests.swift

// MARK: - MusicViewModel Tests

@MainActor
final class MusicViewModelTests: XCTestCase {

    nonisolated(unsafe) var viewModel: MusicViewModel!
    nonisolated(unsafe) var mockService: MockCollectionService!

    override func setUp() {
        super.setUp()
        let (newMockService, newViewModel) = MainActor.assumeIsolated {
            let service = MockCollectionService()
            let vm = MusicViewModel(collectionService: service)
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
        XCTAssertEqual(viewModel.state.collection, "etree")
        XCTAssertTrue(viewModel.state.items.isEmpty)
        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertFalse(viewModel.state.hasItems)
        XCTAssertEqual(viewModel.state.itemCount, 0)
    }

    func testInitWithCollection() {
        let vm = MusicViewModel(collectionService: mockService, collection: "audio")
        XCTAssertEqual(vm.state.collection, "audio")
    }

    // MARK: - Set Collection Tests

    func testSetCollection() {
        viewModel.setCollection("GratefulDead")
        XCTAssertEqual(viewModel.state.collection, "GratefulDead")
    }

    // MARK: - Load Collection Tests

    func testLoadCollection_callsService() async {
        mockService.mockCollectionsResponse = (
            collection: "etree",
            results: [TestFixtures.makeSearchResult(identifier: "test1")]
        )

        await viewModel.loadCollection()

        XCTAssertTrue(mockService.getCollectionsCalled)
        XCTAssertEqual(mockService.lastCollection, "etree")
        XCTAssertEqual(mockService.lastResultType, "collection")
    }

    func testLoadCollection_updatesItems() async {
        let testResults = [
            TestFixtures.makeSearchResult(identifier: "test1", downloads: 100),
            TestFixtures.makeSearchResult(identifier: "test2", downloads: 200)
        ]
        mockService.mockCollectionsResponse = (collection: "etree", results: testResults)

        await viewModel.loadCollection()

        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertEqual(viewModel.state.items.count, 2)
        XCTAssertNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.hasItems)
    }

    func testLoadCollection_updatesCollectionName() async {
        mockService.mockCollectionsResponse = (
            collection: "GratefulDead",
            results: [TestFixtures.makeSearchResult(identifier: "test1")]
        )

        await viewModel.loadCollection()

        XCTAssertEqual(viewModel.state.collection, "GratefulDead")
    }

    func testLoadCollection_sortsResultsByDownloads() async {
        let testResults = [
            TestFixtures.makeSearchResult(identifier: "low", downloads: 50),
            TestFixtures.makeSearchResult(identifier: "high", downloads: 500),
            TestFixtures.makeSearchResult(identifier: "medium", downloads: 200)
        ]
        mockService.mockCollectionsResponse = (collection: "etree", results: testResults)

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
        mockService.mockCollectionsResponse = (collection: "etree", results: [])

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
            collection: "etree",
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
            collection: "etree",
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
            collection: "GratefulDead",
            results: [TestFixtures.makeSearchResult(identifier: "gd1977", title: "Concert 1977")]
        )

        await viewModel.loadCollection()

        let navData = viewModel.navigationData(for: 0)
        XCTAssertNotNil(navData)
        XCTAssertEqual(navData?.collection, "GratefulDead")
        XCTAssertEqual(navData?.name, "Concert 1977")
        XCTAssertEqual(navData?.identifier, "gd1977")
    }

    func testNavigationData_usesIdentifierWhenNoTitle() async {
        mockService.mockCollectionsResponse = (
            collection: "etree",
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
            collection: "etree",
            results: [TestFixtures.makeSearchResult(identifier: "test1")]
        )

        // Before loading
        XCTAssertFalse(viewModel.state.isLoading)

        // After loading completes
        await viewModel.loadCollection()
        XCTAssertFalse(viewModel.state.isLoading)
    }

    // MARK: - hasLoaded Tests

    func testLoadCollection_setsHasLoadedTrue_onSuccess() async {
        mockService.mockCollectionsResponse = (
            collection: "etree",
            results: [TestFixtures.makeSearchResult(identifier: "test1")]
        )

        XCTAssertFalse(viewModel.state.hasLoaded)

        await viewModel.loadCollection()

        XCTAssertTrue(viewModel.state.hasLoaded)
    }

    func testLoadCollection_setsHasLoadedTrue_onError() async {
        mockService.errorToThrow = NetworkError.timeout

        XCTAssertFalse(viewModel.state.hasLoaded)

        await viewModel.loadCollection()

        XCTAssertTrue(viewModel.state.hasLoaded)
        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    func testLoadCollection_hasLoadedFalse_beforeLoad() {
        XCTAssertFalse(viewModel.state.hasLoaded)
    }

    // MARK: - Metadata Loading Tests

    func testLoadCollection_metadataSuccess_setsCollectionTitle() async {
        mockService.mockCollectionsResponse = (
            collection: "etree",
            results: [TestFixtures.makeSearchResult(identifier: "test1")]
        )
        mockService.mockMetadataResponse = ItemMetadataResponse(
            created: nil, d1: nil, d2: nil, dir: nil, files: nil, filesCount: nil,
            itemSize: nil,
            metadata: ItemMetadata(
                identifier: "etree",
                title: "Live Music Archive",
                mediatype: nil,
                creator: nil,
                description: nil
            ),
            server: nil, uniq: nil
        )

        await viewModel.loadCollection()

        XCTAssertEqual(viewModel.state.collectionTitle, "Live Music Archive")
        XCTAssertEqual(viewModel.state.displayTitle, "Live Music Archive")
        XCTAssertTrue(viewModel.state.hasTitleLoadAttempted)
    }

    func testLoadCollection_metadataFailure_usesFallbackTitle() async {
        mockService.mockCollectionsResponse = (
            collection: "etree",
            results: [TestFixtures.makeSearchResult(identifier: "test1")]
        )
        // Don't set mockMetadataResponse - getMetadata will throw NetworkError.resourceNotFound

        await viewModel.loadCollection()

        XCTAssertNil(viewModel.state.collectionTitle)
        XCTAssertEqual(viewModel.state.displayTitle, "Music") // Falls back to "Music"
        XCTAssertTrue(viewModel.state.hasTitleLoadAttempted)
    }

    func testLoadCollection_metadataWithNilTitle_usesFallback() async {
        mockService.mockCollectionsResponse = (
            collection: "etree",
            results: [TestFixtures.makeSearchResult(identifier: "test1")]
        )
        mockService.mockMetadataResponse = ItemMetadataResponse(
            created: nil, d1: nil, d2: nil, dir: nil, files: nil, filesCount: nil,
            itemSize: nil,
            metadata: ItemMetadata(
                identifier: "etree",
                title: nil, // No title in metadata
                mediatype: nil,
                creator: nil,
                description: nil
            ),
            server: nil, uniq: nil
        )

        await viewModel.loadCollection()

        XCTAssertNil(viewModel.state.collectionTitle)
        XCTAssertEqual(viewModel.state.displayTitle, "Music")
        XCTAssertTrue(viewModel.state.hasTitleLoadAttempted)
    }

    func testHasTitleLoadAttempted_falseBeforeLoad() {
        XCTAssertFalse(viewModel.state.hasTitleLoadAttempted)
    }
}

// MARK: - MusicViewState Tests

final class MusicViewStateTests: XCTestCase {

    func testInitialState() {
        let state = MusicViewState.initial

        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(state.collection, "etree")
        XCTAssertTrue(state.items.isEmpty)
        XCTAssertNil(state.errorMessage)
    }

    func testHasItems_whenEmpty() {
        let state = MusicViewState.initial
        XCTAssertFalse(state.hasItems)
    }

    func testHasItems_whenNotEmpty() {
        var state = MusicViewState.initial
        state.items = [TestFixtures.makeSearchResult(identifier: "test1")]
        XCTAssertTrue(state.hasItems)
    }

    func testItemCount() {
        var state = MusicViewState.initial
        XCTAssertEqual(state.itemCount, 0)

        state.items = [
            TestFixtures.makeSearchResult(identifier: "test1"),
            TestFixtures.makeSearchResult(identifier: "test2"),
            TestFixtures.makeSearchResult(identifier: "test3")
        ]
        XCTAssertEqual(state.itemCount, 3)
    }

    // MARK: - hasLoaded Tests

    func testHasLoaded_initiallyFalse() {
        let state = MusicViewState.initial
        XCTAssertFalse(state.hasLoaded)
    }

    func testHasLoaded_canBeSetToTrue() {
        var state = MusicViewState.initial
        state.hasLoaded = true
        XCTAssertTrue(state.hasLoaded)
    }

    func testHasLoaded_remainsTrueAfterSettingItems() {
        var state = MusicViewState.initial
        state.hasLoaded = true
        state.items = [TestFixtures.makeSearchResult(identifier: "test1")]

        XCTAssertTrue(state.hasLoaded)
        XCTAssertTrue(state.hasItems)
    }

    // MARK: - displayTitle Tests

    func testDisplayTitle_usesCollectionTitleWhenSet() {
        var state = MusicViewState.initial
        state.collectionTitle = "Live Music Archive"
        XCTAssertEqual(state.displayTitle, "Live Music Archive")
    }

    func testDisplayTitle_fallsBackToMusicWhenNoCollectionTitle() {
        let state = MusicViewState.initial
        XCTAssertEqual(state.displayTitle, "Music")
    }

    func testDisplayTitle_usesCollectionTitleOverFallback() {
        var state = MusicViewState.initial
        state.collectionTitle = "Grateful Dead"
        XCTAssertEqual(state.displayTitle, "Grateful Dead")

        state.collectionTitle = nil
        XCTAssertEqual(state.displayTitle, "Music")
    }

    // MARK: - hasTitleLoadAttempted Tests

    func testHasTitleLoadAttempted_initiallyFalse() {
        let state = MusicViewState.initial
        XCTAssertFalse(state.hasTitleLoadAttempted)
    }

    func testHasTitleLoadAttempted_canBeSetToTrue() {
        var state = MusicViewState.initial
        state.hasTitleLoadAttempted = true
        XCTAssertTrue(state.hasTitleLoadAttempted)
    }
}
