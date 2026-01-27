//
//  MediaThumbnailViewTests.swift
//  Internet ArchiveTests
//
//  Unit tests for MediaThumbnailView SwiftUI component
//

import XCTest
import SwiftUI
@testable import Internet_Archive

@MainActor
final class MediaThumbnailViewTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_setsIdentifier() {
        let view = MediaThumbnailView(
            identifier: "test-item",
            mediaType: .video,
            size: CGSize(width: 380, height: 214)
        )
        XCTAssertEqual(view.identifier, "test-item")
    }

    func testInit_setsMediaType() {
        let view = MediaThumbnailView(
            identifier: "test-item",
            mediaType: .music,
            size: CGSize(width: 220, height: 220)
        )
        XCTAssertEqual(view.mediaType, .music)
    }

    func testInit_setsSize() {
        let size = CGSize(width: 400, height: 300)
        let view = MediaThumbnailView(
            identifier: "test-item",
            mediaType: .video,
            size: size
        )
        XCTAssertEqual(view.size.width, 400)
        XCTAssertEqual(view.size.height, 300)
    }

    func testInit_defaultCornerRadius() {
        let view = MediaThumbnailView(
            identifier: "test-item",
            mediaType: .video,
            size: CGSize(width: 380, height: 214)
        )
        XCTAssertEqual(view.cornerRadius, 12)
    }

    func testInit_customCornerRadius() {
        var view = MediaThumbnailView(
            identifier: "test-item",
            mediaType: .video,
            size: CGSize(width: 380, height: 214)
        )
        view.cornerRadius = 20
        XCTAssertEqual(view.cornerRadius, 20)
    }

    // MARK: - MediaType Tests

    func testMediaType_video() {
        let view = MediaThumbnailView(
            identifier: "test",
            mediaType: .video,
            size: CGSize(width: 100, height: 100)
        )
        XCTAssertEqual(view.mediaType, .video)
    }

    func testMediaType_music() {
        let view = MediaThumbnailView(
            identifier: "test",
            mediaType: .music,
            size: CGSize(width: 100, height: 100)
        )
        XCTAssertEqual(view.mediaType, .music)
    }

    // MARK: - Size Tests

    func testSize_videoAspectRatio() {
        let view = MediaThumbnailView(
            identifier: "test",
            mediaType: .video,
            size: CGSize(width: 380, height: 214)
        )
        let aspectRatio = view.size.width / view.size.height
        XCTAssertEqual(aspectRatio, 380.0 / 214.0, accuracy: 0.01)
    }

    func testSize_squareForMusic() {
        let view = MediaThumbnailView(
            identifier: "test",
            mediaType: .music,
            size: CGSize(width: 220, height: 220)
        )
        XCTAssertEqual(view.size.width, view.size.height)
    }

    // MARK: - View Type Tests

    func testMediaThumbnailView_isView() {
        let view = MediaThumbnailView(
            identifier: "test",
            mediaType: .video,
            size: CGSize(width: 100, height: 100)
        )
        _ = type(of: view.body)
        XCTAssertNotNil(view)
    }

    // MARK: - Identifier Variations Tests

    func testIdentifier_emptyString() {
        let view = MediaThumbnailView(
            identifier: "",
            mediaType: .video,
            size: CGSize(width: 100, height: 100)
        )
        XCTAssertEqual(view.identifier, "")
    }

    func testIdentifier_longString() {
        let longId = "this-is-a-very-long-identifier-for-testing-purposes"
        let view = MediaThumbnailView(
            identifier: longId,
            mediaType: .video,
            size: CGSize(width: 100, height: 100)
        )
        XCTAssertEqual(view.identifier, longId)
    }

    func testIdentifier_specialCharacters() {
        let specialId = "item_with-special.chars"
        let view = MediaThumbnailView(
            identifier: specialId,
            mediaType: .video,
            size: CGSize(width: 100, height: 100)
        )
        XCTAssertEqual(view.identifier, specialId)
    }

    // MARK: - Corner Radius Tests

    func testCornerRadius_zero() {
        var view = MediaThumbnailView(
            identifier: "test",
            mediaType: .video,
            size: CGSize(width: 100, height: 100)
        )
        view.cornerRadius = 0
        XCTAssertEqual(view.cornerRadius, 0)
    }

    func testCornerRadius_large() {
        var view = MediaThumbnailView(
            identifier: "test",
            mediaType: .video,
            size: CGSize(width: 100, height: 100)
        )
        view.cornerRadius = 50
        XCTAssertEqual(view.cornerRadius, 50)
    }

    // MARK: - Consistent Creation Tests

    func testMultipleInstances_areIndependent() {
        let view1 = MediaThumbnailView(
            identifier: "item1",
            mediaType: .video,
            size: CGSize(width: 100, height: 100)
        )
        let view2 = MediaThumbnailView(
            identifier: "item2",
            mediaType: .music,
            size: CGSize(width: 200, height: 200)
        )

        XCTAssertNotEqual(view1.identifier, view2.identifier)
        XCTAssertNotEqual(view1.mediaType, view2.mediaType)
        XCTAssertNotEqual(view1.size.width, view2.size.width)
    }
}
