//
//  MusicVCTests.swift
//  Internet ArchiveTests
//
//  Unit tests for MusicVC
//

import XCTest
@testable import Internet_Archive

@MainActor
final class MusicVCTests: XCTestCase {

    private var sut: MusicVC!
    private var mockService: MockCollectionService!

    override func setUp() {
        super.setUp()
        mockService = MockCollectionService()
        sut = MusicVC()
        // Inject mock ViewModel before viewDidLoad
        let mockViewModel = MusicViewModel(collectionService: mockService, collection: "etree")
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
        let vc: UIViewController = MusicVC()
        XCTAssertNotNil(vc)
    }

    // MARK: - Property Tests

    func testCollection_defaultValue() {
        XCTAssertEqual(sut.collection, "etree")
    }

    func testCollection_canBeSet() {
        sut.collection = "audio"
        XCTAssertEqual(sut.collection, "audio")
    }

    func testCollection_canBeEmpty() {
        sut.collection = ""
        XCTAssertEqual(sut.collection, "")
    }

    // MARK: - State Access Tests

    func testCurrentState_exposesViewModelState() {
        XCTAssertFalse(sut.currentState.isLoading)
        XCTAssertEqual(sut.currentState.collection, "etree")
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
        let vc1 = MusicVC()
        let vc2 = MusicVC()

        vc1.collection = "etree"
        vc2.collection = "audio"

        XCTAssertNotEqual(vc1.collection, vc2.collection)
        XCTAssertFalse(vc1 === vc2)
    }

    // MARK: - Collection Property Tests

    func testCollection_withSpecialCharacters() {
        sut.collection = "test-collection_123"
        XCTAssertEqual(sut.collection, "test-collection_123")
    }

    func testCollection_withSpaces() {
        sut.collection = "live music archive"
        XCTAssertEqual(sut.collection, "live music archive")
    }

    // MARK: - UIViewController Conformance Tests

    func testTitle_defaultsToNil() {
        XCTAssertNil(sut.title)
    }

    func testTitle_canBeSet() {
        sut.title = "Music"
        XCTAssertEqual(sut.title, "Music")
    }

    // MARK: - Delegate Conformance Tests

    func testConformsToUICollectionViewDelegate() {
        XCTAssertTrue(sut.conforms(to: UICollectionViewDelegate.self))
    }

    // MARK: - ViewModel Injection Tests

    func testSetViewModel_allowsInjection() {
        let customService = MockCollectionService()
        let customViewModel = MusicViewModel(collectionService: customService, collection: "custom")
        sut.setViewModel(customViewModel)

        XCTAssertEqual(sut.collection, "custom")
    }
}
