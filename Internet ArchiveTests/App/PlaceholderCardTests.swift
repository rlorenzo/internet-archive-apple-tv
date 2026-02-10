//
//  PlaceholderCardTests.swift
//  Internet ArchiveTests
//
//  Unit tests for PlaceholderCard SwiftUI component
//

import XCTest
import SwiftUI
@testable import Internet_Archive

@MainActor
final class PlaceholderCardTests: XCTestCase {

    // MARK: - Default Initialization Tests

    func testInit_setsAspectRatio() {
        let card = PlaceholderCard(aspectRatio: 16.0 / 9.0)
        XCTAssertEqual(card.aspectRatio, 16.0 / 9.0, accuracy: 0.01)
    }

    func testInit_defaultTitleHeight() {
        let card = PlaceholderCard(aspectRatio: 1)
        XCTAssertEqual(card.titleHeight, 20)
    }

    func testInit_defaultSubtitleHeight() {
        let card = PlaceholderCard(aspectRatio: 1)
        XCTAssertEqual(card.subtitleHeight, 16)
    }

    func testInit_defaultSubtitleWidth() {
        let card = PlaceholderCard(aspectRatio: 1)
        XCTAssertEqual(card.subtitleWidth, 150)
    }

    // MARK: - Custom Initialization Tests

    func testInit_customTitleHeight() {
        let card = PlaceholderCard(aspectRatio: 1, titleHeight: 24)
        XCTAssertEqual(card.titleHeight, 24)
    }

    func testInit_customSubtitleHeight() {
        let card = PlaceholderCard(aspectRatio: 1, subtitleHeight: 12)
        XCTAssertEqual(card.subtitleHeight, 12)
    }

    func testInit_customSubtitleWidth() {
        let card = PlaceholderCard(aspectRatio: 1, subtitleWidth: 200)
        XCTAssertEqual(card.subtitleWidth, 200)
    }

    func testInit_allCustomValues() {
        let card = PlaceholderCard(
            aspectRatio: 4.0 / 3.0,
            titleHeight: 22,
            subtitleHeight: 14,
            subtitleWidth: 180
        )
        XCTAssertEqual(card.aspectRatio, 4.0 / 3.0, accuracy: 0.01)
        XCTAssertEqual(card.titleHeight, 22)
        XCTAssertEqual(card.subtitleHeight, 14)
        XCTAssertEqual(card.subtitleWidth, 180)
    }

    // MARK: - Static Video Card Tests

    func testVideoCard_aspectRatio() {
        let card = PlaceholderCard.video
        XCTAssertEqual(card.aspectRatio, 16.0 / 9.0, accuracy: 0.01)
    }

    func testVideoCard_defaultTitleHeight() {
        let card = PlaceholderCard.video
        XCTAssertEqual(card.titleHeight, 20)
    }

    func testVideoCard_defaultSubtitleHeight() {
        let card = PlaceholderCard.video
        XCTAssertEqual(card.subtitleHeight, 16)
    }

    func testVideoCard_defaultSubtitleWidth() {
        let card = PlaceholderCard.video
        XCTAssertEqual(card.subtitleWidth, 150)
    }

    // MARK: - Static Music Card Tests

    func testMusicCard_aspectRatio() {
        let card = PlaceholderCard.music
        XCTAssertEqual(card.aspectRatio, 1, accuracy: 0.01)
    }

    func testMusicCard_customTitleHeight() {
        let card = PlaceholderCard.music
        XCTAssertEqual(card.titleHeight, 18)
    }

    func testMusicCard_customSubtitleHeight() {
        let card = PlaceholderCard.music
        XCTAssertEqual(card.subtitleHeight, 14)
    }

    func testMusicCard_customSubtitleWidth() {
        let card = PlaceholderCard.music
        XCTAssertEqual(card.subtitleWidth, 120)
    }

    // MARK: - Aspect Ratio Variations Tests

    func testAspectRatio_16by9() {
        let card = PlaceholderCard(aspectRatio: 16.0 / 9.0)
        XCTAssertEqual(card.aspectRatio, 16.0 / 9.0, accuracy: 0.001)
    }

    func testAspectRatio_square() {
        let card = PlaceholderCard(aspectRatio: 1)
        XCTAssertEqual(card.aspectRatio, 1)
    }

    func testAspectRatio_4by3() {
        let card = PlaceholderCard(aspectRatio: 4.0 / 3.0)
        XCTAssertEqual(card.aspectRatio, 4.0 / 3.0, accuracy: 0.001)
    }

    func testAspectRatio_portrait() {
        let card = PlaceholderCard(aspectRatio: 9.0 / 16.0)
        XCTAssertLessThan(card.aspectRatio, 1)
    }

    func testAspectRatio_widescreen() {
        let card = PlaceholderCard(aspectRatio: 21.0 / 9.0)
        XCTAssertGreaterThan(card.aspectRatio, 2)
    }

    // MARK: - View Type Tests

    func testPlaceholderCard_isView() {
        let card = PlaceholderCard(aspectRatio: 1)
        _ = type(of: card.body)
        XCTAssertNotNil(card)
    }

    // MARK: - Value Consistency Tests

    func testVideo_producesConsistentValues() {
        let card1 = PlaceholderCard.video
        let card2 = PlaceholderCard.video

        XCTAssertEqual(card1.aspectRatio, card2.aspectRatio)
        XCTAssertEqual(card1.titleHeight, card2.titleHeight)
        XCTAssertEqual(card1.subtitleHeight, card2.subtitleHeight)
        XCTAssertEqual(card1.subtitleWidth, card2.subtitleWidth)
    }

    func testMusic_producesConsistentValues() {
        let card1 = PlaceholderCard.music
        let card2 = PlaceholderCard.music

        XCTAssertEqual(card1.aspectRatio, card2.aspectRatio)
        XCTAssertEqual(card1.titleHeight, card2.titleHeight)
        XCTAssertEqual(card1.subtitleHeight, card2.subtitleHeight)
        XCTAssertEqual(card1.subtitleWidth, card2.subtitleWidth)
    }

    // MARK: - Different Card Types Tests

    func testVideoAndMusic_haveDifferentAspectRatios() {
        let video = PlaceholderCard.video
        let music = PlaceholderCard.music

        XCTAssertNotEqual(video.aspectRatio, music.aspectRatio)
    }

    func testVideoAndMusic_haveDifferentSubtitleWidths() {
        let video = PlaceholderCard.video
        let music = PlaceholderCard.music

        XCTAssertNotEqual(video.subtitleWidth, music.subtitleWidth)
    }

    // MARK: - Practical Size Tests

    func testTitleHeight_isReasonable() {
        let card = PlaceholderCard(aspectRatio: 1)
        XCTAssertGreaterThan(card.titleHeight, 10)
        XCTAssertLessThan(card.titleHeight, 50)
    }

    func testSubtitleHeight_isSmallerThanTitle() {
        let card = PlaceholderCard(aspectRatio: 1)
        XCTAssertLessThan(card.subtitleHeight, card.titleHeight)
    }

    func testSubtitleWidth_isReasonable() {
        let card = PlaceholderCard(aspectRatio: 1)
        XCTAssertGreaterThan(card.subtitleWidth, 50)
        XCTAssertLessThan(card.subtitleWidth, 300)
    }
}
