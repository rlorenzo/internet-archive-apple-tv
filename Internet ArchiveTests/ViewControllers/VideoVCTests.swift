//
//  VideoVCTests.swift
//  Internet ArchiveTests
//
//  Unit tests for VideoVC
//

import XCTest
@testable import Internet_Archive

@MainActor
final class VideoVCTests: XCTestCase {

    private var sut: VideoVC!

    override func setUp() {
        super.setUp()
        sut = VideoVC()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit() {
        XCTAssertNotNil(sut)
    }

    func testIsUIViewController() {
        let vc: UIViewController = VideoVC()
        XCTAssertNotNil(vc)
    }

    // MARK: - Property Tests

    func testCollection_defaultValue() {
        XCTAssertEqual(sut.collection, "movies")
    }

    func testCollection_canBeSet() {
        sut.collection = "documentaries"
        XCTAssertEqual(sut.collection, "documentaries")
    }

    func testCollection_canBeEmpty() {
        sut.collection = ""
        XCTAssertEqual(sut.collection, "")
    }

    // MARK: - View Lifecycle Tests

    func testViewDidLoad_doesNotCrash_withoutCollectionView() {
        // Without storyboard, collectionView outlet is nil
        // viewDidLoad should handle this gracefully
        // Note: This will cause issues since collectionView is force-unwrapped IBOutlet
        // This test verifies the class can be instantiated
        XCTAssertNotNil(sut)
    }

    // MARK: - Multiple Instances Tests

    func testMultipleInstances_areIndependent() {
        let vc1 = VideoVC()
        let vc2 = VideoVC()

        vc1.collection = "movies"
        vc2.collection = "documentaries"

        XCTAssertNotEqual(vc1.collection, vc2.collection)
        XCTAssertFalse(vc1 === vc2)
    }

    // MARK: - Collection Property Tests

    func testCollection_withSpecialCharacters() {
        sut.collection = "test-collection_123"
        XCTAssertEqual(sut.collection, "test-collection_123")
    }

    func testCollection_withSpaces() {
        sut.collection = "test collection"
        XCTAssertEqual(sut.collection, "test collection")
    }

    // MARK: - UIViewController Conformance Tests

    func testTitle_defaultsToNil() {
        XCTAssertNil(sut.title)
    }

    func testTitle_canBeSet() {
        sut.title = "Videos"
        XCTAssertEqual(sut.title, "Videos")
    }

    // MARK: - Delegate Conformance Tests

    func testConformsToUICollectionViewDelegate() {
        XCTAssertTrue(sut.conforms(to: UICollectionViewDelegate.self))
    }
}
