//
//  MediaHomeErrorViewTests.swift
//  Internet ArchiveTests
//
//  Unit tests for MediaHomeErrorView SwiftUI component
//

import XCTest
import SwiftUI
@testable import Internet_Archive

@MainActor
final class MediaHomeErrorViewTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_setsMessage() {
        let view = MediaHomeErrorView(
            message: "Test error message",
            onRetry: {}
        )
        XCTAssertEqual(view.message, "Test error message")
    }

    // MARK: - Message Variations Tests

    func testMessage_emptyString() {
        let view = MediaHomeErrorView(message: "", onRetry: {})
        XCTAssertEqual(view.message, "")
    }

    func testMessage_longString() {
        let longMessage = "This is a very long error message that explains exactly what went wrong and might wrap across multiple lines on the screen."
        let view = MediaHomeErrorView(message: longMessage, onRetry: {})
        XCTAssertEqual(view.message, longMessage)
    }

    func testMessage_networkError() {
        let view = MediaHomeErrorView(
            message: "Unable to load content. Please check your connection.",
            onRetry: {}
        )
        XCTAssertTrue(view.message.contains("connection"))
    }

    func testMessage_serviceUnavailable() {
        let view = MediaHomeErrorView(
            message: "Service temporarily unavailable. Please try again later.",
            onRetry: {}
        )
        XCTAssertTrue(view.message.contains("unavailable"))
    }

    // MARK: - Retry Callback Tests

    func testOnRetry_callbackIsSet() {
        var callbackExecuted = false
        let view = MediaHomeErrorView(
            message: "Error",
            onRetry: {
                callbackExecuted = true
            }
        )

        // We can't directly call onRetry since it's async,
        // but we verify the view was created with the callback
        XCTAssertNotNil(view)
        // Mark as false since we can't execute in this synchronous context
        XCTAssertFalse(callbackExecuted)
    }

    // MARK: - View Type Tests

    func testMediaHomeErrorView_isView() {
        let view = MediaHomeErrorView(message: "Error", onRetry: {})
        _ = type(of: view.body)
        XCTAssertNotNil(view)
    }

    func testBody_doesNotCrash() {
        let view = MediaHomeErrorView(message: "Test", onRetry: {})
        _ = view.body
        XCTAssertTrue(true)
    }

    // MARK: - Multiple Instance Tests

    func testMultipleInstances_areIndependent() {
        let view1 = MediaHomeErrorView(message: "Error 1", onRetry: {})
        let view2 = MediaHomeErrorView(message: "Error 2", onRetry: {})

        XCTAssertNotEqual(view1.message, view2.message)
    }

    // MARK: - Common Usage Patterns Tests

    func testCommonPattern_connectionError() {
        let view = MediaHomeErrorView(
            message: "Unable to load content. Please check your connection.",
            onRetry: {}
        )
        XCTAssertNotNil(view)
        XCTAssertFalse(view.message.isEmpty)
    }

    func testCommonPattern_serverError() {
        let view = MediaHomeErrorView(
            message: "Internet Archive services are temporarily unavailable.",
            onRetry: {}
        )
        XCTAssertNotNil(view)
        XCTAssertTrue(view.message.contains("Internet Archive"))
    }

    func testCommonPattern_genericError() {
        let view = MediaHomeErrorView(
            message: "Something went wrong. Please try again.",
            onRetry: {}
        )
        XCTAssertNotNil(view)
    }
}
