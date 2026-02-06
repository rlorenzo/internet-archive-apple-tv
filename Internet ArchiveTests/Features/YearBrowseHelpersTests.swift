//
//  YearBrowseHelpersTests.swift
//  Internet ArchiveTests
//
//  Unit tests for YearBrowseHelpers
//

import XCTest
import SwiftUI
@testable import Internet_Archive

final class YearBrowseHelpersTests: XCTestCase {

    // MARK: - Constants Tests

    func testVideoCardWidthConstant() {
        XCTAssertEqual(YearBrowseHelpers.videoCardWidth, 320)
    }

    func testMusicCardSizeConstant() {
        XCTAssertEqual(YearBrowseHelpers.musicCardSize, 180)
    }

    func testSidebarWidthConstant() {
        XCTAssertEqual(YearBrowseHelpers.sidebarWidth, 300)
    }

    // MARK: - Card Width Tests

    func testCardWidth_video() {
        let width = YearBrowseHelpers.cardWidth(for: .video)
        XCTAssertEqual(width, 320)
    }

    func testCardWidth_music() {
        let width = YearBrowseHelpers.cardWidth(for: .music)
        XCTAssertEqual(width, 180)
    }

    // MARK: - Card Height Tests

    func testCardHeight_video() {
        let height = YearBrowseHelpers.cardHeight(for: .video)
        // Video is 16:9 aspect ratio: 320 * 9 / 16 = 180
        XCTAssertEqual(height, 180)
    }

    func testCardHeight_music() {
        let height = YearBrowseHelpers.cardHeight(for: .music)
        // Music is square
        XCTAssertEqual(height, 180)
    }

    func testVideoAspectRatioIs16By9() {
        let width = YearBrowseHelpers.cardWidth(for: .video)
        let height = YearBrowseHelpers.cardHeight(for: .video)
        let ratio = width / height
        XCTAssertEqual(ratio, 16.0 / 9.0, accuracy: 0.01)
    }

    func testMusicAspectRatioIs1By1() {
        let width = YearBrowseHelpers.cardWidth(for: .music)
        let height = YearBrowseHelpers.cardHeight(for: .music)
        let ratio = width / height
        XCTAssertEqual(ratio, 1.0)
    }

    // MARK: - Grid Column Count Tests

    func testGridColumnCount_video() {
        let count = YearBrowseHelpers.gridColumnCount(for: .video)
        XCTAssertEqual(count, 4)
    }

    func testGridColumnCount_music() {
        let count = YearBrowseHelpers.gridColumnCount(for: .music)
        XCTAssertEqual(count, 5)
    }

    // MARK: - Grid Spacing Tests

    func testGridSpacing_video() {
        let spacing = YearBrowseHelpers.gridSpacing(for: .video)
        XCTAssertEqual(spacing, 48)
    }

    func testGridSpacing_music() {
        let spacing = YearBrowseHelpers.gridSpacing(for: .music)
        XCTAssertEqual(spacing, 40)
    }

    // MARK: - Grid Columns Tests

    func testGridColumns_video() {
        let columns = YearBrowseHelpers.gridColumns(for: .video)
        XCTAssertEqual(columns.count, 4)
    }

    func testGridColumns_music() {
        let columns = YearBrowseHelpers.gridColumns(for: .music)
        XCTAssertEqual(columns.count, 5)
    }

    // MARK: - Title Font Tests

    func testTitleFont_video() {
        let font = YearBrowseHelpers.titleFont(for: .video)
        XCTAssertEqual(font, Font.callout)
    }

    func testTitleFont_music() {
        let font = YearBrowseHelpers.titleFont(for: .music)
        XCTAssertEqual(font, Font.caption)
    }

    // MARK: - Creator Font Tests

    func testCreatorFont_video() {
        let font = YearBrowseHelpers.creatorFont(for: .video)
        XCTAssertEqual(font, Font.caption)
    }

    func testCreatorFont_music() {
        let font = YearBrowseHelpers.creatorFont(for: .music)
        XCTAssertEqual(font, Font.caption2)
    }

    // MARK: - Item Accessibility Label Tests

    func testItemAccessibilityLabel_videoWithCreator() {
        let item = SearchResult(
            identifier: "test-video",
            title: "Test Movie",
            creator: "John Director"
        )

        let label = YearBrowseHelpers.itemAccessibilityLabel(for: item, mediaType: .video)

        XCTAssertEqual(label, "Test Movie, John Director, Video")
    }

    func testItemAccessibilityLabel_videoWithoutCreator() {
        let item = SearchResult(
            identifier: "test-video",
            title: "Test Movie"
        )

        let label = YearBrowseHelpers.itemAccessibilityLabel(for: item, mediaType: .video)

        XCTAssertEqual(label, "Test Movie, Video")
    }

    func testItemAccessibilityLabel_musicWithCreator() {
        let item = SearchResult(
            identifier: "test-music",
            title: "Live Concert 2024",
            creator: "The Band"
        )

        let label = YearBrowseHelpers.itemAccessibilityLabel(for: item, mediaType: .music)

        XCTAssertEqual(label, "Live Concert 2024, The Band, Music")
    }

    func testItemAccessibilityLabel_musicWithoutCreator() {
        let item = SearchResult(
            identifier: "test-music",
            title: "Live Concert 2024"
        )

        let label = YearBrowseHelpers.itemAccessibilityLabel(for: item, mediaType: .music)

        XCTAssertEqual(label, "Live Concert 2024, Music")
    }

    func testItemAccessibilityLabel_nilTitle() {
        let item = SearchResult(
            identifier: "test-item",
            title: nil
        )

        let label = YearBrowseHelpers.itemAccessibilityLabel(for: item, mediaType: .video)

        // safeTitle falls back to "Untitled"
        XCTAssertTrue(label.contains("Untitled"))
        XCTAssertTrue(label.contains("Video"))
    }

    // MARK: - Year Button Accessibility Label Tests

    func testYearButtonAccessibilityLabel_single() {
        let label = YearBrowseHelpers.yearButtonAccessibilityLabel(year: "2024", itemCount: 1)
        XCTAssertEqual(label, "2024, 1 items")
    }

    func testYearButtonAccessibilityLabel_multiple() {
        let label = YearBrowseHelpers.yearButtonAccessibilityLabel(year: "2023", itemCount: 42)
        XCTAssertEqual(label, "2023, 42 items")
    }

    func testYearButtonAccessibilityLabel_zero() {
        let label = YearBrowseHelpers.yearButtonAccessibilityLabel(year: "2020", itemCount: 0)
        XCTAssertEqual(label, "2020, 0 items")
    }

    // MARK: - Year Button Accessibility Hint Tests

    func testYearButtonAccessibilityHint_selected() {
        let hint = YearBrowseHelpers.yearButtonAccessibilityHint(year: "2024", isSelected: true)
        XCTAssertEqual(hint, "Currently selected")
    }

    func testYearButtonAccessibilityHint_notSelected() {
        let hint = YearBrowseHelpers.yearButtonAccessibilityHint(year: "2023", isSelected: false)
        XCTAssertEqual(hint, "Double-tap to browse items from 2023")
    }

    // MARK: - Collection Type Mapping Tests

    func testCollectionType_video() {
        let type = YearBrowseHelpers.collectionType(for: .video)
        XCTAssertEqual(type, "movies")
    }

    func testCollectionType_music() {
        let type = YearBrowseHelpers.collectionType(for: .music)
        XCTAssertEqual(type, "etree")
    }
}
