//
//  AudioQueueManagerTests.swift
//  Internet ArchiveTests
//
//  Unit tests for AudioQueueManager playlist functionality
//

import Testing
import Foundation
@testable import Internet_Archive

@Suite("AudioQueueManager Tests", .serialized)
@MainActor
struct AudioQueueManagerTests {

    var sut: AudioQueueManager
    var testTracks: [AudioTrack]

    init() throws {
        sut = AudioQueueManager.shared
        sut.clear()
        testTracks = try AudioQueueManagerTests.createTestTracks(count: 5)
    }

    // MARK: - Helper

    private static func createTestTracks(count: Int) throws -> [AudioTrack] {
        try (1...count).map { index in
            let streamURL = try #require(URL(string: "https://archive.org/download/test-item/track\(index).mp3"))
            return AudioTrack(
                id: "test-item/track\(index).mp3",
                itemIdentifier: "test-item",
                filename: "track\(index).mp3",
                trackNumber: index,
                title: "Track \(index)",
                artist: "Test Artist",
                album: "Test Album",
                duration: Double(180 + index * 30),
                streamURL: streamURL,
                thumbnailURL: nil
            )
        }
    }

    // MARK: - Queue Setup Tests

    @Test func setQueueSetsTracksAndCurrentIndex() {
        sut.setQueue(testTracks)

        #expect(sut.trackCount == 5)
        #expect(sut.currentTrack?.title == "Track 1")
        #expect(sut.currentPosition == 1)
    }

    @Test func setQueueWithStartIndexStartsAtSpecifiedTrack() {
        sut.setQueue(testTracks, startAt: 2)

        #expect(sut.currentTrack?.title == "Track 3")
        #expect(sut.currentPosition == 3)
    }

    @Test func setQueueWithInvalidStartIndexClampsToValidRange() {
        sut.setQueue(testTracks, startAt: 100)

        #expect(sut.currentTrack?.title == "Track 5")
    }

    @Test func clearResetsAllState() {
        sut.setQueue(testTracks, startAt: 2)
        sut.toggleShuffle()
        sut.cycleRepeatMode()

        sut.clear()

        #expect(sut.isEmpty)
        #expect(sut.trackCount == 0)
        #expect(sut.currentTrack == nil)
        #expect(!sut.isShuffled)
        #expect(sut.repeatMode == .off)
    }

    // MARK: - Navigation Tests

    @Test func nextAdvancesToNextTrack() {
        sut.setQueue(testTracks)

        let nextTrack = sut.next()

        #expect(nextTrack?.title == "Track 2")
        #expect(sut.currentTrack?.title == "Track 2")
    }

    @Test func nextAtEndOfQueueReturnsNilWhenRepeatOff() {
        sut.setQueue(testTracks, startAt: 4)

        let nextTrack = sut.next()

        #expect(nextTrack == nil)
    }

    @Test func nextAtEndOfQueueWrapsToBeginningWhenRepeatAll() {
        sut.setQueue(testTracks, startAt: 4)
        sut.setRepeatMode(.all)

        let nextTrack = sut.next()

        #expect(nextTrack?.title == "Track 1")
    }

    @Test func nextWhenRepeatOneStaysOnCurrentTrack() {
        sut.setQueue(testTracks, startAt: 2)
        sut.setRepeatMode(.one)

        let nextTrack = sut.next()

        #expect(nextTrack?.title == "Track 3")
        #expect(sut.currentTrack?.title == "Track 3")
    }

    @Test func previousGoesToPreviousTrack() {
        sut.setQueue(testTracks, startAt: 2)

        let prevTrack = sut.previous()

        #expect(prevTrack?.title == "Track 2")
    }

    @Test func previousAtBeginningReturnsCurrentTrackWhenRepeatOff() {
        sut.setQueue(testTracks, startAt: 0)

        let prevTrack = sut.previous()

        #expect(prevTrack?.title == "Track 1")
    }

    @Test func previousAtBeginningWrapsToEndWhenRepeatAll() {
        sut.setQueue(testTracks, startAt: 0)
        sut.setRepeatMode(.all)

        let prevTrack = sut.previous()

        #expect(prevTrack?.title == "Track 5")
    }

    @Test func jumpToIndexMovesToSpecifiedTrack() {
        sut.setQueue(testTracks)

        let track = sut.jumpTo(index: 3)

        #expect(track?.title == "Track 4")
        #expect(sut.currentPosition == 4)
    }

    @Test func jumpToIndexWithInvalidIndexReturnsNil() {
        sut.setQueue(testTracks)

        let track = sut.jumpTo(index: 10)

        #expect(track == nil)
    }

    @Test func jumpToTrackMovesToMatchingTrack() {
        sut.setQueue(testTracks)
        let targetTrack = testTracks[3]

        let track = sut.jumpTo(track: targetTrack)

        #expect(track?.title == "Track 4")
    }

    // MARK: - Shuffle Tests

    @Test func toggleShuffleEnablesShuffle() {
        sut.setQueue(testTracks)

        sut.toggleShuffle()

        #expect(sut.isShuffled)
    }

    @Test func toggleShuffleKeepsCurrentTrackFirst() {
        sut.setQueue(testTracks, startAt: 2)
        let currentBefore = sut.currentTrack

        sut.toggleShuffle()

        #expect(sut.currentTrack == currentBefore)
        #expect(sut.currentPosition == 1) // Current track moved to position 1
    }

    @Test func toggleShuffleDisablingRestoresOriginalOrder() {
        sut.setQueue(testTracks, startAt: 2)
        sut.toggleShuffle()

        sut.toggleShuffle()

        #expect(!sut.isShuffled)
        // Tracks should be back in original order
        #expect(sut.tracks.first?.title == "Track 1")
        #expect(sut.tracks.last?.title == "Track 5")
    }

    @Test func setQueueWithShuffleEnabledKeepsStartTrackFirst() throws {
        // Enable shuffle first, then set a new queue with a start index
        sut.setQueue(testTracks)
        sut.toggleShuffle()
        #expect(sut.isShuffled)

        // Create a new set of tracks and set queue starting at track 3
        let newTracks = try AudioQueueManagerTests.createTestTracks(count: 5)
        sut.setQueue(newTracks, startAt: 2)

        // The intended start track (Track 3) should be at position 0
        #expect(sut.currentTrack?.title == "Track 3")
        #expect(sut.currentPosition == 1)  // Position is 1-indexed
    }

    // MARK: - Repeat Mode Tests

    @Test func cycleRepeatModeCyclesThroughModes() {
        sut.setQueue(testTracks)

        #expect(sut.repeatMode == .off)

        sut.cycleRepeatMode()
        #expect(sut.repeatMode == .all)

        sut.cycleRepeatMode()
        #expect(sut.repeatMode == .one)

        sut.cycleRepeatMode()
        #expect(sut.repeatMode == .off)
    }

    @Test func setRepeatModeSetsSpecificMode() {
        sut.setQueue(testTracks)

        sut.setRepeatMode(.one)

        #expect(sut.repeatMode == .one)
    }

    // MARK: - Computed Properties Tests

    @Test func hasNextTrueWhenNotAtEnd() {
        sut.setQueue(testTracks, startAt: 0)

        #expect(sut.hasNext)
    }

    @Test func hasNextFalseAtEndWhenRepeatOff() {
        sut.setQueue(testTracks, startAt: 4)

        #expect(!sut.hasNext)
    }

    @Test func hasNextTrueAtEndWhenRepeatAll() {
        sut.setQueue(testTracks, startAt: 4)
        sut.setRepeatMode(.all)

        #expect(sut.hasNext)
    }

    @Test func hasPreviousFalseAtBeginningWhenRepeatOff() {
        sut.setQueue(testTracks, startAt: 0)

        #expect(!sut.hasPrevious)
    }

    @Test func hasPreviousTrueAtBeginningWhenRepeatAll() {
        sut.setQueue(testTracks, startAt: 0)
        sut.setRepeatMode(.all)

        #expect(sut.hasPrevious)
    }

    @Test func isEmptyTrueWhenNoTracks() {
        #expect(sut.isEmpty)
    }

    @Test func isEmptyFalseWhenTracksExist() {
        sut.setQueue(testTracks)

        #expect(!sut.isEmpty)
    }

    // MARK: - Edge Cases

    @Test func emptyQueueNavigationReturnsNil() {
        #expect(sut.next() == nil)
        #expect(sut.previous() == nil)
        #expect(sut.jumpTo(index: 0) == nil)
    }

    @Test func singleTrackRepeatOneWorks() {
        let singleTrack = [testTracks[0]]
        sut.setQueue(singleTrack)
        sut.setRepeatMode(.one)

        let nextTrack = sut.next()

        #expect(nextTrack?.title == "Track 1")
    }
}
