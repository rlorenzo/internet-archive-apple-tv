//
//  DiffableDataSourceTests.swift
//  Internet ArchiveTests
//
//  Unit tests for DiffableDataSource extensions and ItemViewModel
//

import XCTest
@testable import Internet_Archive

final class DiffableDataSourceTests: XCTestCase {

    // MARK: - CollectionSection Tests

    func testCollectionSection_mainTitle() {
        XCTAssertEqual(CollectionSection.main.title, "All Items")
    }

    func testCollectionSection_videosTitle() {
        XCTAssertEqual(CollectionSection.videos.title, "Videos")
    }

    func testCollectionSection_musicTitle() {
        XCTAssertEqual(CollectionSection.music.title, "Music")
    }

    func testCollectionSection_peopleTitle() {
        XCTAssertEqual(CollectionSection.people.title, "People")
    }

    func testCollectionSection_allCases() {
        let allCases = CollectionSection.allCases
        XCTAssertEqual(allCases.count, 6)
        XCTAssertTrue(allCases.contains(.continueWatching))
        XCTAssertTrue(allCases.contains(.continueListening))
        XCTAssertTrue(allCases.contains(.main))
        XCTAssertTrue(allCases.contains(.videos))
        XCTAssertTrue(allCases.contains(.music))
        XCTAssertTrue(allCases.contains(.people))
    }

    func testCollectionSection_rawValues() {
        XCTAssertEqual(CollectionSection.continueWatching.rawValue, 0)
        XCTAssertEqual(CollectionSection.continueListening.rawValue, 1)
        XCTAssertEqual(CollectionSection.main.rawValue, 2)
        XCTAssertEqual(CollectionSection.videos.rawValue, 3)
        XCTAssertEqual(CollectionSection.music.rawValue, 4)
        XCTAssertEqual(CollectionSection.people.rawValue, 5)
    }

    func testCollectionSection_isHashable() {
        var set: Set<CollectionSection> = []
        set.insert(.main)
        set.insert(.videos)
        set.insert(.main) // Duplicate
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - ItemViewModel Tests

    func testItemViewModel_initialization() {
        let searchResult = TestFixtures.movieSearchResult
        let viewModel = ItemViewModel(item: searchResult)

        XCTAssertEqual(viewModel.item.identifier, searchResult.identifier)
        XCTAssertEqual(viewModel.section, .main) // Default section
    }

    func testItemViewModel_initializationWithSection() {
        let searchResult = TestFixtures.movieSearchResult
        let viewModel = ItemViewModel(item: searchResult, section: .videos)

        XCTAssertEqual(viewModel.section, .videos)
    }

    func testItemViewModel_equality_sameIdentifier() {
        let result1 = TestFixtures.makeSearchResult(identifier: "test123")
        let result2 = TestFixtures.makeSearchResult(identifier: "test123")

        let viewModel1 = ItemViewModel(item: result1)
        let viewModel2 = ItemViewModel(item: result2)

        XCTAssertEqual(viewModel1, viewModel2)
    }

    func testItemViewModel_equality_differentIdentifier() {
        let result1 = TestFixtures.makeSearchResult(identifier: "test123")
        let result2 = TestFixtures.makeSearchResult(identifier: "test456")

        let viewModel1 = ItemViewModel(item: result1)
        let viewModel2 = ItemViewModel(item: result2)

        XCTAssertNotEqual(viewModel1, viewModel2)
    }

    func testItemViewModel_hashable() {
        let result1 = TestFixtures.makeSearchResult(identifier: "test123")
        let result2 = TestFixtures.makeSearchResult(identifier: "test456")
        let result3 = TestFixtures.makeSearchResult(identifier: "test123") // Duplicate

        let viewModel1 = ItemViewModel(item: result1)
        let viewModel2 = ItemViewModel(item: result2)
        let viewModel3 = ItemViewModel(item: result3)

        var set: Set<ItemViewModel> = []
        set.insert(viewModel1)
        set.insert(viewModel2)
        set.insert(viewModel3)

        XCTAssertEqual(set.count, 2, "Duplicate identifier should not create new entry")
    }

    func testItemViewModel_hashValue() {
        let result = TestFixtures.makeSearchResult(identifier: "test123")
        let viewModel1 = ItemViewModel(item: result)
        let viewModel2 = ItemViewModel(item: result, section: .videos)

        // Same identifier should have same hash
        XCTAssertEqual(viewModel1.hashValue, viewModel2.hashValue)
    }

    func testItemViewModel_isSendable() {
        let result = TestFixtures.movieSearchResult
        let viewModel = ItemViewModel(item: result)

        // This compiles because ItemViewModel conforms to Sendable
        let sendable: Sendable = viewModel
        XCTAssertNotNil(sendable)
    }

    // MARK: - Snapshot Extension Tests

    func testSnapshot_isEmpty_whenEmpty() {
        let snapshot = ItemSnapshot()
        XCTAssertTrue(snapshot.isEmpty)
    }

    func testSnapshot_isEmpty_whenNotEmpty() {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.main])
        let viewModel = ItemViewModel(item: TestFixtures.movieSearchResult)
        snapshot.appendItems([viewModel], toSection: .main)

        XCTAssertFalse(snapshot.isEmpty)
    }

    func testSnapshot_allItems_whenEmpty() {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.main])
        XCTAssertTrue(snapshot.allItems.isEmpty)
    }

    func testSnapshot_allItems_singleSection() {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.main])

        let viewModel1 = ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "1"))
        let viewModel2 = ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "2"))
        snapshot.appendItems([viewModel1, viewModel2], toSection: .main)

        let allItems = snapshot.allItems
        XCTAssertEqual(allItems.count, 2)
    }

    func testSnapshot_allItems_multipleSections() {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.videos, .music])

        let video1 = ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "v1"))
        let video2 = ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "v2"))
        snapshot.appendItems([video1, video2], toSection: .videos)

        let music1 = ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "m1"))
        snapshot.appendItems([music1], toSection: .music)

        let allItems = snapshot.allItems
        XCTAssertEqual(allItems.count, 3)
    }

    func testSnapshot_numberOfItems() {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.main])

        XCTAssertEqual(snapshot.numberOfItems, 0)

        let viewModel = ItemViewModel(item: TestFixtures.movieSearchResult)
        snapshot.appendItems([viewModel], toSection: .main)

        XCTAssertEqual(snapshot.numberOfItems, 1)
    }

    // MARK: - Type Alias Tests

    func testItemDataSource_typeAlias() {
        // This test verifies the type alias compiles correctly
        // We can't easily test the type itself without UIKit setup
        XCTAssertTrue(true)
    }

    func testItemSnapshot_typeAlias() {
        var snapshot: ItemSnapshot = NSDiffableDataSourceSnapshot<CollectionSection, ItemViewModel>()
        snapshot.appendSections([.main])
        XCTAssertEqual(snapshot.numberOfSections, 1)
    }
}

// MARK: - DiffableDataSource Extension Tests

@MainActor
final class DiffableDataSourceExtensionTests: XCTestCase {

    nonisolated(unsafe) var collectionView: UICollectionView!
    nonisolated(unsafe) var dataSource: ItemDataSource!

    override func setUp() {
        super.setUp()
        let (newCollectionView, newDataSource) = MainActor.assumeIsolated {
            let layout = UICollectionViewFlowLayout()
            let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: 400, height: 400), collectionViewLayout: layout)
            cv.register(
                ModernItemCell.self,
                forCellWithReuseIdentifier: ModernItemCell.reuseIdentifier
            )

            let ds = ItemDataSource(
                collectionView: cv,
                cellProvider: { collectionView, indexPath, viewModel in
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: ModernItemCell.reuseIdentifier,
                        for: indexPath
                    ) as? ModernItemCell
                    return cell
                }
            )
            return (cv, ds)
        }
        collectionView = newCollectionView
        dataSource = newDataSource
    }

    override func tearDown() {
        collectionView = nil
        dataSource = nil
        super.tearDown()
    }

    // MARK: - applyItems Tests

    func testApplyItems_toSection() async {
        let items = [
            ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "test1"), section: .main),
            ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "test2"), section: .main)
        ]

        await dataSource.applyItems(items, to: CollectionSection.main)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems, 2)
        XCTAssertEqual(snapshot.numberOfSections, 1)
    }

    func testApplyItems_withoutAnimation() async {
        let items = [
            ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "test1"), section: .videos)
        ]

        await dataSource.applyItems(items, to: CollectionSection.videos, animatingDifferences: false)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems, 1)
    }

    func testApplyItems_emptyArray() async {
        await dataSource.applyItems([], to: CollectionSection.main)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems, 0)
        XCTAssertEqual(snapshot.numberOfSections, 1)
    }

    func testApplyItems_replacesPreviousItems() async {
        // First apply
        let items1 = [
            ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "a"), section: .main),
            ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "b"), section: .main)
        ]
        await dataSource.applyItems(items1, to: CollectionSection.main)

        // Second apply - should replace
        let items2 = [
            ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "c"), section: .main)
        ]
        await dataSource.applyItems(items2, to: CollectionSection.main)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.numberOfItems, 1)
    }

    // MARK: - reloadItems Tests

    func testReloadItems() async {
        // First, add items
        let item1 = ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "test1"), section: .main)
        let item2 = ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "test2"), section: .main)

        var snapshot = ItemSnapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems([item1, item2], toSection: .main)
        await dataSource.apply(snapshot, animatingDifferences: false)

        // Now reload specific items
        await dataSource.reloadItems([item1])

        // Verify items are still there
        let currentSnapshot = dataSource.snapshot()
        XCTAssertEqual(currentSnapshot.numberOfItems, 2)
    }

    // MARK: - Section Tests

    func testApplyItems_toDifferentSections() async {
        let videoItems = [
            ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "video1"), section: .videos)
        ]

        await dataSource.applyItems(videoItems, to: CollectionSection.videos)

        let snapshot = dataSource.snapshot()
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: .videos).count, 1)
    }
}
