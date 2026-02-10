//
//  ContinueWatchingCellTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ContinueWatchingCell collection view cell
//

import XCTest
@testable import Internet_Archive

@MainActor
final class ContinueWatchingCellTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeProgress(
        itemIdentifier: String = "test-item",
        filename: String = "video.mp4",
        title: String? = "Test Video",
        mediaType: String = "movies",
        currentTime: Double = 120,
        duration: Double = 600,
        lastWatchedDate: Date = Date()
    ) -> PlaybackProgress {
        PlaybackProgress(
            itemIdentifier: itemIdentifier,
            filename: filename,
            currentTime: currentTime,
            duration: duration,
            lastWatchedDate: lastWatchedDate,
            title: title,
            mediaType: mediaType,
            imageURL: nil
        )
    }

    // MARK: - Initialization Tests

    func testInit_createsCell() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        XCTAssertNotNil(cell)
    }

    func testReuseIdentifier() {
        XCTAssertEqual(ContinueWatchingCell.reuseIdentifier, "ContinueWatchingCell")
    }

    func testCanBecomeFocused() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        XCTAssertTrue(cell.canBecomeFocused)
    }

    // MARK: - Accessibility Tests

    func testAccessibility_isAccessibilityElement() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        XCTAssertTrue(cell.isAccessibilityElement)
    }

    func testAccessibility_hasButtonTrait() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        XCTAssertTrue(cell.accessibilityTraits.contains(.button))
    }

    // MARK: - Configure Tests

    func testConfigure_withVideoProgress_setsAccessibilityLabel() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        let progress = makeProgress(title: "My Video", mediaType: "movies")
        cell.configure(with: progress)
        XCTAssertEqual(cell.accessibilityLabel, "My Video")
    }

    func testConfigure_withAudioProgress_setsAccessibilityLabel() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        let progress = makeProgress(title: "My Song", mediaType: "etree")
        cell.configure(with: progress)
        XCTAssertEqual(cell.accessibilityLabel, "My Song")
    }

    func testConfigure_withNilTitle_showsUntitled() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        let progress = makeProgress(title: nil)
        cell.configure(with: progress)
        // Title label should show "Untitled" but accessibility label uses the title which is nil
        XCTAssertNil(cell.accessibilityLabel)
    }

    func testConfigure_setsAccessibilityValue() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        let progress = makeProgress(currentTime: 300, duration: 600)
        cell.configure(with: progress)
        XCTAssertNotNil(cell.accessibilityValue)
    }

    func testConfigure_setsAccessibilityHint() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        let progress = makeProgress()
        cell.configure(with: progress)
        XCTAssertEqual(cell.accessibilityHint, "Double-tap to resume")
    }

    // MARK: - Prepare For Reuse Tests

    func testPrepareForReuse_resetsState() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        let progress = makeProgress(title: "Test")
        cell.configure(with: progress)
        cell.prepareForReuse()

        XCTAssertNil(cell.accessibilityLabel)
        XCTAssertNil(cell.accessibilityValue)
    }

    // MARK: - Layout Tests

    func testLayoutSubviews_doesNotCrash() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        cell.layoutSubviews()
        XCTAssertNotNil(cell)
    }

    // MARK: - Edge Cases

    func testConfigure_withZeroProgress() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        let progress = makeProgress(currentTime: 0, duration: 600)
        cell.configure(with: progress)
        XCTAssertNotNil(cell)
    }

    func testConfigure_withNearCompleteProgress() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        let progress = makeProgress(currentTime: 570, duration: 600)
        cell.configure(with: progress)
        XCTAssertNotNil(cell)
    }

    func testConfigure_withNoThumbnail() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        let progress = makeProgress(itemIdentifier: "")
        cell.configure(with: progress)
        XCTAssertNotNil(cell)
    }

    func testConfigure_multipleConfigurations() {
        let cell = ContinueWatchingCell(frame: CGRect(x: 0, y: 0, width: 400, height: 320))
        let progress1 = makeProgress(title: "First Video")
        let progress2 = makeProgress(title: "Second Video")

        cell.configure(with: progress1)
        XCTAssertEqual(cell.accessibilityLabel, "First Video")

        cell.configure(with: progress2)
        XCTAssertEqual(cell.accessibilityLabel, "Second Video")
    }
}
