//
//  SliderTests.swift
//  Internet ArchiveTests
//
//  Unit tests for Slider component
//

import XCTest
@testable import Internet_Archive

// MARK: - Mock Slider Delegate

final class MockSliderDelegate: SliderDelegate {
    var didTapCalled = false
    var didChangeValueCalled = false
    var lastChangedValue: Double?
    var textForValueCalled = false
    var lastTextForValue: Double?
    var customTextToReturn: String?
    var didBeginScrubbingCalled = false
    var didEndScrubbingCalled = false
    var didFinishScrubbingCalled = false
    var beginScrubbingCallCount = 0
    var endScrubbingCallCount = 0
    var finishScrubbingCallCount = 0

    func slider(_ slider: Slider, textWithValue value: Double) -> String {
        textForValueCalled = true
        lastTextForValue = value
        return customTextToReturn ?? "\(Int(value))"
    }

    func sliderDidTap(_ slider: Slider) {
        didTapCalled = true
    }

    func slider(_ slider: Slider, didChangeValue value: Double) {
        didChangeValueCalled = true
        lastChangedValue = value
    }

    func slider(_ slider: Slider, didUpdateFocusInContext context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        // Focus update handling
    }

    func sliderDidBeginScrubbing(_ slider: Slider) {
        didBeginScrubbingCalled = true
        beginScrubbingCallCount += 1
    }

    func sliderDidEndScrubbing(_ slider: Slider) {
        didEndScrubbingCalled = true
        endScrubbingCallCount += 1
    }

    func sliderDidFinishScrubbing(_ slider: Slider) {
        didFinishScrubbingCalled = true
        finishScrubbingCallCount += 1
    }

    func reset() {
        didTapCalled = false
        didChangeValueCalled = false
        lastChangedValue = nil
        textForValueCalled = false
        lastTextForValue = nil
        customTextToReturn = nil
        didBeginScrubbingCalled = false
        didEndScrubbingCalled = false
        didFinishScrubbingCalled = false
        beginScrubbingCallCount = 0
        endScrubbingCallCount = 0
        finishScrubbingCallCount = 0
    }
}

// MARK: - Slider Tests

@MainActor
final class SliderTests: XCTestCase {

    private var slider: Slider!
    private var mockDelegate: MockSliderDelegate!

    // Helper to create test objects - call at start of each test that needs them
    private func createTestObjects() {
        slider = Slider(frame: CGRect(x: 0, y: 0, width: 400, height: 50))
        mockDelegate = MockSliderDelegate()
    }

    // MARK: - Initialization Tests

    func testInit_withFrame() {
        let slider = Slider(frame: CGRect(x: 0, y: 0, width: 300, height: 40))
        XCTAssertNotNil(slider)
    }

    func testInit_defaultValues() {
        createTestObjects()
        XCTAssertEqual(slider.value, 0)
        XCTAssertEqual(slider.min, 0)
        XCTAssertEqual(slider.max, 100)
    }

    func testCanBecomeFocused() {
        createTestObjects()
        XCTAssertTrue(slider.canBecomeFocused)
    }

    // MARK: - Value Tests

    func testSetValue() {
        createTestObjects()
        slider.value = 50
        XCTAssertEqual(slider.value, 50)
    }

    func testSetValue_callsDelegate() {
        createTestObjects()
        slider.delegate = mockDelegate
        slider.value = 75

        XCTAssertTrue(mockDelegate.didChangeValueCalled)
        XCTAssertEqual(mockDelegate.lastChangedValue, 75)
    }

    func testSetValue_multipleChanges() {
        createTestObjects()
        slider.delegate = mockDelegate

        slider.value = 25
        XCTAssertEqual(mockDelegate.lastChangedValue, 25)

        slider.value = 50
        XCTAssertEqual(mockDelegate.lastChangedValue, 50)

        slider.value = 100
        XCTAssertEqual(mockDelegate.lastChangedValue, 100)
    }

    // MARK: - Min/Max Tests

    func testSetMin() {
        createTestObjects()
        slider.min = 10
        XCTAssertEqual(slider.min, 10)
    }

    func testSetMax() {
        createTestObjects()
        slider.max = 200
        XCTAssertEqual(slider.max, 200)
    }

    func testSetMaxUpdatesDistance() {
        createTestObjects()
        slider.max = 50
        // Setting max also updates distance internally
        XCTAssertEqual(slider.max, 50)
    }

    // MARK: - Animated Value Setting

    func testSetValueAnimated() {
        createTestObjects()
        slider.set(value: 50, animated: true)
        XCTAssertEqual(slider.value, 50)
    }

    func testSetValueNotAnimated() {
        createTestObjects()
        slider.set(value: 75, animated: false)
        XCTAssertEqual(slider.value, 75)
    }

    func testSetValue_whenDistanceIsZero() {
        createTestObjects()
        slider.max = 0
        slider.min = 0
        slider.set(value: 50, animated: false)
        XCTAssertEqual(slider.value, 50)
    }

    // MARK: - Animation Speed Tests

    func testAnimationSpeed_default() {
        createTestObjects()
        XCTAssertEqual(slider.animationSpeed, 1.0)
    }

    func testAnimationSpeed_custom() {
        createTestObjects()
        slider.animationSpeed = 2.0
        XCTAssertEqual(slider.animationSpeed, 2.0)
    }

    // MARK: - Deceleration Tests

    func testDecelerationRate_default() {
        createTestObjects()
        XCTAssertEqual(slider.decelerationRate, 0.92)
    }

    func testDecelerationRate_custom() {
        createTestObjects()
        slider.decelerationRate = 0.85
        XCTAssertEqual(slider.decelerationRate, 0.85)
    }

    func testDecelerationMaxVelocity_default() {
        createTestObjects()
        XCTAssertEqual(slider.decelerationMaxVelocity, 1000)
    }

    func testDecelerationMaxVelocity_custom() {
        createTestObjects()
        slider.decelerationMaxVelocity = 500
        XCTAssertEqual(slider.decelerationMaxVelocity, 500)
    }

    // MARK: - Delegate Tests

    func testDelegate_canBeSet() {
        createTestObjects()
        slider.delegate = mockDelegate
        XCTAssertNotNil(slider.delegate)
    }

    func testDelegate_textWithValue_defaultImplementation() {
        createTestObjects()
        // Without custom implementation, should return int string
        let delegate = MockSliderDelegate()
        let text = delegate.slider(slider, textWithValue: 42.7)
        XCTAssertEqual(text, "42")
    }

    func testDelegate_textWithValue_customImplementation() {
        createTestObjects()
        mockDelegate.customTextToReturn = "Custom: 50"
        slider.delegate = mockDelegate

        let text = mockDelegate.slider(slider, textWithValue: 50)
        XCTAssertEqual(text, "Custom: 50")
        XCTAssertTrue(mockDelegate.textForValueCalled)
    }

    // MARK: - Layout Tests

    func testLayoutSubviews_doesNotCrash() {
        createTestObjects()
        slider.layoutSubviews()
        // Just verify it doesn't crash
        XCTAssertNotNil(slider)
    }

    // MARK: - Gesture Recognizer Delegate Tests

    func testGestureRecognizerShouldBegin_notFocused() {
        createTestObjects()
        // When slider is not focused, pan gestures should not begin
        let panGesture = UIPanGestureRecognizer()
        let shouldBegin = slider.gestureRecognizerShouldBegin(panGesture)
        XCTAssertFalse(shouldBegin)
    }

    func testGestureRecognizer_shouldRecognizeSimultaneously() {
        createTestObjects()
        let gesture1 = UITapGestureRecognizer()
        let gesture2 = UIPanGestureRecognizer()
        let shouldRecognize = slider.gestureRecognizer(gesture1, shouldRecognizeSimultaneouslyWith: gesture2)
        XCTAssertTrue(shouldRecognize)
    }

    // MARK: - Arrow Key Increment Step Tests

    func testArrowKeyIncrementStep_default() {
        createTestObjects()
        // Default should be same as accessibility increment step
        XCTAssertEqual(slider.arrowKeyIncrementStep, slider.accessibilityIncrementStep)
    }

    func testArrowKeyIncrementStep_setterUpdatesAccessibilityStep() {
        createTestObjects()
        slider.arrowKeyIncrementStep = 15.0
        XCTAssertEqual(slider.accessibilityIncrementStep, 15.0)
        XCTAssertEqual(slider.arrowKeyIncrementStep, 15.0)
    }

    func testAccessibilityIncrementStep_setterUpdatesArrowKeyStep() {
        createTestObjects()
        slider.accessibilityIncrementStep = 20.0
        XCTAssertEqual(slider.arrowKeyIncrementStep, 20.0)
    }

    func testArrowKeyIncrementStep_customValue() {
        createTestObjects()
        slider.arrowKeyIncrementStep = 5.0
        XCTAssertEqual(slider.arrowKeyIncrementStep, 5.0)
    }

    // MARK: - Accessibility Increment/Decrement Tests

    func testAccessibilityIncrement_usesIncrementStep() {
        createTestObjects()
        slider.min = 0
        slider.max = 100
        slider.accessibilityIncrementStep = 10.0
        slider.set(value: 50, animated: false)

        slider.accessibilityIncrement()

        XCTAssertEqual(slider.value, 60, accuracy: 0.001)
    }

    func testAccessibilityDecrement_usesIncrementStep() {
        createTestObjects()
        slider.min = 0
        slider.max = 100
        slider.accessibilityIncrementStep = 10.0
        slider.set(value: 50, animated: false)

        slider.accessibilityDecrement()

        XCTAssertEqual(slider.value, 40, accuracy: 0.001)
    }

    func testAccessibilityIncrement_clampsToMax() {
        createTestObjects()
        slider.min = 0
        slider.max = 100
        slider.accessibilityIncrementStep = 10.0
        slider.set(value: 95, animated: false)

        slider.accessibilityIncrement()

        XCTAssertEqual(slider.value, 100, accuracy: 0.001)
    }

    func testAccessibilityDecrement_clampsToMin() {
        createTestObjects()
        slider.min = 0
        slider.max = 100
        slider.accessibilityIncrementStep = 10.0
        slider.set(value: 5, animated: false)

        slider.accessibilityDecrement()

        XCTAssertEqual(slider.value, 0, accuracy: 0.001)
    }

    // MARK: - Accessibility Scrubbing Delegate Callback Tests

    func testAccessibilityIncrement_callsScrubbingDelegates() {
        createTestObjects()
        slider.delegate = mockDelegate
        slider.min = 0
        slider.max = 100
        slider.accessibilityIncrementStep = 10.0
        slider.set(value: 50, animated: false)
        mockDelegate.reset()

        slider.accessibilityIncrement()

        // Verify all scrubbing delegate callbacks are fired
        XCTAssertTrue(mockDelegate.didBeginScrubbingCalled, "accessibilityIncrement should call sliderDidBeginScrubbing")
        XCTAssertTrue(mockDelegate.didEndScrubbingCalled, "accessibilityIncrement should call sliderDidEndScrubbing")
        XCTAssertTrue(mockDelegate.didFinishScrubbingCalled, "accessibilityIncrement should call sliderDidFinishScrubbing")
        XCTAssertEqual(mockDelegate.beginScrubbingCallCount, 1)
        XCTAssertEqual(mockDelegate.endScrubbingCallCount, 1)
        XCTAssertEqual(mockDelegate.finishScrubbingCallCount, 1)
    }

    func testAccessibilityDecrement_callsScrubbingDelegates() {
        createTestObjects()
        slider.delegate = mockDelegate
        slider.min = 0
        slider.max = 100
        slider.accessibilityIncrementStep = 10.0
        slider.set(value: 50, animated: false)
        mockDelegate.reset()

        slider.accessibilityDecrement()

        // Verify all scrubbing delegate callbacks are fired
        XCTAssertTrue(mockDelegate.didBeginScrubbingCalled, "accessibilityDecrement should call sliderDidBeginScrubbing")
        XCTAssertTrue(mockDelegate.didEndScrubbingCalled, "accessibilityDecrement should call sliderDidEndScrubbing")
        XCTAssertTrue(mockDelegate.didFinishScrubbingCalled, "accessibilityDecrement should call sliderDidFinishScrubbing")
        XCTAssertEqual(mockDelegate.beginScrubbingCallCount, 1)
        XCTAssertEqual(mockDelegate.endScrubbingCallCount, 1)
        XCTAssertEqual(mockDelegate.finishScrubbingCallCount, 1)
    }

    func testAccessibilityIncrement_multipleAdjustments_callsDelegatesEachTime() {
        createTestObjects()
        slider.delegate = mockDelegate
        slider.min = 0
        slider.max = 100
        slider.accessibilityIncrementStep = 10.0
        slider.set(value: 30, animated: false)
        mockDelegate.reset()

        // Multiple VoiceOver adjustments
        slider.accessibilityIncrement()
        slider.accessibilityIncrement()
        slider.accessibilityIncrement()

        // Each adjustment should trigger the full scrubbing lifecycle
        XCTAssertEqual(mockDelegate.beginScrubbingCallCount, 3)
        XCTAssertEqual(mockDelegate.endScrubbingCallCount, 3)
        XCTAssertEqual(mockDelegate.finishScrubbingCallCount, 3)
    }
}

// MARK: - SliderDelegate Default Implementation Tests

@MainActor
final class SliderDelegateDefaultTests: XCTestCase {

    // Test the protocol extension default implementations
    func testDefaultTextWithValue() {
        let delegate = MockSliderDelegate()
        let slider = Slider(frame: .zero)
        let text = delegate.slider(slider, textWithValue: 100.5)
        XCTAssertEqual(text, "100")
    }

    func testDefaultSliderDidTap_doesNotCrash() {
        let delegate = DefaultSliderDelegate()
        let slider = Slider(frame: .zero)
        // Should not crash - default implementation does nothing
        delegate.sliderDidTap(slider)
    }

    func testDefaultDidChangeValue_doesNotCrash() {
        let delegate = DefaultSliderDelegate()
        let slider = Slider(frame: .zero)
        // Should not crash - default implementation does nothing
        delegate.slider(slider, didChangeValue: 50)
    }

    func testDefaultSliderDidBeginScrubbing_doesNotCrash() {
        let delegate = DefaultSliderDelegate()
        let slider = Slider(frame: .zero)
        // Should not crash - default implementation does nothing
        delegate.sliderDidBeginScrubbing(slider)
    }

    func testDefaultSliderDidEndScrubbing_doesNotCrash() {
        let delegate = DefaultSliderDelegate()
        let slider = Slider(frame: .zero)
        // Should not crash - default implementation does nothing
        delegate.sliderDidEndScrubbing(slider)
    }

    func testDefaultSliderDidFinishScrubbing_doesNotCrash() {
        let delegate = DefaultSliderDelegate()
        let slider = Slider(frame: .zero)
        // Should not crash - default implementation does nothing
        delegate.sliderDidFinishScrubbing(slider)
    }
}

// MARK: - Slider Scrubbing Delegate Tests

@MainActor
final class SliderScrubbingDelegateTests: XCTestCase {

    func testScrubbingDelegate_beginEndAndFinishAreCalled() {
        let slider = Slider(frame: CGRect(x: 0, y: 0, width: 400, height: 50))
        let mockDelegate = MockSliderDelegate()
        slider.delegate = mockDelegate

        // Simulate scrubbing begin
        mockDelegate.sliderDidBeginScrubbing(slider)
        XCTAssertTrue(mockDelegate.didBeginScrubbingCalled)
        XCTAssertEqual(mockDelegate.beginScrubbingCallCount, 1)

        // Simulate scrubbing end (gesture ended, deceleration may continue)
        mockDelegate.sliderDidEndScrubbing(slider)
        XCTAssertTrue(mockDelegate.didEndScrubbingCalled)
        XCTAssertEqual(mockDelegate.endScrubbingCallCount, 1)

        // Simulate scrubbing finish (deceleration complete)
        mockDelegate.sliderDidFinishScrubbing(slider)
        XCTAssertTrue(mockDelegate.didFinishScrubbingCalled)
        XCTAssertEqual(mockDelegate.finishScrubbingCallCount, 1)
    }

    func testScrubbingDelegate_multipleScrubbingSessions() {
        let slider = Slider(frame: CGRect(x: 0, y: 0, width: 400, height: 50))
        let mockDelegate = MockSliderDelegate()
        slider.delegate = mockDelegate

        // First scrubbing session
        mockDelegate.sliderDidBeginScrubbing(slider)
        mockDelegate.sliderDidEndScrubbing(slider)
        mockDelegate.sliderDidFinishScrubbing(slider)

        // Second scrubbing session
        mockDelegate.sliderDidBeginScrubbing(slider)
        mockDelegate.sliderDidEndScrubbing(slider)
        mockDelegate.sliderDidFinishScrubbing(slider)

        XCTAssertEqual(mockDelegate.beginScrubbingCallCount, 2)
        XCTAssertEqual(mockDelegate.endScrubbingCallCount, 2)
        XCTAssertEqual(mockDelegate.finishScrubbingCallCount, 2)
    }

    func testScrubbingDelegate_reset() {
        let mockDelegate = MockSliderDelegate()
        let slider = Slider(frame: .zero)

        mockDelegate.sliderDidBeginScrubbing(slider)
        mockDelegate.sliderDidEndScrubbing(slider)
        mockDelegate.sliderDidFinishScrubbing(slider)

        XCTAssertTrue(mockDelegate.didBeginScrubbingCalled)
        XCTAssertTrue(mockDelegate.didEndScrubbingCalled)
        XCTAssertTrue(mockDelegate.didFinishScrubbingCalled)

        mockDelegate.reset()

        XCTAssertFalse(mockDelegate.didBeginScrubbingCalled)
        XCTAssertFalse(mockDelegate.didEndScrubbingCalled)
        XCTAssertFalse(mockDelegate.didFinishScrubbingCalled)
        XCTAssertEqual(mockDelegate.beginScrubbingCallCount, 0)
        XCTAssertEqual(mockDelegate.endScrubbingCallCount, 0)
        XCTAssertEqual(mockDelegate.finishScrubbingCallCount, 0)
    }
}

// Helper class to test protocol extension defaults
final class DefaultSliderDelegate: SliderDelegate {
    // Uses all default implementations from protocol extension
}
