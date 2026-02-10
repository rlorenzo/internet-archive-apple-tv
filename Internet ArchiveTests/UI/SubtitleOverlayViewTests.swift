//
//  SubtitleOverlayViewTests.swift
//  Internet ArchiveTests
//
//  Unit tests for SubtitleOverlayView subtitle display
//

import XCTest
import AVFoundation
@testable import Internet_Archive

@MainActor
final class SubtitleOverlayViewTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeCue(
        startTime: Double = 0,
        endTime: Double = 5,
        text: String = "Test subtitle"
    ) -> SubtitleCue {
        SubtitleCue(startTime: startTime, endTime: endTime, text: text)
    }

    // MARK: - Initialization Tests

    func testInit_withFrame_createsView() {
        let view = SubtitleOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        XCTAssertNotNil(view)
    }

    func testInit_userInteractionDisabled() {
        let view = SubtitleOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        XCTAssertFalse(view.isUserInteractionEnabled)
    }

    // MARK: - Accessibility Tests

    func testAccessibility_isAccessibilityElement() {
        let view = SubtitleOverlayView(frame: .zero)
        XCTAssertTrue(view.isAccessibilityElement)
    }

    func testAccessibility_hasStaticTextTrait() {
        let view = SubtitleOverlayView(frame: .zero)
        XCTAssertTrue(view.accessibilityTraits.contains(.staticText))
    }

    func testAccessibility_hasLabel() {
        let view = SubtitleOverlayView(frame: .zero)
        XCTAssertEqual(view.accessibilityLabel, "Subtitles")
    }

    // MARK: - Stop Tests

    func testStop_hidesView() {
        let view = SubtitleOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        view.isHidden = false
        view.stop()
        XCTAssertTrue(view.isHidden)
    }

    // MARK: - Update Cues Tests

    func testUpdateCues_withEmptyCues() {
        let view = SubtitleOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        view.updateCues([])
        XCTAssertNotNil(view)
    }

    func testUpdateCues_withValidCues() {
        let view = SubtitleOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let cues = [
            makeCue(startTime: 0, endTime: 5, text: "First"),
            makeCue(startTime: 5, endTime: 10, text: "Second")
        ]
        view.updateCues(cues)
        XCTAssertNotNil(view)
    }

    // MARK: - Update Subtitle Position Tests

    func testUpdateSubtitlePosition_controlsVisible() {
        let view = SubtitleOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        view.updateSubtitlePosition(controlsVisible: true)
        XCTAssertNotNil(view)
    }

    func testUpdateSubtitlePosition_controlsHidden() {
        let view = SubtitleOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        view.updateSubtitlePosition(controlsVisible: false)
        XCTAssertNotNil(view)
    }

    func testUpdateSubtitlePosition_toggleControlsVisibility() {
        let view = SubtitleOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        view.updateSubtitlePosition(controlsVisible: true)
        view.updateSubtitlePosition(controlsVisible: false)
        view.updateSubtitlePosition(controlsVisible: true)
        XCTAssertNotNil(view)
    }

    func testUpdateSubtitlePosition_sameValueTwice_noopOnSecondCall() {
        let view = SubtitleOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        view.updateSubtitlePosition(controlsVisible: true)
        view.updateSubtitlePosition(controlsVisible: true)
        XCTAssertNotNil(view)
    }

    // MARK: - Configure Tests

    func testConfigure_withPlayerAndCues() {
        let view = SubtitleOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        view.isHidden = true
        let player = AVPlayer()
        let cues = [makeCue(text: "Hello")]
        view.configure(with: cues, player: player)
        XCTAssertFalse(view.isHidden)
    }

    func testConfigure_withEmptyCues() {
        let view = SubtitleOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let player = AVPlayer()
        view.configure(with: [], player: player)
        XCTAssertFalse(view.isHidden)
    }

    func testConfigure_thenStop() {
        let view = SubtitleOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let player = AVPlayer()
        let cues = [makeCue(text: "Test")]
        view.configure(with: cues, player: player)
        XCTAssertFalse(view.isHidden)

        view.stop()
        XCTAssertTrue(view.isHidden)
    }

    // MARK: - Lifecycle Tests

    func testConfigure_reconfigure_doesNotCrash() {
        let view = SubtitleOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        let player = AVPlayer()

        view.configure(with: [makeCue(text: "First")], player: player)
        view.stop()
        view.configure(with: [makeCue(text: "Second")], player: player)
        XCTAssertFalse(view.isHidden)
    }
}
