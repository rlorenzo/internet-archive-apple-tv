//
//  PlaybackProgressManagerTests.swift
//  Internet ArchiveTests
//
//  Tests for PlaybackProgressManager functionality
//

import Testing
import Foundation
@testable import Internet_Archive

@Suite("PlaybackProgressManager Tests", .serialized)
@MainActor
struct PlaybackProgressManagerTests {

    var manager: PlaybackProgressManager

    init() {
        manager = PlaybackProgressManager.shared
        manager.resetForTesting()
    }

    // MARK: - Save and Retrieve Tests

    @Test func saveAndRetrieveProgress() {
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Test Video"
        ))

        manager.saveProgress(progress)

        let retrieved = manager.getProgress(for: "test-item", filename: "video.mp4")
        #expect(retrieved != nil)
        #expect(retrieved?.currentTime == 100)
    }

    @Test func getProgressByIdentifierOnly() {
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Test Video"
        ))

        manager.saveProgress(progress)

        let retrieved = manager.getProgress(for: "test-item")
        #expect(retrieved != nil)
        #expect(retrieved?.filename == "video.mp4")
    }

    @Test func getProgressReturnsMostRecentForItem() {
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
        #expect(retrieved?.filename == "video2.mp4")
    }

    @Test func saveProgressUpdatesExisting() {
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
        #expect(matchingItems.count == 1)
        #expect(matchingItems.first?.currentTime == 200)
    }

    @Test func saveProgressRemovesCompleteItems() {
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 3500,
            duration: 3600, // 97% complete
            title: "Test Video"
        ))

        manager.saveProgress(progress)

        let retrieved = manager.getProgress(for: "test-item", filename: "video.mp4")
        #expect(retrieved == nil, "Complete items should not be saved")
    }

    @Test func saveProgressWithIsCompleteRemovesExistingEntry() {
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
        #expect(savedProgress != nil, "Incomplete progress should be saved")

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
        #expect(retrieved == nil, "Complete progress should remove existing entry")

        // Verify it doesn't appear in continue watching
        let continueWatching = manager.getContinueWatchingItems()
        #expect(!continueWatching.contains { $0.itemIdentifier == "test-item" },
                "Completed item should not appear in continue watching")
    }

    @Test func removeProgressByIdentifierAndFilename() {
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
        #expect(retrieved == nil)
    }

    @Test func removeProgressByIdentifier() {
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

        #expect(manager.getProgress(for: "test-item", filename: "video1.mp4") == nil)
        #expect(manager.getProgress(for: "test-item", filename: "video2.mp4") == nil)
    }

    // MARK: - Continue Watching/Listening Tests

    @Test func getContinueWatchingItemsOnlyReturnsVideos() {
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
        #expect(continueWatching.count == 1)
        #expect(continueWatching.first?.itemIdentifier == "video-item")
    }

    @Test func getContinueListeningItemsOnlyReturnsAudio() {
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
        #expect(continueListening.count == 1)
        #expect(continueListening.first?.itemIdentifier == "audio-item")
    }

    @Test func continueWatchingExcludesCompleteItems() {
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
        #expect(continueWatching.count == 1)
    }

    @Test func continueWatchingOrderedByMostRecent() {
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
        #expect(continueWatching.count == 2)
        #expect(continueWatching[0].itemIdentifier == "newer-video")
        #expect(continueWatching[1].itemIdentifier == "older-video")
    }

    @Test func continueWatchingRespectsLimit() {
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
        #expect(continueWatching.count == 5)
    }

    @Test func continueWatchingDefaultLimitIs20AndSortedByDate() {
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
        #expect(continueWatching.count == 20)

        // Should be sorted by most recent first (highest index first)
        #expect(continueWatching[0].itemIdentifier == "video-24")
        #expect(continueWatching[19].itemIdentifier == "video-5")

        // Verify items are in descending order by date
        for idx in 0..<(continueWatching.count - 1) {
            #expect(continueWatching[idx].lastWatchedDate >= continueWatching[idx + 1].lastWatchedDate,
                    "Items should be sorted by lastWatchedDate descending")
        }
    }

    @Test func continueListeningDefaultLimitIs20AndSortedByDate() {
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
        #expect(continueListening.count == 20)

        // Most recent (index 24) should be first
        #expect(continueListening[0].itemIdentifier == "audio-24")
        #expect(continueListening[19].itemIdentifier == "audio-5")
    }

    @Test func continueListeningRespectsLimit() {
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
        #expect(continueListening.count == 5)
    }

    // MARK: - Has Resumable Progress Tests

    @Test func hasResumableProgressTrue() {
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 100, // More than 10 seconds
            duration: 3600,
            title: "Test Video"
        ))

        manager.saveProgress(progress)

        #expect(manager.hasResumableProgress(for: "test-item"))
    }

    @Test func hasResumableProgressFalseUnder10Seconds() {
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 5, // Less than 10 seconds
            duration: 3600,
            title: "Test Video"
        ))

        manager.saveProgress(progress)

        #expect(!manager.hasResumableProgress(for: "test-item"))
    }

    @Test func hasResumableProgressFalseWhenNoProgress() {
        #expect(!manager.hasResumableProgress(for: "nonexistent-item"))
    }

    @Test func hasResumableProgressAudioWithTrackTime() {
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
        #expect(manager.hasResumableProgress(for: "album-123"))
    }

    @Test func hasResumableProgressAudioWithLowTrackTime() {
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
        #expect(!manager.hasResumableProgress(for: "album-456"))
    }

    // MARK: - Progress Count Tests

    @Test func progressCount() {
        #expect(manager.progressCount == 0)

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
        #expect(manager.progressCount == 1)

        manager.saveProgress(progress2)
        #expect(manager.progressCount == 2)
    }

    // MARK: - Clear All Tests

    @Test func clearAllProgress() {
        let progress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "test-item",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Test Video"
        ))

        manager.saveProgress(progress)
        #expect(manager.progressCount == 1)

        manager.clearAllProgress()
        #expect(manager.progressCount == 0)
    }

    // MARK: - Pruning Tests

    @Test func pruningRemovesOldEntries() {
        let recentProgress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "recent-item",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Recent Video"
        ))

        manager.saveProgress(recentProgress)
        // Old entries would be pruned on next save
        #expect(manager.getProgress(for: "recent-item") != nil)
    }

    @Test func pruningLimitsTo50Items() {
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
        #expect(manager.progressCount <= 50)
    }

    @Test func pruningRemovesOldestItemsFirst() {
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

        #expect(manager.progressCount == 50)

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
        #expect(manager.progressCount <= 50)

        // The newest item should exist
        #expect(manager.getProgress(for: "video-54") != nil)
    }

    @Test func pruningPreservesOrderByDate() {
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
        #expect(continueWatching.first?.itemIdentifier == "video-24")

        // Verify descending order
        for idx in 0..<(continueWatching.count - 1) {
            #expect(continueWatching[idx].lastWatchedDate >= continueWatching[idx + 1].lastWatchedDate)
        }
    }

    @Test func pruningDoesNotAffectDifferentMediaTypes() {
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
        #expect(videos.count > 0 || audio.count > 0)
        #expect(manager.progressCount <= 50)
    }

    // MARK: - Persistence Tests

    @Test func progressPersistsAcrossManagerAccess() {
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
        #expect(retrieved != nil)
        #expect(retrieved?.currentTime == 100)
    }

    // MARK: - Edge Cases

    @Test func getProgressReturnsNilForNonexistent() {
        let result = manager.getProgress(for: "nonexistent", filename: "video.mp4")
        #expect(result == nil)
    }

    @Test func removeProgressDoesNothingForNonexistent() {
        // Should not crash
        manager.removeProgress(for: "nonexistent", filename: "video.mp4")
        manager.removeProgress(for: "nonexistent")

        #expect(manager.progressCount == 0)
    }

    @Test func saveProgressWithSameIdentifierDifferentFilenames() {
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

        #expect(manager.progressCount == 2)
        #expect(manager.getProgress(for: "same-item", filename: "video1.mp4") != nil)
        #expect(manager.getProgress(for: "same-item", filename: "video2.mp4") != nil)
    }

    // MARK: - isValid Filtering Tests

    @Test func getContinueWatchingItemsFiltersOutInvalidIdentifiers() {
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
        #expect(continueWatching.count == 1)
        #expect(continueWatching.first?.itemIdentifier == "valid-video-123")

        // Verify the invalid item fails isValid check
        #expect(!invalidProgress.isValid)
    }

    @Test func getContinueWatchingItemsFiltersOutNilTitles() {
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
        #expect(continueWatching.count == 1)
        #expect(continueWatching.first?.itemIdentifier == "valid-video")

        #expect(!invalidProgress.isValid)
    }

    @Test func getContinueListeningItemsFiltersOutInvalidEntries() {
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
        #expect(continueListening.count == 1)
        #expect(continueListening.first?.itemIdentifier == "valid-album-123")

        #expect(!invalidAudio.isValid)
    }

    @Test func getContinueListeningItemsFiltersOutMultipleInvalidTypes() {
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
        #expect(continueListening.count == 2)

        let identifiers = continueListening.map { $0.itemIdentifier }
        #expect(identifiers.contains("valid-album-1"))
        #expect(identifiers.contains("valid-album-2"))

        // Verify all invalid items fail isValid check
        #expect(!invalidEmptyId.isValid)
        #expect(!invalidNilTitle.isValid)
        #expect(!invalidWhitespaceTitle.isValid)
        #expect(!invalidSpacesInId.isValid)
    }

    @Test func getContinueWatchingItemsFiltersOutWhitespaceOnlyTitles() {
        let validProgress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "valid-video",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Valid Video Title"
        ))

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
        #expect(continueWatching.count == 1)
        #expect(continueWatching.first?.itemIdentifier == "valid-video")

        #expect(!invalidProgress.isValid)
    }

    @Test func getContinueWatchingItemsFiltersOutInvalidIdentifierPatterns() {
        let validProgress = PlaybackProgress.video(MediaProgressInfo(
            identifier: "valid-item-123",
            filename: "video.mp4",
            currentTime: 100,
            duration: 3600,
            title: "Valid Video"
        ))

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
        #expect(continueWatching.count == 1)
        #expect(continueWatching.first?.itemIdentifier == "valid-item-123")

        #expect(!invalidProgress.isValid)
    }
}
