//
//  ItemDetailView.swift
//  Internet Archive
//
//  Item detail modal view displaying metadata, description, and playback controls
//

import SwiftUI

/// Item detail view displaying metadata, description, and playback controls.
///
/// This view presents:
/// - Large thumbnail image
/// - Title, creator, and date metadata
/// - Formatted description with HTML support
/// - Playback buttons (Play, Resume, Start Over)
/// - Favorite toggle button
///
/// ## Usage
/// ```swift
/// NavigationStack {
///     VideoHomeView()
///         .navigationDestination(item: $selectedItem) { item in
///             ItemDetailView(item: item, mediaType: .video)
///         }
/// }
/// ```
struct ItemDetailView: View {
    // MARK: - Properties

    /// The search result item to display
    let item: SearchResult

    /// Media type determines aspect ratio and playback behavior
    let mediaType: MediaItemCard.MediaType

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    // MARK: - State

    /// Detailed metadata fetched from API
    @State private var metadata: ItemMetadata?

    /// Full metadata response (includes files and server info)
    @State private var metadataResponse: ItemMetadataResponse?

    /// Files available for playback
    @State private var files: [FileInfo]?

    /// Loading state for metadata fetch
    @State private var isLoading = true

    /// Error message if fetch fails
    @State private var errorMessage: String?

    /// Saved playback progress for resume functionality
    @State private var savedProgress: PlaybackProgress?

    /// Whether this item is favorited
    @State private var isFavorited = false

    /// Show player via fullScreenCover
    @State private var showPlayer = false

    /// Resume time to pass to player
    @State private var resumeTime: Double?

    /// Whether playback is pending (waiting for metadata to load)
    @State private var playbackPending = false

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 60) {
                // Left side: Thumbnail
                thumbnailView
                    .frame(width: geometry.size.width * 0.4)

                // Right side: Metadata and controls
                VStack(alignment: .leading, spacing: 30) {
                    metadataSection
                    Spacer()
                    controlsSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 60)
            }
            .padding(.horizontal, 80)
        }
        .background(Color.black.opacity(0.95))
        .onAppear {
            loadMetadata()
            checkFavoriteStatus()
            checkSavedProgress()
        }
        .fullScreenCover(isPresented: $showPlayer) {
            playerView
        }
    }

    // MARK: - Thumbnail View

    private var thumbnailView: some View {
        VStack {
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case .empty:
                    placeholderImage
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    placeholderImage
                @unknown default:
                    placeholderImage
                }
            }
            .aspectRatio(mediaType.aspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 20)
        }
        .padding(.vertical, 60)
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray.opacity(0.3))
            .aspectRatio(mediaType.aspectRatio, contentMode: .fit)
            .overlay(
                Image(systemName: mediaType.placeholderIcon)
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)
            )
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            Text(item.safeTitle)
                .font(.title)
                .fontWeight(.bold)
                .lineLimit(3)
                .accessibilityAddTraits(.isHeader)

            // Creator / Archived By
            if let creator = displayCreator {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                    Text(creator)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            // Date and License
            if let dateText = displayDate {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text(dateText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            // Subtitle info (if video has subtitles)
            if let subtitleInfo = subtitleInfoText {
                HStack(spacing: 8) {
                    Text("CC")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Text(subtitleInfo)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            // Description
            if isLoading {
                ProgressView()
                    .padding(.top, 10)
            } else if let description = displayDescription, !description.isEmpty {
                DescriptionView(htmlContent: description)
                    .padding(.top, 10)
            }
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Playback buttons
            PlaybackButtons(
                savedProgress: savedProgress,
                onPlay: { playFromBeginning() },
                onResume: { playWithResume() },
                onStartOver: { startOver() }
            )

            // Favorite button (only if authenticated and API is configured)
            if AppConfiguration.shared.isConfigured {
                FavoriteButton(
                    isFavorited: $isFavorited,
                    onToggle: toggleFavorite
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var thumbnailURL: URL? {
        URL(string: "https://archive.org/services/img/\(item.identifier)")
    }

    private var displayCreator: String? {
        metadata?.creator ?? item.creator
    }

    private var displayDate: String? {
        if let date = metadata?.date ?? item.date {
            var text = "Date: \(Global.formatDate(string: date) ?? date)"
            if let licenseURL = metadata?.licenseurl ?? item.licenseurl {
                let licenseType = ContentFilterService.shared.getLicenseType(licenseURL)
                text += "  \u{2022}  License: \(licenseType)"
            }
            return text
        }
        return nil
    }

    private var displayDescription: String? {
        metadata?.description ?? item.description
    }

    private var subtitleInfoText: String? {
        guard mediaType == .video, let files = files else { return nil }

        // Filter for subtitle files by checking file extension
        let subtitleExtensions = [".srt", ".vtt", ".webvtt"]
        let subtitleFiles = files.filter { file in
            let lowercasedName = file.name.lowercased()
            return subtitleExtensions.contains { lowercasedName.hasSuffix($0) }
        }
        guard !subtitleFiles.isEmpty else { return nil }

        let languages = subtitleFiles.compactMap { file -> String? in
            // Extract language from filename pattern like "identifier_english.srt"
            let basename = (file.name as NSString).deletingPathExtension
            if let underscoreIndex = basename.lastIndex(of: "_") {
                let langPart = String(basename[basename.index(after: underscoreIndex)...])
                return langPart.capitalized
            }
            return nil
        }

        let uniqueLanguages = Array(Set(languages)).sorted()
        if !uniqueLanguages.isEmpty {
            return "Subtitles: \(uniqueLanguages.joined(separator: ", "))"
        } else if subtitleFiles.count == 1 {
            return "1 subtitle track available"
        } else {
            return "\(subtitleFiles.count) subtitle tracks available"
        }
    }

    // MARK: - Data Loading

    private func loadMetadata() {
        isLoading = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let response = try await APIManager.sharedManager.getMetaDataTyped(
                    identifier: item.identifier
                )
                metadataResponse = response
                metadata = response.metadata
                files = response.files
                isLoading = false

                // If playback was pending, present player now that metadata is loaded
                if playbackPending {
                    showPlayer = false // Dismiss loading view first
                    presentPlayer()
                }
            } catch let networkError as NetworkError {
                errorMessage = ErrorPresenter.shared.userFriendlyMessage(for: networkError)
                isLoading = false
                // Dismiss loading view if playback was pending so user sees the error
                if playbackPending {
                    showPlayer = false
                    playbackPending = false
                }
            } catch {
                errorMessage = "Failed to load item details. Please try again."
                isLoading = false
                // Dismiss loading view if playback was pending so user sees the error
                if playbackPending {
                    showPlayer = false
                    playbackPending = false
                }
            }
        }
    }

    private func checkFavoriteStatus() {
        if let favorites = Global.getFavoriteData() {
            isFavorited = favorites.contains(item.identifier)
        }
    }

    private func checkSavedProgress() {
        savedProgress = PlaybackProgressManager.shared.getProgress(for: item.identifier)
    }

    // MARK: - Actions

    private func playFromBeginning() {
        resumeTime = nil
        presentPlayer()
    }

    private func playWithResume() {
        if let progress = savedProgress {
            // For audio, use trackCurrentTime; for video, use currentTime
            resumeTime = progress.isAudio ? progress.trackCurrentTime : progress.currentTime
        }
        presentPlayer()
    }

    private func startOver() {
        // Clear saved progress
        if savedProgress != nil {
            PlaybackProgressManager.shared.removeProgress(for: item.identifier)
            savedProgress = nil
        }
        resumeTime = nil
        presentPlayer()
    }

    /// Present the appropriate player based on media type
    private func presentPlayer() {
        guard let response = metadataResponse else {
            // Metadata not loaded yet - mark playback as pending and show loading view
            playbackPending = true
            showPlayer = true
            return
        }

        playbackPending = false

        if mediaType == .video {
            // Use UIKit presentation for proper transport bar controls
            let success = VideoPlayerPresenter.presentFromMetadata(
                item: item,
                metadata: response,
                resumeTime: resumeTime,
                onDismiss: {
                    // Refresh progress after playback
                    self.checkSavedProgress()
                }
            )
            if !success {
                // Show error if no playable video found
                showPlayer = true // Will show error view
            }
        } else {
            // Use SwiftUI fullScreenCover for audio (NowPlayingView)
            showPlayer = true
        }
    }

    private func toggleFavorite() {
        if isFavorited {
            Global.removeFavoriteData(identifier: item.identifier)
        } else {
            Global.saveFavoriteData(identifier: item.identifier)
        }
        isFavorited.toggle()
    }

    // MARK: - Player View (for fullScreenCover - audio only)

    /// Returns the appropriate player view for fullScreenCover.
    /// Note: Video playback now uses UIKit presentation via VideoPlayerPresenter
    /// for proper transport bar controls. This is only used for audio and errors.
    @ViewBuilder
    private var playerView: some View {
        if let response = metadataResponse {
            if mediaType == .video {
                // Video should be presented via VideoPlayerPresenter, not here
                // This is only shown if presentFromMetadata failed
                PlayerErrorView(
                    message: "No playable video found for this item.",
                    onDismiss: { showPlayer = false }
                )
            } else {
                audioPlayerView(response: response)
            }
        } else {
            // Fallback if metadata isn't loaded yet
            PlayerLoadingView(mediaType: mediaType) {
                playbackPending = false
                showPlayer = false
            }
        }
    }

    /// Audio player view using NowPlayingView wrapper
    @ViewBuilder
    private func audioPlayerView(response: ItemMetadataResponse) -> some View {
        if let playerView = NowPlayingView.fromMetadata(
            item: item,
            metadata: response,
            savedProgress: savedProgress,
            onDismiss: {
                // Refresh progress after playback (same as video path)
                self.checkSavedProgress()
                showPlayer = false
            }
        ) {
            playerView
        } else {
            PlayerErrorView(
                message: "No playable audio found for this item.",
                onDismiss: { showPlayer = false }
            )
        }
    }
}

// MARK: - Player Loading View

/// View shown while metadata is loading before presenting the player
private struct PlayerLoadingView: View {
    let mediaType: MediaItemCard.MediaType
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: mediaType == .video ? "play.rectangle.fill" : "music.note")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            ProgressView("Loading...")
                .font(.title3)

            Button("Cancel") {
                onDismiss()
            }
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Player Error View

/// View shown when no playable media is found
private struct PlayerErrorView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.yellow)

            Text("Unable to Play")
                .font(.title)
                .fontWeight(.bold)

            Text(message)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Close") {
                onDismiss()
            }
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Preview

#Preview("Video Item") {
    NavigationStack {
        ItemDetailView(
            item: SearchResult(
                identifier: "example-video",
                title: "Example Video Title",
                creator: "Example Creator",
                description: "<p>This is an example <b>HTML</b> description.</p>",
                date: "2024-01-15"
            ),
            mediaType: .video
        )
    }
    .environmentObject(AppState())
}

#Preview("Music Item") {
    NavigationStack {
        ItemDetailView(
            item: SearchResult(
                identifier: "example-music",
                title: "Example Album",
                creator: "Example Artist",
                year: "2024"
            ),
            mediaType: .music
        )
    }
    .environmentObject(AppState())
}
