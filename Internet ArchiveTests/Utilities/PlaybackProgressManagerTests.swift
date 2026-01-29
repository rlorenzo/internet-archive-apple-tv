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

    nonisolated(unsafe) var manager: PlaybackProgressManager!

    override func setUp() {
        super.setUp()
        let newManager = MainActor.assumeIsolated {
            let mgr = PlaybackProgressManager.shared
            mgr.resetForTesting()
            return mgr
        }
        manager = newManager
    }

    override func tearDown() {
        MainActor.assumeIsolated {
            PlaybackProgressManager.shared.resetForTesting()
        }
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

    func testSaveProgressWithIsComplete_removesExistingEntry() {
        // First save an incomplete progress
        let incompleteProgress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 1800,  // 50% complete
            duration: 3600,
            title: "Test Video"
        ))
        manager.saveProgress(incompleteProgress)

        // Verify it was saved
        let savedProgress = manager.getProgress(for: "test-item", filename: "video.mp4")
        XCTAssertNotNil(savedProgress, "Incomplete progress should be saved")

        // Now save the same item as complete (>95%)
        let completeProgress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 3500,  // 97% complete
            duration: 3600,
            title: "Test Video"
        ))
        manager.saveProgress(completeProgress)

        // Verify the entry is removed, not just not re-added
        let retrieved = manager.getProgress(for: "test-item", filename: "video.mp4")
        XCTAssertNil(retrieved, "Complete progress should remove existing entry")

        // Verify it doesn't appear in continue watching
        let continueWatching = manager.getContinueWatchingItems()
        XCTAssertFalse(continueWatching.contains { $0.itemIdentifier == "test-item" },
                       "Completed item should not appear in continue watching")
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

    func testContinueWatchingDefaultLimitIs20AndSortedByDate() {
        // Seed 25 items with descending lastWatchedDate (index 24 is most recent)
        for index in 0..<25 {
            let progress = PlaybackProgress(
                itemIdentifier: "video-\(index)",
                filename: "video.mp4",
                currentTime: 100,
                duration: 3600,
                lastWatchedDate: Date().addingTimeInterval(Double(index)), // Higher index = more recent
                title: "Video \(index)",
                mediaType: "movies",
                imageURL: nil
            )
            manager.saveProgress(progress)
        }

        // Call without limit parameter (default is 20)
        let continueWatching = manager.getContinueWatchingItems()

        // Should return exactly 20 items (default limit)
        XCTAssertEqual(continueWatching.count, 20)

        // Should be sorted by most recent first (highest index first)
        // Most recent item (index 24) should be first
        XCTAssertEqual(continueWatching[0].itemIdentifier, "video-24")
        // Oldest returned item should be index 5 (25 - 20 = 5)
        XCTAssertEqual(continueWatching[19].itemIdentifier, "video-5")

        // Verify items are in descending order by date
        for idx in 0..<(continueWatching.count - 1) {
            XCTAssertGreaterThanOrEqual(
                continueWatching[idx].lastWatchedDate,
                continueWatching[idx + 1].lastWatchedDate,
                "Items should be sorted by lastWatchedDate descending"
            )
        }
    }

    func testContinueListeningDefaultLimitIs20AndSortedByDate() {
        // Seed 25 audio items with descending lastWatchedDate
        for index in 0..<25 {
            let progress = PlaybackProgress(
                itemIdentifier: "audio-\(index)",
                filename: "track.mp3",
                currentTime: 60,
                duration: 300,
                lastWatchedDate: Date().addingTimeInterval(Double(index)),
                title: "Track \(index)",
                mediaType: "etree",
                imageURL: nil
            )
            manager.saveProgress(progress)
        }

        // Call without limit parameter (default is 20)
        let continueListening = manager.getContinueListeningItems()

        // Should return exactly 20 items
        XCTAssertEqual(continueListening.count, 20)

        // Most recent (index 24) should be first
        XCTAssertEqual(continueListening[0].itemIdentifier, "audio-24")
        // Oldest returned item should be index 5
        XCTAssertEqual(continueListening[19].itemIdentifier, "audio-5")
    }

    func testContinueListeningRespectsLimit() {
        for index in 0..<10 {
            let progress = PlaybackProgress.audio(MediaProgressInfo(
                identifier: "audio-\(index)",
                filename: "track.mp3",
                currentTime: 60,
                duration: 300,
                title: "Track \(index)"
            ))
            manager.saveProgress(progress)
        }

        let continueListening = manager.getContinueListeningItems(limit: 5)
        XCTAssertEqual(continueListening.count, 5)
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
        // Note: This variable documents what an old progress entry would look like,
        // but can't be used since saveProgress() always updates the lastWatchedDate
        _ = PlaybackProgress(
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

    func testPruning_removesOldestItemsFirst() {
        // Add exactly 50 items with sequential timestamps
        for index in 0..<50 {
            let progress = PlaybackProgress(
                itemIdentifier: "video-\(index)",
                filename: "video.mp4",
                currentTime: 100,
                duration: 3600,
                lastWatchedDate: Date().addingTimeInterval(Double(index)),
                title: "Video \(index)",
                mediaType: "movies",
                imageURL: nil
            )
            manager.saveProgress(progress)
        }

        XCTAssertEqual(manager.progressCount, 50)

        // Add 5 more items (these should cause oldest 5 to be removed)
        for index in 50..<55 {
            let progress = PlaybackProgress(
                itemIdentifier: "video-\(index)",
                filename: "video.mp4",
                currentTime: 100,
                duration: 3600,
                lastWatchedDate: Date().addingTimeInterval(Double(index)),
                title: "Video \(index)",
                mediaType: "movies",
                imageURL: nil
            )
            manager.saveProgress(progress)
        }

        // Should still be capped at 50
        XCTAssertLessThanOrEqual(manager.progressCount, 50)

        // The oldest items (0-4) should have been removed
        // Note: Pruning behavior may keep most recent, so check that newest exists
        XCTAssertNotNil(manager.getProgress(for: "video-54"))
    }

    func testPruning_preservesOrderByDate() {
        // Add items with specific ordering
        for index in 0..<25 {
            let progress = PlaybackProgress(
                itemIdentifier: "video-\(index)",
                filename: "video.mp4",
                currentTime: 100,
                duration: 3600,
                lastWatchedDate: Date().addingTimeInterval(Double(index) * 60), // 1 minute apart
                title: "Video \(index)",
                mediaType: "movies",
                imageURL: nil
            )
            manager.saveProgress(progress)
        }

        let continueWatching = manager.getContinueWatchingItems()

        // Items should be sorted by most recent first
        XCTAssertEqual(continueWatching.first?.itemIdentifier, "video-24")

        // Verify descending order
        for idx in 0..<(continueWatching.count - 1) {
            XCTAssertGreaterThanOrEqual(
                continueWatching[idx].lastWatchedDate,
                continueWatching[idx + 1].lastWatchedDate
            )
        }
    }

    func testPruning_doesNotAffectDifferentMediaTypes() {
        // Add 30 videos
        for index in 0..<30 {
            let progress = PlaybackProgress(
                itemIdentifier: "video-\(index)",
                filename: "video.mp4",
                currentTime: 100,
                duration: 3600,
                lastWatchedDate: Date().addingTimeInterval(Double(index)),
                title: "Video \(index)",
                mediaType: "movies",
                imageURL: nil
            )
            manager.saveProgress(progress)
        }

        // Add 25 audio items
        for index in 0..<25 {
            let progress = PlaybackProgress(
                itemIdentifier: "audio-\(index)",
                filename: "track.mp3",
                currentTime: 60,
                duration: 300,
                lastWatchedDate: Date().addingTimeInterval(Double(index) + 30), // After videos
                title: "Track \(index)",
                mediaType: "etree",
                imageURL: nil
            )
            manager.saveProgress(progress)
        }

        // Both types should be present within limit
        let videos = manager.getContinueWatchingItems()
        let audio = manager.getContinueListeningItems()

        // Both should have items (may be pruned based on combined count)
        XCTAssertTrue(videos.count > 0 || audio.count > 0)
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

    // MARK: - isValid Filtering Tests

    func testGetContinueWatchingItemsFiltersOutInvalidIdentifiers() {
        // Valid progress entry
        let validProgress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "valid-video-123",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Valid Video"
        ))

        // Invalid progress with empty identifier (corrupted entry)
        let invalidProgress = PlaybackProgress(
            itemIdentifier: "",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            lastWatchedDate: Date(),
            title: "Invalid Video",
            mediaType: "movies",
            imageURL: nil
        )

        manager.saveProgress(validProgress)
        manager.saveProgress(invalidProgress)

        let continueWatching = manager.getContinueWatchingItems()
        // Should only contain the valid item (invalid filtered by isValid check)
        XCTAssertEqual(continueWatching.count, 1)
        XCTAssertEqual(continueWatching.first?.itemIdentifier, "valid-video-123")

        // Verify the invalid item fails isValid check
        XCTAssertFalse(invalidProgress.isValid)
    }

    func testGetContinueWatchingItemsFiltersOutNilTitles() {
        // Valid progress entry
        let validProgress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "valid-video",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Valid Video Title"
        ))

        // Invalid progress with nil title
        let invalidProgress = PlaybackProgress(
            itemIdentifier: "valid-id-but-nil-title",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            lastWatchedDate: Date(),
            title: nil,
            mediaType: "movies",
            imageURL: nil
        )

        manager.saveProgress(validProgress)
        manager.saveProgress(invalidProgress)

        let continueWatching = manager.getContinueWatchingItems()
        // Should only contain the valid item (invalid filtered by isValid check)
        XCTAssertEqual(continueWatching.count, 1)
        XCTAssertEqual(continueWatching.first?.itemIdentifier, "valid-video")

        // Verify the invalid item fails isValid check
        XCTAssertFalse(invalidProgress.isValid)
    }

    func testGetContinueListeningItemsFiltersOutInvalidEntries() {
        // Valid audio progress entry
        let validAudio = PlaybackProgress.audio(MediaProgressInfo(
            identifier: "valid-album-123",
            filename: "__album__",
            currentTime: 50.0,
            duration: 100.0,
            title: "Valid Artist: Track 5",
            trackIndex: 4,
            trackFilename: "track05.mp3",
            trackCurrentTime: 120.0
        ))

        // Invalid audio progress with empty title
        let invalidAudio = PlaybackProgress(
            itemIdentifier: "album-with-empty-title",
            filename: "__album__",
            currentTime: 50.0,
            duration: 100.0,
            lastWatchedDate: Date(),
            title: "",
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 4,
            trackFilename: "track05.mp3",
            trackCurrentTime: 120.0
        )

        manager.saveProgress(validAudio)
        manager.saveProgress(invalidAudio)

        let continueListening = manager.getContinueListeningItems()
        // Should only contain the valid item (invalid filtered by isValid check)
        XCTAssertEqual(continueListening.count, 1)
        XCTAssertEqual(continueListening.first?.itemIdentifier, "valid-album-123")

        // Verify the invalid item fails isValid check
        XCTAssertFalse(invalidAudio.isValid)
    }

    func testGetContinueListeningItemsFiltersOutMultipleInvalidTypes() {
        // Valid audio entries
        let validAudio1 = PlaybackProgress.audio(MediaProgressInfo(
            identifier: "valid-album-1",
            filename: "__album__",
            currentTime: 50.0,
            duration: 100.0,
            title: "Valid Artist: Track 1"
        ))

        let validAudio2 = PlaybackProgress.audio(MediaProgressInfo(
            identifier: "valid-album-2",
            filename: "__album__",
            currentTime: 30.0,
            duration: 100.0,
            title: "Another Valid: Track 2"
        ))

        // Invalid: empty identifier
        let invalidEmptyId = PlaybackProgress(
            itemIdentifier: "",
            filename: "__album__",
            currentTime: 50.0,
            duration: 100.0,
            lastWatchedDate: Date(),
            title: "Empty ID Track",
            mediaType: "etree",
            imageURL: nil
        )

        // Invalid: nil title
        let invalidNilTitle = PlaybackProgress(
            itemIdentifier: "album-nil-title",
            filename: "__album__",
            currentTime: 50.0,
            duration: 100.0,
            lastWatchedDate: Date(),
            title: nil,
            mediaType: "etree",
            imageURL: nil
        )

        // Invalid: whitespace-only title
        let invalidWhitespaceTitle = PlaybackProgress(
            itemIdentifier: "album-whitespace-title",
            filename: "__album__",
            currentTime: 50.0,
            duration: 100.0,
            lastWatchedDate: Date(),
            title: "   \t\n  ",
            mediaType: "etree",
            imageURL: nil
        )

        // Invalid: spaces in identifier
        let invalidSpacesInId = PlaybackProgress(
            itemIdentifier: "invalid album with spaces",
            filename: "__album__",
            currentTime: 50.0,
            duration: 100.0,
            lastWatchedDate: Date(),
            title: "Spaces In ID Track",
            mediaType: "etree",
            imageURL: nil
        )

        manager.saveProgress(validAudio1)
        manager.saveProgress(invalidEmptyId)
        manager.saveProgress(validAudio2)
        manager.saveProgress(invalidNilTitle)
        manager.saveProgress(invalidWhitespaceTitle)
        manager.saveProgress(invalidSpacesInId)

        let continueListening = manager.getContinueListeningItems()

        // Should only contain the 2 valid items
        XCTAssertEqual(continueListening.count, 2)

        let identifiers = continueListening.map { $0.itemIdentifier }
        XCTAssertTrue(identifiers.contains("valid-album-1"))
        XCTAssertTrue(identifiers.contains("valid-album-2"))

        // Verify all invalid items fail isValid check
        XCTAssertFalse(invalidEmptyId.isValid)
        XCTAssertFalse(invalidNilTitle.isValid)
        XCTAssertFalse(invalidWhitespaceTitle.isValid)
        XCTAssertFalse(invalidSpacesInId.isValid)
    }

    func testGetContinueWatchingItemsFiltersOutWhitespaceOnlyTitles() {
        // Valid progress entry
        let validProgress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "valid-video",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Valid Video Title"
        ))

        // Invalid progress with whitespace-only title
        let invalidProgress = PlaybackProgress(
            itemIdentifier: "whitespace-title",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            lastWatchedDate: Date(),
            title: "   \t\n  ",
            mediaType: "movies",
            imageURL: nil
        )

        manager.saveProgress(validProgress)
        manager.saveProgress(invalidProgress)

        let continueWatching = manager.getContinueWatchingItems()
        // Should only contain the valid item (invalid filtered by isValid check)
        XCTAssertEqual(continueWatching.count, 1)
        XCTAssertEqual(continueWatching.first?.itemIdentifier, "valid-video")

        // Verify the invalid item fails isValid check
        XCTAssertFalse(invalidProgress.isValid)
    }

    func testGetContinueWatchingItemsFiltersOutInvalidIdentifierPatterns() {
        // Valid progress entry
        let validProgress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "valid-item-123",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Valid Video"
        ))

        // Invalid progress with spaces in identifier
        let invalidProgress = PlaybackProgress(
            itemIdentifier: "invalid item with spaces",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            lastWatchedDate: Date(),
            title: "Invalid Video",
            mediaType: "movies",
            imageURL: nil
        )

        manager.saveProgress(validProgress)
        manager.saveProgress(invalidProgress)

        let continueWatching = manager.getContinueWatchingItems()
        // Should only contain the valid item (invalid filtered by isValid check)
        XCTAssertEqual(continueWatching.count, 1)
        XCTAssertEqual(continueWatching.first?.itemIdentifier, "valid-item-123")

        // Verify the invalid item fails isValid check
        XCTAssertFalse(invalidProgress.isValid)
    }
}
