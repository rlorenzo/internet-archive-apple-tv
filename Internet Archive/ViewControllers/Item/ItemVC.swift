//
//  ItemVC.swift
//  Internet Archive
//
//  Created by mac-admin on 5/29/18.
//  Copyright © 2018 mac-admin. All rights reserved.
//
//

import UIKit
import AVKit
import AVFoundation
import CoreMedia
import TvOSMoreButton
import TvOSTextViewer

@MainActor
class ItemVC: UIViewController, AVPlayerViewControllerDelegate, AVAudioPlayerDelegate {

    @IBOutlet weak var btnPlay: UIButton!
    @IBOutlet weak var btnFavorite: UIButton!
    @IBOutlet weak var txtTitle: UILabel!
    @IBOutlet weak var txtArchivedBy: UILabel!
    @IBOutlet weak var txtDate: UILabel!
    @IBOutlet weak var txtDescription: TvOSMoreButton!
    @IBOutlet weak var itemImage: UIImageView!
    @IBOutlet weak var slider: Slider!

    var iIdentifier: String?
    var iTitle: String?
    var iArchivedBy: String?
    var iDate: String?
    var iDescription: String?
    var iImageURL: URL?
    var iMediaType: String?
    var iLicenseURL: String?

    var player: AVPlayer!

    /// Current filename being played (for progress tracking)
    private var currentFilename: String?

    /// Timer for saving audio progress
    private var audioProgressTimer: Timer?

    /// Saved progress for resume functionality
    private var savedProgress: PlaybackProgress?

    /// Resume button (shown when there's saved progress)
    private lazy var btnResume: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("  Resume  ", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 38, weight: .semibold)
        button.addTarget(self, action: #selector(onResume), for: .primaryActionTriggered)
        button.isHidden = true
        return button
    }()

    /// Start Over button (shown when there's saved progress)
    private lazy var btnStartOver: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("  Start Over  ", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 38, weight: .regular)
        button.addTarget(self, action: #selector(onStartOver), for: .primaryActionTriggered)
        button.isHidden = true
        return button
    }()

    /// Label showing time remaining for resume
    private lazy var resumeTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    /// Label to show subtitle availability
    private lazy var subtitleInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        btnPlay.setImage(UIImage(named: "play.png"), for: .normal)

        txtTitle.text = iTitle
        txtArchivedBy.text = "Archived By:  \(iArchivedBy ?? "")"

        // Build date text, optionally including license
        var dateText = "Date:  \(iDate ?? "")"
        if let licenseURL = iLicenseURL {
            let licenseType = ContentFilterService.shared.getLicenseType(licenseURL)
            dateText += "  •  License: \(licenseType)"
        }
        txtDate.text = dateText

        txtDescription.text = iDescription

        if let imageURL = iImageURL {
            itemImage.af.setImage(withURL: imageURL)
        }

        txtDescription.buttonWasPressed = onMoreButtonPressed
        btnPlay.imageView?.contentMode = .scaleAspectFit
        btnFavorite.imageView?.contentMode = .scaleAspectFit

        self.slider.isHidden = true
        self.slider.delegate = self

        // Setup resume button and subtitle info label
        setupResumeButton()
        setupSubtitleInfoLabel()

        // Check for subtitles if this is a video
        if iMediaType == "movies" {
            checkForSubtitles()
        }
    }

    private func setupResumeButton() {
        view.addSubview(btnResume)
        view.addSubview(btnStartOver)
        view.addSubview(resumeTimeLabel)

        NSLayoutConstraint.activate([
            // Resume button - positioned where the Play button is (same leading edge)
            btnResume.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 150),
            btnResume.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150),
            btnResume.heightAnchor.constraint(equalToConstant: 80),

            // Start Over button - positioned to the right of the Resume button
            btnStartOver.leadingAnchor.constraint(equalTo: btnResume.trailingAnchor, constant: 30),
            btnStartOver.centerYAnchor.constraint(equalTo: btnResume.centerYAnchor),
            btnStartOver.heightAnchor.constraint(equalToConstant: 80),

            // Time remaining label - below the resume button
            resumeTimeLabel.leadingAnchor.constraint(equalTo: btnResume.leadingAnchor),
            resumeTimeLabel.topAnchor.constraint(equalTo: btnResume.bottomAnchor, constant: 8)
        ])
    }

    private func setupSubtitleInfoLabel() {
        view.addSubview(subtitleInfoLabel)
        NSLayoutConstraint.activate([
            subtitleInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 100),
            subtitleInfoLabel.topAnchor.constraint(equalTo: txtDescription.bottomAnchor, constant: 20)
        ])
    }

    private func checkForSubtitles() {
        guard let identifier = iIdentifier else { return }

        Task {
            do {
                let metadataResponse = try await APIManager.sharedManager.getMetaDataTyped(identifier: identifier)

                guard let files = metadataResponse.files else { return }

                let subtitleTracks = SubtitleManager.shared.extractSubtitleTracks(
                    from: files,
                    identifier: identifier,
                    server: metadataResponse.server
                )

                if !subtitleTracks.isEmpty {
                    // Build subtitle info text
                    let trackCount = subtitleTracks.count
                    let languages = subtitleTracks.compactMap { track -> String? in
                        // Only include if a specific language was detected
                        if track.languageCode != nil {
                            return track.languageDisplayName
                        }
                        return nil
                    }
                    let uniqueLanguages = Array(Set(languages)).sorted()

                    var infoText = "CC  Subtitles available"
                    if !uniqueLanguages.isEmpty {
                        infoText = "CC  Subtitles: \(uniqueLanguages.joined(separator: ", "))"
                    } else if trackCount == 1 {
                        infoText = "CC  1 subtitle track available"
                    } else {
                        infoText = "CC  \(trackCount) subtitle tracks available"
                    }

                    subtitleInfoLabel.text = infoText
                    subtitleInfoLabel.isHidden = false
                }
            } catch {
                // Silently fail - subtitle info is not critical
                NSLog("Failed to check for subtitles: \(error)")
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Check for saved playback progress and update resume UI
        updateResumeUI()

        // Hide favorite button if API credentials are not configured (read-only mode)
        if !AppConfiguration.shared.isConfigured {
            btnFavorite.isHidden = true
            return
        }

        if let favorites = Global.getFavoriteData(),
           let identifier = iIdentifier,
           favorites.contains(identifier) {
            btnFavorite.setImage(UIImage(named: "favorited.png"), for: .normal)
            btnFavorite.tag = 1
        } else {
            btnFavorite.setImage(UIImage(named: "favorite.png"), for: .normal)
            btnFavorite.tag = 0
        }
    }

    /// Update the resume button UI based on saved progress
    private func updateResumeUI() {
        guard let identifier = iIdentifier else {
            hideResumeUI()
            return
        }

        // Check for saved progress
        if let progress = PlaybackProgressManager.shared.getProgress(for: identifier),
           !progress.isComplete,
           progress.currentTime > 10 {
            savedProgress = progress
            showResumeUI(progress: progress)
        } else {
            savedProgress = nil
            hideResumeUI()
        }
    }

    /// Show the resume button and hide the Play button
    private func showResumeUI(progress: PlaybackProgress) {
        // Hide the original Play button
        btnPlay.isHidden = true

        // Show Resume and Start Over buttons
        btnResume.isHidden = false
        btnStartOver.isHidden = false
        resumeTimeLabel.isHidden = false
        resumeTimeLabel.text = progress.formattedTimeRemaining
    }

    /// Hide the resume buttons and restore Play button
    private func hideResumeUI() {
        // Show the original Play button
        btnPlay.isHidden = false

        // Hide Resume and Start Over buttons
        btnResume.isHidden = true
        btnStartOver.isHidden = true
        resumeTimeLabel.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Save audio progress and clean up timer when leaving
        if btnPlay.tag == 1 {
            saveAudioProgress()
        }
        stopAudioProgressTracking()
    }

    @IBAction func onPlay(_ sender: Any) {
        if self.btnPlay.tag == 1 {
            stopPlaying()
            return
        }

        guard let identifier = iIdentifier, let mediaType = iMediaType else {
            Global.showAlert(title: "Error", message: "Missing item information", target: self)
            return
        }

        // Start from beginning (this is only called when there's no saved progress)
        startPlayback(identifier: identifier, mediaType: mediaType, resumeTime: nil)
    }

    /// Resume playback from saved position
    @objc private func onResume() {
        guard let identifier = iIdentifier,
              let mediaType = iMediaType,
              let progress = savedProgress else {
            Global.showAlert(title: "Error", message: "No saved progress found", target: self)
            return
        }

        // Resume from saved position
        startPlayback(identifier: identifier, mediaType: mediaType, resumeTime: progress.currentTime)
    }

    /// Start playback from the beginning, clearing any saved progress
    @objc private func onStartOver() {
        guard let identifier = iIdentifier, let mediaType = iMediaType else {
            Global.showAlert(title: "Error", message: "Missing item information", target: self)
            return
        }

        // Clear saved progress when starting over
        if let progress = savedProgress {
            PlaybackProgressManager.shared.removeProgress(for: progress.itemIdentifier, filename: progress.filename)
            savedProgress = nil
        }

        // Start from beginning
        startPlayback(identifier: identifier, mediaType: mediaType, resumeTime: nil)
    }

    /// Start playback with optional resume position
    private func startPlayback(identifier: String, mediaType: String, resumeTime: Double?) {
        AppProgressHUD.sharedManager.show(view: self.view)

        Task {
            do {
                // Use retry for metadata loading
                let metadataResponse = try await RetryMechanism.execute(config: .single) {
                    try await APIManager.sharedManager.getMetaDataTyped(identifier: identifier)
                }

                AppProgressHUD.sharedManager.hide()

                guard let files = metadataResponse.files else {
                    let context = ErrorContext(
                        operation: .loadMedia,
                        userFacingTitle: "Playback Error",
                        additionalInfo: ["identifier": identifier]
                    )
                    ErrorPresenter.shared.present(
                        NetworkError.resourceNotFound,
                        context: context,
                        on: self
                    )
                    return
                }

                let filesToPlay = files.filter { file in
                    let ext = file.name.suffix(4)
                    if mediaType == "movies" {
                        return ext == ".mp4"
                    } else if mediaType == "etree" {
                        return ext == ".mp3"
                    }
                    return false
                }

                guard !filesToPlay.isEmpty else {
                    let context = ErrorContext(
                        operation: .loadMedia,
                        userFacingTitle: "Playback Error",
                        additionalInfo: ["identifier": identifier, "mediaType": mediaType]
                    )
                    ErrorPresenter.shared.present(
                        NetworkError.resourceNotFound,
                        context: context,
                        on: self
                    )
                    return
                }

                let filename = filesToPlay[0].name
                self.currentFilename = filename

                // Use URL APIs for proper path encoding (appendingPathComponent handles special characters)
                guard let downloadBaseURL = URL(string: "https://archive.org/download") else {
                    let context = ErrorContext(
                        operation: .loadMedia,
                        userFacingTitle: "Playback Error",
                        additionalInfo: ["identifier": identifier, "filename": filename]
                    )
                    ErrorPresenter.shared.present(
                        NetworkError.invalidParameters,
                        context: context,
                        on: self
                    )
                    return
                }
                let mediaURL = downloadBaseURL
                    .appendingPathComponent(identifier)
                    .appendingPathComponent(filename)

                let asset = AVAsset(url: mediaURL)
                let playerItem = AVPlayerItem(asset: asset)
                self.player = AVPlayer(playerItem: playerItem)

                if mediaType == "movies" {
                    // Extract subtitle tracks from metadata
                    let subtitleTracks = SubtitleManager.shared.extractSubtitleTracks(
                        from: files,
                        identifier: identifier,
                        server: metadataResponse.server
                    )

                    // Use custom video player with subtitle support and progress tracking
                    let playerViewController = VideoPlayerViewController(
                        player: self.player,
                        subtitleTracks: subtitleTracks,
                        identifier: identifier,
                        filename: filename,
                        title: iTitle,
                        thumbnailURL: iImageURL?.absoluteString,
                        resumeFromTime: resumeTime
                    )
                    playerViewController.delegate = self

                    self.present(playerViewController, animated: true) {
                        self.player.play()
                    }

                    ErrorLogger.shared.logSuccess(
                        operation: .playVideo,
                        info: [
                            "identifier": identifier,
                            "filename": filename,
                            "subtitleTracksCount": "\(subtitleTracks.count)",
                            "resuming": resumeTime != nil ? "true" : "false"
                        ]
                    )
                } else if mediaType == "etree" {
                    self.startPlaying(resumeTime: resumeTime)

                    ErrorLogger.shared.logSuccess(
                        operation: .playAudio,
                        info: [
                            "identifier": identifier,
                            "filename": filename,
                            "resuming": resumeTime != nil ? "true" : "false"
                        ]
                    )
                }

            } catch {
                AppProgressHUD.sharedManager.hide()

                let context = ErrorContext(
                    operation: .loadMedia,
                    userFacingTitle: "Playback Error",
                    additionalInfo: ["identifier": identifier, "mediaType": mediaType]
                )

                ErrorPresenter.shared.present(
                    error,
                    context: context,
                    on: self,
                    retry: { [weak self] in
                        self?.startPlayback(identifier: identifier, mediaType: mediaType, resumeTime: resumeTime)
                    }
                )
            }
        }
    }

    @IBAction func onFavorite(_ sender: Any) {
        guard Global.getUserData() != nil,
              let identifier = iIdentifier,
              let mediaType = iMediaType,
              let title = iTitle else {
            Global.showAlert(title: "Error", message: "Login is required", target: self)
            return
        }

        if btnFavorite.tag == 0 {
            btnFavorite.setImage(UIImage(named: "favorited.png"), for: .normal)
            btnFavorite.tag = 1
            Global.saveFavoriteData(identifier: identifier)
        } else {
            btnFavorite.setImage(UIImage(named: "favorite.png"), for: .normal)
            btnFavorite.tag = 0
            Global.removeFavoriteData(identifier: identifier)
        }

        // Note: FavoriteItemParams would be used when saveFavoriteItem API is implemented
        // For now, just log the local save operation
        _ = FavoriteItemParams(
            identifier: identifier,
            mediatype: mediaType,
            title: title
        )

        ErrorLogger.shared.logSuccess(
            operation: .saveFavorite,
            info: ["identifier": identifier, "action": btnFavorite.tag == 1 ? "add" : "remove"]
        )
    }

    private func onMoreButtonPressed(text: String?) {
        guard let text = text else {
            return
        }

        let textViewerController = TvOSTextViewerViewController()
        textViewerController.text = text
        textViewerController.textEdgeInsets = UIEdgeInsets(top: 100, left: 250, bottom: 100, right: 250)
        present(textViewerController, animated: true, completion: nil)
    }

    @objc func playerDidFinishPlaying(not: NSNotification) {
        // Clear progress when finished (completed)
        if let identifier = iIdentifier, let filename = currentFilename {
            PlaybackProgressManager.shared.removeProgress(for: identifier, filename: filename)
        }
        stopPlaying()
    }

    func normalizedPowerLevelFromDecibels(_ decibels: Float) -> Float {
        if decibels < -60.0 || decibels == 0.0 {
            return 0.0
        }
        return powf((powf(10.0, 0.05 * decibels) - powf(10.0, 0.05 * -60.0)) * (1.0 / (1.0 - powf(10.0, 0.05 * -60.0))), 1.0 / 2.0)
    }

    func startPlaying(resumeTime: Double? = nil) {
        self.player.play()
        self.btnPlay.tag = 1
        self.btnPlay.setImage(UIImage(named: "stop.png"), for: .normal)
        self.slider.leftLabel.text = format(forTime: 0.0)

        // Load duration asynchronously using modern API
        Task {
            if let asset = player.currentItem?.asset {
                do {
                    let duration = try await asset.load(.duration)
                    self.slider.max = duration.seconds

                    // Seek to resume position after duration is loaded
                    if let resumeTime = resumeTime, resumeTime > 0 {
                        let targetTime = CMTime(seconds: resumeTime, preferredTimescale: 600)
                        await self.player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
                        self.slider.set(value: resumeTime, animated: false)
                    }
                } catch {
                    // Fallback: duration will remain at default
                }
            }
        }

        self.slider.isHidden = false
        UIApplication.shared.isIdleTimerDisabled = true

        // Remove any existing observer before adding a new one to prevent duplicates
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)

        // Start audio progress tracking
        startAudioProgressTracking()
    }

    func stopPlaying() {
        // Remove playback observer
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)

        // Save audio progress before stopping
        saveAudioProgress()
        stopAudioProgressTracking()

        if self.player.rate != 0 && self.player.error == nil {
            self.player.pause()
        }

        self.btnPlay.tag = 0
        self.btnPlay.setImage(UIImage(named: "play.png"), for: .normal)
        UIApplication.shared.isIdleTimerDisabled = false
        self.slider.set(value: 0.0, animated: false)
        self.slider.isHidden = true
    }

    // MARK: - Audio Progress Tracking

    /// Start periodic audio progress saving
    private func startAudioProgressTracking() {
        guard iMediaType == "etree", iIdentifier != nil, currentFilename != nil else { return }

        // Save progress every 10 seconds
        audioProgressTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.saveAudioProgress()
            }
        }
    }

    /// Stop audio progress tracking
    private func stopAudioProgressTracking() {
        audioProgressTimer?.invalidate()
        audioProgressTimer = nil
    }

    /// Save current audio playback progress
    private func saveAudioProgress() {
        guard iMediaType == "etree",
              let identifier = iIdentifier,
              let filename = currentFilename,
              let player = player,
              player.currentItem != nil else {
            return
        }

        let currentTime = player.currentTime().seconds
        let duration = slider.max

        // Don't save if at the very beginning (less than 10 seconds) or invalid duration
        guard currentTime >= 10, duration > 0 else { return }

        let progress = PlaybackProgress.audio(
            identifier: identifier,
            filename: filename,
            currentTime: currentTime,
            duration: duration,
            title: iTitle,
            imageURL: iImageURL?.absoluteString
        )

        PlaybackProgressManager.shared.saveProgress(progress)
    }

    private func format(forTime time: Double) -> String {
        let sign = time < 0 ? -1.0 : 1.0
        let minutes = Int(time * sign) / 60
        let seconds = Int(time * sign) % 60
        return (sign < 0 ? "-" : "") + "\(minutes):" + String(format: "%02d", seconds)
    }
}

extension ItemVC: @preconcurrency SliderDelegate {
    func sliderDidTap(slider: Slider) {
        print("tapped")
    }

    func slider(_ slider: Slider, textWithValue value: Double) -> String {
        format(forTime: value)
    }

    func slider(_ slider: Slider, didChangeValue value: Double) {
        slider.rightLabel.text = format(forTime: value - slider.max)
    }
}
