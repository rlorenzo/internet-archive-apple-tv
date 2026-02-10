//
//  NowPlayingControlsViewTests.swift
//  Internet ArchiveTests
//
//  Unit tests for NowPlayingControlsView music transport controls
//

import XCTest
@testable import Internet_Archive

// MARK: - Mock Controls Delegate

@MainActor
final class MockNowPlayingControlsDelegate: NowPlayingControlsDelegate {
    var didTapPlayPauseCalled = false
    var didTapNextCalled = false
    var didTapPreviousCalled = false
    var didTapShuffleCalled = false
    var didTapRepeatCalled = false

    func controlsDidTapPlayPause() { didTapPlayPauseCalled = true }
    func controlsDidTapNext() { didTapNextCalled = true }
    func controlsDidTapPrevious() { didTapPreviousCalled = true }
    func controlsDidTapShuffle() { didTapShuffleCalled = true }
    func controlsDidTapRepeat() { didTapRepeatCalled = true }
}

// MARK: - NowPlayingControlsView Tests

@MainActor
final class NowPlayingControlsViewTests: XCTestCase {

    private var controlsView: NowPlayingControlsView!

    override func setUp() async throws {
        try await super.setUp()
        controlsView = NowPlayingControlsView(frame: CGRect(x: 0, y: 0, width: 600, height: 80))
    }

    override func tearDown() async throws {
        controlsView = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInit_createsView() {
        XCTAssertNotNil(controlsView)
    }

    func testInit_defaultIsPlayingFalse() {
        XCTAssertFalse(controlsView.isPlaying)
    }

    func testInit_defaultIsShuffledFalse() {
        XCTAssertFalse(controlsView.isShuffled)
    }

    func testInit_defaultRepeatModeOff() {
        XCTAssertEqual(controlsView.repeatMode, .off)
    }

    func testInit_delegateNilByDefault() {
        XCTAssertNil(controlsView.delegate)
    }

    // MARK: - Focus Tests

    func testFocusableButtons_containsFiveButtons() {
        XCTAssertEqual(controlsView.focusableButtons.count, 5)
    }

    func testDefaultFocusedButton_isNotNil() {
        XCTAssertNotNil(controlsView.defaultFocusedButton)
    }

    func testDefaultFocusedButton_isInFocusableButtons() {
        XCTAssertTrue(controlsView.focusableButtons.contains(controlsView.defaultFocusedButton))
    }

    // MARK: - State Update Tests

    func testSetPlaying_true_updatesState() {
        controlsView.setPlaying(true)
        XCTAssertTrue(controlsView.isPlaying)
    }

    func testSetPlaying_false_updatesState() {
        controlsView.setPlaying(true)
        controlsView.setPlaying(false)
        XCTAssertFalse(controlsView.isPlaying)
    }

    func testSetPlaying_true_updatesAccessibilityLabel() {
        controlsView.setPlaying(true)
        let playPauseButton = controlsView.defaultFocusedButton
        XCTAssertEqual(playPauseButton.accessibilityLabel, "Pause")
    }

    func testSetPlaying_false_updatesAccessibilityLabel() {
        controlsView.setPlaying(false)
        let playPauseButton = controlsView.defaultFocusedButton
        XCTAssertEqual(playPauseButton.accessibilityLabel, "Play")
    }

    func testSetShuffled_true_updatesState() {
        controlsView.setShuffled(true)
        XCTAssertTrue(controlsView.isShuffled)
    }

    func testSetShuffled_false_updatesState() {
        controlsView.setShuffled(true)
        controlsView.setShuffled(false)
        XCTAssertFalse(controlsView.isShuffled)
    }

    func testSetShuffled_true_updatesAccessibilityValue() {
        controlsView.setShuffled(true)
        let shuffleButton = controlsView.focusableButtons[0]
        XCTAssertEqual(shuffleButton.accessibilityValue, "On")
    }

    func testSetShuffled_false_updatesAccessibilityValue() {
        controlsView.setShuffled(false)
        let shuffleButton = controlsView.focusableButtons[0]
        XCTAssertEqual(shuffleButton.accessibilityValue, "Off")
    }

    func testSetRepeatMode_off() {
        controlsView.setRepeatMode(.off)
        XCTAssertEqual(controlsView.repeatMode, .off)
    }

    func testSetRepeatMode_all() {
        controlsView.setRepeatMode(.all)
        XCTAssertEqual(controlsView.repeatMode, .all)
    }

    func testSetRepeatMode_one() {
        controlsView.setRepeatMode(.one)
        XCTAssertEqual(controlsView.repeatMode, .one)
    }

    func testSetRepeatMode_updatesAccessibilityValue() {
        controlsView.setRepeatMode(.all)
        let repeatButton = controlsView.focusableButtons[4]
        XCTAssertEqual(repeatButton.accessibilityValue, AudioQueueManager.RepeatMode.all.accessibilityLabel)
    }

    func testSetHasNext_true_enablesButton() {
        controlsView.setHasNext(true)
        let nextButton = controlsView.focusableButtons[3]
        XCTAssertTrue(nextButton.isEnabled)
        XCTAssertEqual(nextButton.alpha, 1.0)
    }

    func testSetHasNext_false_disablesButton() {
        controlsView.setHasNext(false)
        let nextButton = controlsView.focusableButtons[3]
        XCTAssertFalse(nextButton.isEnabled)
        XCTAssertEqual(nextButton.alpha, 0.4, accuracy: 0.01)
    }

    func testSetHasPrevious_true_enablesButton() {
        controlsView.setHasPrevious(true)
        let previousButton = controlsView.focusableButtons[1]
        XCTAssertTrue(previousButton.isEnabled)
        XCTAssertEqual(previousButton.alpha, 1.0)
    }

    func testSetHasPrevious_false_disablesButton() {
        controlsView.setHasPrevious(false)
        let previousButton = controlsView.focusableButtons[1]
        XCTAssertFalse(previousButton.isEnabled)
        XCTAssertEqual(previousButton.alpha, 0.4, accuracy: 0.01)
    }

    // MARK: - Delegate Callback Tests

    func testPlayPauseButton_callsDelegate() {
        let mockDelegate = MockNowPlayingControlsDelegate()
        controlsView.delegate = mockDelegate
        let playPauseButton = controlsView.defaultFocusedButton
        playPauseButton.sendActions(for: .primaryActionTriggered)
        XCTAssertTrue(mockDelegate.didTapPlayPauseCalled)
    }

    func testNextButton_callsDelegate() {
        let mockDelegate = MockNowPlayingControlsDelegate()
        controlsView.delegate = mockDelegate
        let nextButton = controlsView.focusableButtons[3]
        nextButton.sendActions(for: .primaryActionTriggered)
        XCTAssertTrue(mockDelegate.didTapNextCalled)
    }

    func testPreviousButton_callsDelegate() {
        let mockDelegate = MockNowPlayingControlsDelegate()
        controlsView.delegate = mockDelegate
        let previousButton = controlsView.focusableButtons[1]
        previousButton.sendActions(for: .primaryActionTriggered)
        XCTAssertTrue(mockDelegate.didTapPreviousCalled)
    }

    func testShuffleButton_callsDelegate() {
        let mockDelegate = MockNowPlayingControlsDelegate()
        controlsView.delegate = mockDelegate
        let shuffleButton = controlsView.focusableButtons[0]
        shuffleButton.sendActions(for: .primaryActionTriggered)
        XCTAssertTrue(mockDelegate.didTapShuffleCalled)
    }

    func testRepeatButton_callsDelegate() {
        let mockDelegate = MockNowPlayingControlsDelegate()
        controlsView.delegate = mockDelegate
        let repeatButton = controlsView.focusableButtons[4]
        repeatButton.sendActions(for: .primaryActionTriggered)
        XCTAssertTrue(mockDelegate.didTapRepeatCalled)
    }

    // MARK: - Accessibility Tests

    func testAccessibility_playPauseHasHint() {
        let playPauseButton = controlsView.defaultFocusedButton
        XCTAssertEqual(playPauseButton.accessibilityHint, "Double-tap to play or pause")
    }

    func testAccessibility_previousHasLabel() {
        let previousButton = controlsView.focusableButtons[1]
        XCTAssertEqual(previousButton.accessibilityLabel, "Previous track")
    }

    func testAccessibility_nextHasLabel() {
        let nextButton = controlsView.focusableButtons[3]
        XCTAssertEqual(nextButton.accessibilityLabel, "Next track")
    }

    func testAccessibility_shuffleHasLabel() {
        let shuffleButton = controlsView.focusableButtons[0]
        XCTAssertEqual(shuffleButton.accessibilityLabel, "Shuffle")
    }

    func testAccessibility_repeatHasLabel() {
        let repeatButton = controlsView.focusableButtons[4]
        XCTAssertEqual(repeatButton.accessibilityLabel, "Repeat")
    }

    // MARK: - Tint Color Tests

    func testSetShuffled_true_changesTintColor() {
        controlsView.setShuffled(true)
        let shuffleButton = controlsView.focusableButtons[0]
        XCTAssertEqual(shuffleButton.tintColor, .systemBlue)
    }

    func testSetShuffled_false_resetsTintColor() {
        controlsView.setShuffled(false)
        let shuffleButton = controlsView.focusableButtons[0]
        XCTAssertEqual(shuffleButton.tintColor, .white)
    }

    func testSetRepeatMode_active_changesTintColor() {
        controlsView.setRepeatMode(.all)
        let repeatButton = controlsView.focusableButtons[4]
        XCTAssertEqual(repeatButton.tintColor, .systemBlue)
    }

    func testSetRepeatMode_off_resetsTintColor() {
        controlsView.setRepeatMode(.off)
        let repeatButton = controlsView.focusableButtons[4]
        XCTAssertEqual(repeatButton.tintColor, .white)
    }
}
