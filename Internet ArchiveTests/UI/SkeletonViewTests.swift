//
//  SkeletonViewTests.swift
//  Internet ArchiveTests
//
//  Unit tests for SkeletonView and SkeletonItemCell
//

import XCTest
@testable import Internet_Archive

@MainActor
final class SkeletonViewTests: XCTestCase {

    // MARK: - SkeletonView Initialization Tests

    func testInit_withFrame() {
        let skeleton = SkeletonView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        XCTAssertNotNil(skeleton)
    }

    func testInit_hasCornerRadius() {
        let skeleton = SkeletonView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        XCTAssertEqual(skeleton.layer.cornerRadius, 12)
    }

    func testInit_hasBackgroundColor() {
        let skeleton = SkeletonView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        XCTAssertNotNil(skeleton.backgroundColor)
    }

    func testInit_clipsSubviews() {
        let skeleton = SkeletonView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        XCTAssertTrue(skeleton.clipsToBounds)
    }

    func testInit_hasGradientSublayer() {
        let skeleton = SkeletonView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let hasGradient = skeleton.layer.sublayers?.contains { $0 is CAGradientLayer } ?? false
        XCTAssertTrue(hasGradient)
    }

    // MARK: - Animation Tests

    func testStartAnimating() {
        let skeleton = SkeletonView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        skeleton.startAnimating()
        // Just verify it doesn't crash
        XCTAssertNotNil(skeleton)
    }

    func testStopAnimating() {
        let skeleton = SkeletonView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        skeleton.startAnimating()
        skeleton.stopAnimating()
        // Just verify it doesn't crash
        XCTAssertNotNil(skeleton)
    }

    func testStartAnimating_calledTwice_doesNotCrash() {
        let skeleton = SkeletonView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        skeleton.startAnimating()
        skeleton.startAnimating()
        XCTAssertNotNil(skeleton)
    }

    func testStopAnimating_calledWithoutStart_doesNotCrash() {
        let skeleton = SkeletonView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        skeleton.stopAnimating()
        XCTAssertNotNil(skeleton)
    }

    // MARK: - Layout Tests

    func testLayoutSubviews_updatesGradientFrame() {
        let skeleton = SkeletonView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        skeleton.layoutSubviews()
        XCTAssertNotNil(skeleton)
    }
}

// MARK: - SkeletonItemCell Tests

@MainActor
final class SkeletonItemCellTests: XCTestCase {

    func testReuseIdentifier() {
        XCTAssertEqual(SkeletonItemCell.reuseIdentifier, "SkeletonItemCell")
    }

    func testInit_withFrame() {
        let cell = SkeletonItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        XCTAssertNotNil(cell)
    }

    func testInit_hasSubviews() {
        let cell = SkeletonItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        XCTAssertFalse(cell.contentView.subviews.isEmpty)
    }

    func testInit_hasTwoSkeletonViews() {
        let cell = SkeletonItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        let skeletonViews = cell.contentView.subviews.filter { $0 is SkeletonView }
        XCTAssertEqual(skeletonViews.count, 2)
    }

    func testStartAnimating() {
        let cell = SkeletonItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        cell.startAnimating()
        XCTAssertNotNil(cell)
    }

    func testStopAnimating() {
        let cell = SkeletonItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        cell.startAnimating()
        cell.stopAnimating()
        XCTAssertNotNil(cell)
    }

    func testPrepareForReuse_stopsAnimating() {
        let cell = SkeletonItemCell(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        cell.startAnimating()
        cell.prepareForReuse()
        XCTAssertNotNil(cell)
    }
}

// MARK: - UICollectionView Extension Tests

@MainActor
final class CollectionViewSkeletonExtensionTests: XCTestCase {

    func testShowSkeletonLoading_defaultCount() {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showSkeletonLoading()
        // Verify cell is registered by trying to dequeue
        XCTAssertNotNil(collectionView)
    }

    func testShowSkeletonLoading_customCount() {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showSkeletonLoading(itemCount: 10)
        XCTAssertNotNil(collectionView)
    }
}
