//
//  ContinueWatchingCardTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ContinueWatchingCard and ContinueWatchingSection SwiftUI components
//

import XCTest
import SwiftUI
@testable import Internet_Archive

@MainActor
final class ContinueWatchingCardTests: XCTestCase {

    // MARK: - Test Helpers

    /// Creates a video progress for testing
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

    /// Creates an audio progress for testing
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

    /// Creates multiple progress items for section testing
    private func createMultipleProgressItems() -> [PlaybackProgress] {
        [
            createVideoProgress(identifier: "video-1", currentTime: 1000, duration: 5000),
            createVideoProgress(identifier: "video-2", currentTime: 2000, duration: 6000),
            createAudioProgress(identifier: "audio-1", currentTime: 30, duration: 200),
            createVideoProgress(identifier: "video-3", currentTime: 4800, duration: 5000), // Near complete
        ]
    }

    // MARK: - ContinueWatchingCard Tests

    // MARK: Initialization

    func testContinueWatchingCard_initWithVideoProgress() {
        var tapped = false
        let progress = createVideoProgress()

        let card = ContinueWatchingCard(progress: progress) {
            tapped = true
        }

        XCTAssertNotNil(card)
        card.onTap()
        XCTAssertTrue(tapped)
    }

    func testContinueWatchingCard_initWithAudioProgress() {
        var tapped = false
        let progress = createAudioProgress()

        let card = ContinueWatchingCard(progress: progress) {
            tapped = true
        }

        XCTAssertNotNil(card)
        card.onTap()
        XCTAssertTrue(tapped)
    }

    // MARK: Progress Property Tests

    func testContinueWatchingCard_progressStored() {
        let progress = createVideoProgress(identifier: "my-movie")

        let card = ContinueWatchingCard(progress: progress) {}

        XCTAssertEqual(card.progress.itemIdentifier, "my-movie")
    }

    func testContinueWatchingCard_videoProgressIsVideo() {
        let progress = createVideoProgress()

        let card = ContinueWatchingCard(progress: progress) {}

        XCTAssertTrue(card.progress.isVideo)
        XCTAssertFalse(card.progress.isAudio)
    }

    func testContinueWatchingCard_audioProgressIsAudio() {
        let progress = createAudioProgress()

        let card = ContinueWatchingCard(progress: progress) {}

        XCTAssertTrue(card.progress.isAudio)
        XCTAssertFalse(card.progress.isVideo)
    }

    // MARK: Tap Callback Tests

    func testContinueWatchingCard_onTapCalled() {
        var tapCount = 0
        let progress = createVideoProgress()

        let card = ContinueWatchingCard(progress: progress) {
            tapCount += 1
        }

        card.onTap()
        card.onTap()
        card.onTap()

        XCTAssertEqual(tapCount, 3)
    }

    // MARK: Title Tests

    func testContinueWatchingCard_titleFromProgress() {
        let progress = createVideoProgress(title: "My Movie Title")

        let card = ContinueWatchingCard(progress: progress) {}

        XCTAssertEqual(card.progress.title, "My Movie Title")
    }

    func testContinueWatchingCard_nilTitleFallsBackToIdentifier() {
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

        XCTAssertNil(card.progress.title)
        XCTAssertEqual(card.progress.itemIdentifier, "fallback-identifier")
    }

    // MARK: Progress Percentage Tests

    func testContinueWatchingCard_progressPercentageHalfway() {
        let progress = createVideoProgress(currentTime: 3600, duration: 7200)

        let card = ContinueWatchingCard(progress: progress) {}

        XCTAssertEqual(card.progress.progressPercentage, 0.5, accuracy: 0.01)
    }

    func testContinueWatchingCard_progressPercentageQuarter() {
        let progress = createVideoProgress(currentTime: 1800, duration: 7200)

        let card = ContinueWatchingCard(progress: progress) {}

        XCTAssertEqual(card.progress.progressPercentage, 0.25, accuracy: 0.01)
    }

    func testContinueWatchingCard_progressPercentageZero() {
        let progress = createVideoProgress(currentTime: 0, duration: 7200)

        let card = ContinueWatchingCard(progress: progress) {}

        XCTAssertEqual(card.progress.progressPercentage, 0, accuracy: 0.01)
    }

    func testContinueWatchingCard_progressPercentageFull() {
        let progress = createVideoProgress(currentTime: 7200, duration: 7200)

        let card = ContinueWatchingCard(progress: progress) {}

        XCTAssertEqual(card.progress.progressPercentage, 1.0, accuracy: 0.01)
    }

    // MARK: - ContinueWatchingSection Tests

    // MARK: Initialization

    func testContinueWatchingSection_initWithItems() {
        let items = createMultipleProgressItems()
        var tappedItem: PlaybackProgress?

        let section = ContinueWatchingSection(
            items: items,
            mediaType: nil,
            onItemTap: { tappedItem = $0 }
        )

        XCTAssertNotNil(section)
        section.onItemTap(items[0])
        XCTAssertEqual(tappedItem?.itemIdentifier, items[0].itemIdentifier)
    }

    func testContinueWatchingSection_initWithVideoFilter() {
        let items = createMultipleProgressItems()

        let section = ContinueWatchingSection(
            items: items,
            mediaType: .video,
            onItemTap: { _ in }
        )

        XCTAssertNotNil(section)
    }

    func testContinueWatchingSection_initWithAudioFilter() {
        let items = createMultipleProgressItems()

        let section = ContinueWatchingSection(
            items: items,
            mediaType: .audio,
            onItemTap: { _ in }
        )

        XCTAssertNotNil(section)
    }

    func testContinueWatchingSection_initWithEmptyItems() {
        let section = ContinueWatchingSection(
            items: [],
            mediaType: nil,
            onItemTap: { _ in }
        )

        XCTAssertNotNil(section)
    }

    // MARK: Media Filter Tests

    func testContinueWatchingSection_mediaFilterNil() {
        let items = createMultipleProgressItems()

        let section = ContinueWatchingSection(
            items: items,
            mediaType: nil,
            onItemTap: { _ in }
        )

        XCTAssertNil(section.mediaType)
    }

    func testContinueWatchingSection_mediaFilterVideo() {
        let items = createMultipleProgressItems()

        let section = ContinueWatchingSection(
            items: items,
            mediaType: .video,
            onItemTap: { _ in }
        )

        XCTAssertNotNil(section.mediaType)
    }

    func testContinueWatchingSection_mediaFilterAudio() {
        let items = createMultipleProgressItems()

        let section = ContinueWatchingSection(
            items: items,
            mediaType: .audio,
            onItemTap: { _ in }
        )

        XCTAssertNotNil(section.mediaType)
    }

    // MARK: Item Tap Callback Tests

    func testContinueWatchingSection_onItemTapCalledWithCorrectItem() {
        let items = createMultipleProgressItems()
        var tappedIdentifiers: [String] = []

        let section = ContinueWatchingSection(
            items: items,
            mediaType: nil,
            onItemTap: { tappedIdentifiers.append($0.itemIdentifier) }
        )

        section.onItemTap(items[0])
        section.onItemTap(items[1])
        section.onItemTap(items[0])

        XCTAssertEqual(tappedIdentifiers.count, 3)
        XCTAssertEqual(tappedIdentifiers[0], items[0].itemIdentifier)
        XCTAssertEqual(tappedIdentifiers[1], items[1].itemIdentifier)
    }

    // MARK: Items Storage Tests

    func testContinueWatchingSection_itemsStored() {
        let items = createMultipleProgressItems()

        let section = ContinueWatchingSection(
            items: items,
            mediaType: nil,
            onItemTap: { _ in }
        )

        XCTAssertEqual(section.items.count, items.count)
    }

    // MARK: - Edge Cases

    func testContinueWatchingCard_veryLongTitle() {
        let longTitle = String(repeating: "Very Long Movie Title ", count: 10)
        let progress = createVideoProgress(title: longTitle)

        let card = ContinueWatchingCard(progress: progress) {}

        XCTAssertEqual(card.progress.title, longTitle)
    }

    func testContinueWatchingCard_specialCharactersInTitle() {
        let progress = createVideoProgress(title: "Movie: Part II (2024) - Director's Cut™")

        let card = ContinueWatchingCard(progress: progress) {}

        XCTAssertEqual(card.progress.title, "Movie: Part II (2024) - Director's Cut™")
    }

    func testContinueWatchingCard_emptyTitle() {
        let progress = createVideoProgress(title: "")

        let card = ContinueWatchingCard(progress: progress) {}

        XCTAssertEqual(card.progress.title, "")
    }

    func testContinueWatchingCard_veryLongDuration() {
        // 24 hour video
        let progress = createVideoProgress(currentTime: 43200, duration: 86400)

        let card = ContinueWatchingCard(progress: progress) {}

        XCTAssertEqual(card.progress.progressPercentage, 0.5, accuracy: 0.01)
    }

    func testContinueWatchingCard_veryShortDuration() {
        let progress = createVideoProgress(currentTime: 5, duration: 10)

        let card = ContinueWatchingCard(progress: progress) {}

        XCTAssertEqual(card.progress.progressPercentage, 0.5, accuracy: 0.01)
    }

    func testContinueWatchingSection_singleItem() {
        let items = [createVideoProgress()]

        let section = ContinueWatchingSection(
            items: items,
            mediaType: nil,
            onItemTap: { _ in }
        )

        XCTAssertEqual(section.items.count, 1)
    }

    func testContinueWatchingSection_manyItems() {
        var items: [PlaybackProgress] = []
        for idx in 0..<50 {
            items.append(createVideoProgress(identifier: "video-\(idx)"))
        }

        let section = ContinueWatchingSection(
            items: items,
            mediaType: nil,
            onItemTap: { _ in }
        )

        XCTAssertEqual(section.items.count, 50)
    }

    // MARK: - MediaFilter Enum Tests

    func testMediaFilter_videoCase() {
        let filter = ContinueWatchingSection.MediaFilter.video
        XCTAssertEqual(filter, .video)
    }

    func testMediaFilter_audioCase() {
        let filter = ContinueWatchingSection.MediaFilter.audio
        XCTAssertEqual(filter, .audio)
    }

    // MARK: - Time Remaining Tests

    func testContinueWatchingCard_formattedTimeRemaining() {
        let progress = createVideoProgress(currentTime: 2700, duration: 7200)

        let card = ContinueWatchingCard(progress: progress) {}

        // Should have time remaining formatted
        XCTAssertFalse(card.progress.formattedTimeRemaining.isEmpty)
    }

    func testContinueWatchingCard_audioFormattedTimeRemaining() {
        let progress = createAudioProgress(currentTime: 50, duration: 200)

        let card = ContinueWatchingCard(progress: progress) {}

        XCTAssertFalse(card.progress.formattedTimeRemaining.isEmpty)
    }
}
