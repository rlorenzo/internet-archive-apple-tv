//
//  PlaybackProgressManager.swift
//  Internet Archive
//
//  Manages saving and retrieving playback progress for resume functionality
//

import Foundation

/// Manages playback progress persistence for Continue Watching/Listening features
@MainActor
final class PlaybackProgressManager {

    // MARK: - Singleton

    /// Shared instance for app-wide progress management
    static let shared = PlaybackProgressManager()

    // MARK: - Constants

    private enum Keys {
        static let progressData = "playback_progress_items"
        static let audioProgressMigrationComplete = "audio_progress_migration_v1_complete"
    }

    private enum Limits {
        static let maxItems = 50
        static let maxAgeDays = 30
    }

    /// Marker filename for album-level audio progress (instead of per-track)
    static let albumMarkerFilename = "__album__"

    // MARK: - Initialization

    private init() {
        migrateAudioProgressIfNeeded()
    }

    // MARK: - Migration

    /// One-time migration to clear old per-track audio progress entries
    /// Now using album-level tracking for audio content
    private func migrateAudioProgressIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Keys.audioProgressMigrationComplete) else {
            return
        }

        // Remove all existing audio (etree) progress entries
        var items = allProgress
        let beforeCount = items.count
        items.removeAll { $0.isAudio }
        let removedCount = beforeCount - items.count

        if removedCount > 0 {
            allProgress = items
            #if DEBUG
            print("🔄 Migrated audio progress: removed \(removedCount) per-track entries")
            #endif
        }

        UserDefaults.standard.set(true, forKey: Keys.audioProgressMigrationComplete)
    }

    // MARK: - Public Methods

    /// Save or update playback progress for an item
    /// - Parameter progress: The progress to save
    func saveProgress(_ progress: PlaybackProgress) {
        var items = allProgress

        // Remove existing entry for this item+filename if present
        items.removeAll { $0.itemIdentifier == progress.itemIdentifier && $0.filename == progress.filename }

        // Don't save if complete (>95%)
        guard !progress.isComplete else {
            // Remove from list if it was previously saved
            allProgress = items
            pruneOldEntries()
            return
        }

        // Add the new/updated progress
        items.append(progress)

        // Save and prune
        allProgress = items
        pruneOldEntries()
    }

    /// Get saved progress for a specific item and filename
    /// - Parameters:
    ///   - identifier: The item identifier
    ///   - filename: The media filename
    /// - Returns: The saved progress if found
    func getProgress(for identifier: String, filename: String) -> PlaybackProgress? {
        allProgress.first { $0.itemIdentifier == identifier && $0.filename == filename }
    }

    /// Get saved progress for an item (any filename)
    /// - Parameter identifier: The item identifier
    /// - Returns: The most recent saved progress for the item
    func getProgress(for identifier: String) -> PlaybackProgress? {
        allProgress
            .filter { $0.itemIdentifier == identifier }
            .max { $0.lastWatchedDate < $1.lastWatchedDate }
    }

    /// Remove progress for a specific item and filename
    /// - Parameters:
    ///   - identifier: The item identifier
    ///   - filename: The media filename
    func removeProgress(for identifier: String, filename: String) {
        var items = allProgress
        items.removeAll { $0.itemIdentifier == identifier && $0.filename == filename }
        allProgress = items
    }

    /// Remove all progress for an item
    /// - Parameter identifier: The item identifier
    func removeProgress(for identifier: String) {
        var items = allProgress
        items.removeAll { $0.itemIdentifier == identifier }
        allProgress = items
    }

    /// Get items for Continue Watching section (videos only)
    /// - Parameter limit: Maximum number of items to return
    /// - Returns: Video progress items sorted by most recently watched
    func getContinueWatchingItems(limit: Int = 20) -> [PlaybackProgress] {
        allProgress
            .filter { $0.isVideo && !$0.isComplete && $0.isValid }
            .sorted { $0.lastWatchedDate > $1.lastWatchedDate }
            .prefix(limit)
            .map { $0 }
    }

    /// Get items for Continue Listening section (audio only)
    /// - Parameter limit: Maximum number of items to return
    /// - Returns: Audio progress items sorted by most recently listened
    func getContinueListeningItems(limit: Int = 20) -> [PlaybackProgress] {
        allProgress
            .filter { $0.isAudio && !$0.isComplete && $0.isValid }
            .sorted { $0.lastWatchedDate > $1.lastWatchedDate }
            .prefix(limit)
            .map { $0 }
    }

    /// Check if there's resumable progress for an item
    /// - Parameter identifier: The item identifier
    /// - Returns: True if there's incomplete progress saved
    func hasResumableProgress(for identifier: String) -> Bool {
        guard let progress = getProgress(for: identifier) else { return false }
        return !progress.isComplete && progress.hasResumableProgress
    }

    /// Clear all saved progress
    func clearAllProgress() {
        cachedProgress = nil
        UserDefaults.standard.removeObject(forKey: Keys.progressData)
    }

    /// Get the count of items with saved progress
    var progressCount: Int {
        allProgress.count
    }

    // MARK: - Private Storage

    /// Cached progress items (loaded once per app session for performance)
    private var cachedProgress: [PlaybackProgress]?

    /// Load progress from UserDefaults if not already cached
    private func loadProgressIfNeeded() {
        guard cachedProgress == nil else { return }
        guard let data = UserDefaults.standard.data(forKey: Keys.progressData),
              let items = try? JSONDecoder().decode([PlaybackProgress].self, from: data) else {
            cachedProgress = []
            return
        }
        cachedProgress = items
    }

    /// All saved progress items (cached for performance)
    private var allProgress: [PlaybackProgress] {
        get {
            loadProgressIfNeeded()
            return cachedProgress ?? []
        }
        set {
            cachedProgress = newValue
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            UserDefaults.standard.set(data, forKey: Keys.progressData)
        }
    }

    /// Remove old entries beyond limits
    private func pruneOldEntries() {
        var items = allProgress

        // Remove entries older than 30 days
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -Limits.maxAgeDays, to: Date()) ?? Date()
        items.removeAll { $0.lastWatchedDate < cutoffDate }

        // If still over limit, remove oldest entries
        if items.count > Limits.maxItems {
            items.sort { $0.lastWatchedDate > $1.lastWatchedDate }
            items = Array(items.prefix(Limits.maxItems))
        }

        allProgress = items
    }
}

// MARK: - Testing Support

extension PlaybackProgressManager {

    /// Reset all progress (for testing)
    func resetForTesting() {
        clearAllProgress()
    }

    /// Get all progress items (for testing)
    func getAllProgressForTesting() -> [PlaybackProgress] {
        allProgress
    }
}
