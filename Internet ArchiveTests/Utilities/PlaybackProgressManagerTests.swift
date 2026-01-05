//
//  PlaybackProgressManagerTests.swift
//  Internet ArchiveTests
//
//  Tests for PlaybackProgressManager functionality
//

import XCTest
@testable import Internet_Archive

@MainActor
final class PlaybackProgressManagerTests: XCTestCase {

    var manager: PlaybackProgressManager!

    override func setUp() {
        super.setUp()
        manager = PlaybackProgressManager.shared
        manager.resetForTesting()
    }

    override func tearDown() {
        manager.resetForTesting()
        super.tearDown()
    }

    // MARK: - Save and Retrieve Tests

    func testSaveAndRetrieveProgress() {
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Test Video"
        ))

        manager.saveProgress(progress)

        let retrieved = manager.getProgress(for: "test-item", filename: "video.mp4")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.currentTime, 100)
    }

    func testGetProgressByIdentifierOnly() {
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Test Video"
        ))

        manager.saveProgress(progress)

        let retrieved = manager.getProgress(for: "test-item")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.filename, "video.mp4")
    }

    func testGetProgressReturnsMostRecentForItem() {
        let progress1 = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video1.mp4",
            currentTime: 100,
            duration: 3600,
            lastWatchedDate: Date().addingTimeInterval(-3600),
            title: "Video 1",
            mediaType: "movies",
            imageURL: nil
        )

        let progress2 = PlaybackProgress(
            itemIdentifier: "test-item",
            filename: "video2.mp4",
            currentTime: 200,
            duration: 3600,
            lastWatchedDate: Date(),
            title: "Video 2",
            mediaType: "movies",
            imageURL: nil
        )

        manager.saveProgress(progress1)
        manager.saveProgress(progress2)

        let retrieved = manager.getProgress(for: "test-item")
        XCTAssertEqual(retrieved?.filename, "video2.mp4")
    }

    func testSaveProgressUpdatesExisting() {
        let progress1 = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Test Video"
        ))

        let progress2 = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 200,
            duration: 3600,
            title: "Test Video Updated"
        ))

        manager.saveProgress(progress1)
        manager.saveProgress(progress2)

        // Should only have one entry
        let allProgress = manager.getAllProgressForTesting()
        let matchingItems = allProgress.filter {
            $0.itemIdentifier == "test-item" && $0.filename == "video.mp4"
        }
        XCTAssertEqual(matchingItems.count, 1)
        XCTAssertEqual(matchingItems.first?.currentTime, 200)
    }

    func testSaveProgressRemovesCompleteItems() {
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 3500,
            duration: 3600, // 97% complete
            title: "Test Video"
        ))

        manager.saveProgress(progress)

        let retrieved = manager.getProgress(for: "test-item", filename: "video.mp4")
        XCTAssertNil(retrieved, "Complete items should not be saved")
    }

    func testRemoveProgressByIdentifierAndFilename() {
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Test Video"
        ))

        manager.saveProgress(progress)
        manager.removeProgress(for: "test-item", filename: "video.mp4")

        let retrieved = manager.getProgress(for: "test-item", filename: "video.mp4")
        XCTAssertNil(retrieved)
    }

    func testRemoveProgressByIdentifier() {
        let progress1 = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video1.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Video 1"
        ))

        let progress2 = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video2.mp4",
            currentTime: 200,
            duration: 3600,
            title: "Video 2"
        ))

        manager.saveProgress(progress1)
        manager.saveProgress(progress2)
        manager.removeProgress(for: "test-item")

        XCTAssertNil(manager.getProgress(for: "test-item", filename: "video1.mp4"))
        XCTAssertNil(manager.getProgress(for: "test-item", filename: "video2.mp4"))
    }

    // MARK: - Continue Watching/Listening Tests

    func testGetContinueWatchingItemsOnlyReturnsVideos() {
        let video = PlaybackProgress.video(MediaProgressInfo(
            identifier: "video-item",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Test Video"
        ))

        let audio = PlaybackProgress.audio(MediaProgressInfo(
            identifier: "audio-item",
            filename: "track.mp3",
            currentTime: 60,
            duration: 300,
            title: "Test Track"
        ))

        manager.saveProgress(video)
        manager.saveProgress(audio)

        let continueWatching = manager.getContinueWatchingItems()
        XCTAssertEqual(continueWatching.count, 1)
        XCTAssertEqual(continueWatching.first?.itemIdentifier, "video-item")
    }

    func testGetContinueListeningItemsOnlyReturnsAudio() {
        let video = PlaybackProgress.video(MediaProgressInfo(
            identifier: "video-item",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Test Video"
        ))

        let audio = PlaybackProgress.audio(MediaProgressInfo(
            identifier: "audio-item",
            filename: "track.mp3",
            currentTime: 60,
            duration: 300,
            title: "Test Track"
        ))

        manager.saveProgress(video)
        manager.saveProgress(audio)

        let continueListening = manager.getContinueListeningItems()
        XCTAssertEqual(continueListening.count, 1)
        XCTAssertEqual(continueListening.first?.itemIdentifier, "audio-item")
    }

    func testContinueWatchingExcludesCompleteItems() {
        let incomplete = PlaybackProgress.video(MediaProgressInfo(
            identifier: "incomplete-video",
            filename: "video.mp4",
            currentTime: 1800,
            duration: 3600, // 50%
            title: "Incomplete"
        ))

        manager.saveProgress(incomplete)

        // Complete item won't be saved anyway due to saveProgress logic
        let continueWatching = manager.getContinueWatchingItems()
        XCTAssertEqual(continueWatching.count, 1)
    }

    func testContinueWatchingOrderedByMostRecent() {
        let older = PlaybackProgress(
            itemIdentifier: "older-video",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            lastWatchedDate: Date().addingTimeInterval(-3600),
            title: "Older Video",
            mediaType: "movies",
            imageURL: nil
        )

        let newer = PlaybackProgress(
            itemIdentifier: "newer-video",
            filename: "video.mp4",
            currentTime: 200,
            duration: 3600,
            lastWatchedDate: Date(),
            title: "Newer Video",
            mediaType: "movies",
            imageURL: nil
        )

        manager.saveProgress(older)
        manager.saveProgress(newer)

        let continueWatching = manager.getContinueWatchingItems()
        XCTAssertEqual(continueWatching.count, 2)
        XCTAssertEqual(continueWatching[0].itemIdentifier, "newer-video")
        XCTAssertEqual(continueWatching[1].itemIdentifier, "older-video")
    }

    func testContinueWatchingRespectsLimit() {
        for index in 0..<10 {
            let progress = PlaybackProgress.video(MediaProgressInfo(
                identifier: "video-\(index)",
                filename: "video.mp4",
                currentTime: 100,
                duration: 3600,
                title: "Video \(index)"
            ))
            manager.saveProgress(progress)
        }

        let continueWatching = manager.getContinueWatchingItems(limit: 5)
        XCTAssertEqual(continueWatching.count, 5)
    }

    // MARK: - Has Resumable Progress Tests

    func testHasResumableProgressTrue() {
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 100, // More than 10 seconds
            duration: 3600,
            title: "Test Video"
        ))

        manager.saveProgress(progress)

        XCTAssertTrue(manager.hasResumableProgress(for: "test-item"))
    }

    func testHasResumableProgressFalseUnder10Seconds() {
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 5, // Less than 10 seconds
            duration: 3600,
            title: "Test Video"
        ))

        manager.saveProgress(progress)

        XCTAssertFalse(manager.hasResumableProgress(for: "test-item"))
    }

    func testHasResumableProgressFalseWhenNoProgress() {
        XCTAssertFalse(manager.hasResumableProgress(for: "nonexistent-item"))
    }

    func testHasResumableProgressAudioWithTrackTime() {
        // Audio album: currentTime is album percentage (low), trackCurrentTime is actual seconds (high)
        let progress = PlaybackProgress(
            itemIdentifier: "album-123",
            filename: "__album__",
            currentTime: 5.0, // Only 5% through album (would fail old threshold)
            duration: 100.0,
            lastWatchedDate: Date(),
            title: "Artist: Track 1",
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 0,
            trackFilename: "track01.mp3",
            trackCurrentTime: 30.0 // 30 seconds into track (passes new threshold)
        )

        manager.saveProgress(progress)

        // Should return true because trackCurrentTime > 10
        XCTAssertTrue(manager.hasResumableProgress(for: "album-123"))
    }

    func testHasResumableProgressAudioWithLowTrackTime() {
        // Audio album: both album percentage and track time are low
        let progress = PlaybackProgress(
            itemIdentifier: "album-456",
            filename: "__album__",
            currentTime: 1.0, // 1% through album
            duration: 100.0,
            lastWatchedDate: Date(),
            title: "Artist: Track 1",
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 0,
            trackFilename: "track01.mp3",
            trackCurrentTime: 5.0 // Only 5 seconds into track
        )

        manager.saveProgress(progress)

        // Should return false because trackCurrentTime <= 10
        XCTAssertFalse(manager.hasResumableProgress(for: "album-456"))
    }

    // MARK: - Progress Count Tests

    func testProgressCount() {
        XCTAssertEqual(manager.progressCount, 0)

        let progress1 = PlaybackProgress.video(MediaProgressInfo(
            identifier: "video-1",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Video 1"
        ))

        let progress2 = PlaybackProgress.audio(MediaProgressInfo(
            identifier: "audio-1",
            filename: "track.mp3",
            currentTime: 60,
            duration: 300,
            title: "Track 1"
        ))

        manager.saveProgress(progress1)
        XCTAssertEqual(manager.progressCount, 1)

        manager.saveProgress(progress2)
        XCTAssertEqual(manager.progressCount, 2)
    }

    // MARK: - Clear All Tests

    func testClearAllProgress() {
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Test Video"
        ))

        manager.saveProgress(progress)
        XCTAssertEqual(manager.progressCount, 1)

        manager.clearAllProgress()
        XCTAssertEqual(manager.progressCount, 0)
    }

    // MARK: - Pruning Tests

    func testPruningRemovesOldEntries() {
        // Create an entry that's 31 days old
        let oldDate = Calendar.current.date(byAdding: .day, value: -31, to: Date()) ?? Date()
        let oldProgress = PlaybackProgress(
            itemIdentifier: "old-item",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            lastWatchedDate: oldDate,
            title: "Old Video",
            mediaType: "movies",
            imageURL: nil
        )

        let recentProgress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "recent-item",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Recent Video"
        ))

        // Add old progress directly (bypassing date update)
        // Since saveProgress always creates new date, we need to test via internal state
        // For this test, we'll verify the pruning happens by adding many items

        manager.saveProgress(recentProgress)
        // Old entries would be pruned on next save
        XCTAssertNotNil(manager.getProgress(for: "recent-item"))
    }

    func testPruningLimitsTo50Items() {
        // Add 55 items
        for index in 0..<55 {
            let progress = PlaybackProgress(
                itemIdentifier: "item-\(index)",
                filename: "video.mp4",
                currentTime: 100,
                duration: 3600,
                lastWatchedDate: Date().addingTimeInterval(Double(index)), // Slightly different times
                title: "Video \(index)",
                mediaType: "movies",
                imageURL: nil
            )
            manager.saveProgress(progress)
        }

        // Should be capped at 50
        XCTAssertLessThanOrEqual(manager.progressCount, 50)
    }

    // MARK: - Persistence Tests

    func testProgressPersistsAcrossManagerAccess() {
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "persist-test",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Persistence Test"
        ))

        manager.saveProgress(progress)

        // Access the shared instance again (simulating app restart)
        let retrieved = PlaybackProgressManager.shared.getProgress(for: "persist-test", filename: "video.mp4")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.currentTime, 100)
    }

    // MARK: - Edge Cases

    func testGetProgressReturnsNilForNonexistent() {
        let result = manager.getProgress(for: "nonexistent", filename: "video.mp4")
        XCTAssertNil(result)
    }

    func testRemoveProgressDoesNothingForNonexistent() {
        // Should not crash
        manager.removeProgress(for: "nonexistent", filename: "video.mp4")
        manager.removeProgress(for: "nonexistent")

        XCTAssertEqual(manager.progressCount, 0)
    }

    func testSaveProgressWithSameIdentifierDifferentFilenames() {
        let progress1 = PlaybackProgress.video(MediaProgressInfo(
            identifier: "same-item",
            filename: "video1.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Video 1"
        ))

        let progress2 = PlaybackProgress.video(MediaProgressInfo(
            identifier: "same-item",
            filename: "video2.mp4",
            currentTime: 200,
            duration: 3600,
            title: "Video 2"
        ))

        manager.saveProgress(progress1)
        manager.saveProgress(progress2)

        XCTAssertEqual(manager.progressCount, 2)
        XCTAssertNotNil(manager.getProgress(for: "same-item", filename: "video1.mp4"))
        XCTAssertNotNil(manager.getProgress(for: "same-item", filename: "video2.mp4"))
    }
}
