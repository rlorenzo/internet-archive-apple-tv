//
//  StateViewsTests.swift
//  Internet ArchiveTests
//
//  Unit tests for SwiftUI state views (EmptyContentView, ErrorContentView)
//

import XCTest
import SwiftUI
@testable import Internet_Archive

@MainActor
final class StateViewsTests: XCTestCase {

    // MARK: - EmptyContentView Tests

    // MARK: Initialization

    func testEmptyContentView_initWithRequiredParameters() {
        let view = EmptyContentView(
            icon: "heart",
            title: "Test Title",
            message: "Test Message"
        )

        XCTAssertNotNil(view)
    }

    func testEmptyContentView_initWithAllParameters() {
        var actionCalled = false
        let view = EmptyContentView(
            icon: "star",
            title: "Title",
            message: "Message",
            buttonTitle: "Action",
            buttonAction: { actionCalled = true }
        )

        XCTAssertNotNil(view)
        // Call the action to verify it was stored
        view.buttonAction?()
        XCTAssertTrue(actionCalled)
    }

    func testEmptyContentView_initWithNilButton() {
        let view = EmptyContentView(
            icon: "folder",
            title: "Empty",
            message: "No items",
            buttonTitle: nil,
            buttonAction: nil
        )

        XCTAssertNil(view.buttonTitle)
        XCTAssertNil(view.buttonAction)
    }

    func testEmptyContentView_storesIconCorrectly() {
        let view = EmptyContentView(
            icon: "magnifyingglass",
            title: "Search",
            message: "No results"
        )

        XCTAssertEqual(view.icon, "magnifyingglass")
    }

    func testEmptyContentView_storesTitleCorrectly() {
        let view = EmptyContentView(
            icon: "star",
            title: "My Title",
            message: "Description"
        )

        XCTAssertEqual(view.title, "My Title")
    }

    func testEmptyContentView_storesMessageCorrectly() {
        let view = EmptyContentView(
            icon: "star",
            title: "Title",
            message: "My custom message here"
        )

        XCTAssertEqual(view.message, "My custom message here")
    }

    // MARK: EmptyContentView Presets

    func testEmptyContentView_noSearchResults_withoutAction() {
        let view = EmptyContentView.noSearchResults()

        XCTAssertEqual(view.icon, "magnifyingglass")
        XCTAssertEqual(view.title, "No Results Found")
        XCTAssertTrue(view.message.contains("different keywords"))
        XCTAssertNil(view.buttonTitle)
        XCTAssertNil(view.buttonAction)
    }

    func testEmptyContentView_noSearchResults_withClearAction() {
        var clearCalled = false
        let view = EmptyContentView.noSearchResults {
            clearCalled = true
        }

        XCTAssertEqual(view.buttonTitle, "Clear Search")
        XCTAssertNotNil(view.buttonAction)

        view.buttonAction?()
        XCTAssertTrue(clearCalled)
    }

    func testEmptyContentView_noFavorites_withoutAction() {
        let view = EmptyContentView.noFavorites()

        XCTAssertEqual(view.icon, "heart")
        XCTAssertEqual(view.title, "No Favorites Yet")
        XCTAssertTrue(view.message.contains("favorites"))
        XCTAssertNil(view.buttonTitle)
    }

    func testEmptyContentView_noFavorites_withBrowseAction() {
        var browseCalled = false
        let view = EmptyContentView.noFavorites {
            browseCalled = true
        }

        XCTAssertEqual(view.buttonTitle, "Browse Content")
        view.buttonAction?()
        XCTAssertTrue(browseCalled)
    }

    func testEmptyContentView_noContinueWatching() {
        let view = EmptyContentView.noContinueWatching

        XCTAssertEqual(view.icon, "play.circle")
        XCTAssertEqual(view.title, "Nothing to Continue")
        XCTAssertTrue(view.message.contains("Videos"))
        XCTAssertNil(view.buttonTitle)
    }

    func testEmptyContentView_noContinueListening() {
        let view = EmptyContentView.noContinueListening

        XCTAssertEqual(view.icon, "music.note")
        XCTAssertEqual(view.title, "Nothing to Continue")
        XCTAssertTrue(view.message.contains("Albums"))
        XCTAssertNil(view.buttonTitle)
    }

    func testEmptyContentView_emptyCollection() {
        let view = EmptyContentView.emptyCollection(collectionName: "Movies")

        XCTAssertEqual(view.icon, "folder")
        XCTAssertEqual(view.title, "No Items")
        XCTAssertTrue(view.message.contains("Movies"))
    }

    func testEmptyContentView_emptyCollection_differentName() {
        let view = EmptyContentView.emptyCollection(collectionName: "Grateful Dead")

        XCTAssertTrue(view.message.contains("Grateful Dead"))
    }

    func testEmptyContentView_loginRequired() {
        var loginCalled = false
        let view = EmptyContentView.loginRequired {
            loginCalled = true
        }

        XCTAssertEqual(view.icon, "person.crop.circle")
        XCTAssertEqual(view.title, "Sign In Required")
        XCTAssertEqual(view.buttonTitle, "Sign In")

        view.buttonAction?()
        XCTAssertTrue(loginCalled)
    }

    // MARK: - ErrorContentView Tests

    // MARK: Initialization

    func testErrorContentView_initWithMessageOnly() {
        let view = ErrorContentView(message: "An error occurred")

        XCTAssertEqual(view.icon, "exclamationmark.triangle")
        XCTAssertEqual(view.title, "Something Went Wrong")
        XCTAssertEqual(view.message, "An error occurred")
        XCTAssertNil(view.onRetry)
    }

    func testErrorContentView_initWithAllParameters() {
        var retryCalled = false
        let view = ErrorContentView(
            icon: "wifi.slash",
            title: "Connection Failed",
            message: "Check your network",
            onRetry: { retryCalled = true }
        )

        XCTAssertEqual(view.icon, "wifi.slash")
        XCTAssertEqual(view.title, "Connection Failed")
        XCTAssertEqual(view.message, "Check your network")

        view.onRetry?()
        XCTAssertTrue(retryCalled)
    }

    func testErrorContentView_initWithDefaultValues() {
        let view = ErrorContentView(message: "Error message")

        XCTAssertEqual(view.icon, "exclamationmark.triangle")
        XCTAssertEqual(view.title, "Something Went Wrong")
    }

    func testErrorContentView_storesOnRetryCorrectly() {
        var retryCount = 0
        let view = ErrorContentView(message: "Error") {
            retryCount += 1
        }

        view.onRetry?()
        view.onRetry?()

        XCTAssertEqual(retryCount, 2)
    }

    // MARK: ErrorContentView Presets

    func testErrorContentView_networkError_withoutRetry() {
        let view = ErrorContentView.networkError()

        XCTAssertEqual(view.icon, "wifi.slash")
        XCTAssertEqual(view.title, "No Connection")
        XCTAssertTrue(view.message.contains("internet connection"))
        XCTAssertNil(view.onRetry)
    }

    func testErrorContentView_networkError_withRetry() {
        var retryCalled = false
        let view = ErrorContentView.networkError {
            retryCalled = true
        }

        XCTAssertNotNil(view.onRetry)
        view.onRetry?()
        XCTAssertTrue(retryCalled)
    }

    func testErrorContentView_serverError_withoutRetry() {
        let view = ErrorContentView.serverError()

        XCTAssertEqual(view.icon, "server.rack")
        XCTAssertEqual(view.title, "Server Error")
        XCTAssertTrue(view.message.contains("Internet Archive"))
        XCTAssertNil(view.onRetry)
    }

    func testErrorContentView_serverError_withRetry() {
        var retryCalled = false
        let view = ErrorContentView.serverError {
            retryCalled = true
        }

        XCTAssertNotNil(view.onRetry)
        view.onRetry?()
        XCTAssertTrue(retryCalled)
    }

    func testErrorContentView_notFound_defaultItemType() {
        let view = ErrorContentView.notFound()

        XCTAssertEqual(view.icon, "questionmark.folder")
        XCTAssertEqual(view.title, "Not Found")
        XCTAssertTrue(view.message.contains("content"))
        XCTAssertNil(view.onRetry)
    }

    func testErrorContentView_notFound_customItemType() {
        let view = ErrorContentView.notFound(itemType: "video")

        XCTAssertTrue(view.message.contains("video"))
    }

    func testErrorContentView_notFound_anotherItemType() {
        let view = ErrorContentView.notFound(itemType: "album")

        XCTAssertTrue(view.message.contains("album"))
    }

    func testErrorContentView_loadingFailed_defaultContentType() {
        let view = ErrorContentView.loadingFailed()

        XCTAssertEqual(view.icon, "exclamationmark.triangle")
        XCTAssertEqual(view.title, "Failed to Load")
        XCTAssertTrue(view.message.contains("content"))
    }

    func testErrorContentView_loadingFailed_customContentType() {
        var retryCalled = false
        let view = ErrorContentView.loadingFailed(contentType: "videos") {
            retryCalled = true
        }

        XCTAssertTrue(view.message.contains("videos"))
        view.onRetry?()
        XCTAssertTrue(retryCalled)
    }

    func testErrorContentView_playbackError_withoutRetry() {
        let view = ErrorContentView.playbackError()

        XCTAssertEqual(view.icon, "play.slash")
        XCTAssertEqual(view.title, "Playback Error")
        XCTAssertTrue(view.message.contains("media file"))
        XCTAssertNil(view.onRetry)
    }

    func testErrorContentView_playbackError_withRetry() {
        var retryCalled = false
        let view = ErrorContentView.playbackError {
            retryCalled = true
        }

        view.onRetry?()
        XCTAssertTrue(retryCalled)
    }

    func testErrorContentView_authError_withoutRetry() {
        let view = ErrorContentView.authError()

        XCTAssertEqual(view.icon, "person.crop.circle.badge.exclamationmark")
        XCTAssertEqual(view.title, "Authentication Failed")
        XCTAssertTrue(view.message.contains("credentials"))
        XCTAssertNil(view.onRetry)
    }

    func testErrorContentView_authError_withRetry() {
        var retryCalled = false
        let view = ErrorContentView.authError {
            retryCalled = true
        }

        view.onRetry?()
        XCTAssertTrue(retryCalled)
    }

    // MARK: - ErrorContentView from NetworkError

    func testErrorContentView_fromNetworkError_noConnection() {
        let view = ErrorContentView(networkError: .noConnection)

        XCTAssertEqual(view.icon, "wifi.slash")
        XCTAssertEqual(view.title, "No Connection")
    }

    func testErrorContentView_fromNetworkError_timeout() {
        let view = ErrorContentView(networkError: .timeout)

        XCTAssertEqual(view.title, "No Connection")
    }

    func testErrorContentView_fromNetworkError_serverError() {
        let view = ErrorContentView(networkError: .serverError(statusCode: 500))

        XCTAssertEqual(view.title, "Server Error")
    }

    func testErrorContentView_fromNetworkError_resourceNotFound() {
        let view = ErrorContentView(networkError: .resourceNotFound)

        XCTAssertEqual(view.title, "Not Found")
    }

    func testErrorContentView_fromNetworkError_unauthorized() {
        let view = ErrorContentView(networkError: .unauthorized)

        XCTAssertEqual(view.title, "Authentication Failed")
    }

    func testErrorContentView_fromNetworkError_authenticationFailed() {
        let view = ErrorContentView(networkError: .authenticationFailed)

        XCTAssertEqual(view.title, "Authentication Failed")
    }

    func testErrorContentView_fromNetworkError_invalidCredentials() {
        let view = ErrorContentView(networkError: .invalidCredentials)

        XCTAssertEqual(view.title, "Authentication Failed")
    }

    func testErrorContentView_fromNetworkError_withRetry() {
        var retryCalled = false
        let view = ErrorContentView(networkError: .noConnection) {
            retryCalled = true
        }

        view.onRetry?()
        XCTAssertTrue(retryCalled)
    }

    func testErrorContentView_fromNetworkError_decodingFailed() {
        let view = ErrorContentView(networkError: .decodingFailed(NSError(domain: "", code: 0)))

        // Should use default error handling with ErrorPresenter message
        XCTAssertNotNil(view)
    }

    func testErrorContentView_fromNetworkError_invalidData() {
        let view = ErrorContentView(networkError: .invalidData)

        XCTAssertNotNil(view)
    }

    func testErrorContentView_fromNetworkError_unknown() {
        let view = ErrorContentView(networkError: .unknown(NSError(domain: "", code: 0)))

        XCTAssertNotNil(view)
    }

    // MARK: - Edge Cases

    func testEmptyContentView_emptyStrings() {
        let view = EmptyContentView(
            icon: "",
            title: "",
            message: ""
        )

        XCTAssertEqual(view.icon, "")
        XCTAssertEqual(view.title, "")
        XCTAssertEqual(view.message, "")
    }

    func testEmptyContentView_longStrings() {
        let longMessage = String(repeating: "This is a very long message. ", count: 50)
        let view = EmptyContentView(
            icon: "star",
            title: "Long Title " + String(repeating: "Extra", count: 20),
            message: longMessage
        )

        XCTAssertEqual(view.message, longMessage)
    }

    func testEmptyContentView_specialCharactersInText() {
        let view = EmptyContentView(
            icon: "star",
            title: "Title with émojis 🎬 & symbols ™",
            message: "Message with <html> & \"quotes\""
        )

        XCTAssertTrue(view.title.contains("🎬"))
        XCTAssertTrue(view.message.contains("<html>"))
    }

    func testErrorContentView_emptyMessage() {
        let view = ErrorContentView(message: "")

        XCTAssertEqual(view.message, "")
    }

    func testErrorContentView_veryLongMessage() {
        let longMessage = String(repeating: "Error details here. ", count: 100)
        let view = ErrorContentView(message: longMessage)

        XCTAssertEqual(view.message, longMessage)
    }
}
