//
//  CompositionalLayoutBuilderTests.swift
//  Internet ArchiveTests
//
//  Unit tests for CompositionalLayoutBuilder
//

import XCTest
@testable import Internet_Archive

@MainActor
final class CompositionalLayoutBuilderTests: XCTestCase {

    // MARK: - Grid Layout Tests

    func testCreateGridLayout_returnsNonNilLayout() {
        let layout = CompositionalLayoutBuilder.createGridLayout()
        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_withCustomColumns() {
        let layout = CompositionalLayoutBuilder.createGridLayout(columns: 3)
        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_withCustomSpacing() {
        let layout = CompositionalLayoutBuilder.createGridLayout(spacing: 20)
        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_withCustomAspectRatio() {
        let layout = CompositionalLayoutBuilder.createGridLayout(aspectRatio: 1.0)
        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_withAllCustomParameters() {
        let layout = CompositionalLayoutBuilder.createGridLayout(
            columns: 4,
            spacing: 30,
            aspectRatio: 0.8
        )
        XCTAssertNotNil(layout)
    }

    // MARK: - List Layout Tests

    func testCreateListLayout_returnsNonNilLayout() {
        let layout = CompositionalLayoutBuilder.createListLayout()
        XCTAssertNotNil(layout)
    }

    func testCreateListLayout_withCustomItemHeight() {
        let layout = CompositionalLayoutBuilder.createListLayout(itemHeight: 100)
        XCTAssertNotNil(layout)
    }

    func testCreateListLayout_withCustomSpacing() {
        let layout = CompositionalLayoutBuilder.createListLayout(spacing: 10)
        XCTAssertNotNil(layout)
    }

    func testCreateListLayout_withAllCustomParameters() {
        let layout = CompositionalLayoutBuilder.createListLayout(
            itemHeight: 120,
            spacing: 15
        )
        XCTAssertNotNil(layout)
    }

    // MARK: - Horizontal Layout Tests

    func testCreateHorizontalLayout_returnsNonNilLayout() {
        let layout = CompositionalLayoutBuilder.createHorizontalLayout()
        XCTAssertNotNil(layout)
    }

    func testCreateHorizontalLayout_withCustomItemWidth() {
        let layout = CompositionalLayoutBuilder.createHorizontalLayout(itemWidth: 300)
        XCTAssertNotNil(layout)
    }

    func testCreateHorizontalLayout_withCustomItemHeight() {
        let layout = CompositionalLayoutBuilder.createHorizontalLayout(itemHeight: 200)
        XCTAssertNotNil(layout)
    }

    func testCreateHorizontalLayout_withAllCustomParameters() {
        let layout = CompositionalLayoutBuilder.createHorizontalLayout(
            itemWidth: 350,
            itemHeight: 250,
            spacing: 30
        )
        XCTAssertNotNil(layout)
    }

    // MARK: - Multi-Section Layout Tests

    func testCreateMultiSectionLayout_returnsNonNilLayout() {
        let layout = CompositionalLayoutBuilder.createMultiSectionLayout { _, _ in
            nil
        }
        XCTAssertNotNil(layout)
    }

    func testCreateMultiSectionLayout_withCustomSectionProvider() {
        let layout = CompositionalLayoutBuilder.createMultiSectionLayout { sectionIndex, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(100)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
            return NSCollectionLayoutSection(group: group)
        }
        XCTAssertNotNil(layout)
    }

    // MARK: - Preset Configuration Tests

    func testStandardGrid_returnsNonNilLayout() {
        let layout = CompositionalLayoutBuilder.standardGrid
        XCTAssertNotNil(layout)
    }

    func testCompactGrid_returnsNonNilLayout() {
        let layout = CompositionalLayoutBuilder.compactGrid
        XCTAssertNotNil(layout)
    }

    func testLargeItemGrid_returnsNonNilLayout() {
        let layout = CompositionalLayoutBuilder.largeItemGrid
        XCTAssertNotNil(layout)
    }

    func testListLayout_returnsNonNilLayout() {
        let layout = CompositionalLayoutBuilder.listLayout
        XCTAssertNotNil(layout)
    }

    // MARK: - Layout Type Tests

    func testAllLayoutsAreUICollectionViewLayout() {
        // Verify layouts are properly typed (these assertions validate the API contract)
        let standardGrid: UICollectionViewLayout = CompositionalLayoutBuilder.standardGrid
        let compactGrid: UICollectionViewLayout = CompositionalLayoutBuilder.compactGrid
        let largeItemGrid: UICollectionViewLayout = CompositionalLayoutBuilder.largeItemGrid
        let listLayout: UICollectionViewLayout = CompositionalLayoutBuilder.listLayout

        XCTAssertNotNil(standardGrid)
        XCTAssertNotNil(compactGrid)
        XCTAssertNotNil(largeItemGrid)
        XCTAssertNotNil(listLayout)
    }

    func testAllLayoutsAreCompositionalLayout() {
        // Verify layouts are UICollectionViewCompositionalLayout instances using runtime check
        let standardGrid = CompositionalLayoutBuilder.standardGrid as? UICollectionViewCompositionalLayout
        let compactGrid = CompositionalLayoutBuilder.compactGrid as? UICollectionViewCompositionalLayout
        let largeItemGrid = CompositionalLayoutBuilder.largeItemGrid as? UICollectionViewCompositionalLayout
        let listLayout = CompositionalLayoutBuilder.listLayout as? UICollectionViewCompositionalLayout

        XCTAssertNotNil(standardGrid, "standardGrid should be UICollectionViewCompositionalLayout")
        XCTAssertNotNil(compactGrid, "compactGrid should be UICollectionViewCompositionalLayout")
        XCTAssertNotNil(largeItemGrid, "largeItemGrid should be UICollectionViewCompositionalLayout")
        XCTAssertNotNil(listLayout, "listLayout should be UICollectionViewCompositionalLayout")
    }

    // MARK: - Edge Case Tests

    func testCreateGridLayout_withOneColumn() {
        let layout = CompositionalLayoutBuilder.createGridLayout(columns: 1)
        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_withManyColumns() {
        let layout = CompositionalLayoutBuilder.createGridLayout(columns: 10)
        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_withZeroSpacing() {
        let layout = CompositionalLayoutBuilder.createGridLayout(spacing: 0)
        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_withSmallAspectRatio() {
        let layout = CompositionalLayoutBuilder.createGridLayout(aspectRatio: 0.1)
        XCTAssertNotNil(layout)
    }

    func testCreateGridLayout_withLargeAspectRatio() {
        let layout = CompositionalLayoutBuilder.createGridLayout(aspectRatio: 5.0)
        XCTAssertNotNil(layout)
    }

    func testCreateListLayout_withSmallItemHeight() {
        let layout = CompositionalLayoutBuilder.createListLayout(itemHeight: 10)
        XCTAssertNotNil(layout)
    }

    func testCreateListLayout_withLargeItemHeight() {
        let layout = CompositionalLayoutBuilder.createListLayout(itemHeight: 500)
        XCTAssertNotNil(layout)
    }

    func testCreateHorizontalLayout_withSmallDimensions() {
        let layout = CompositionalLayoutBuilder.createHorizontalLayout(
            itemWidth: 50,
            itemHeight: 50,
            spacing: 5
        )
        XCTAssertNotNil(layout)
    }

    func testCreateHorizontalLayout_withLargeDimensions() {
        let layout = CompositionalLayoutBuilder.createHorizontalLayout(
            itemWidth: 800,
            itemHeight: 600,
            spacing: 50
        )
        XCTAssertNotNil(layout)
    }

    // MARK: - Layout Can Be Applied Tests

    func testStandardGrid_canBeAppliedToCollectionView() {
        let layout = CompositionalLayoutBuilder.standardGrid
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        XCTAssertNotNil(collectionView)
        XCTAssertTrue(collectionView.collectionViewLayout is UICollectionViewCompositionalLayout)
    }

    func testListLayout_canBeAppliedToCollectionView() {
        let layout = CompositionalLayoutBuilder.listLayout
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        XCTAssertNotNil(collectionView)
    }

    func testMultiSectionLayout_withDifferentSections() {
        let layout = CompositionalLayoutBuilder.createMultiSectionLayout { sectionIndex, environment in
            switch sectionIndex {
            case 0:
                // Grid section
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.5),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(200)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                return NSCollectionLayoutSection(group: group)
            case 1:
                // List section
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(80)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
                return NSCollectionLayoutSection(group: group)
            default:
                return nil
            }
        }
        XCTAssertNotNil(layout)
    }
}
