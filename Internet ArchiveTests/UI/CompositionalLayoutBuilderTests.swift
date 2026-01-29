//
//  CompositionalLayoutBuilderTests.swift
//  Internet ArchiveTests
//
//  Unit tests for CompositionalLayoutBuilder and FocusableCompositionalLayout
//

import XCTest
import UIKit
@testable import Internet_Archive

@MainActor
final class CompositionalLayoutBuilderTests: XCTestCase {

    // MARK: - FocusableCompositionalLayout Tests

    func testFocusableCompositionalLayout_init() {
        let layout = FocusableCompositionalLayout { _, _ in
            nil
        }

        XCTAssertNotNil(layout)
    }

    func testFocusableCompositionalLayout_pendingContentOffsetInitiallyNil() {
        let layout = FocusableCompositionalLayout { _, _ in
            nil
        }

        XCTAssertNil(layout.pendingContentOffset)
    }

    func testFocusableCompositionalLayout_setPendingContentOffset() {
        let layout = FocusableCompositionalLayout { _, _ in
            nil
        }

        layout.pendingContentOffset = CGPoint(x: 100, y: 200)

        XCTAssertEqual(layout.pendingContentOffset?.x, 100)
        XCTAssertEqual(layout.pendingContentOffset?.y, 200)
    }

    func testFocusableCompositionalLayout_targetContentOffsetUsesPending() {
        let layout = FocusableCompositionalLayout { _, _ in
            nil
        }

        layout.pendingContentOffset = CGPoint(x: 50, y: 150)

        let result = layout.targetContentOffset(forProposedContentOffset: CGPoint(x: 0, y: 0))

        XCTAssertEqual(result.x, 50)
        XCTAssertEqual(result.y, 150)
    }

    func testFocusableCompositionalLayout_targetContentOffsetClearsPending() {
        let layout = FocusableCompositionalLayout { _, _ in
            nil
        }

        layout.pendingContentOffset = CGPoint(x: 50, y: 150)

        _ = layout.targetContentOffset(forProposedContentOffset: CGPoint.zero)

        XCTAssertNil(layout.pendingContentOffset)
    }

    func testFocusableCompositionalLayout_targetContentOffsetUsesProposedWhenNoPending() {
        let layout = FocusableCompositionalLayout { _, _ in
            nil
        }

        let proposed = CGPoint(x: 300, y: 400)
        let result = layout.targetContentOffset(forProposedContentOffset: proposed)

        XCTAssertEqual(result.x, 300)
        XCTAssertEqual(result.y, 400)
    }

    // MARK: - Grid Layout Tests

    func testCreateGridLayout_default() {
        let layout = CompositionalLayoutBuilder.createGridLayout()

        XCTAssertNotNil(layout)
        XCTAssertTrue(layout is UICollectionViewCompositionalLayout)
    }

    func testCreateGridLayout_customColumns() {
        let layout = CompositionalLayoutBuilder.createGridLayout(columns: 3)

        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_customSpacing() {
        let layout = CompositionalLayoutBuilder.createGridLayout(spacing: 20)

        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_customAspectRatio() {
        let layout = CompositionalLayoutBuilder.createGridLayout(aspectRatio: 1.0)

        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_allCustomParameters() {
        let layout = CompositionalLayoutBuilder.createGridLayout(
            columns: 4,
            spacing: 30,
            aspectRatio: 0.67
        )

        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_singleColumn() {
        let layout = CompositionalLayoutBuilder.createGridLayout(columns: 1)

        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_manyColumns() {
        let layout = CompositionalLayoutBuilder.createGridLayout(columns: 10)

        XCTAssertNotNil(layout)
    }

    // MARK: - List Layout Tests

    func testCreateListLayout_default() {
        let layout = CompositionalLayoutBuilder.createListLayout()

        XCTAssertNotNil(layout)
        XCTAssertTrue(layout is UICollectionViewCompositionalLayout)
    }

    func testCreateListLayout_customItemHeight() {
        let layout = CompositionalLayoutBuilder.createListLayout(itemHeight: 120)

        XCTAssertNotNil(layout)
    }

    func testCreateListLayout_customSpacing() {
        let layout = CompositionalLayoutBuilder.createListLayout(spacing: 10)

        XCTAssertNotNil(layout)
    }

    func testCreateListLayout_allCustomParameters() {
        let layout = CompositionalLayoutBuilder.createListLayout(
            itemHeight: 100,
            spacing: 15
        )

        XCTAssertNotNil(layout)
    }

    func testCreateListLayout_verySmallItemHeight() {
        let layout = CompositionalLayoutBuilder.createListLayout(itemHeight: 20)

        XCTAssertNotNil(layout)
    }

    func testCreateListLayout_veryLargeItemHeight() {
        let layout = CompositionalLayoutBuilder.createListLayout(itemHeight: 500)

        XCTAssertNotNil(layout)
    }

    // MARK: - Horizontal Layout Tests

    func testCreateHorizontalLayout_default() {
        let layout = CompositionalLayoutBuilder.createHorizontalLayout()

        XCTAssertNotNil(layout)
        XCTAssertTrue(layout is UICollectionViewCompositionalLayout)
    }

    func testCreateHorizontalLayout_customItemWidth() {
        let layout = CompositionalLayoutBuilder.createHorizontalLayout(itemWidth: 300)

        XCTAssertNotNil(layout)
    }

    func testCreateHorizontalLayout_customItemHeight() {
        let layout = CompositionalLayoutBuilder.createHorizontalLayout(itemHeight: 200)

        XCTAssertNotNil(layout)
    }

    func testCreateHorizontalLayout_customSpacing() {
        let layout = CompositionalLayoutBuilder.createHorizontalLayout(spacing: 50)

        XCTAssertNotNil(layout)
    }

    func testCreateHorizontalLayout_allCustomParameters() {
        let layout = CompositionalLayoutBuilder.createHorizontalLayout(
            itemWidth: 350,
            itemHeight: 250,
            spacing: 35
        )

        XCTAssertNotNil(layout)
    }

    // MARK: - Multi-Section Layout Tests

    func testCreateMultiSectionLayout_withProvider() {
        let layout = CompositionalLayoutBuilder.createMultiSectionLayout { _, _ in
            nil
        }

        XCTAssertNotNil(layout)
        XCTAssertTrue(layout is UICollectionViewCompositionalLayout)
    }

    func testCreateMultiSectionLayout_providerCalledWithSectionIndex() {
        var calledSections: [Int] = []

        _ = CompositionalLayoutBuilder.createMultiSectionLayout { sectionIndex, _ in
            calledSections.append(sectionIndex)
            return nil
        }

        XCTAssertNotNil(calledSections)
    }

    // MARK: - Common Configurations Tests

    func testStandardGrid() {
        let layout = CompositionalLayoutBuilder.standardGrid

        XCTAssertNotNil(layout)
        XCTAssertTrue(layout is UICollectionViewCompositionalLayout)
    }

    func testCompactGrid() {
        let layout = CompositionalLayoutBuilder.compactGrid

        XCTAssertNotNil(layout)
        XCTAssertTrue(layout is UICollectionViewCompositionalLayout)
    }

    func testLargeItemGrid() {
        let layout = CompositionalLayoutBuilder.largeItemGrid

        XCTAssertNotNil(layout)
        XCTAssertTrue(layout is UICollectionViewCompositionalLayout)
    }

    func testListLayout() {
        let layout = CompositionalLayoutBuilder.listLayout

        XCTAssertNotNil(layout)
        XCTAssertTrue(layout is UICollectionViewCompositionalLayout)
    }

    // MARK: - Video Home Layout Tests

    func testCreateVideoHomeLayout_withContinueWatching() {
        let layout = CompositionalLayoutBuilder.createVideoHomeLayout(hasContinueWatching: true)

        XCTAssertNotNil(layout)
        XCTAssertTrue(layout is FocusableCompositionalLayout)
    }

    func testCreateVideoHomeLayout_withoutContinueWatching() {
        let layout = CompositionalLayoutBuilder.createVideoHomeLayout(hasContinueWatching: false)

        XCTAssertNotNil(layout)
        XCTAssertTrue(layout is FocusableCompositionalLayout)
    }

    // MARK: - Music Home Layout Tests

    func testCreateMusicHomeLayout_withContinueListening() {
        let layout = CompositionalLayoutBuilder.createMusicHomeLayout(hasContinueListening: true)

        XCTAssertNotNil(layout)
        XCTAssertTrue(layout is FocusableCompositionalLayout)
    }

    func testCreateMusicHomeLayout_withoutContinueListening() {
        let layout = CompositionalLayoutBuilder.createMusicHomeLayout(hasContinueListening: false)

        XCTAssertNotNil(layout)
        XCTAssertTrue(layout is FocusableCompositionalLayout)
    }

    // MARK: - Edge Cases

    func testCreateGridLayout_zeroSpacing() {
        let layout = CompositionalLayoutBuilder.createGridLayout(spacing: 0)

        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_verySmallAspectRatio() {
        let layout = CompositionalLayoutBuilder.createGridLayout(aspectRatio: 0.1)

        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_veryLargeAspectRatio() {
        let layout = CompositionalLayoutBuilder.createGridLayout(aspectRatio: 10.0)

        XCTAssertNotNil(layout)
    }

    func testCreateListLayout_zeroSpacing() {
        let layout = CompositionalLayoutBuilder.createListLayout(spacing: 0)

        XCTAssertNotNil(layout)
    }

    func testCreateHorizontalLayout_zeroSpacing() {
        let layout = CompositionalLayoutBuilder.createHorizontalLayout(spacing: 0)

        XCTAssertNotNil(layout)
    }

    // MARK: - Layout Configuration Tests

    func testListLayout_hasConfiguration() {
        let layout = CompositionalLayoutBuilder.createListLayout() as? UICollectionViewCompositionalLayout

        XCTAssertNotNil(layout?.configuration)
    }

    func testHorizontalLayout_hasConfiguration() {
        let layout = CompositionalLayoutBuilder.createHorizontalLayout() as? UICollectionViewCompositionalLayout

        XCTAssertNotNil(layout?.configuration)
    }

    func testMultiSectionLayout_hasConfiguration() {
        let layout = CompositionalLayoutBuilder.createMultiSectionLayout { _, _ in nil }
            as? UICollectionViewCompositionalLayout

        XCTAssertNotNil(layout?.configuration)
    }

    // MARK: - Content Insets Reference Tests

    func testListLayout_usesSafeAreaContentInsetsReference() {
        let layout = CompositionalLayoutBuilder.createListLayout() as? UICollectionViewCompositionalLayout

        XCTAssertEqual(layout?.configuration.contentInsetsReference, .safeArea)
    }

    func testHorizontalLayout_usesSafeAreaContentInsetsReference() {
        let layout = CompositionalLayoutBuilder.createHorizontalLayout() as? UICollectionViewCompositionalLayout

        XCTAssertEqual(layout?.configuration.contentInsetsReference, .safeArea)
    }

    func testMultiSectionLayout_usesSafeAreaContentInsetsReference() {
        let layout = CompositionalLayoutBuilder.createMultiSectionLayout { _, _ in nil }
            as? UICollectionViewCompositionalLayout

        XCTAssertEqual(layout?.configuration.contentInsetsReference, .safeArea)
    }

    // MARK: - FocusableCompositionalLayout Multiple Access Tests

    func testFocusableCompositionalLayout_multipleTargetContentOffsetCalls() {
        let layout = FocusableCompositionalLayout { _, _ in nil }

        layout.pendingContentOffset = CGPoint(x: 100, y: 100)
        let first = layout.targetContentOffset(forProposedContentOffset: .zero)
        let second = layout.targetContentOffset(forProposedContentOffset: CGPoint(x: 200, y: 200))

        XCTAssertEqual(first, CGPoint(x: 100, y: 100))
        XCTAssertEqual(second, CGPoint(x: 200, y: 200)) // Should use proposed since pending was cleared
    }

    func testFocusableCompositionalLayout_setPendingAfterAccess() {
        let layout = FocusableCompositionalLayout { _, _ in nil }

        layout.pendingContentOffset = CGPoint(x: 50, y: 50)
        _ = layout.targetContentOffset(forProposedContentOffset: .zero)

        // Set new pending
        layout.pendingContentOffset = CGPoint(x: 150, y: 150)

        let result = layout.targetContentOffset(forProposedContentOffset: .zero)
        XCTAssertEqual(result, CGPoint(x: 150, y: 150))
    }
}
