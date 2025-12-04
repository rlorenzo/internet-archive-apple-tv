//
//  YearsViewModelTests.swift
//  Internet ArchiveTests
//
//  Unit tests for YearsViewModel
//

import XCTest
@testable import Internet_Archive

// Note: Uses MockCollectionService defined in CollectionViewModelTests.swift

// MARK: - YearsViewModel Tests

@MainActor
final class YearsViewModelTests: XCTestCase {

    var viewModel: YearsViewModel!
    var mockService: MockCollectionService!

    override func setUp() {
        super.setUp()
        mockService = MockCollectionService()
        viewModel = YearsViewModel(collectionService: mockService)
    }

    override func tearDown() {
        viewModel = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertTrue(viewModel.state.name.isEmpty)
        XCTAssertTrue(viewModel.state.identifier.isEmpty)
        XCTAssertTrue(viewModel.state.collection.isEmpty)
        XCTAssertTrue(viewModel.state.sortedData.isEmpty)
        XCTAssertTrue(viewModel.state.sortedKeys.isEmpty)
        XCTAssertEqual(viewModel.state.selectedYearIndex, 0)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    // MARK: - Configure Tests

    func testConfigure() {
        viewModel.configure(name: "Grateful Dead", identifier: "GratefulDead", collection: "etree")

        XCTAssertEqual(viewModel.state.name, "Grateful Dead")
        XCTAssertEqual(viewModel.state.identifier, "GratefulDead")
        XCTAssertEqual(viewModel.state.collection, "etree")
    }

    // MARK: - Load Years Data Tests

    func testLoadYearsData_emptyIdentifier_setsError() async {
        await viewModel.loadYearsData()

        XCTAssertNotNil(viewModel.state.errorMessage)
        XCTAssertTrue(viewModel.state.errorMessage?.contains("Missing") ?? false)
    }

    func testLoadYearsData_callsService() async {
        viewModel.configure(name: "Test", identifier: "test_id", collection: "collection")
        mockService.mockCollectionsResponse = (collection: "collection", results: [])

        await viewModel.loadYearsData()

        XCTAssertTrue(mockService.getCollectionsCalled)
        XCTAssertEqual(mockService.lastCollection, "test_id")
        XCTAssertEqual(mockService.lastResultType, "collection")
    }

    func testLoadYearsData_groupsItemsByYear() async {
        viewModel.configure(name: "Test", identifier: "test_id", collection: "collection")

        let testResults = [
            TestFixtures.makeSearchResult(identifier: "item1", year: "2020"),
            TestFixtures.makeSearchResult(identifier: "item2", year: "2020"),
            TestFixtures.makeSearchResult(identifier: "item3", year: "2019")
        ]
        mockService.mockCollectionsResponse = (collection: "collection", results: testResults)

        await viewModel.loadYearsData()

        XCTAssertEqual(viewModel.state.sortedKeys.count, 2)
        XCTAssertEqual(viewModel.state.sortedData["2020"]?.count, 2)
        XCTAssertEqual(viewModel.state.sortedData["2019"]?.count, 1)
    }

    func testLoadYearsData_sortsYearsDescending() async {
        viewModel.configure(name: "Test", identifier: "test_id", collection: "collection")

        let testResults = [
            TestFixtures.makeSearchResult(identifier: "item1", year: "2018"),
            TestFixtures.makeSearchResult(identifier: "item2", year: "2020"),
            TestFixtures.makeSearchResult(identifier: "item3", year: "2019")
        ]
        mockService.mockCollectionsResponse = (collection: "collection", results: testResults)

        await viewModel.loadYearsData()

        XCTAssertEqual(viewModel.state.sortedKeys[0], "2020")
        XCTAssertEqual(viewModel.state.sortedKeys[1], "2019")
        XCTAssertEqual(viewModel.state.sortedKeys[2], "2018")
    }

    func testLoadYearsData_handlesNilYearAsUndated() async {
        viewModel.configure(name: "Test", identifier: "test_id", collection: "collection")

        let testResults = [
            TestFixtures.makeSearchResult(identifier: "item1", year: nil),
            TestFixtures.makeSearchResult(identifier: "item2", year: "2020")
        ]
        mockService.mockCollectionsResponse = (collection: "collection", results: testResults)

        await viewModel.loadYearsData()

        XCTAssertTrue(viewModel.state.sortedKeys.contains("Undated"))
        XCTAssertEqual(viewModel.state.sortedData["Undated"]?.count, 1)
    }

    func testLoadYearsData_withError_setsErrorMessage() async {
        viewModel.configure(name: "Test", identifier: "test_id", collection: "collection")
        mockService.errorToThrow = NetworkError.timeout

        await viewModel.loadYearsData()

        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNotNil(viewModel.state.errorMessage)
    }

    // MARK: - Group By Year Tests

    func testGroupByYear_multipleYears() {
        let items = [
            TestFixtures.makeSearchResult(identifier: "a", year: "2020"),
            TestFixtures.makeSearchResult(identifier: "b", year: "2019"),
            TestFixtures.makeSearchResult(identifier: "c", year: "2020")
        ]

        let grouped = viewModel.groupByYear(items)

        XCTAssertEqual(grouped.count, 2)
        XCTAssertEqual(grouped["2020"]?.count, 2)
        XCTAssertEqual(grouped["2019"]?.count, 1)
    }

    func testGroupByYear_emptyArray() {
        let grouped = viewModel.groupByYear([])
        XCTAssertTrue(grouped.isEmpty)
    }

    func testGroupByYear_nilYears() {
        let items = [
            TestFixtures.makeSearchResult(identifier: "a", year: nil),
            TestFixtures.makeSearchResult(identifier: "b", year: nil)
        ]

        let grouped = viewModel.groupByYear(items)

        XCTAssertEqual(grouped.count, 1)
        XCTAssertEqual(grouped["Undated"]?.count, 2)
    }

    func testGroupByYear_mixedYears() {
        let items = [
            TestFixtures.makeSearchResult(identifier: "a", year: "2020"),
            TestFixtures.makeSearchResult(identifier: "b", year: nil),
            TestFixtures.makeSearchResult(identifier: "c", year: "2020")
        ]

        let grouped = viewModel.groupByYear(items)

        XCTAssertEqual(grouped.count, 2)
        XCTAssertEqual(grouped["2020"]?.count, 2)
        XCTAssertEqual(grouped["Undated"]?.count, 1)
    }

    // MARK: - Select Year Tests

    func testSelectYear_validIndex() async {
        viewModel.configure(name: "Test", identifier: "test_id", collection: "collection")
        mockService.mockCollectionsResponse = (collection: "collection", results: [
            TestFixtures.makeSearchResult(identifier: "a", year: "2020"),
            TestFixtures.makeSearchResult(identifier: "b", year: "2019")
        ])

        await viewModel.loadYearsData()
        viewModel.selectYear(at: 1)

        XCTAssertEqual(viewModel.state.selectedYearIndex, 1)
        XCTAssertEqual(viewModel.state.selectedYear, "2019")
    }

    func testSelectYear_invalidIndex() async {
        viewModel.configure(name: "Test", identifier: "test_id", collection: "collection")
        mockService.mockCollectionsResponse = (collection: "collection", results: [
            TestFixtures.makeSearchResult(identifier: "a", year: "2020")
        ])

        await viewModel.loadYearsData()

        viewModel.selectYear(at: -1)
        XCTAssertEqual(viewModel.state.selectedYearIndex, 0)

        viewModel.selectYear(at: 100)
        XCTAssertEqual(viewModel.state.selectedYearIndex, 0)
    }

    // MARK: - Year Access Tests

    func testYearAtIndex_validIndex() async {
        viewModel.configure(name: "Test", identifier: "test_id", collection: "collection")
        mockService.mockCollectionsResponse = (collection: "collection", results: [
            TestFixtures.makeSearchResult(identifier: "a", year: "2020")
        ])

        await viewModel.loadYearsData()

        XCTAssertEqual(viewModel.year(at: 0), "2020")
    }

    func testYearAtIndex_invalidIndex() {
        XCTAssertNil(viewModel.year(at: 0))
        XCTAssertNil(viewModel.year(at: -1))
    }

    // MARK: - Items For Year Tests

    func testItemsForYearAtIndex() async {
        viewModel.configure(name: "Test", identifier: "test_id", collection: "collection")
        mockService.mockCollectionsResponse = (collection: "collection", results: [
            TestFixtures.makeSearchResult(identifier: "a", year: "2020"),
            TestFixtures.makeSearchResult(identifier: "b", year: "2020")
        ])

        await viewModel.loadYearsData()

        let items = viewModel.items(forYearAt: 0)
        XCTAssertEqual(items.count, 2)
    }

    func testItemsForYearAtIndex_invalidIndex() {
        let items = viewModel.items(forYearAt: 0)
        XCTAssertTrue(items.isEmpty)
    }

    // MARK: - Item Access Tests

    func testItemAtIndex_validIndex() async {
        viewModel.configure(name: "Test", identifier: "test_id", collection: "collection")
        mockService.mockCollectionsResponse = (collection: "collection", results: [
            TestFixtures.makeSearchResult(identifier: "test_item", year: "2020")
        ])

        await viewModel.loadYearsData()

        let item = viewModel.item(at: 0)
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.identifier, "test_item")
    }

    func testItemAtIndex_invalidIndex() {
        XCTAssertNil(viewModel.item(at: 0))
        XCTAssertNil(viewModel.item(at: -1))
    }

    // MARK: - Build Navigation Data Tests

    func testBuildItemNavigationData_validIndex() async {
        viewModel.configure(name: "Test", identifier: "test_id", collection: "collection")
        mockService.mockCollectionsResponse = (collection: "collection", results: [
            TestFixtures.makeSearchResult(
                identifier: "nav_item",
                title: "Test Title",
                mediatype: "etree",
                creator: "Test Creator",
                year: "2020"
            )
        ])

        await viewModel.loadYearsData()

        let navData = viewModel.buildItemNavigationData(at: 0)
        XCTAssertNotNil(navData)
        XCTAssertEqual(navData?.identifier, "nav_item")
        XCTAssertEqual(navData?.title, "Test Title")
        XCTAssertEqual(navData?.archivedBy, "Test Creator")
        XCTAssertEqual(navData?.mediaType, "etree")
        XCTAssertNotNil(navData?.imageURL)
        XCTAssertTrue(navData?.imageURL?.absoluteString.contains("nav_item") ?? false)
    }

    func testBuildItemNavigationData_invalidIndex() {
        let navData = viewModel.buildItemNavigationData(at: 0)
        XCTAssertNil(navData)
    }

    func testBuildItemNavigationData_handlesNilValues() async {
        viewModel.configure(name: "Test", identifier: "test_id", collection: "collection")
        mockService.mockCollectionsResponse = (collection: "collection", results: [
            TestFixtures.makeSearchResult(
                identifier: "item",
                title: nil,
                mediatype: nil,
                creator: nil,
                year: "2020"
            )
        ])

        await viewModel.loadYearsData()

        let navData = viewModel.buildItemNavigationData(at: 0)
        XCTAssertNotNil(navData)
        XCTAssertEqual(navData?.title, "")
        XCTAssertEqual(navData?.archivedBy, "")
        XCTAssertEqual(navData?.mediaType, "")
    }

    // MARK: - Clear Error Tests

    func testClearError() async {
        viewModel.configure(name: "Test", identifier: "test_id", collection: "collection")
        mockService.errorToThrow = NetworkError.timeout
        await viewModel.loadYearsData()

        XCTAssertNotNil(viewModel.state.errorMessage)

        viewModel.clearError()

        XCTAssertNil(viewModel.state.errorMessage)
    }
}

// MARK: - YearsViewState Tests

final class YearsViewStateTests: XCTestCase {

    func testInitialState() {
        let state = YearsViewState.initial

        XCTAssertFalse(state.isLoading)
        XCTAssertTrue(state.name.isEmpty)
        XCTAssertTrue(state.identifier.isEmpty)
        XCTAssertTrue(state.sortedKeys.isEmpty)
        XCTAssertEqual(state.selectedYearIndex, 0)
    }

    func testHasYears_whenEmpty() {
        let state = YearsViewState.initial
        XCTAssertFalse(state.hasYears)
    }

    func testHasYears_whenNotEmpty() {
        var state = YearsViewState.initial
        state.sortedKeys = ["2020", "2019"]
        XCTAssertTrue(state.hasYears)
    }

    func testYearsCount() {
        var state = YearsViewState.initial
        XCTAssertEqual(state.yearsCount, 0)

        state.sortedKeys = ["2020", "2019", "2018"]
        XCTAssertEqual(state.yearsCount, 3)
    }

    func testSelectedYear_validIndex() {
        var state = YearsViewState.initial
        state.sortedKeys = ["2020", "2019"]
        state.selectedYearIndex = 1

        XCTAssertEqual(state.selectedYear, "2019")
    }

    func testSelectedYear_invalidIndex() {
        var state = YearsViewState.initial
        state.selectedYearIndex = 5

        XCTAssertNil(state.selectedYear)
    }

    func testSelectedYearItems() {
        var state = YearsViewState.initial
        state.sortedKeys = ["2020"]
        state.sortedData = ["2020": [
            TestFixtures.makeSearchResult(identifier: "a"),
            TestFixtures.makeSearchResult(identifier: "b")
        ]]
        state.selectedYearIndex = 0

        XCTAssertEqual(state.selectedYearItems.count, 2)
    }

    func testSelectedYearItemCount() {
        var state = YearsViewState.initial
        state.sortedKeys = ["2020"]
        state.sortedData = ["2020": [
            TestFixtures.makeSearchResult(identifier: "a"),
            TestFixtures.makeSearchResult(identifier: "b"),
            TestFixtures.makeSearchResult(identifier: "c")
        ]]
        state.selectedYearIndex = 0

        XCTAssertEqual(state.selectedYearItemCount, 3)
    }
}

// MARK: - ItemNavigationData Tests

final class ItemNavigationDataTests: XCTestCase {

    func testEquatable() {
        let data1 = ItemNavigationData(
            identifier: "id1",
            title: "Title",
            archivedBy: "Creator",
            date: "2020",
            description: "Desc",
            mediaType: "etree",
            imageURL: URL(string: "https://example.com")
        )

        let data2 = ItemNavigationData(
            identifier: "id1",
            title: "Title",
            archivedBy: "Creator",
            date: "2020",
            description: "Desc",
            mediaType: "etree",
            imageURL: URL(string: "https://example.com")
        )

        XCTAssertEqual(data1, data2)
    }

    func testNotEqual() {
        let data1 = ItemNavigationData(
            identifier: "id1",
            title: "Title",
            archivedBy: "Creator",
            date: "2020",
            description: "Desc",
            mediaType: "etree",
            imageURL: nil
        )

        let data2 = ItemNavigationData(
            identifier: "id2",
            title: "Title",
            archivedBy: "Creator",
            date: "2020",
            description: "Desc",
            mediaType: "etree",
            imageURL: nil
        )

        XCTAssertNotEqual(data1, data2)
    }
}
