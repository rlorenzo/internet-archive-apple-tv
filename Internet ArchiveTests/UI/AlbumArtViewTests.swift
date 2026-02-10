//
//  AlbumArtViewTests.swift
//  Internet ArchiveTests
//
//  Unit tests for AlbumArtView album artwork display
//

import XCTest
@testable import Internet_Archive

@MainActor
final class AlbumArtViewTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_withSize_createsView() {
        let view = AlbumArtView(size: 300)
        XCTAssertNotNil(view)
    }

    func testInit_withDefaultSize_createsView() {
        let view = AlbumArtView()
        XCTAssertNotNil(view)
    }

    func testInit_withFrame_createsView() {
        let view = AlbumArtView(frame: CGRect(x: 0, y: 0, width: 400, height: 500))
        XCTAssertNotNil(view)
    }

    // MARK: - Accessibility Tests

    func testAccessibility_isAccessibilityElement() {
        let view = AlbumArtView(size: 300)
        XCTAssertTrue(view.isAccessibilityElement)
    }

    func testAccessibility_hasImageTrait() {
        let view = AlbumArtView(size: 300)
        XCTAssertTrue(view.accessibilityTraits.contains(.image))
    }

    func testAccessibility_defaultLabel() {
        let view = AlbumArtView(size: 300)
        XCTAssertEqual(view.accessibilityLabel, "Album artwork")
    }

    // MARK: - Set Image Tests

    func testSetImage_withUIImage_updatesAccessibilityLabel() {
        let view = AlbumArtView(size: 300)
        let image = UIImage(systemName: "music.note")
        view.setImage(image)
        XCTAssertEqual(view.accessibilityLabel, "Album artwork")
    }

    func testSetImage_withNil_showsPlaceholder() {
        let view = AlbumArtView(size: 300)
        view.setImage(nil as UIImage?)
        XCTAssertEqual(view.accessibilityLabel, "Album artwork placeholder")
    }

    func testSetImage_withNilURL_showsPlaceholder() {
        let view = AlbumArtView(size: 300)
        view.setImage(url: nil)
        XCTAssertEqual(view.accessibilityLabel, "Album artwork placeholder")
    }

    // MARK: - Layout Tests

    func testLayoutSubviews_doesNotCrash() {
        let view = AlbumArtView(size: 300)
        view.frame = CGRect(x: 0, y: 0, width: 300, height: 400)
        view.layoutSubviews()
        XCTAssertNotNil(view)
    }

    // MARK: - Animation Tests

    func testAnimatePulse_doesNotCrash() {
        let view = AlbumArtView(size: 300)
        view.animatePulse()
        XCTAssertNotNil(view)
    }

    // MARK: - Image State Tests

    func testSetImage_withImage_thenNil_showsPlaceholder() {
        let view = AlbumArtView(size: 300)
        let image = UIImage(systemName: "music.note")!
        view.setImage(image)
        XCTAssertEqual(view.accessibilityLabel, "Album artwork")

        view.setImage(nil as UIImage?)
        XCTAssertEqual(view.accessibilityLabel, "Album artwork placeholder")
    }

    func testSetImage_multipleImages() {
        let view = AlbumArtView(size: 300)
        let image1 = UIImage(systemName: "music.note")
        let image2 = UIImage(systemName: "music.note.list")
        view.setImage(image1)
        view.setImage(image2)
        XCTAssertEqual(view.accessibilityLabel, "Album artwork")
    }
}
