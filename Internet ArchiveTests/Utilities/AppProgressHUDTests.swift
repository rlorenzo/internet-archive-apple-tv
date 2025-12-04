//
//  AppProgressHUDTests.swift
//  Internet ArchiveTests
//
//  Unit tests for AppProgressHUD
//

import XCTest
@testable import Internet_Archive

@MainActor
final class AppProgressHUDTests: XCTestCase {

    var testView: UIView!

    override func setUp() {
        super.setUp()
        testView = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
    }

    override func tearDown() {
        testView = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedManager() {
        let instance1 = AppProgressHUD.sharedManager
        let instance2 = AppProgressHUD.sharedManager
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Show Tests

    func testShow_addsIndicatorToView() {
        let hud = AppProgressHUD.sharedManager

        hud.show(view: testView)

        // Verify indicator was added
        let activityIndicators = testView.subviews.compactMap { $0 as? UIActivityIndicatorView }
        XCTAssertFalse(activityIndicators.isEmpty)
    }

    func testShow_indicatorIsAnimating() {
        let hud = AppProgressHUD.sharedManager

        hud.show(view: testView)

        let activityIndicators = testView.subviews.compactMap { $0 as? UIActivityIndicatorView }
        XCTAssertFalse(activityIndicators.isEmpty)
        XCTAssertTrue(activityIndicators.first?.isAnimating ?? false)
    }

    func testShow_centeredInView() {
        let hud = AppProgressHUD.sharedManager

        hud.show(view: testView)

        let activityIndicators = testView.subviews.compactMap { $0 as? UIActivityIndicatorView }
        let indicator = activityIndicators.first
        XCTAssertEqual(indicator?.center, testView.center)
    }

    // MARK: - Hide Tests

    func testHide_removesIndicatorFromView() {
        let hud = AppProgressHUD.sharedManager

        hud.show(view: testView)
        hud.hide()

        let activityIndicators = testView.subviews.compactMap { $0 as? UIActivityIndicatorView }
        XCTAssertTrue(activityIndicators.isEmpty)
    }

    func testHide_withoutShow_doesNotCrash() {
        let hud = AppProgressHUD.sharedManager

        // Should not crash
        hud.hide()

        XCTAssertNotNil(hud)
    }

    // MARK: - Show/Hide Cycle Tests

    func testShowHideShowCycle() {
        let hud = AppProgressHUD.sharedManager

        // First show
        hud.show(view: testView)
        var activityIndicators = testView.subviews.compactMap { $0 as? UIActivityIndicatorView }
        XCTAssertFalse(activityIndicators.isEmpty)

        // Hide
        hud.hide()
        activityIndicators = testView.subviews.compactMap { $0 as? UIActivityIndicatorView }
        XCTAssertTrue(activityIndicators.isEmpty)

        // Show again
        hud.show(view: testView)
        activityIndicators = testView.subviews.compactMap { $0 as? UIActivityIndicatorView }
        XCTAssertFalse(activityIndicators.isEmpty)

        // Clean up
        hud.hide()
    }

    func testMultipleHideCalls() {
        let hud = AppProgressHUD.sharedManager

        hud.show(view: testView)
        hud.hide()
        hud.hide()
        hud.hide()

        // Should not crash and view should be empty
        let activityIndicators = testView.subviews.compactMap { $0 as? UIActivityIndicatorView }
        XCTAssertTrue(activityIndicators.isEmpty)
    }
}
