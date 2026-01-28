//
//  VideoHomeViewTests.swift
//  Internet ArchiveTests
//
//  Tests for VideoHomeView-specific functionality
//  Note: VideoViewModel core tests are in VideoViewModelTests.swift or similar
//  Note: Continue watching tests are in PlaybackProgressManagerTests.swift
//

import XCTest
import Combine
@testable import Internet_Archive

// MARK: - VideoViewModel Loading State Tests

/// Tests that specifically require observing loading state transitions
/// which need mock service with configurable delay
@MainActor
final class VideoLoadingStateTests: XCTestCase {

    nonisolated(unsafe) var viewModel: VideoViewModel!
    nonisolated(unsafe) var mockService: MockVideoCollectionService!
    nonisolated(unsafe) var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        let (newMockService, newViewModel) = MainActor.assumeIsolated {
            let service = MockVideoCollectionService()
            let vm = VideoViewModel(collectionService: service)
            return (service, vm)
        }
        mockService = newMockService
        viewModel = newViewModel
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        viewModel = nil
        mockService = nil
        super.tearDown()
    }

    func testLoadCollection_setsLoadingState() async {
        mockService.mockResults = TestFixtures.makeVideoResults(count: 5)
        mockService.delayMilliseconds = 100  // Brief delay to observe loading state

        // Use expectation to deterministically observe the loading state transition
        let loadingObserved = expectation(description: "Loading state should become true")
        loadingObserved.assertForOverFulfill = false

        viewModel.$state
            .map(\.isLoading)
            .dropFirst()  // Skip initial value
            .sink { isLoading in
                if isLoading {
                    loadingObserved.fulfill()
                }
            }
            .store(in: &cancellables)

        // Start loading
        let loadTask = Task {
            await viewModel.loadCollection()
        }

        // Wait for loading state to become true
        await fulfillment(of: [loadingObserved], timeout: 2.0)

        // Wait for completion
        await loadTask.value

        // Verify final state
        XCTAssertFalse(viewModel.state.isLoading, "isLoading should be false after load completes")
    }
}

// MARK: - Mock Video Collection Service

final class MockVideoCollectionService: CollectionServiceProtocol, @unchecked Sendable {
    var mockResults: [SearchResult] = []
    var mockMetadataResponse: ItemMetadataResponse?
    var errorToThrow: Error?
    var getCollectionsCalled = false
    var delayMilliseconds: UInt64 = 0

    func getCollections(collection: String, resultType: String, limit: Int?) async throws -> (collection: String, results: [SearchResult]) {
        getCollectionsCalled = true

        if delayMilliseconds > 0 {
            try? await Task.sleep(nanoseconds: delayMilliseconds * 1_000_000)
        }

        if let error = errorToThrow {
            throw error
        }

        return (collection, mockResults)
    }

    func getMetadata(identifier: String) async throws -> ItemMetadataResponse {
        if let error = errorToThrow {
            throw error
        }

        guard let response = mockMetadataResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

    func reset() {
        mockResults = []
        mockMetadataResponse = nil
        errorToThrow = nil
        getCollectionsCalled = false
        delayMilliseconds = 0
    }
}

// MARK: - Notification Tests

final class VideoNotificationTests: XCTestCase {

    func testPopVideoNavigationNotification_exists() {
        // Verify the notification name is accessible
        let notificationName = Notification.Name.popVideoNavigation
        XCTAssertEqual(notificationName.rawValue, "popVideoNavigation")
    }

    func testPopVideoNavigationNotification_canBePosted() {
        let expectation = XCTestExpectation(description: "Notification received")

        let observer = NotificationCenter.default.addObserver(
            forName: .popVideoNavigation,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        NotificationCenter.default.post(name: .popVideoNavigation, object: nil)

        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
}
