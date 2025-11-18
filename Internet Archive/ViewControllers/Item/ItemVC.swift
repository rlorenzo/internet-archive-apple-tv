//
//  ItemVC.swift
//  Internet Archive
//
//  Created by mac-admin on 5/29/18.
//  Copyright © 2018 mac-admin. All rights reserved.
//
//  Updated for Sprint 6: Async/await migration with typed models
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

    var player: AVPlayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        btnPlay.setImage(UIImage(named: "play.png"), for: .normal)

        txtTitle.text = iTitle
        txtArchivedBy.text = "Archived By:  \(iArchivedBy ?? "")"
        txtDate.text = "Date:  \(iDate ?? "")"
        txtDescription.text = iDescription

        if let imageURL = iImageURL {
            itemImage.af_setImage(withURL: imageURL)
        }

        txtDescription.buttonWasPressed = onMoreButtonPressed
        btnPlay.imageView?.contentMode = .scaleAspectFit
        btnFavorite.imageView?.contentMode = .scaleAspectFit

        self.slider.isHidden = true
        self.slider.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
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
                let metadataResponse = try await APIManager.sharedManager.getMetaDataTyped(identifier: identifier)
                AppProgressHUD.sharedManager.hide()

                guard let files = metadataResponse.files else {
                    Global.showAlert(title: "Error", message: "No files found", target: self)
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
                    Global.showAlert(title: "Error", message: "There is no playable content", target: self)
                    return
                }

                let filename = filesToPlay[0].name
                guard let encodedFilename = filename.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                      let mediaURL = URL(string: "https://archive.org/download/\(identifier)/\(encodedFilename)") else {
                    Global.showAlert(title: "Error", message: "Invalid media URL", target: self)
                    return
                }

                let asset = AVAsset(url: mediaURL)
                let playerItem = AVPlayerItem(asset: asset)
                self.player = AVPlayer(playerItem: playerItem)

                if mediaType == "movies" {
                    let playerViewController = AVPlayerViewController()
                    playerViewController.delegate = self
                    playerViewController.player = self.player

                    self.present(playerViewController, animated: true) {
                        self.player.play()
                    }
                } else if mediaType == "etree" {
                    self.startPlaying()
                }

            } catch {
                AppProgressHUD.sharedManager.hide()
                let errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                Global.showAlert(title: "Error", message: errorMessage, target: self)
            }
        }
    }

    @IBAction func onFavorite(_ sender: Any) {
        guard let userData = Global.getUserData(),
              let email = userData["email"] as? String,
              let password = userData["password"] as? String,
              !email.isEmpty,
              !password.isEmpty,
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

        Task {
            do {
                try await APIManager.sharedManager.saveFavoriteItem(
                    email: email,
                    password: password,
                    identifier: identifier,
                    mediatype: mediaType,
                    title: title
                )
            } catch {
                // Silently fail for now - favorite state already updated locally
                print("Failed to save favorite item: \(error)")
            }
        }
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

        if let duration = player.currentItem?.asset.duration.seconds {
            self.slider.max = duration
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

extension ItemVC: SliderDelegate {
    func sliderDidTap(slider: Slider) {
        print("tapped")
    }

    func slider(_ slider: Slider, textWithValue value: Double) -> String {
        return format(forTime: value)
    }

    func slider(_ slider: Slider, didChangeValue value: Double) {
        slider.rightLabel.text = format(forTime: value - slider.max)
    }
}
