//
//  TrackListCellTests.swift
//  Internet ArchiveTests
//
//  Tests for TrackListCell - a UICollectionViewCell for displaying audio tracks
//

import Testing
import UIKit
@testable import Internet_Archive

@Suite("TrackListCell Tests")
@MainActor
struct TrackListCellTests {

    // MARK: - Helpers

    private func makeCell() -> TrackListCell {
        TrackListCell(frame: CGRect(x: 0, y: 0, width: 800, height: 60))
    }

    private func makeTrack(
        trackNumber: Int? = 1,
        title: String = "Test Track",
        artist: String? = "Test Artist",
        duration: Double? = 225  // 3:45
    ) -> AudioTrack {
        AudioTrack(
            id: "test_item/track.mp3",
            itemIdentifier: "test_item",
            filename: "track.mp3",
            trackNumber: trackNumber,
            title: title,
            artist: artist,
            album: "Test Album",
            duration: duration,
            streamURL: URL(string: "https://archive.org/download/test_item/track.mp3")!,
            thumbnailURL: nil
        )
    }

    // MARK: - Reuse Identifier

    @Test("Static reuseIdentifier equals TrackListCell")
    func reuseIdentifierIsSet() {
        #expect(TrackListCell.reuseIdentifier == "TrackListCell")
    }

    // MARK: - Initialization

    @Test("Cell initializes with frame without crashing")
    func initWithFrame() {
        let cell = makeCell()
        #expect(cell.frame.width == 800)
        #expect(cell.frame.height == 60)
    }

    @Test("Cell contentView has subviews after init")
    func contentViewHasSubviews() {
        let cell = makeCell()
        #expect(!cell.contentView.subviews.isEmpty)
    }

    // MARK: - Configuration: Accessibility Label

    @Test("Configure sets accessibility label containing track number")
    func configureDisplaysTrackNumber() {
        let cell = makeCell()
        let track = makeTrack(trackNumber: 5)
        cell.configure(with: track, isPlaying: false)
        #expect(cell.accessibilityLabel?.contains("Track 5") == true)
    }

    @Test("Configure sets accessibility label containing title")
    func configureDisplaysTitle() {
        let cell = makeCell()
        let track = makeTrack(title: "My Song")
        cell.configure(with: track, isPlaying: false)
        #expect(cell.accessibilityLabel?.contains("My Song") == true)
    }

    @Test("Configure sets accessibility label containing formatted duration")
    func configureDisplaysDuration() {
        let cell = makeCell()
        let track = makeTrack(duration: 225)  // 3:45
        cell.configure(with: track, isPlaying: false)
        #expect(cell.accessibilityLabel?.contains("3:45") == true)
    }

    @Test("Configure with nil track number omits Track prefix from accessibility label")
    func configureWithNilTrackNumber() {
        let cell = makeCell()
        let track = makeTrack(trackNumber: nil, title: "My Song")
        cell.configure(with: track, isPlaying: false)
        #expect(cell.accessibilityLabel?.contains("Track") != true)
    }

    @Test("Configure with nil duration shows placeholder duration")
    func configureWithNilDuration() {
        let cell = makeCell()
        let track = makeTrack(duration: nil)
        cell.configure(with: track, isPlaying: false)
        #expect(cell.accessibilityLabel?.contains("--:--") == true)
    }

    @Test("Accessibility label format is comma-separated components")
    func accessibilityLabelFormat() {
        let cell = makeCell()
        let track = makeTrack(trackNumber: 3, title: "Blue Moon", duration: 185)
        cell.configure(with: track, isPlaying: false)
        // Expected: "Track 3, Blue Moon, 3:05"
        #expect(cell.accessibilityLabel == "Track 3, Blue Moon, 3:05")
    }

    @Test("Accessibility label without track number omits track component")
    func accessibilityLabelWithoutTrackNumber() {
        let cell = makeCell()
        let track = makeTrack(trackNumber: nil, title: "Intro", duration: 60)
        cell.configure(with: track, isPlaying: false)
        // Expected: "Intro, 1:00"
        #expect(cell.accessibilityLabel == "Intro, 1:00")
    }

    // MARK: - Now Playing State

    @Test("Playing state prepends Now playing to accessibility label")
    func playingStateIncludesNowPlaying() {
        let cell = makeCell()
        let track = makeTrack()
        cell.configure(with: track, isPlaying: true)
        #expect(cell.accessibilityLabel?.hasPrefix("Now playing") == true)
    }

    @Test("Not playing state excludes Now playing from accessibility label")
    func notPlayingStateExcludesNowPlaying() {
        let cell = makeCell()
        let track = makeTrack()
        cell.configure(with: track, isPlaying: false)
        #expect(cell.accessibilityLabel?.contains("Now playing") != true)
    }

    @Test("Full accessibility label format when playing")
    func accessibilityLabelWhenPlaying() {
        let cell = makeCell()
        let track = makeTrack(trackNumber: 2, title: "Sunset", duration: 300)
        cell.configure(with: track, isPlaying: true)
        // Expected: "Now playing, Track 2, Sunset, 5:00"
        #expect(cell.accessibilityLabel == "Now playing, Track 2, Sunset, 5:00")
    }

    @Test("Reconfigure from playing to not playing updates accessibility label")
    func reconfigureFromPlayingToNotPlaying() {
        let cell = makeCell()
        let track = makeTrack()

        cell.configure(with: track, isPlaying: true)
        #expect(cell.accessibilityLabel?.contains("Now playing") == true)

        cell.configure(with: track, isPlaying: false)
        #expect(cell.accessibilityLabel?.contains("Now playing") != true)
    }

    @Test("Reconfigure from not playing to playing updates accessibility label")
    func reconfigureFromNotPlayingToPlaying() {
        let cell = makeCell()
        let track = makeTrack()

        cell.configure(with: track, isPlaying: false)
        #expect(cell.accessibilityLabel?.contains("Now playing") != true)

        cell.configure(with: track, isPlaying: true)
        #expect(cell.accessibilityLabel?.contains("Now playing") == true)
    }

    // MARK: - Accessibility Properties

    @Test("Accessibility traits include button")
    func accessibilityTraitsIncludesButton() {
        let cell = makeCell()
        #expect(cell.accessibilityTraits.contains(.button))
    }

    @Test("Cell is an accessibility element")
    func isAccessibilityElement() {
        let cell = makeCell()
        #expect(cell.isAccessibilityElement)
    }

    @Test("Accessibility hint is set after configure")
    func accessibilityHintIsSet() {
        let cell = makeCell()
        let track = makeTrack()
        cell.configure(with: track, isPlaying: false)
        #expect(cell.accessibilityHint == "Double-tap to play this track")
    }

    @Test("Accessibility traits set before configure")
    func accessibilityTraitsSetOnInit() {
        let cell = makeCell()
        // Traits should be set during init via setupAccessibility
        #expect(cell.accessibilityTraits.contains(.button))
        #expect(cell.isAccessibilityElement)
    }

    // MARK: - Focus

    @Test("Cell can become focused")
    func canBecomeFocused() {
        let cell = makeCell()
        #expect(cell.canBecomeFocused)
    }

    // MARK: - Prepare for Reuse

    @Test("Prepare for reuse resets transform to identity")
    func prepareForReuseResetsTransform() {
        let cell = makeCell()
        let track = makeTrack()
        cell.configure(with: track, isPlaying: true)
        // Simulate a transform that would happen during focus
        cell.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)

        cell.prepareForReuse()

        #expect(cell.transform == .identity)
    }

    @Test("Prepare for reuse resets shadow opacity")
    func prepareForReuseResetsShadow() {
        let cell = makeCell()
        cell.layer.shadowOpacity = 0.3

        cell.prepareForReuse()

        #expect(cell.layer.shadowOpacity == 0)
    }

    @Test("Cell can be reconfigured after prepareForReuse")
    func reconfigureAfterPrepareForReuse() {
        let cell = makeCell()

        // First configuration
        let track1 = makeTrack(trackNumber: 1, title: "First Song")
        cell.configure(with: track1, isPlaying: true)
        #expect(cell.accessibilityLabel?.contains("First Song") == true)

        // Prepare for reuse
        cell.prepareForReuse()

        // Second configuration
        let track2 = makeTrack(trackNumber: 2, title: "Second Song")
        cell.configure(with: track2, isPlaying: false)
        #expect(cell.accessibilityLabel?.contains("Second Song") == true)
        #expect(cell.accessibilityLabel?.contains("First Song") != true)
    }

    // MARK: - Multiple Configurations

    @Test("Configure multiple times applies last configuration")
    func configureMultipleTimes() {
        let cell = makeCell()

        for i in 1...5 {
            let track = makeTrack(trackNumber: i, title: "Track \(i)")
            cell.configure(with: track, isPlaying: false)
        }

        #expect(cell.accessibilityLabel?.contains("Track 5") == true)
        #expect(cell.accessibilityLabel?.contains("Track 4") != true)
    }

    // MARK: - Edge Cases

    @Test("Configure with zero duration shows 0:00")
    func configureWithZeroDuration() {
        let cell = makeCell()
        let track = makeTrack(duration: 0)
        cell.configure(with: track, isPlaying: false)
        #expect(cell.accessibilityLabel?.contains("0:00") == true)
    }

    @Test("Configure with large track number")
    func configureWithLargeTrackNumber() {
        let cell = makeCell()
        let track = makeTrack(trackNumber: 999)
        cell.configure(with: track, isPlaying: false)
        #expect(cell.accessibilityLabel?.contains("Track 999") == true)
    }

    @Test("Configure with long duration formats correctly")
    func configureWithLongDuration() {
        let cell = makeCell()
        // 1 hour, 23 minutes, 45 seconds = 5025 seconds
        let track = makeTrack(duration: 5025)
        cell.configure(with: track, isPlaying: false)
        #expect(cell.accessibilityLabel?.contains("1:23:45") == true)
    }

    @Test("Configure with empty title")
    func configureWithEmptyTitle() {
        let cell = makeCell()
        let track = makeTrack(title: "")
        cell.configure(with: track, isPlaying: false)
        // Should not crash; accessibility label should still be set
        #expect(cell.accessibilityLabel != nil)
    }

    @Test("Cell initializes with zero frame without crashing")
    func initWithZeroFrame() {
        let cell = TrackListCell(frame: .zero)
        #expect(cell.frame.width == 0)
        #expect(cell.frame.height == 0)
    }

    @Test("Cell starts unfocused")
    func cellStartsUnfocused() {
        let cell = makeCell()
        #expect(!cell.isFocused)
        #expect(cell.transform == .identity)
    }

    @Test("Layout does not crash after configure")
    func layoutAfterConfigure() {
        let cell = makeCell()
        let track = makeTrack()
        cell.configure(with: track, isPlaying: false)
        cell.layoutIfNeeded()
        #expect(cell.contentView.constraints.count > 0)
    }
}
