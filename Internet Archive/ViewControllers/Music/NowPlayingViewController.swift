//
//  NowPlayingViewController.swift
//  Internet Archive
//
//  Full-screen Now Playing view controller for music playback
//  Inspired by Apple Music's tvOS design
//

import UIKit
import AVFoundation
import Combine

/// Full-screen Now Playing view controller for music playback
@MainActor
final class NowPlayingViewController: UIViewController {

    // MARK: - Properties

    private let queueManager = AudioQueueManager.shared
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var cancellables = Set<AnyCancellable>()

    private let itemIdentifier: String
    private let itemTitle: String?
    private let imageURL: URL?
    private var tracks: [AudioTrack]
    private let startTrackIndex: Int
    private let initialResumeTime: Double?

    /// Timer for periodic progress saving
    private var progressSaveTimer: Timer?

    /// Flag to track if we're currently scrubbing
    private var isScrubbing: Bool = false

    /// Flag to track if we were playing before scrubbing
    private var wasPlayingBeforeScrub: Bool = false

    // MARK: - UI Components

    private let albumArtView = AlbumArtView(size: 400)

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 42, weight: .bold)
        label.textColor = .white
        label.textAlignment = .left
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let artistLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let trackPositionLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 24, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var slider: Slider = {
        let slider = Slider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.delegate = self
        // Hide the seeker bubble, we show time in left/right labels
        slider.seekerLabel.isHidden = true
        slider.seekerLabelBackgroundView.isHidden = true
        return slider
    }()

    private let controlsView = NowPlayingControlsView()

    private lazy var trackListCollectionView: UICollectionView = {
        let layout = createTrackListLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(TrackListCell.self, forCellWithReuseIdentifier: TrackListCell.reuseIdentifier)
        cv.remembersLastFocusedIndexPath = true
        return cv
    }()

    private var trackListDataSource: UICollectionViewDiffableDataSource<Int, AudioTrack>?

    private let trackListHeaderLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .semibold)
        label.textColor = .secondaryLabel
        label.text = "Up Next"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    init(
        itemIdentifier: String,
        itemTitle: String?,
        imageURL: URL?,
        tracks: [AudioTrack],
        startAt index: Int = 0,
        resumeTime: Double? = nil
    ) {
        self.itemIdentifier = itemIdentifier
        self.itemTitle = itemTitle
        self.imageURL = imageURL
        self.tracks = tracks
        self.startTrackIndex = index
        self.initialResumeTime = resumeTime
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupViews()
        setupConstraints()
        setupAccessibility()
        configureDataSource()
        bindQueueManager()

        // Initialize queue and start playback
        queueManager.setQueue(tracks, startAt: startTrackIndex)
        if let track = queueManager.currentTrack {
            playTrack(track, resumeTime: initialResumeTime)
        }

        updateTrackListSnapshot()
        updateControlsState()

        // Observe app backgrounding to save progress
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveProgress()
        stopTimeObserver()
        stopProgressTracking()
        player?.pause()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupViews() {
        albumArtView.translatesAutoresizingMaskIntoConstraints = false
        controlsView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(albumArtView)
        view.addSubview(titleLabel)
        view.addSubview(artistLabel)
        view.addSubview(trackPositionLabel)
        view.addSubview(slider)
        view.addSubview(controlsView)
        view.addSubview(trackListHeaderLabel)
        view.addSubview(trackListCollectionView)

        controlsView.delegate = self
        trackListCollectionView.delegate = self
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Left side - Album art
            albumArtView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 90),
            albumArtView.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),
            albumArtView.widthAnchor.constraint(equalToConstant: 440),
            albumArtView.heightAnchor.constraint(equalToConstant: 520),

            // Track title below album art
            titleLabel.topAnchor.constraint(equalTo: albumArtView.bottomAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: albumArtView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: albumArtView.trailingAnchor, constant: -20),

            // Artist below title
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            // Track position (e.g., "Track 3 of 12")
            trackPositionLabel.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: 8),
            trackPositionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            // Slider below track info
            slider.topAnchor.constraint(equalTo: trackPositionLabel.bottomAnchor, constant: 30),
            slider.leadingAnchor.constraint(equalTo: albumArtView.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: albumArtView.trailingAnchor, constant: -20),
            slider.heightAnchor.constraint(equalToConstant: 50),

            // Controls below slider
            controlsView.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 30),
            controlsView.centerXAnchor.constraint(equalTo: albumArtView.centerXAnchor),
            controlsView.heightAnchor.constraint(equalToConstant: 90),
            controlsView.widthAnchor.constraint(equalToConstant: 400),

            // Right side - Track list header
            trackListHeaderLabel.leadingAnchor.constraint(equalTo: albumArtView.trailingAnchor, constant: 80),
            trackListHeaderLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),

            // Track list - ensure it doesn't extend below the controls area
            trackListCollectionView.leadingAnchor.constraint(equalTo: trackListHeaderLabel.leadingAnchor),
            trackListCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            trackListCollectionView.topAnchor.constraint(equalTo: trackListHeaderLabel.bottomAnchor, constant: 20),
            trackListCollectionView.bottomAnchor.constraint(equalTo: controlsView.bottomAnchor)
        ])
    }

    private func setupAccessibility() {
        view.accessibilityLabel = "Now Playing"
        titleLabel.accessibilityTraits = .header

        slider.isAccessibilityElement = true
        slider.accessibilityTraits = .adjustable
        slider.accessibilityLabel = "Playback position"
        slider.accessibilityHint = "Swipe up or down to adjust playback position"
    }

    // MARK: - Focus

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [controlsView.defaultFocusedButton]
    }

    // MARK: - Data Source

    private func configureDataSource() {
        trackListDataSource = UICollectionViewDiffableDataSource<Int, AudioTrack>(
            collectionView: trackListCollectionView
        ) { [weak self] collectionView, indexPath, track in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TrackListCell.reuseIdentifier,
                for: indexPath
            ) as? TrackListCell else {
                return UICollectionViewCell()
            }

            let isPlaying = self?.queueManager.currentTrack == track
            cell.configure(with: track, isPlaying: isPlaying)
            return cell
        }
    }

    private func updateTrackListSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, AudioTrack>()
        snapshot.appendSections([0])
        snapshot.appendItems(queueManager.tracks, toSection: 0)
        trackListDataSource?.apply(snapshot, animatingDifferences: true)

        // Reconfigure all visible cells to update the "now playing" indicator
        // This is needed because AudioTrack equality is based on ID only,
        // so changing the current track doesn't trigger cell reconfiguration
        var reconfigureSnapshot = trackListDataSource?.snapshot() ?? snapshot
        reconfigureSnapshot.reconfigureItems(queueManager.tracks)
        trackListDataSource?.apply(reconfigureSnapshot, animatingDifferences: false)
    }

    private func createTrackListLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(70)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(70)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 4

        return UICollectionViewCompositionalLayout(section: section)
    }

    // MARK: - Queue Manager Binding

    private func bindQueueManager() {
        queueManager.$currentIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTrackListSnapshot()
                self?.updateControlsState()
                self?.updateTrackPositionLabel()
            }
            .store(in: &cancellables)

        queueManager.$isShuffled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isShuffled in
                self?.controlsView.setShuffled(isShuffled)
                self?.updateTrackListSnapshot()
                self?.updateTrackPositionLabel()
            }
            .store(in: &cancellables)

        queueManager.$repeatMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                self?.controlsView.setRepeatMode(mode)
                self?.updateControlsState()
            }
            .store(in: &cancellables)
    }

    // MARK: - Playback

    private func playTrack(_ track: AudioTrack, resumeTime: Double? = nil) {
        // Update UI
        titleLabel.text = track.title
        artistLabel.text = track.artistAlbumDisplay
        albumArtView.setImage(url: track.thumbnailURL ?? imageURL)
        updateTrackPositionLabel()

        // Animate album art
        albumArtView.animatePulse()

        // Reset slider (will update after seeking if resuming)
        let initialTime = resumeTime ?? 0
        slider.set(value: initialTime, animated: false)
        slider.leftLabel.text = formatTime(initialTime)
        slider.rightLabel.text = "--:--"

        // Setup player
        let playerItem = AVPlayerItem(url: track.streamURL)

        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }

        // If resuming, defer playback until after seeking
        let shouldDeferPlayback = (resumeTime ?? 0) > 0

        // Load duration asynchronously, then seek if resuming
        // Capture track duration for fallback
        let trackDuration = track.duration
        Task { @MainActor in
            do {
                let duration = try await playerItem.asset.load(.duration)
                let durationSeconds = duration.seconds

                // Use loaded duration if finite, otherwise fall back to track metadata
                let effectiveDuration: Double?
                if durationSeconds.isFinite && durationSeconds > 0 {
                    effectiveDuration = durationSeconds
                } else {
                    effectiveDuration = trackDuration
                }

                if let effectiveDuration = effectiveDuration {
                    slider.max = effectiveDuration
                    slider.rightLabel.text = formatTime(initialTime - effectiveDuration)
                }

                // Seek to resume position after duration is loaded
                if let resumeTime = resumeTime, resumeTime > 0 {
                    let targetTime = CMTime(seconds: resumeTime, preferredTimescale: 600)
                    await player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
                    // Start playback after seek completes
                    player?.play()
                }
            } catch {
                // Use track duration if available
                if let duration = trackDuration {
                    slider.max = duration
                    slider.rightLabel.text = formatTime(initialTime - duration)
                }
                // If we failed to load duration but were deferring, start playback anyway
                if shouldDeferPlayback {
                    player?.play()
                }
            }
        }

        // Start playback immediately only if not resuming
        if !shouldDeferPlayback {
            player?.play()
        }
        controlsView.setPlaying(true)
        startTimeObserver()
        startProgressTracking()

        // Setup end notification
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(trackDidEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        UIApplication.shared.isIdleTimerDisabled = true

        // Log success
        ErrorLogger.shared.logSuccess(
            operation: .playAudio,
            info: [
                "identifier": track.itemIdentifier,
                "filename": track.filename,
                "trackNumber": "\(track.trackNumber ?? 0)"
            ]
        )
    }

    @objc private func trackDidEnd() {
        if let nextTrack = queueManager.next() {
            // Continue to next track - progress will be updated on next save
            playTrack(nextTrack)
        } else {
            // Album finished - remove from Continue Listening
            PlaybackProgressManager.shared.removeProgress(
                for: itemIdentifier,
                filename: PlaybackProgressManager.albumMarkerFilename
            )
            controlsView.setPlaying(false)
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func updateControlsState() {
        controlsView.setHasNext(queueManager.hasNext)
        controlsView.setHasPrevious(queueManager.hasPrevious)
    }

    private func updateTrackPositionLabel() {
        trackPositionLabel.text = "Track \(queueManager.currentPosition) of \(queueManager.trackCount)"
    }

    // MARK: - Time Observer

    private func startTimeObserver() {
        stopTimeObserver()

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                guard let self = self else { return }

                // Don't update while scrubbing
                guard !self.isScrubbing else { return }

                let seconds = time.seconds
                guard seconds.isFinite else { return }

                self.slider.set(value: seconds, animated: false)
                self.slider.leftLabel.text = self.formatTime(seconds)
                // Update remaining time (negative value shows countdown)
                self.slider.rightLabel.text = self.formatTime(seconds - self.slider.max)
                self.updateSliderAccessibility(currentTime: seconds)
            }
        }
    }

    private func stopTimeObserver() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    // MARK: - Progress Tracking

    private func startProgressTracking() {
        stopProgressTracking()
        progressSaveTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.saveProgress()
            }
        }
    }

    private func stopProgressTracking() {
        progressSaveTimer?.invalidate()
        progressSaveTimer = nil
    }

    private func saveProgress() {
        guard let track = queueManager.currentTrack,
              let player = player else { return }

        let currentTime = player.currentTime().seconds
        let trackDuration = slider.max

        // Don't save if at the very beginning
        guard currentTime >= 10, trackDuration > 0 else { return }

        // Calculate album-level progress using consistent normalized scale (0-100)
        // This ensures the progress bar displays smoothly across all tracks
        let trackProgressPercentage = currentTime / trackDuration
        let albumProgress = (Double(queueManager.currentIndex) + trackProgressPercentage) / Double(queueManager.trackCount)

        // Always use normalized 0-100 scale for consistent progress bar display
        let effectiveDuration = 100.0
        let effectiveCurrentTime = albumProgress * 100.0

        // Save at album level using marker filename, with track index for resume
        let progress = PlaybackProgress.audio(MediaProgressInfo(
            identifier: itemIdentifier,
            filename: PlaybackProgressManager.albumMarkerFilename,
            currentTime: effectiveCurrentTime,
            duration: effectiveDuration,
            title: "\(track.artist ?? itemTitle ?? ""): \(track.title)",
            imageURL: (track.thumbnailURL ?? imageURL)?.absoluteString,
            trackIndex: queueManager.currentIndex,
            trackFilename: track.filename,
            trackCurrentTime: currentTime  // Actual track position for resume
        ))

        PlaybackProgressManager.shared.saveProgress(progress)
    }

    @objc private func appWillResignActive() {
        saveProgress()
    }

    // MARK: - Helpers

    private func formatTime(_ time: Double) -> String {
        let sign = time < 0 ? -1.0 : 1.0
        let absTime = abs(time)
        let hours = Int(absTime) / 3600
        let minutes = (Int(absTime) % 3600) / 60
        let seconds = Int(absTime) % 60

        let prefix = sign < 0 ? "-" : ""

        if hours > 0 {
            return prefix + String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return prefix + String(format: "%d:%02d", minutes, seconds)
        }
    }

    private func updateSliderAccessibility(currentTime: Double) {
        let currentFormatted = formatTime(currentTime)
        let durationFormatted = formatTime(slider.max)
        slider.accessibilityValue = "\(currentFormatted) of \(durationFormatted)"
    }
}

// MARK: - SliderDelegate

extension NowPlayingViewController: @preconcurrency SliderDelegate {
    func slider(_ slider: Slider, textWithValue value: Double) -> String {
        formatTime(value)
    }

    func slider(_ slider: Slider, didChangeValue value: Double) {
        slider.rightLabel.text = formatTime(value - slider.max)

        if isScrubbing {
            slider.leftLabel.text = formatTime(value)
        }

        updateSliderAccessibility(currentTime: value)
    }

    func sliderDidBeginScrubbing(_ slider: Slider) {
        isScrubbing = true
        wasPlayingBeforeScrub = player?.rate != 0
        player?.pause()
    }

    func sliderDidEndScrubbing(_ slider: Slider) {
        // Wait for deceleration to finish
    }

    func sliderDidFinishScrubbing(_ slider: Slider) {
        isScrubbing = false
        let targetTime = CMTime(seconds: slider.value, preferredTimescale: 600)
        player?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)

        if wasPlayingBeforeScrub {
            player?.play()
        }
    }
}

// MARK: - NowPlayingControlsDelegate

extension NowPlayingViewController: NowPlayingControlsDelegate {
    func controlsDidTapPlayPause() {
        if controlsView.isPlaying {
            player?.pause()
            controlsView.setPlaying(false)
        } else {
            player?.play()
            controlsView.setPlaying(true)
        }
    }

    func controlsDidTapNext() {
        if let track = queueManager.next() {
            playTrack(track)
        }
    }

    func controlsDidTapPrevious() {
        // If more than 3 seconds in, restart current track
        if let player = player, player.currentTime().seconds > 3 {
            player.seek(to: .zero)
            slider.set(value: 0, animated: true)
        } else if let track = queueManager.previous() {
            playTrack(track)
        }
    }

    func controlsDidTapShuffle() {
        queueManager.toggleShuffle()

        // Announce for accessibility
        let announcement = queueManager.isShuffled ? "Shuffle on" : "Shuffle off"
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    func controlsDidTapRepeat() {
        queueManager.cycleRepeatMode()

        // Announce for accessibility
        UIAccessibility.post(notification: .announcement, argument: queueManager.repeatMode.accessibilityLabel)
    }
}

// MARK: - UICollectionViewDelegate

extension NowPlayingViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let track = queueManager.jumpTo(index: indexPath.item) {
            playTrack(track)
        }
    }
}
