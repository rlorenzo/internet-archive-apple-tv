//
//  ItemDetailView.swift
//  Internet Archive
//
//  Item detail modal view displaying metadata, description, and playback controls
//

import NukeUI
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

    @EnvironmentObject private var appState: AppState

    @Environment(\.isCompactLayout) private var isCompactLayout

    // MARK: - ViewModel

    /// Item detail view model: owns metadata loading (with retry) and the
    /// favorite toggle logic
    @StateObject private var viewModel = ItemDetailViewModel(
        metadataService: DefaultMetadataService()
    )

    // MARK: - State

    /// Saved playback progress for resume functionality
    @State private var savedProgress: PlaybackProgress?

    /// Whether this item is favorited (mirrors the view model, bound to FavoriteButton)
    @State private var isFavorited = false

    /// Show player via fullScreenCover
    @State private var showPlayer = false

    /// Resume time to pass to player
    @State private var resumeTime: Double?

    /// Whether playback is pending (waiting for metadata to load)
    @State private var playbackPending = false

    /// Task for loading metadata (stored for cancellation)
    @State private var loadMetadataTask: Task<Void, Never>?

    // MARK: - ViewModel Accessors

    /// Full metadata response (includes files and server info)
    private var metadataResponse: ItemMetadataResponse? {
        viewModel.state.metadataResponse
    }

    /// Detailed metadata fetched from API
    private var metadata: ItemMetadata? {
        metadataResponse?.metadata
    }

    /// Files available for playback
    private var files: [FileInfo]? {
        metadataResponse?.files
    }

    /// Whether the description area should show its loading indicator
    private var isLoadingMetadata: Bool {
        viewModel.state.isLoading
            || (metadataResponse == nil && viewModel.state.errorMessage == nil)
    }

    // MARK: - Body

    var body: some View {
        Group {
            if isCompactLayout == true {
                compactBody
            } else {
                wideBody
            }
        }
        .background(Color.libraryCharcoal)
        .onAppear {
            configureViewModel()
            // Only fetch metadata when we don't have it yet - onAppear
            // re-fires when returning from the player
            if metadataResponse == nil {
                loadMetadata()
            }
            isFavorited = viewModel.state.isFavorite
            checkSavedProgress()
        }
        .onDisappear {
            loadMetadataTask?.cancel()
            loadMetadataTask = nil
        }
        .fullScreenCover(isPresented: $showPlayer, onDismiss: handlePlayerCoverDismiss) {
            playerView
        }
    }

    /// Present the deferred player once the loading cover has fully
    /// dismissed. Presenting synchronously while the cover is still
    /// animating away makes UIKit reject the presentation, leaving the
    /// user with no player.
    private func handlePlayerCoverDismiss() {
        if playbackPending && metadataResponse != nil {
            presentPlayer()
        }
    }

    /// Wide layout (tvOS, iPad, visionOS, regular-width iOS): thumbnail and
    /// controls on the left, metadata column on the right. Wrapped in a
    /// `ScrollView` so iPad / regular-iOS surfaces with tall metadata don't
    /// clip off the bottom (tvOS focus scrolling still works inside a
    /// ScrollView). Outer `GeometryReader` measures available width so the
    /// 40 / 60 split survives Stage Manager and iPad Split View resizes; its
    /// own height is unused (the ScrollView inside sizes to content).
    private var wideBody: some View {
        GeometryReader { geometry in
            ScrollView {
                let outerPadding = PlatformMetrics.horizontalPadding(compact: false)
                let columnSpacing: CGFloat = 60
                // Subtract both the outer padding and the inter-column spacing
                // before splitting so the thumbnail / metadata ratio is a true
                // 40 / 60 of the *usable* two-column area, not of the full
                // GeometryReader width.
                let columnsWidth = max(0, geometry.size.width - outerPadding * 2 - columnSpacing)
                HStack(alignment: .top, spacing: columnSpacing) {
                    VStack(alignment: .leading, spacing: 30) {
                        thumbnailView
                        controlsSection
                    }
                    .frame(width: columnsWidth * 0.4)

                    VStack(alignment: .leading, spacing: 30) {
                        metadataSection
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 60)
                }
                .padding(.horizontal, outerPadding)
            }
        }
    }

    /// Compact layout (iPhone, narrow iPad Split View): thumbnail, controls,
    /// then metadata flow vertically inside a ScrollView so nothing is clipped
    /// at 390pt width.
    private var compactBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                thumbnailView
                controlsSection
                metadataSection
            }
            .padding(.horizontal, PlatformMetrics.horizontalPadding(compact: true))
            .padding(.vertical, 24)
        }
    }

    // MARK: - Thumbnail View

    private var thumbnailView: some View {
        VStack {
            LazyImage(url: thumbnailURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    placeholderImage
                }
            }
            .aspectRatio(mediaType.aspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.vertical, 60)
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.placeholderFill)
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
                        .accessibilityHidden(true)
                    Text(creator)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Creator: \(creator)")
            }

            // Date and License
            if let dateText = displayDate {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(dateText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(dateText)
            }

            // Subtitle info (if video has subtitles)
            if let subtitleInfo = subtitleInfoText {
                HStack(spacing: 8) {
                    Text("CC")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.chromeRest)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .accessibilityHidden(true)
                    Text(subtitleInfo)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Closed captions available. \(subtitleInfo)")
            }

            // Description
            if isLoadingMetadata {
                ProgressView()
                    .padding(.top, 10)
                    .accessibilityLabel("Loading item details")
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
        IAURLHelpers.thumbnailURL(for: item.identifier)
    }

    private var displayCreator: String? {
        metadata?.creator ?? item.creator
    }

    private var displayDate: String? {
        let date = metadata?.date ?? item.date
        let licenseURL = metadata?.licenseurl ?? item.licenseurl

        return DateFormattingHelpers.formatDateWithLicense(
            dateString: date,
            formattedDate: date.flatMap { Global.formatDate(string: $0) },
            licenseType: licenseURL.map { ContentFilterService.shared.getLicenseType($0) }
        )
    }

    private var displayDescription: String? {
        metadata?.description ?? item.description
    }

    /// Subtitle availability text via the tested SubtitleHelpers (which,
    /// unlike the previous inline copy, validates that the extracted
    /// language actually looks like a language - "movie_01.srt" no longer
    /// shows "Subtitles: 01").
    private var subtitleInfoText: String? {
        guard mediaType == .video, let files = files else { return nil }
        return SubtitleHelpers.formatSubtitleInfo(files: files)
    }

    // MARK: - Data Loading

    /// Configure the view model with this item's data (also refreshes the
    /// favorite status from local storage).
    private func configureViewModel() {
        guard viewModel.state.identifier != item.identifier else {
            viewModel.updateFavoriteStatus()
            return
        }

        viewModel.configure(with: ItemConfiguration(
            identifier: item.identifier,
            title: item.safeTitle,
            archivedBy: item.creator ?? "",
            date: item.date ?? "",
            description: item.description ?? "",
            mediaType: item.mediatype ?? "",
            imageURL: IAURLHelpers.thumbnailURL(for: item.identifier)
        ))
    }

    /// Load metadata through the view model (retry + mock-aware service).
    private func loadMetadata() {
        // Cancel any previous task before starting new one
        loadMetadataTask?.cancel()

        loadMetadataTask = Task { @MainActor in
            let response = await viewModel.loadMetadata()

            guard !Task.isCancelled else { return }

            if playbackPending {
                if response != nil {
                    // Dismiss the loading cover; the player is presented
                    // from the cover's onDismiss handler once the dismissal
                    // has actually completed
                    showPlayer = false
                } else {
                    // Dismiss the loading cover so the user sees the error
                    showPlayer = false
                    playbackPending = false
                }
            }
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
            // If a previous metadata load failed, retry so the pending
            // playback can actually complete instead of spinning forever
            if viewModel.state.errorMessage != nil {
                loadMetadata()
            }
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
            // Use UIKit presentation for proper tvOS focus handling
            let success = NowPlayingPresenter.presentFromMetadata(
                item: item,
                metadata: response,
                savedProgress: savedProgress,
                onDismiss: {
                    self.checkSavedProgress()
                }
            )
            if !success {
                showPlayer = true // Will show error view
            }
        }
    }

    private func toggleFavorite() {
        // Favorites are device-local (no API key for server-side saves);
        // the view model owns the toggle logic and logging
        isFavorited = viewModel.toggleFavorite()
        // Let the Favorites tab know it needs to refresh
        appState.notifyFavoritesChanged()
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
        .background(Color.libraryCharcoal)
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
        .background(Color.libraryCharcoal)
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
