//
//  ContinueWatchingCardTests.swift
//  Internet ArchiveTests
//
//  Tests for ContinueWatchingCard, ContinueWatchingSection, and ContinueWatchingHelpers
//  Migrated to Swift Testing for Sprint 2
//

import Testing
import SwiftUI
@testable import Internet_Archive

// MARK: - ContinueWatchingCard Tests

@Suite("ContinueWatchingCard Tests")
@MainActor
struct ContinueWatchingCardTests {

    // MARK: - Test Helpers

    private func createVideoProgress(
        identifier: String = "test-video",
        currentTime: TimeInterval = 2700,
        duration: TimeInterval = 7200,
        title: String? = "Test Movie"
    ) -> PlaybackProgress {
        PlaybackProgress(
            itemIdentifier: identifier,
            filename: "movie.mp4",
            currentTime: currentTime,
            duration: duration,
            lastWatchedDate: Date(),
            title: title,
            mediaType: "movies",
            imageURL: nil
        )
    }

    private func createAudioProgress(
        identifier: String = "test-audio",
        currentTime: TimeInterval = 45,
        duration: TimeInterval = 100,
        title: String? = "Live Concert"
    ) -> PlaybackProgress {
        PlaybackProgress(
            itemIdentifier: identifier,
            filename: "album",
            currentTime: currentTime,
            duration: duration,
            lastWatchedDate: Date(),
            title: title,
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 3,
            trackFilename: "track04.mp3",
            trackCurrentTime: 180
        )
    }

    // MARK: - Initialization

    @Test("Card initializes with video progress and callback works")
    func initWithVideoProgress() {
        var tapped = false
        let progress = createVideoProgress()

        let card = ContinueWatchingCard(progress: progress) {
            tapped = true
        }

        #expect(card.progress.itemIdentifier == "test-video")
        card.onTap()
        #expect(tapped)
    }

    @Test("Card initializes with audio progress and callback works")
    func initWithAudioProgress() {
        var tapped = false
        let progress = createAudioProgress()

        let card = ContinueWatchingCard(progress: progress) {
            tapped = true
        }

        #expect(card.progress.isAudio)
        card.onTap()
        #expect(tapped)
    }

    // MARK: - Progress Properties

    @Test("Card stores progress correctly")
    func progressStored() {
        let progress = createVideoProgress(identifier: "my-movie")
        let card = ContinueWatchingCard(progress: progress) {}
        #expect(card.progress.itemIdentifier == "my-movie")
    }

    @Test("Card with video progress stores video media type")
    func videoProgressMediaType() {
        let progress = createVideoProgress()
        let card = ContinueWatchingCard(progress: progress) {}
        #expect(card.progress.mediaType == "movies")
    }

    @Test("Card with audio progress stores audio media type")
    func audioProgressMediaType() {
        let progress = createAudioProgress()
        let card = ContinueWatchingCard(progress: progress) {}
        #expect(card.progress.mediaType == "etree")
    }

    // MARK: - Tap Callback

    @Test("onTap callback fires multiple times")
    func onTapCalledMultipleTimes() {
        var tapCount = 0
        let progress = createVideoProgress()
        let card = ContinueWatchingCard(progress: progress) { tapCount += 1 }

        card.onTap()
        card.onTap()
        card.onTap()

        #expect(tapCount == 3)
    }

    // MARK: - Title

    @Test("Card stores title from progress")
    func titleFromProgress() {
        let progress = createVideoProgress(title: "My Movie Title")
        let card = ContinueWatchingCard(progress: progress) {}
        #expect(card.progress.title == "My Movie Title")
    }

    @Test("Nil title falls back to identifier")
    func nilTitleFallsBackToIdentifier() {
        let progress = PlaybackProgress(
            itemIdentifier: "fallback-identifier",
            filename: "file.mp4",
            currentTime: 100,
            duration: 1000,
            lastWatchedDate: Date(),
            title: nil,
            mediaType: "movies",
            imageURL: nil
        )
        let card = ContinueWatchingCard(progress: progress) {}
        #expect(card.progress.title == nil)
        #expect(card.progress.itemIdentifier == "fallback-identifier")
    }

    // MARK: - Progress Percentage (parameterized)

    @Test("Progress percentage calculated correctly",
          arguments: [
            (2700.0, 7200.0, 0.375),
            (3600.0, 7200.0, 0.5),
            (1800.0, 7200.0, 0.25),
            (0.0, 7200.0, 0.0),
            (7200.0, 7200.0, 1.0),
            (5.0, 10.0, 0.5),
            (43200.0, 86400.0, 0.5)
          ])
    func progressPercentage(currentTime: Double, duration: Double, expected: Double) {
        let progress = createVideoProgress(currentTime: currentTime, duration: duration)
        let card = ContinueWatchingCard(progress: progress) {}
        #expect(abs(card.progress.progressPercentage - expected) < 0.01)
    }

    // MARK: - Time Remaining

    @Test("Formatted time remaining contains 'remaining' for video")
    func formattedTimeRemainingVideo() {
        let progress = createVideoProgress(currentTime: 2700, duration: 7200)
        let card = ContinueWatchingCard(progress: progress) {}
        let formatted = card.progress.formattedTimeRemaining
        #expect(!formatted.isEmpty)
        #expect(formatted.contains("remaining"))
    }

    @Test("Formatted time remaining contains 'remaining' for audio")
    func formattedTimeRemainingAudio() {
        let progress = createAudioProgress(currentTime: 50, duration: 200)
        let card = ContinueWatchingCard(progress: progress) {}
        let formatted = card.progress.formattedTimeRemaining
        #expect(!formatted.isEmpty)
        #expect(formatted.contains("remaining"))
    }

    // MARK: - Edge Cases

    @Test("Very long title preserved")
    func veryLongTitle() {
        let longTitle = String(repeating: "Very Long Movie Title ", count: 10)
        let progress = createVideoProgress(title: longTitle)
        let card = ContinueWatchingCard(progress: progress) {}
        #expect(card.progress.title == longTitle)
    }

    @Test("Special characters in title preserved")
    func specialCharactersInTitle() {
        let progress = createVideoProgress(title: "Movie: Part II (2024) - Director's Cut™")
        let card = ContinueWatchingCard(progress: progress) {}
        #expect(card.progress.title == "Movie: Part II (2024) - Director's Cut™")
    }

    @Test("Empty title stored correctly")
    func emptyTitle() {
        let progress = createVideoProgress(title: "")
        let card = ContinueWatchingCard(progress: progress) {}
        #expect(card.progress.title == "")
    }
}

// MARK: - ContinueWatchingSection Tests

@Suite("ContinueWatchingSection Tests")
@MainActor
struct ContinueWatchingSectionTests {

    // MARK: - Test Helpers

    private func createVideoProgress(
        identifier: String = "test-video",
        currentTime: TimeInterval = 2700,
        duration: TimeInterval = 7200,
        lastWatchedDate: Date = Date(),
        title: String? = "Test Movie"
    ) -> PlaybackProgress {
        PlaybackProgress(
            itemIdentifier: identifier,
            filename: "movie.mp4",
            currentTime: currentTime,
            duration: duration,
            lastWatchedDate: lastWatchedDate,
            title: title,
            mediaType: "movies",
            imageURL: nil
        )
    }

    private func createAudioProgress(
        identifier: String = "test-audio",
        currentTime: TimeInterval = 45,
        duration: TimeInterval = 100,
        lastWatchedDate: Date = Date(),
        title: String? = "Live Concert"
    ) -> PlaybackProgress {
        PlaybackProgress(
            itemIdentifier: identifier,
            filename: "album",
            currentTime: currentTime,
            duration: duration,
            lastWatchedDate: lastWatchedDate,
            title: title,
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 3,
            trackFilename: "track04.mp3",
            trackCurrentTime: 180
        )
    }

    private func createMultipleItems() -> [PlaybackProgress] {
        [
            createVideoProgress(identifier: "video-1", currentTime: 1000, duration: 5000),
            createVideoProgress(identifier: "video-2", currentTime: 2000, duration: 6000),
            createAudioProgress(identifier: "audio-1", currentTime: 30, duration: 200),
            createVideoProgress(identifier: "video-3", currentTime: 4800, duration: 5000)
        ]
    }

    // MARK: - Initialization

    @Test("Section initializes with items and callback works")
    func initWithItems() {
        let items = createMultipleItems()
        var tappedItem: PlaybackProgress?

        let section = ContinueWatchingSection(
            items: items,
            mediaType: nil,
            onItemTap: { tappedItem = $0 }
        )

        section.onItemTap(items[0])
        #expect(tappedItem?.itemIdentifier == items[0].itemIdentifier)
    }

    @Test("Section initializes with video filter")
    func initWithVideoFilter() {
        let section = ContinueWatchingSection(
            items: createMultipleItems(),
            mediaType: .video,
            onItemTap: { _ in }
        )
        #expect(section.mediaType != nil)
    }

    @Test("Section initializes with audio filter")
    func initWithAudioFilter() {
        let section = ContinueWatchingSection(
            items: createMultipleItems(),
            mediaType: .audio,
            onItemTap: { _ in }
        )
        #expect(section.mediaType != nil)
    }

    @Test("Section initializes with empty items")
    func initWithEmptyItems() {
        let section = ContinueWatchingSection(
            items: [],
            mediaType: nil,
            onItemTap: { _ in }
        )
        #expect(section.items.isEmpty)
    }

    // MARK: - Media Filter

    @Test("Nil media type passes through")
    func mediaFilterNil() {
        let section = ContinueWatchingSection(
            items: createMultipleItems(),
            mediaType: nil,
            onItemTap: { _ in }
        )
        #expect(section.mediaType == nil)
    }

    // MARK: - Item Tap Callback

    @Test("onItemTap called with correct items")
    func onItemTapCalledWithCorrectItem() {
        let items = createMultipleItems()
        var tappedIdentifiers: [String] = []

        let section = ContinueWatchingSection(
            items: items,
            mediaType: nil,
            onItemTap: { tappedIdentifiers.append($0.itemIdentifier) }
        )

        section.onItemTap(items[0])
        section.onItemTap(items[1])

        #expect(tappedIdentifiers.count == 2)
        #expect(tappedIdentifiers[0] == items[0].itemIdentifier)
        #expect(tappedIdentifiers[1] == items[1].itemIdentifier)
    }

    // MARK: - Items Storage

    @Test("Section stores all items")
    func itemsStored() {
        let items = createMultipleItems()
        let section = ContinueWatchingSection(
            items: items,
            mediaType: nil,
            onItemTap: { _ in }
        )
        #expect(section.items.count == items.count)
    }

    @Test("Section handles single item")
    func singleItem() {
        let section = ContinueWatchingSection(
            items: [createVideoProgress()],
            mediaType: nil,
            onItemTap: { _ in }
        )
        #expect(section.items.count == 1)
    }

    @Test("Section handles many items")
    func manyItems() {
        let items = (0..<50).map { createVideoProgress(identifier: "video-\($0)") }
        let section = ContinueWatchingSection(
            items: items,
            mediaType: nil,
            onItemTap: { _ in }
        )
        #expect(section.items.count == 50)
    }

}

// MARK: - ContinueWatchingHelpers Tests

@Suite("ContinueWatchingHelpers Tests")
@MainActor
struct ContinueWatchingHelpersTests {

    // MARK: - Test Helpers

    private func createVideoProgress(
        identifier: String = "test-video",
        currentTime: TimeInterval = 2700,
        duration: TimeInterval = 7200,
        lastWatchedDate: Date = Date(),
        title: String? = "Test Movie"
    ) -> PlaybackProgress {
        PlaybackProgress(
            itemIdentifier: identifier,
            filename: "movie.mp4",
            currentTime: currentTime,
            duration: duration,
            lastWatchedDate: lastWatchedDate,
            title: title,
            mediaType: "movies",
            imageURL: nil
        )
    }

    private func createAudioProgress(
        identifier: String = "test-audio",
        currentTime: TimeInterval = 45,
        duration: TimeInterval = 100,
        lastWatchedDate: Date = Date(),
        title: String? = "Live Concert"
    ) -> PlaybackProgress {
        PlaybackProgress(
            itemIdentifier: identifier,
            filename: "album",
            currentTime: currentTime,
            duration: duration,
            lastWatchedDate: lastWatchedDate,
            title: title,
            mediaType: "etree",
            imageURL: nil,
            trackIndex: 3,
            trackFilename: "track04.mp3",
            trackCurrentTime: 180
        )
    }

    private func createCompletedProgress(
        identifier: String = "completed",
        isVideo: Bool = true
    ) -> PlaybackProgress {
        if isVideo {
            return PlaybackProgress(
                itemIdentifier: identifier,
                filename: "movie.mp4",
                currentTime: 9800,
                duration: 10000,
                lastWatchedDate: Date(),
                title: "Completed Movie",
                mediaType: "movies",
                imageURL: nil
            )
        } else {
            return PlaybackProgress(
                itemIdentifier: identifier,
                filename: "album",
                currentTime: 980,
                duration: 1000,
                lastWatchedDate: Date(),
                title: "Completed Album",
                mediaType: "etree",
                imageURL: nil
            )
        }
    }

    // MARK: - Filter Tests

    @Test("Excludes completed items (>95%)")
    func filterExcludesCompleted() {
        let items = [
            createVideoProgress(identifier: "active", currentTime: 500, duration: 1000),
            createCompletedProgress(identifier: "completed")
        ]
        let filtered = ContinueWatchingHelpers.filterProgressItems(items, mediaType: nil)
        #expect(filtered.count == 1)
        #expect(filtered.first?.itemIdentifier == "active")
    }

    @Test("Filters video only")
    func filterVideoOnly() {
        let items = [
            createVideoProgress(identifier: "video-1"),
            createAudioProgress(identifier: "audio-1"),
            createVideoProgress(identifier: "video-2")
        ]
        let filtered = ContinueWatchingHelpers.filterProgressItems(items, mediaType: .video)
        #expect(filtered.count == 2)
        #expect(filtered.allSatisfy { $0.isVideo })
    }

    @Test("Filters audio only")
    func filterAudioOnly() {
        let items = [
            createVideoProgress(identifier: "video-1"),
            createAudioProgress(identifier: "audio-1"),
            createAudioProgress(identifier: "audio-2")
        ]
        let filtered = ContinueWatchingHelpers.filterProgressItems(items, mediaType: .audio)
        #expect(filtered.count == 2)
        #expect(filtered.allSatisfy { $0.isAudio })
    }

    @Test("Nil media type shows all non-completed")
    func filterNilShowsAll() {
        let items = [
            createVideoProgress(identifier: "video-1"),
            createAudioProgress(identifier: "audio-1")
        ]
        let filtered = ContinueWatchingHelpers.filterProgressItems(items, mediaType: nil)
        #expect(filtered.count == 2)
    }

    @Test("Sorts by most recent first")
    func filterSortsByMostRecent() {
        let old = Date().addingTimeInterval(-3600)
        let recent = Date()
        let items = [
            createVideoProgress(identifier: "old", lastWatchedDate: old),
            createVideoProgress(identifier: "recent", lastWatchedDate: recent)
        ]
        let filtered = ContinueWatchingHelpers.filterProgressItems(items, mediaType: nil)
        #expect(filtered.first?.itemIdentifier == "recent")
        #expect(filtered.last?.itemIdentifier == "old")
    }

    @Test("Empty input returns empty")
    func filterEmptyInput() {
        let filtered = ContinueWatchingHelpers.filterProgressItems([], mediaType: nil)
        #expect(filtered.isEmpty)
    }

    @Test("All completed returns empty")
    func filterAllCompleted() {
        let items = [
            createCompletedProgress(identifier: "completed-1"),
            createCompletedProgress(identifier: "completed-2")
        ]
        let filtered = ContinueWatchingHelpers.filterProgressItems(items, mediaType: nil)
        #expect(filtered.isEmpty)
    }

    @Test("Combined filtering and sorting")
    func filterCombined() {
        let old = Date().addingTimeInterval(-3600)
        let recent = Date()
        let items = [
            createVideoProgress(identifier: "old-video", lastWatchedDate: old),
            createAudioProgress(identifier: "audio"),
            createVideoProgress(identifier: "recent-video", lastWatchedDate: recent),
            createCompletedProgress(identifier: "completed-video", isVideo: true)
        ]
        let filtered = ContinueWatchingHelpers.filterProgressItems(items, mediaType: .video)
        #expect(filtered.count == 2)
        #expect(filtered[0].itemIdentifier == "recent-video")
        #expect(filtered[1].itemIdentifier == "old-video")
    }

    // MARK: - Card Width Tests

    @Test("Card width for media types",
          arguments: [
            (ContinueWatchingSection.MediaFilter?.some(.video), CGFloat(350)),
            (ContinueWatchingSection.MediaFilter?.some(.audio), CGFloat(200)),
            (ContinueWatchingSection.MediaFilter?.none, CGFloat(350))
          ])
    func cardWidth(mediaType: ContinueWatchingSection.MediaFilter?, expected: CGFloat) {
        #expect(ContinueWatchingHelpers.cardWidth(for: mediaType) == expected)
    }

    // MARK: - Aspect Ratio Tests

    @Test("Video aspect ratio is 16:9")
    func aspectRatioVideo() {
        let ratio = ContinueWatchingHelpers.aspectRatio(isVideo: true)
        #expect(abs(ratio - 16.0 / 9.0) < 0.001)
    }

    @Test("Audio aspect ratio is 1:1")
    func aspectRatioAudio() {
        #expect(ContinueWatchingHelpers.aspectRatio(isVideo: false) == 1.0)
    }

    // MARK: - Accessibility Label Tests

    @Test("Accessibility label for video includes all components")
    func accessibilityLabelVideo() {
        let progress = createVideoProgress(currentTime: 3600, duration: 7200, title: "Test Movie")
        let label = ContinueWatchingHelpers.accessibilityLabel(for: progress)
        #expect(label.contains("Test Movie"))
        #expect(label.contains("Video"))
        #expect(label.contains("50% complete"))
    }

    @Test("Accessibility label for audio includes music")
    func accessibilityLabelAudio() {
        let progress = createAudioProgress(currentTime: 25, duration: 100, title: "Concert")
        let label = ContinueWatchingHelpers.accessibilityLabel(for: progress)
        #expect(label.contains("Concert"))
        #expect(label.contains("Music"))
        #expect(label.contains("25% complete"))
    }

    @Test("Accessibility label with nil title uses identifier")
    func accessibilityLabelNilTitle() {
        let progress = PlaybackProgress(
            itemIdentifier: "my-identifier",
            filename: "file.mp4",
            currentTime: 100,
            duration: 200,
            lastWatchedDate: Date(),
            title: nil,
            mediaType: "movies",
            imageURL: nil
        )
        let label = ContinueWatchingHelpers.accessibilityLabel(for: progress)
        #expect(label.contains("my-identifier"))
    }

    // MARK: - Section Accessibility Label Tests

    @Test("Section accessibility labels",
          arguments: [
            (ContinueWatchingSection.MediaFilter?.some(.video), 5, "Continue watching section with 5 items"),
            (ContinueWatchingSection.MediaFilter?.some(.audio), 3, "Continue listening section with 3 items"),
            (ContinueWatchingSection.MediaFilter?.none, 10, "Continue playing section with 10 items"),
            (ContinueWatchingSection.MediaFilter?.some(.video), 0, "Continue watching section with 0 items")
          ])
    func sectionAccessibilityLabel(
        mediaType: ContinueWatchingSection.MediaFilter?,
        itemCount: Int,
        expected: String
    ) {
        let label = ContinueWatchingHelpers.sectionAccessibilityLabel(
            mediaType: mediaType,
            itemCount: itemCount
        )
        #expect(label == expected)
    }

    // MARK: - Thumbnail URL Tests

    @Test("Thumbnail URL generated correctly")
    func thumbnailURLValid() {
        let url = ContinueWatchingHelpers.thumbnailURL(for: "my-movie-id")
        #expect(url?.absoluteString == "https://archive.org/services/img/my-movie-id")
    }

    @Test("Thumbnail URL with special characters")
    func thumbnailURLSpecialChars() {
        let url = ContinueWatchingHelpers.thumbnailURL(for: "movie-2024_version")
        #expect(url?.absoluteString == "https://archive.org/services/img/movie-2024_version")
    }
}
