//
//  AudioQueueManager.swift
//  Internet Archive
//
//  Manages audio playback queue with shuffle and repeat functionality
//

import Foundation
import Combine

/// Manages audio playback queue with shuffle and repeat functionality
@MainActor
final class AudioQueueManager: ObservableObject {

    // MARK: - Singleton

    static let shared = AudioQueueManager()

    // MARK: - Published State

    /// Current track queue
    @Published private(set) var tracks: [AudioTrack] = []

    /// Index of currently playing track
    @Published private(set) var currentIndex: Int = 0

    /// Whether shuffle mode is enabled
    @Published private(set) var isShuffled: Bool = false

    /// Current repeat mode
    @Published private(set) var repeatMode: RepeatMode = .off

    // MARK: - Types

    /// Repeat mode options
    enum RepeatMode: Int, CaseIterable, Sendable {
        case off = 0
        case all = 1
        case one = 2

        /// SF Symbol name for the repeat mode
        var iconName: String {
            switch self {
            case .off: return "repeat"
            case .all: return "repeat"
            case .one: return "repeat.1"
            }
        }

        /// Accessibility label for the repeat mode
        var accessibilityLabel: String {
            switch self {
            case .off: return "Repeat off"
            case .all: return "Repeat all"
            case .one: return "Repeat one"
            }
        }

        /// Whether repeat is active (not off)
        var isActive: Bool {
            self != .off
        }
    }

    // MARK: - Private Properties

    /// Original track order before shuffle
    private var originalOrder: [AudioTrack] = []

    // MARK: - Initialization

    private init() {}

    // MARK: - Computed Properties

    /// Currently playing track
    var currentTrack: AudioTrack? {
        guard currentIndex >= 0 && currentIndex < tracks.count else { return nil }
        return tracks[currentIndex]
    }

    /// Whether there is a next track available
    var hasNext: Bool {
        if repeatMode == .all || repeatMode == .one {
            return !tracks.isEmpty
        }
        return currentIndex < tracks.count - 1
    }

    /// Whether there is a previous track available
    var hasPrevious: Bool {
        if repeatMode == .all {
            return !tracks.isEmpty
        }
        return currentIndex > 0
    }

    /// Total number of tracks in the queue
    var trackCount: Int {
        tracks.count
    }

    /// Whether the queue is empty
    var isEmpty: Bool {
        tracks.isEmpty
    }

    /// Current track position (1-indexed) for display
    var currentPosition: Int {
        currentIndex + 1
    }

    // MARK: - Queue Management

    /// Set the queue with tracks, optionally starting at a specific index
    /// - Parameters:
    ///   - tracks: Array of tracks to queue
    ///   - startAt: Index to start playing from (default: 0)
    func setQueue(_ tracks: [AudioTrack], startAt index: Int = 0) {
        self.originalOrder = tracks
        let clampedIndex = min(max(index, 0), max(tracks.count - 1, 0))

        if isShuffled && !tracks.isEmpty {
            // Keep the intended start track at position 0 when shuffled
            let startTrack = tracks[clampedIndex]
            self.tracks = shuffleTracks(tracks, keepingCurrent: startTrack)
            self.currentIndex = 0
        } else {
            self.tracks = tracks
            self.currentIndex = clampedIndex
        }
    }

    /// Clear the queue
    func clear() {
        tracks = []
        originalOrder = []
        currentIndex = 0
        isShuffled = false
        repeatMode = .off
    }

    // MARK: - Navigation

    /// Advance to the next track
    /// - Returns: The next track, or nil if at the end (and repeat is off)
    @discardableResult
    func next() -> AudioTrack? {
        guard !tracks.isEmpty else { return nil }

        // Repeat one: stay on current track
        if repeatMode == .one {
            return currentTrack
        }

        // Move to next track
        if currentIndex < tracks.count - 1 {
            currentIndex += 1
        } else if repeatMode == .all {
            // Wrap around to beginning
            currentIndex = 0
        } else {
            // End of queue, no repeat
            return nil
        }

        return currentTrack
    }

    /// Go to the previous track
    /// - Returns: The previous track, or nil if at the beginning (and repeat is off)
    @discardableResult
    func previous() -> AudioTrack? {
        guard !tracks.isEmpty else { return nil }

        // Move to previous track
        if currentIndex > 0 {
            currentIndex -= 1
        } else if repeatMode == .all {
            // Wrap around to end
            currentIndex = tracks.count - 1
        } else {
            // At beginning, no repeat - restart current track
            return currentTrack
        }

        return currentTrack
    }

    /// Jump to a specific index
    /// - Parameter index: The index to jump to
    /// - Returns: The track at the index, or nil if out of bounds
    @discardableResult
    func jumpTo(index: Int) -> AudioTrack? {
        guard index >= 0 && index < tracks.count else { return nil }
        currentIndex = index
        return currentTrack
    }

    /// Jump to a specific track
    /// - Parameter track: The track to jump to
    /// - Returns: The track if found in the queue, or nil
    @discardableResult
    func jumpTo(track: AudioTrack) -> AudioTrack? {
        guard let index = tracks.firstIndex(of: track) else { return nil }
        return jumpTo(index: index)
    }

    // MARK: - Shuffle

    /// Toggle shuffle mode
    func toggleShuffle() {
        isShuffled.toggle()

        if isShuffled {
            // Shuffle tracks, keeping current track at the front
            guard let current = currentTrack else { return }
            tracks = shuffleTracks(originalOrder, keepingCurrent: current)
            currentIndex = 0
        } else {
            // Restore original order, find current track
            guard let current = currentTrack else { return }
            tracks = originalOrder
            currentIndex = tracks.firstIndex(of: current) ?? 0
        }
    }

    /// Shuffle tracks, optionally keeping a specific track at the front
    private func shuffleTracks(_ tracks: [AudioTrack], keepingCurrent current: AudioTrack?) -> [AudioTrack] {
        guard let current = current else {
            return tracks.shuffled()
        }

        var shuffled = tracks.filter { $0 != current }.shuffled()
        shuffled.insert(current, at: 0)
        return shuffled
    }

    // MARK: - Repeat

    /// Cycle through repeat modes: off -> all -> one -> off
    func cycleRepeatMode() {
        let modes = RepeatMode.allCases
        let currentModeIndex = modes.firstIndex(of: repeatMode) ?? 0
        let nextIndex = (currentModeIndex + 1) % modes.count
        repeatMode = modes[nextIndex]
    }

    /// Set a specific repeat mode
    /// - Parameter mode: The repeat mode to set
    func setRepeatMode(_ mode: RepeatMode) {
        repeatMode = mode
    }
}
