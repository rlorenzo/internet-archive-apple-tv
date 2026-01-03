//
//  AudioQueueManagerTests.swift
//  Internet ArchiveTests
//
//  Unit tests for AudioQueueManager playlist functionality
//

import XCTest
@testable import Internet_Archive

@MainActor
final class AudioQueueManagerTests: XCTestCase {

    var sut: AudioQueueManager!
    var testTracks: [AudioTrack]!

    override func setUp() async throws {
        sut = AudioQueueManager.shared
        sut.clear()

        // Create test tracks
        testTracks = createTestTracks(count: 5)
    }

    override func tearDown() async throws {
        sut.clear()
    }

    // MARK: - Helper

    private func createTestTracks(count: Int) -> [AudioTrack] {
        (1...count).compactMap { index in
            guard let streamURL = URL(string: "https://archive.org/download/test-item/track\(index).mp3") else {
                XCTFail("Failed to create stream URL for track \(index)")
                return nil
            }
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

    func testSetQueue_setsTracksAndCurrentIndex() {
        sut.setQueue(testTracks)

        XCTAssertEqual(sut.trackCount, 5)
        XCTAssertEqual(sut.currentTrack?.title, "Track 1")
        XCTAssertEqual(sut.currentPosition, 1)
    }

    func testSetQueue_withStartIndex_startsAtSpecifiedTrack() {
        sut.setQueue(testTracks, startAt: 2)

        XCTAssertEqual(sut.currentTrack?.title, "Track 3")
        XCTAssertEqual(sut.currentPosition, 3)
    }

    func testSetQueue_withInvalidStartIndex_clampsToValidRange() {
        sut.setQueue(testTracks, startAt: 100)

        XCTAssertEqual(sut.currentTrack?.title, "Track 5")
    }

    func testClear_resetsAllState() {
        sut.setQueue(testTracks, startAt: 2)
        sut.toggleShuffle()
        sut.cycleRepeatMode()

        sut.clear()

        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.trackCount, 0)
        XCTAssertNil(sut.currentTrack)
        XCTAssertFalse(sut.isShuffled)
        XCTAssertEqual(sut.repeatMode, .off)
    }

    // MARK: - Navigation Tests

    func testNext_advancesToNextTrack() {
        sut.setQueue(testTracks)

        let nextTrack = sut.next()

        XCTAssertEqual(nextTrack?.title, "Track 2")
        XCTAssertEqual(sut.currentTrack?.title, "Track 2")
    }

    func testNext_atEndOfQueue_returnsNilWhenRepeatOff() {
        sut.setQueue(testTracks, startAt: 4)

        let nextTrack = sut.next()

        XCTAssertNil(nextTrack)
    }

    func testNext_atEndOfQueue_wrapsToBeginningWhenRepeatAll() {
        sut.setQueue(testTracks, startAt: 4)
        sut.setRepeatMode(.all)

        let nextTrack = sut.next()

        XCTAssertEqual(nextTrack?.title, "Track 1")
    }

    func testNext_whenRepeatOne_staysOnCurrentTrack() {
        sut.setQueue(testTracks, startAt: 2)
        sut.setRepeatMode(.one)

        let nextTrack = sut.next()

        XCTAssertEqual(nextTrack?.title, "Track 3")
        XCTAssertEqual(sut.currentTrack?.title, "Track 3")
    }

    func testPrevious_goesToPreviousTrack() {
        sut.setQueue(testTracks, startAt: 2)

        let prevTrack = sut.previous()

        XCTAssertEqual(prevTrack?.title, "Track 2")
    }

    func testPrevious_atBeginning_returnsCurrentTrackWhenRepeatOff() {
        sut.setQueue(testTracks, startAt: 0)

        let prevTrack = sut.previous()

        XCTAssertEqual(prevTrack?.title, "Track 1")
    }

    func testPrevious_atBeginning_wrapsToEndWhenRepeatAll() {
        sut.setQueue(testTracks, startAt: 0)
        sut.setRepeatMode(.all)

        let prevTrack = sut.previous()

        XCTAssertEqual(prevTrack?.title, "Track 5")
    }

    func testJumpToIndex_movesToSpecifiedTrack() {
        sut.setQueue(testTracks)

        let track = sut.jumpTo(index: 3)

        XCTAssertEqual(track?.title, "Track 4")
        XCTAssertEqual(sut.currentPosition, 4)
    }

    func testJumpToIndex_withInvalidIndex_returnsNil() {
        sut.setQueue(testTracks)

        let track = sut.jumpTo(index: 10)

        XCTAssertNil(track)
    }

    func testJumpToTrack_movesToMatchingTrack() {
        sut.setQueue(testTracks)
        let targetTrack = testTracks[3]

        let track = sut.jumpTo(track: targetTrack)

        XCTAssertEqual(track?.title, "Track 4")
    }

    // MARK: - Shuffle Tests

    func testToggleShuffle_enablesShuffle() {
        sut.setQueue(testTracks)

        sut.toggleShuffle()

        XCTAssertTrue(sut.isShuffled)
    }

    func testToggleShuffle_keepsCurrentTrackFirst() {
        sut.setQueue(testTracks, startAt: 2)
        let currentBefore = sut.currentTrack

        sut.toggleShuffle()

        XCTAssertEqual(sut.currentTrack, currentBefore)
        XCTAssertEqual(sut.currentPosition, 1) // Current track moved to position 1
    }

    func testToggleShuffle_disablingRestoresOriginalOrder() {
        sut.setQueue(testTracks, startAt: 2)
        sut.toggleShuffle()

        sut.toggleShuffle()

        XCTAssertFalse(sut.isShuffled)
        // Tracks should be back in original order
        XCTAssertEqual(sut.tracks.first?.title, "Track 1")
        XCTAssertEqual(sut.tracks.last?.title, "Track 5")
    }

    func testSetQueue_withShuffleEnabled_keepsStartTrackFirst() {
        // Enable shuffle first, then set a new queue with a start index
        sut.setQueue(testTracks)
        sut.toggleShuffle()
        XCTAssertTrue(sut.isShuffled)

        // Create a new set of tracks and set queue starting at track 3
        let newTracks = createTestTracks(count: 5)
        sut.setQueue(newTracks, startAt: 2)

        // The intended start track (Track 3) should be at position 0
        XCTAssertEqual(sut.currentTrack?.title, "Track 3")
        XCTAssertEqual(sut.currentPosition, 1)  // Position is 1-indexed
    }

    // MARK: - Repeat Mode Tests

    func testCycleRepeatMode_cyclesThroughModes() {
        sut.setQueue(testTracks)

        XCTAssertEqual(sut.repeatMode, .off)

        sut.cycleRepeatMode()
        XCTAssertEqual(sut.repeatMode, .all)

        sut.cycleRepeatMode()
        XCTAssertEqual(sut.repeatMode, .one)

        sut.cycleRepeatMode()
        XCTAssertEqual(sut.repeatMode, .off)
    }

    func testSetRepeatMode_setsSpecificMode() {
        sut.setQueue(testTracks)

        sut.setRepeatMode(.one)

        XCTAssertEqual(sut.repeatMode, .one)
    }

    // MARK: - Computed Properties Tests

    func testHasNext_trueWhenNotAtEnd() {
        sut.setQueue(testTracks, startAt: 0)

        XCTAssertTrue(sut.hasNext)
    }

    func testHasNext_falseAtEndWhenRepeatOff() {
        sut.setQueue(testTracks, startAt: 4)

        XCTAssertFalse(sut.hasNext)
    }

    func testHasNext_trueAtEndWhenRepeatAll() {
        sut.setQueue(testTracks, startAt: 4)
        sut.setRepeatMode(.all)

        XCTAssertTrue(sut.hasNext)
    }

    func testHasPrevious_falseAtBeginningWhenRepeatOff() {
        sut.setQueue(testTracks, startAt: 0)

        XCTAssertFalse(sut.hasPrevious)
    }

    func testHasPrevious_trueAtBeginningWhenRepeatAll() {
        sut.setQueue(testTracks, startAt: 0)
        sut.setRepeatMode(.all)

        XCTAssertTrue(sut.hasPrevious)
    }

    func testIsEmpty_trueWhenNoTracks() {
        XCTAssertTrue(sut.isEmpty)
    }

    func testIsEmpty_falseWhenTracksExist() {
        sut.setQueue(testTracks)

        XCTAssertFalse(sut.isEmpty)
    }

    // MARK: - Edge Cases

    func testEmptyQueue_navigationReturnsNil() {
        XCTAssertNil(sut.next())
        XCTAssertNil(sut.previous())
        XCTAssertNil(sut.jumpTo(index: 0))
    }

    func testSingleTrack_repeatOneWorks() {
        let singleTrack = [testTracks[0]]
        sut.setQueue(singleTrack)
        sut.setRepeatMode(.one)

        let nextTrack = sut.next()

        XCTAssertEqual(nextTrack?.title, "Track 1")
    }
}
