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

        // Setup subtitle info label
        setupSubtitleInfoLabel()

        // Check for subtitles if this is a video
        if iMediaType == "movies" {
            checkForSubtitles()
        }
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

    @IBAction func onPlay(_ sender: Any) {
        if self.btnPlay.tag == 1 {
            stopPlyaing()
            return
        }

        guard let identifier = iIdentifier, let mediaType = iMediaType else {
            Global.showAlert(title: "Error", message: "Missing item information", target: self)
            return
        }

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
                guard let encodedFilename = filename.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                      let mediaURL = URL(string: "https://archive.org/download/\(identifier)/\(encodedFilename)") else {
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

                    // Use custom video player with subtitle support
                    let playerViewController = VideoPlayerViewController(
                        player: self.player,
                        subtitleTracks: subtitleTracks,
                        identifier: identifier
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
                            "subtitleTracksCount": "\(subtitleTracks.count)"
                        ]
                    )
                } else if mediaType == "etree" {
                    self.startPlaying()

                    ErrorLogger.shared.logSuccess(
                        operation: .playAudio,
                        info: ["identifier": identifier, "filename": filename]
                    )
                }

            } catch {
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
                        self?.onPlay(sender)
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
        stopPlyaing()
    }

    func normalizedPowerLevelFromDecibels(_ decibels: Float) -> Float {
        if decibels < -60.0 || decibels == 0.0 {
            return 0.0
        }
        return powf((powf(10.0, 0.05 * decibels) - powf(10.0, 0.05 * -60.0)) * (1.0 / (1.0 - powf(10.0, 0.05 * -60.0))), 1.0 / 2.0)
    }

    func startPlaying() {
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
                } catch {
                    // Fallback: duration will remain at default
                }
            }
        }

        self.slider.isHidden = false
        UIApplication.shared.isIdleTimerDisabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }

    func stopPlyaing() {
        if self.player.rate != 0 && self.player.error == nil {
            self.player.pause()
        }

        self.btnPlay.tag = 0
        self.btnPlay.setImage(UIImage(named: "play.png"), for: .normal)
        UIApplication.shared.isIdleTimerDisabled = false
        self.slider.set(value: 0.0, animated: false)
        self.slider.isHidden = true
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
