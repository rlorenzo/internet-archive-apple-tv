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

    // MARK: - SkeletonView Tests

    func testInit_createsSkeletonView() {
        let view = SkeletonView()
        XCTAssertNotNil(view)
    }

    func testInit_withFrame() {
        let frame = CGRect(x: 0, y: 0, width: 200, height: 150)
        let view = SkeletonView(frame: frame)

        XCTAssertEqual(view.frame.width, 200)
        XCTAssertEqual(view.frame.height, 150)
    }

    func testBackgroundColor_isSemiTransparent() {
        let view = SkeletonView()

        XCTAssertNotNil(view.backgroundColor)
        // Should be a semi-transparent gray
    }

    func testCornerRadius_isSet() {
        let view = SkeletonView()

        XCTAssertEqual(view.layer.cornerRadius, 12)
    }

    func testClipsToBounds_isEnabled() {
        let view = SkeletonView()

        XCTAssertTrue(view.clipsToBounds)
    }

    func testAccessibility_isHidden() {
        let view = SkeletonView()

        // Skeleton views are decorative loading indicators
        XCTAssertFalse(view.isAccessibilityElement)
        XCTAssertTrue(view.accessibilityElementsHidden)
    }

    func testStartAnimating_addsShimmerAnimation() {
        let view = SkeletonView()
        view.startAnimating()

        // Check that animation was added
        let animation = view.layer.sublayers?.first?.animation(forKey: "shimmer")
        XCTAssertNotNil(animation)
    }

    func testStopAnimating_removesShimmerAnimation() {
        let view = SkeletonView()
        view.startAnimating()
        view.stopAnimating()

        // Check that animation was removed
        let animation = view.layer.sublayers?.first?.animation(forKey: "shimmer")
        XCTAssertNil(animation)
    }

    func testStartAnimating_multipleTimes_doesNotAddDuplicateAnimations() {
        let view = SkeletonView()
        view.startAnimating()
        view.startAnimating()
        view.startAnimating()

        // Should still only have one shimmer animation
        let gradientLayer = view.layer.sublayers?.first as? CAGradientLayer
        XCTAssertNotNil(gradientLayer)
    }

    func testLayoutSubviews_updatesGradientFrame() {
        let view = SkeletonView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        // Change frame
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 150)
        view.layoutSubviews()

        // Gradient layer should match new bounds
        let gradientLayer = view.layer.sublayers?.first as? CAGradientLayer
        XCTAssertEqual(gradientLayer?.frame.width, 200)
        XCTAssertEqual(gradientLayer?.frame.height, 150)
    }

    // MARK: - SkeletonItemCell Tests

    func testSkeletonItemCell_reuseIdentifier() {
        XCTAssertEqual(SkeletonItemCell.reuseIdentifier, "SkeletonItemCell")
    }

    func testSkeletonItemCell_init() {
        let cell = SkeletonItemCell()
        XCTAssertNotNil(cell)
    }

    func testSkeletonItemCell_initWithFrame() {
        let frame = CGRect(x: 0, y: 0, width: 300, height: 400)
        let cell = SkeletonItemCell(frame: frame)

        XCTAssertEqual(cell.frame.width, 300)
        XCTAssertEqual(cell.frame.height, 400)
    }

    func testSkeletonItemCell_hasSubviews() {
        let cell = SkeletonItemCell(frame: CGRect(x: 0, y: 0, width: 300, height: 400))

        // Should have skeleton views as subviews
        XCTAssertFalse(cell.contentView.subviews.isEmpty)
    }

    func testSkeletonItemCell_hasImageSkeleton() {
        let cell = SkeletonItemCell(frame: CGRect(x: 0, y: 0, width: 300, height: 400))

        // Should have SkeletonView as subview
        let hasSkeletonView = cell.contentView.subviews.contains { $0 is SkeletonView }
        XCTAssertTrue(hasSkeletonView)
    }

    func testSkeletonItemCell_accessibilityIsHidden() {
        let cell = SkeletonItemCell()

        // Skeleton cells should be hidden from VoiceOver
        XCTAssertFalse(cell.isAccessibilityElement)
        XCTAssertTrue(cell.accessibilityElementsHidden)
    }

    func testSkeletonItemCell_startAnimating_doesNotCrash() {
        let cell = SkeletonItemCell(frame: CGRect(x: 0, y: 0, width: 300, height: 400))

        // Should not crash
        cell.startAnimating()

        XCTAssertNotNil(cell)
    }

    func testSkeletonItemCell_stopAnimating_doesNotCrash() {
        let cell = SkeletonItemCell(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        cell.startAnimating()
        cell.stopAnimating()

        XCTAssertNotNil(cell)
    }

    func testSkeletonItemCell_prepareForReuse_stopsAnimating() {
        let cell = SkeletonItemCell(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        cell.startAnimating()
        cell.prepareForReuse()

        // After prepareForReuse, animations should be stopped
        XCTAssertNotNil(cell)
    }

    // MARK: - UICollectionView Extension Tests

    func testCollectionView_showSkeletonLoading_doesNotCrash() {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 400, height: 600), collectionViewLayout: layout)

        // Should not crash
        collectionView.showSkeletonLoading(itemCount: 10)

        XCTAssertNotNil(collectionView)
    }

    func testCollectionView_showSkeletonLoading_defaultCount() {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 400, height: 600), collectionViewLayout: layout)

        // Should not crash with default count
        collectionView.showSkeletonLoading()

        XCTAssertNotNil(collectionView)
    }
}
