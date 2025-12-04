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
    private var mockService: MockCollectionService!

    override func setUp() {
        super.setUp()
        mockService = MockCollectionService()
        sut = VideoVC()
        // Inject mock ViewModel before viewDidLoad
        let mockViewModel = VideoViewModel(collectionService: mockService, collection: "movies")
        sut.setViewModel(mockViewModel)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
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

    // MARK: - State Access Tests

    func testCurrentState_exposesViewModelState() {
        XCTAssertFalse(sut.currentState.isLoading)
        XCTAssertEqual(sut.currentState.collection, "movies")
        XCTAssertTrue(sut.currentState.items.isEmpty)
        XCTAssertNil(sut.currentState.errorMessage)
    }

    func testItemCount_initiallyZero() {
        XCTAssertEqual(sut.itemCount, 0)
    }

    // MARK: - View Lifecycle Tests

    func testViewDidLoad_doesNotCrash_withoutCollectionView() {
        // Without storyboard, collectionView outlet is nil
        // viewDidLoad should handle this gracefully with optional collectionView
        XCTAssertNotNil(sut)

        // Trigger viewDidLoad by accessing view
        // This should not crash since collectionView is now optional
        _ = sut.view
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

    // MARK: - ViewModel Injection Tests

    func testSetViewModel_allowsInjection() {
        let customService = MockCollectionService()
        let customViewModel = VideoViewModel(collectionService: customService, collection: "custom")
        sut.setViewModel(customViewModel)

        XCTAssertEqual(sut.collection, "custom")
    }
}
