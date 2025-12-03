//
//  ItemDetailViewModel.swift
//  Internet Archive
//
//  ViewModel for item detail screen with testable business logic
//

import Foundation

/// Protocol for metadata operations - enables dependency injection for testing
protocol MetadataServiceProtocol: Sendable {
    func getMetadata(identifier: String) async throws -> ItemMetadataResponse
}

/// Configuration for item detail view model
struct ItemConfiguration: Sendable {
    let identifier: String
    let title: String
    let archivedBy: String
    let date: String
    let description: String
    let mediaType: String
    let imageURL: URL?
}

/// ViewModel state for item detail
struct ItemDetailViewState: Sendable {
    var isLoading: Bool = false
    var identifier: String = ""
    var title: String = ""
    var archivedBy: String = ""
    var date: String = ""
    var description: String = ""
    var mediaType: String = ""
    var imageURL: URL?
    var isFavorite: Bool = false
    var isPlaying: Bool = false
    var errorMessage: String?
    var playableFiles: [FileInfo] = []
    var currentMediaURL: URL?

    static let initial = ItemDetailViewState()

    /// Format the archived by text for display
    var formattedArchivedBy: String {
        "Archived By:  \(archivedBy)"
    }

    /// Format the date text for display
    var formattedDate: String {
        "Date:  \(date)"
    }

    /// Check if this is a video item
    var isVideo: Bool {
        mediaType == "movies"
    }

    /// Check if this is an audio item
    var isAudio: Bool {
        mediaType == "etree" || mediaType == "audio"
    }

    /// Build image URL from identifier
    mutating func setImageFromIdentifier(_ identifier: String) {
        imageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(identifier)")
    }
}

/// ViewModel for item detail screen - handles all business logic
@MainActor
final class ItemDetailViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var state = ItemDetailViewState.initial

    // MARK: - Dependencies

    private let metadataService: MetadataServiceProtocol

    // MARK: - Initialization

    init(metadataService: MetadataServiceProtocol) {
        self.metadataService = metadataService
    }

    // MARK: - Public Methods

    /// Configure the view model with item data
    func configure(with config: ItemConfiguration) {
        state.identifier = config.identifier
        state.title = config.title
        state.archivedBy = config.archivedBy
        state.date = config.date
        state.description = config.description
        state.mediaType = config.mediaType
        state.imageURL = config.imageURL
        updateFavoriteStatus()
    }

    /// Update favorite status from stored data
    func updateFavoriteStatus() {
        if let favorites = Global.getFavoriteData() {
            state.isFavorite = favorites.contains(state.identifier)
        } else {
            state.isFavorite = false
        }
    }

    /// Toggle favorite status
    func toggleFavorite() -> Bool {
        guard !state.identifier.isEmpty else { return false }

        if state.isFavorite {
            Global.removeFavoriteData(identifier: state.identifier)
            state.isFavorite = false
        } else {
            Global.saveFavoriteData(identifier: state.identifier)
            state.isFavorite = true
        }

        ErrorLogger.shared.logSuccess(
            operation: state.isFavorite ? .saveFavorite : .removeFavorite,
            info: ["identifier": state.identifier, "action": state.isFavorite ? "add" : "remove"]
        )

        return state.isFavorite
    }

    /// Load metadata and prepare for playback
    func loadMediaForPlayback() async -> URL? {
        guard !state.identifier.isEmpty else {
            state.errorMessage = "Missing item information"
            return nil
        }

        state.isLoading = true
        state.errorMessage = nil

        do {
            let metadataResponse = try await RetryMechanism.execute(config: .single) {
                try await self.metadataService.getMetadata(identifier: self.state.identifier)
            }

            state.isLoading = false

            guard let files = metadataResponse.files else {
                state.errorMessage = "No files available"
                return nil
            }

            // Filter for playable files based on media type
            let playableFiles = filterPlayableFiles(files: files)

            guard !playableFiles.isEmpty else {
                state.errorMessage = "No playable files found"
                return nil
            }

            state.playableFiles = playableFiles

            // Build media URL for first file
            let filename = playableFiles[0].name
            guard let mediaURL = buildMediaURL(identifier: state.identifier, filename: filename) else {
                state.errorMessage = "Invalid file URL"
                return nil
            }

            state.currentMediaURL = mediaURL
            return mediaURL

        } catch {
            state.isLoading = false
            state.errorMessage = mapErrorToMessage(error)
            return nil
        }
    }

    /// Filter files for playable media
    func filterPlayableFiles(files: [FileInfo]) -> [FileInfo] {
        files.filter { file in
            let ext = String(file.name.suffix(4)).lowercased()
            if state.isVideo {
                return ext == ".mp4"
            } else if state.isAudio {
                return ext == ".mp3"
            }
            return false
        }
    }

    /// Build media URL for download
    func buildMediaURL(identifier: String, filename: String) -> URL? {
        guard let encodedFilename = filename.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "https://archive.org/download/\(identifier)/\(encodedFilename)")
    }

    /// Set playing state
    func setPlaying(_ playing: Bool) {
        state.isPlaying = playing

        if playing {
            ErrorLogger.shared.logSuccess(
                operation: state.isVideo ? .playVideo : .playAudio,
                info: ["identifier": state.identifier]
            )
        }
    }

    /// Format time for display
    func formatTime(_ time: Double) -> String {
        let sign = time < 0 ? -1.0 : 1.0
        let minutes = Int(time * sign) / 60
        let seconds = Int(time * sign) % 60
        return (sign < 0 ? "-" : "") + "\(minutes):" + String(format: "%02d", seconds)
    }

    /// Check if API is configured for favorites
    var canManageFavorites: Bool {
        AppConfiguration.shared.isConfigured
    }

    /// Check if user is logged in
    var isLoggedIn: Bool {
        Global.getUserData() != nil
    }

    // MARK: - Private Methods

    private func mapErrorToMessage(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            return ErrorPresenter.shared.userFriendlyMessage(for: networkError)
        }
        return "An unexpected error occurred. Please try again."
    }
}

// MARK: - Default Metadata Service Implementation

/// Default implementation using APIManager
struct DefaultMetadataService: MetadataServiceProtocol {

    @MainActor
    func getMetadata(identifier: String) async throws -> ItemMetadataResponse {
        try await APIManager.sharedManager.getMetaDataTyped(identifier: identifier)
    }
}
