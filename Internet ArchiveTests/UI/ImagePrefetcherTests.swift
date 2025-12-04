//
//  ImagePrefetcherTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ImagePrefetcher and SearchResult imageURL extension
//

import XCTest
@testable import Internet_Archive

@MainActor
final class ImagePrefetcherTests: XCTestCase {

    var collectionView: UICollectionView!
    var prefetcher: ImagePrefetcher!
    var dataSource: ItemDataSource!

    override func setUp() {
        super.setUp()
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 400, height: 400), collectionViewLayout: layout)
        collectionView.register(
            ModernItemCell.self,
            forCellWithReuseIdentifier: ModernItemCell.reuseIdentifier
        )
    }

    override func tearDown() {
        collectionView = nil
        prefetcher = nil
        dataSource = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_setsCollectionViewPrefetchDataSource() {
        prefetcher = ImagePrefetcher(collectionView: collectionView)

        XCTAssertNotNil(collectionView.prefetchDataSource)
        XCTAssertTrue(collectionView.prefetchDataSource === prefetcher)
    }

    func testInit_withDataSource() {
        dataSource = ItemDataSource(
            collectionView: collectionView,
            cellProvider: { collectionView, indexPath, viewModel in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ModernItemCell.reuseIdentifier,
                    for: indexPath
                ) as? ModernItemCell
                return cell
            }
        )
        prefetcher = ImagePrefetcher(collectionView: collectionView, dataSource: dataSource)

        XCTAssertNotNil(collectionView.prefetchDataSource)
        XCTAssertTrue(collectionView.prefetchDataSource === prefetcher)
    }

    func testSetDataSource() {
        prefetcher = ImagePrefetcher(collectionView: collectionView)

        dataSource = ItemDataSource(
            collectionView: collectionView,
            cellProvider: { collectionView, indexPath, viewModel in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ModernItemCell.reuseIdentifier,
                    for: indexPath
                ) as? ModernItemCell
                return cell
            }
        )

        prefetcher.setDataSource(dataSource)
        // Just verify it doesn't crash
        XCTAssertNotNil(prefetcher)
    }

    // MARK: - Prefetching Tests

    func testPrefetchItemsAt_withNoDataSource() {
        prefetcher = ImagePrefetcher(collectionView: collectionView)

        // Should not crash when no data source
        prefetcher.collectionView(collectionView, prefetchItemsAt: [IndexPath(item: 0, section: 0)])
        XCTAssertNotNil(prefetcher)
    }

    func testPrefetchItemsAt_withEmptyIndexPaths() {
        prefetcher = ImagePrefetcher(collectionView: collectionView)

        // Should not crash with empty array
        prefetcher.collectionView(collectionView, prefetchItemsAt: [])
        XCTAssertNotNil(prefetcher)
    }

    func testCancelPrefetchingForItemsAt_doesNotCrash() {
        prefetcher = ImagePrefetcher(collectionView: collectionView)

        // Should not crash
        prefetcher.collectionView(collectionView, cancelPrefetchingForItemsAt: [IndexPath(item: 0, section: 0)])
        XCTAssertNotNil(prefetcher)
    }

    func testCancelPrefetchingForItemsAt_withEmptyIndexPaths() {
        prefetcher = ImagePrefetcher(collectionView: collectionView)

        // Should not crash with empty array
        prefetcher.collectionView(collectionView, cancelPrefetchingForItemsAt: [])
        XCTAssertNotNil(prefetcher)
    }

    func testPrefetchItemsAt_withValidDataSource() async {
        dataSource = ItemDataSource(
            collectionView: collectionView,
            cellProvider: { collectionView, indexPath, viewModel in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ModernItemCell.reuseIdentifier,
                    for: indexPath
                ) as? ModernItemCell
                return cell
            }
        )
        prefetcher = ImagePrefetcher(collectionView: collectionView, dataSource: dataSource)

        // Apply a snapshot with items
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.main])
        let viewModels = [
            ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "test1"), section: .main),
            ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "test2"), section: .main)
        ]
        snapshot.appendItems(viewModels, toSection: .main)
        await dataSource.apply(snapshot, animatingDifferences: false)

        // Should not crash when prefetching valid items
        prefetcher.collectionView(collectionView, prefetchItemsAt: [
            IndexPath(item: 0, section: 0),
            IndexPath(item: 1, section: 0)
        ])
        XCTAssertNotNil(prefetcher)
    }

    func testPrefetchItemsAt_withInvalidIndexPath() async {
        dataSource = ItemDataSource(
            collectionView: collectionView,
            cellProvider: { collectionView, indexPath, viewModel in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ModernItemCell.reuseIdentifier,
                    for: indexPath
                ) as? ModernItemCell
                return cell
            }
        )
        prefetcher = ImagePrefetcher(collectionView: collectionView, dataSource: dataSource)

        // Apply a snapshot with items
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.main])
        let viewModels = [
            ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "test1"), section: .main)
        ]
        snapshot.appendItems(viewModels, toSection: .main)
        await dataSource.apply(snapshot, animatingDifferences: false)

        // Should not crash when prefetching invalid index
        prefetcher.collectionView(collectionView, prefetchItemsAt: [
            IndexPath(item: 100, section: 0)
        ])
        XCTAssertNotNil(prefetcher)
    }

    // MARK: - Multiple Sections Tests

    func testPrefetchItemsAt_withMultipleSections() async {
        dataSource = ItemDataSource(
            collectionView: collectionView,
            cellProvider: { collectionView, indexPath, viewModel in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ModernItemCell.reuseIdentifier,
                    for: indexPath
                ) as? ModernItemCell
                return cell
            }
        )
        prefetcher = ImagePrefetcher(collectionView: collectionView, dataSource: dataSource)

        // Apply a snapshot with multiple sections
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.videos, .music])
        snapshot.appendItems([
            ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "video1"), section: .videos)
        ], toSection: .videos)
        snapshot.appendItems([
            ItemViewModel(item: TestFixtures.makeSearchResult(identifier: "music1"), section: .music)
        ], toSection: .music)
        await dataSource.apply(snapshot, animatingDifferences: false)

        // Should not crash when prefetching from multiple sections
        prefetcher.collectionView(collectionView, prefetchItemsAt: [
            IndexPath(item: 0, section: 0),
            IndexPath(item: 0, section: 1)
        ])
        XCTAssertNotNil(prefetcher)
    }
}

// MARK: - SearchResult imageURL Extension Tests

final class SearchResultImageURLTests: XCTestCase {

    func testImageURL_returnsCorrectURL() {
        let result = TestFixtures.makeSearchResult(identifier: "test_item")

        let url = result.imageURL

        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://archive.org/services/img/test_item")
    }

    func testImageURL_withSpecialCharacters() {
        let result = TestFixtures.makeSearchResult(identifier: "test-item_123")

        let url = result.imageURL

        XCTAssertNotNil(url)
        XCTAssertEqual(url?.absoluteString, "https://archive.org/services/img/test-item_123")
    }

    func testImageURL_multipleResults() {
        let results = [
            TestFixtures.makeSearchResult(identifier: "id1"),
            TestFixtures.makeSearchResult(identifier: "id2"),
            TestFixtures.makeSearchResult(identifier: "id3")
        ]

        let urls = results.compactMap { $0.imageURL }

        XCTAssertEqual(urls.count, 3)
        XCTAssertEqual(urls[0].absoluteString, "https://archive.org/services/img/id1")
        XCTAssertEqual(urls[1].absoluteString, "https://archive.org/services/img/id2")
        XCTAssertEqual(urls[2].absoluteString, "https://archive.org/services/img/id3")
    }
}
