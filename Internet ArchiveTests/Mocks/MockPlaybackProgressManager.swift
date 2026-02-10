//
//  MockPlaybackProgressManager.swift
//  Internet ArchiveTests
//
//  In-memory mock for PlaybackProgressManager, useful for isolated testing
//  of code that depends on playback progress tracking.
//

import Foundation
@testable import Internet_Archive

/// In-memory mock that mirrors `PlaybackProgressManager`'s public API.
///
/// Unlike the real manager (which persists to UserDefaults), this mock
/// stores all progress in memory for fast, isolated, deterministic tests.
///
/// ## Usage Notes
///
/// Since `PlaybackProgressManager` does not currently have a protocol,
/// this mock cannot be injected via protocol conformance. It is designed to:
/// 1. Test progress logic in isolation without UserDefaults side effects
/// 2. Serve as a ready-to-use mock when a protocol is introduced
/// 3. Track method calls for verifying interactions
///
/// ## Example Usage
///
/// ```swift
/// let mock = MockPlaybackProgressManager()
/// let progress = TestFixtures.makePlaybackProgress(identifier: "video1")
/// mock.saveProgress(progress)
/// #expect(mock.saveProgressCalled)
/// #expect(mock.getProgress(for: "video1") != nil)
/// ```
@MainActor
final class MockPlaybackProgressManager {

    // MARK: - Call Tracking

    private(set) var saveProgressCalled = false
    private(set) var saveProgressCallCount = 0
    private(set) var getProgressCalled = false
    private(set) var getProgressCallCount = 0
    private(set) var removeProgressCalled = false
    private(set) var getContinueWatchingCalled = false
    private(set) var getContinueListeningCalled = false
    private(set) var clearAllProgressCalled = false

    // MARK: - In-Memory Storage

    private var progressItems: [PlaybackProgress] = []

    // MARK: - Public Methods (mirrors PlaybackProgressManager API)

    func saveProgress(_ progress: PlaybackProgress) {
        saveProgressCalled = true
        saveProgressCallCount += 1

        // Remove existing entry for this item+filename
        progressItems.removeAll {
            $0.itemIdentifier == progress.itemIdentifier && $0.filename == progress.filename
        }

        // Don't save if complete (>95%), matching real behavior
        guard !progress.isComplete else { return }

        progressItems.append(progress)
    }

    func getProgress(for identifier: String, filename: String) -> PlaybackProgress? {
        getProgressCalled = true
        getProgressCallCount += 1
        return progressItems.first {
            $0.itemIdentifier == identifier && $0.filename == filename
        }
    }

    func getProgress(for identifier: String) -> PlaybackProgress? {
        getProgressCalled = true
        getProgressCallCount += 1
        return progressItems
            .filter { $0.itemIdentifier == identifier }
            .max { $0.lastWatchedDate < $1.lastWatchedDate }
    }

    func removeProgress(for identifier: String, filename: String) {
        removeProgressCalled = true
        progressItems.removeAll {
            $0.itemIdentifier == identifier && $0.filename == filename
        }
    }

    func removeProgress(for identifier: String) {
        removeProgressCalled = true
        progressItems.removeAll { $0.itemIdentifier == identifier }
    }

    func getContinueWatchingItems(limit: Int = 20) -> [PlaybackProgress] {
        getContinueWatchingCalled = true
        return progressItems
            .filter { $0.isVideo && !$0.isComplete && $0.isValid }
            .sorted { $0.lastWatchedDate > $1.lastWatchedDate }
            .prefix(limit)
            .map { $0 }
    }

    func getContinueListeningItems(limit: Int = 20) -> [PlaybackProgress] {
        getContinueListeningCalled = true
        return progressItems
            .filter { $0.isAudio && !$0.isComplete && $0.isValid }
            .sorted { $0.lastWatchedDate > $1.lastWatchedDate }
            .prefix(limit)
            .map { $0 }
    }

    func hasResumableProgress(for identifier: String) -> Bool {
        guard let progress = getProgress(for: identifier) else { return false }
        return !progress.isComplete && progress.hasResumableProgress
    }

    func clearAllProgress() {
        clearAllProgressCalled = true
        progressItems = []
    }

    var progressCount: Int {
        progressItems.count
    }

    // MARK: - Test Helpers

    /// All stored progress items (for test assertions)
    var allProgress: [PlaybackProgress] {
        progressItems
    }

    /// Reset all tracking state and stored data
    func reset() {
        progressItems = []
        saveProgressCalled = false
        saveProgressCallCount = 0
        getProgressCalled = false
        getProgressCallCount = 0
        removeProgressCalled = false
        getContinueWatchingCalled = false
        getContinueListeningCalled = false
        clearAllProgressCalled = false
    }
}
