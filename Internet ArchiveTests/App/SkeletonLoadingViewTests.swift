//
//  SkeletonLoadingViewTests.swift
//  Internet ArchiveTests
//
//  Unit tests for skeleton loading views (SkeletonCard, SkeletonGrid, SkeletonRow, etc.)
//

import XCTest
import SwiftUI
@testable import Internet_Archive

@MainActor
final class SkeletonLoadingViewTests: XCTestCase {

    // MARK: - SkeletonCard Tests

    // MARK: Initialization

    func testSkeletonCard_initWithAspectRatio() {
        let card = SkeletonCard(aspectRatio: 16.0 / 9.0)

        XCTAssertEqual(card.aspectRatio, 16.0 / 9.0, accuracy: 0.01)
    }

    func testSkeletonCard_initWithSquareAspectRatio() {
        let card = SkeletonCard(aspectRatio: 1.0)

        XCTAssertEqual(card.aspectRatio, 1.0, accuracy: 0.01)
    }

    func testSkeletonCard_defaultTitleHeight() {
        let card = SkeletonCard(aspectRatio: 1.0)

        XCTAssertEqual(card.titleHeight, 20)
    }

    func testSkeletonCard_defaultSubtitleHeight() {
        let card = SkeletonCard(aspectRatio: 1.0)

        XCTAssertEqual(card.subtitleHeight, 16)
    }

    func testSkeletonCard_defaultSubtitleWidth() {
        let card = SkeletonCard(aspectRatio: 1.0)

        XCTAssertEqual(card.subtitleWidth, 150)
    }

    func testSkeletonCard_initWithAllParameters() {
        let card = SkeletonCard(
            aspectRatio: 4.0 / 3.0,
            titleHeight: 24,
            subtitleHeight: 18,
            subtitleWidth: 200
        )

        XCTAssertEqual(card.aspectRatio, 4.0 / 3.0, accuracy: 0.01)
        XCTAssertEqual(card.titleHeight, 24)
        XCTAssertEqual(card.subtitleHeight, 18)
        XCTAssertEqual(card.subtitleWidth, 200)
    }

    // MARK: Static Constructors

    func testSkeletonCard_video() {
        let card = SkeletonCard.video

        XCTAssertEqual(card.aspectRatio, 16.0 / 9.0, accuracy: 0.01)
    }

    func testSkeletonCard_music() {
        let card = SkeletonCard.music

        XCTAssertEqual(card.aspectRatio, 1.0, accuracy: 0.01)
        XCTAssertEqual(card.titleHeight, 18)
        XCTAssertEqual(card.subtitleHeight, 14)
        XCTAssertEqual(card.subtitleWidth, 120)
    }

    // MARK: Edge Cases

    func testSkeletonCard_veryWideAspectRatio() {
        let card = SkeletonCard(aspectRatio: 21.0 / 9.0)

        XCTAssertEqual(card.aspectRatio, 21.0 / 9.0, accuracy: 0.01)
    }

    func testSkeletonCard_veryNarrowAspectRatio() {
        let card = SkeletonCard(aspectRatio: 9.0 / 16.0)

        XCTAssertEqual(card.aspectRatio, 9.0 / 16.0, accuracy: 0.01)
    }

    func testSkeletonCard_verySmallTitleHeight() {
        let card = SkeletonCard(aspectRatio: 1.0, titleHeight: 1)

        XCTAssertEqual(card.titleHeight, 1)
    }

    func testSkeletonCard_veryLargeTitleHeight() {
        let card = SkeletonCard(aspectRatio: 1.0, titleHeight: 100)

        XCTAssertEqual(card.titleHeight, 100)
    }

    // MARK: - SkeletonGrid Tests

    // MARK: Initialization

    func testSkeletonGrid_initVideoType() {
        let grid = SkeletonGrid(cardType: .video, columns: 4, rows: 2)

        XCTAssertEqual(grid.columns, 4)
        XCTAssertEqual(grid.rows, 2)
    }

    func testSkeletonGrid_initMusicType() {
        let grid = SkeletonGrid(cardType: .music, columns: 6, rows: 3)

        XCTAssertEqual(grid.columns, 6)
        XCTAssertEqual(grid.rows, 3)
    }

    // MARK: Card Type Tests

    func testSkeletonGrid_videoCardType() {
        let grid = SkeletonGrid(cardType: .video, columns: 4, rows: 2)
        XCTAssertEqual(grid.cardType, .video)
    }

    func testSkeletonGrid_musicCardType() {
        let grid = SkeletonGrid(cardType: .music, columns: 6, rows: 2)
        XCTAssertEqual(grid.cardType, .music)
    }

    // MARK: Grid Configuration

    func testSkeletonGrid_singleCell() {
        let grid = SkeletonGrid(cardType: .video, columns: 1, rows: 1)

        XCTAssertEqual(grid.columns * grid.rows, 1)
    }

    func testSkeletonGrid_manyColumns() {
        let grid = SkeletonGrid(cardType: .music, columns: 10, rows: 2)

        XCTAssertEqual(grid.columns, 10)
    }

    func testSkeletonGrid_manyRows() {
        let grid = SkeletonGrid(cardType: .video, columns: 4, rows: 10)

        XCTAssertEqual(grid.rows, 10)
    }

    func testSkeletonGrid_totalItems() {
        let grid = SkeletonGrid(cardType: .video, columns: 5, rows: 4)

        XCTAssertEqual(grid.columns * grid.rows, 20)
    }

    // MARK: - SkeletonRow Tests

    // MARK: Initialization

    func testSkeletonRow_initVideoType() {
        let row = SkeletonRow(cardType: .video, count: 5)

        XCTAssertEqual(row.count, 5)
    }

    func testSkeletonRow_initMusicType() {
        let row = SkeletonRow(cardType: .music, count: 8)

        XCTAssertEqual(row.count, 8)
    }

    // MARK: Card Type Tests

    func testSkeletonRow_videoCardType() {
        let row = SkeletonRow(cardType: .video, count: 3)
        XCTAssertEqual(row.cardType, .video)
    }

    func testSkeletonRow_musicCardType() {
        let row = SkeletonRow(cardType: .music, count: 4)
        XCTAssertEqual(row.cardType, .music)
    }

    // MARK: Count Tests

    func testSkeletonRow_singleItem() {
        let row = SkeletonRow(cardType: .video, count: 1)

        XCTAssertEqual(row.count, 1)
    }

    func testSkeletonRow_manyItems() {
        let row = SkeletonRow(cardType: .music, count: 50)

        XCTAssertEqual(row.count, 50)
    }

    // MARK: - SkeletonText Tests

    // MARK: Initialization

    func testSkeletonText_initWithLineCount() {
        let text = SkeletonText(lineCount: 3)

        XCTAssertEqual(text.lineCount, 3)
    }

    func testSkeletonText_defaultLineSpacing() {
        let text = SkeletonText(lineCount: 3)

        XCTAssertEqual(text.lineSpacing, 8)
    }

    func testSkeletonText_defaultLastLineWidth() {
        let text = SkeletonText(lineCount: 3)

        XCTAssertEqual(text.lastLineWidth, 0.7, accuracy: 0.01)
    }

    func testSkeletonText_initWithAllParameters() {
        let text = SkeletonText(
            lineCount: 5,
            lineSpacing: 12,
            lastLineWidth: 0.5
        )

        XCTAssertEqual(text.lineCount, 5)
        XCTAssertEqual(text.lineSpacing, 12)
        XCTAssertEqual(text.lastLineWidth, 0.5, accuracy: 0.01)
    }

    // MARK: Line Count Tests

    func testSkeletonText_singleLine() {
        let text = SkeletonText(lineCount: 1)

        XCTAssertEqual(text.lineCount, 1)
    }

    func testSkeletonText_manyLines() {
        let text = SkeletonText(lineCount: 20)

        XCTAssertEqual(text.lineCount, 20)
    }

    func testSkeletonText_customLineSpacing() {
        let text = SkeletonText(lineCount: 3, lineSpacing: 16)

        XCTAssertEqual(text.lineSpacing, 16)
    }

    func testSkeletonText_customLastLineWidth() {
        let text = SkeletonText(lineCount: 3, lastLineWidth: 0.3)

        XCTAssertEqual(text.lastLineWidth, 0.3, accuracy: 0.01)
    }

    func testSkeletonText_fullLastLineWidth() {
        let text = SkeletonText(lineCount: 3, lastLineWidth: 1.0)

        XCTAssertEqual(text.lastLineWidth, 1.0, accuracy: 0.01)
    }

    // MARK: - SkeletonLoadingView Tests

    // MARK: Initialization

    func testSkeletonLoadingView_initWithDefaults() {
        let view = SkeletonLoadingView()

        XCTAssertNil(view.title)
    }

    func testSkeletonLoadingView_initWithTitle() {
        let view = SkeletonLoadingView(title: "Loading Videos")

        XCTAssertEqual(view.title, "Loading Videos")
    }

    func testSkeletonLoadingView_initWithVideoCardType() {
        let view = SkeletonLoadingView(cardType: .video)
        XCTAssertEqual(view.cardType, .video)
    }

    func testSkeletonLoadingView_initWithMusicCardType() {
        let view = SkeletonLoadingView(cardType: .music)
        XCTAssertEqual(view.cardType, .music)
    }

    func testSkeletonLoadingView_initWithAllParameters() {
        let view = SkeletonLoadingView(title: "Featured", cardType: .music)

        XCTAssertEqual(view.title, "Featured")
    }

    // MARK: Card Type Enum Tests

    func testSkeletonLoadingViewCardType_video() {
        let cardType: SkeletonLoadingView.CardType = .video
        XCTAssertEqual(cardType, .video)
    }

    func testSkeletonLoadingViewCardType_music() {
        let cardType: SkeletonLoadingView.CardType = .music
        XCTAssertEqual(cardType, .music)
    }

    // MARK: Title Tests

    func testSkeletonLoadingView_nilTitle() {
        let view = SkeletonLoadingView(title: nil)

        XCTAssertNil(view.title)
    }

    func testSkeletonLoadingView_emptyTitle() {
        let view = SkeletonLoadingView(title: "")

        XCTAssertEqual(view.title, "")
    }

    func testSkeletonLoadingView_longTitle() {
        let longTitle = String(repeating: "Loading ", count: 50)
        let view = SkeletonLoadingView(title: longTitle)

        XCTAssertEqual(view.title, longTitle)
    }

    func testSkeletonLoadingView_specialCharactersInTitle() {
        let view = SkeletonLoadingView(title: "Loading: Videos & Music™")

        XCTAssertEqual(view.title, "Loading: Videos & Music™")
    }

    // MARK: - SkeletonGrid CardType Enum Tests

    func testSkeletonGridCardType_video() {
        let cardType: SkeletonGrid.CardType = .video
        XCTAssertEqual(cardType, .video)
    }

    func testSkeletonGridCardType_music() {
        let cardType: SkeletonGrid.CardType = .music
        XCTAssertEqual(cardType, .music)
    }

    // MARK: - SkeletonRow CardType Enum Tests

    func testSkeletonRowCardType_video() {
        let cardType: SkeletonRow.CardType = .video
        XCTAssertEqual(cardType, .video)
    }

    func testSkeletonRowCardType_music() {
        let cardType: SkeletonRow.CardType = .music
        XCTAssertEqual(cardType, .music)
    }

    // MARK: - Edge Cases

    func testSkeletonCard_zeroAspectRatioComponent() {
        // Test with very small but non-zero aspect ratio
        let card = SkeletonCard(aspectRatio: 0.01)

        XCTAssertEqual(card.aspectRatio, 0.01, accuracy: 0.001)
    }

    func testSkeletonGrid_zeroColumns() {
        let grid = SkeletonGrid(cardType: .video, columns: 0, rows: 2)

        XCTAssertEqual(grid.columns, 0)
        XCTAssertEqual(grid.columns * grid.rows, 0)
    }

    func testSkeletonGrid_zeroRows() {
        let grid = SkeletonGrid(cardType: .music, columns: 4, rows: 0)

        XCTAssertEqual(grid.rows, 0)
        XCTAssertEqual(grid.columns * grid.rows, 0)
    }

    func testSkeletonRow_zeroCount() {
        let row = SkeletonRow(cardType: .video, count: 0)

        XCTAssertEqual(row.count, 0)
    }

    func testSkeletonText_zeroLineCount() {
        let text = SkeletonText(lineCount: 0)

        XCTAssertEqual(text.lineCount, 0)
    }

    func testSkeletonText_zeroLineSpacing() {
        let text = SkeletonText(lineCount: 3, lineSpacing: 0)

        XCTAssertEqual(text.lineSpacing, 0)
    }

    func testSkeletonText_zeroLastLineWidth() {
        let text = SkeletonText(lineCount: 3, lastLineWidth: 0)

        XCTAssertEqual(text.lastLineWidth, 0, accuracy: 0.01)
    }
}
