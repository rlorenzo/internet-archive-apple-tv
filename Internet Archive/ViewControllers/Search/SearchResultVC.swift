//
//  SearchResultVC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//
//  Updated for Sprint 6: Async/await migration with typed models
//

import UIKit
import AVKit

@MainActor
class SearchResultVC: UIViewController, UISearchResultsUpdating, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, AVPlayerViewControllerDelegate {

    @IBOutlet weak var clsVideo: UICollectionView!
    @IBOutlet weak var clsMusic: UICollectionView!
    @IBOutlet weak var lblMovies: UILabel!
    @IBOutlet weak var lblMusic: UILabel!

    var videoItems: [SearchResult] = []
    var musicItems: [SearchResult] = []

    var query = "" {
        didSet {
            // Return if the filter string hasn't changed.
            let trimedQuery = query.trimmingCharacters(in: .whitespaces)
            guard trimedQuery != oldValue else { return }
            if trimedQuery.isEmpty {
                videoItems.removeAll()
                musicItems.removeAll()
                self.clsVideo.reloadData()
                self.clsMusic.reloadData()

                return
            }
            // Apply the filter or show all items if the filter string is empty.

            AppProgressHUD.sharedManager.show(view: self.view)
            videoItems.removeAll()
            musicItems.removeAll()

            clsVideo.isHidden = true
            clsMusic.isHidden = true
            lblMovies.isHidden = true
            lblMusic.isHidden = true

            Task {
                do {
                    let options = [
                        "rows": "50",
                        "fl[]": "identifier,title,downloads,mediatype"
                    ]

                    let searchResponse = try await APIManager.sharedManager.searchTyped(
                        query: "\(trimedQuery) AND mediatype:(etree OR movies)",
                        options: options
                    )

                    self.clsVideo.isHidden = false
                    self.clsMusic.isHidden = false
                    self.lblMovies.isHidden = false
                    self.lblMusic.isHidden = false

                    for item in searchResponse.response.docs {
                        if item.safeMediaType == "movies" {
                            self.videoItems.append(item)
                        } else {
                            self.musicItems.append(item)
                        }
                    }

                    // Reload the collection view to reflect the changes.
                    self.clsVideo.reloadData()
                    self.clsMusic.reloadData()

                    AppProgressHUD.sharedManager.hide()

                } catch {
                    AppProgressHUD.sharedManager.hide()
                    let errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                    Global.showAlert(title: "Error", message: errorMessage, target: self)
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        clsVideo.isHidden = true
        clsMusic.isHidden = true
        lblMovies.isHidden = true
        lblMusic.isHidden = true
    }

    func updateSearchResults(for searchController: UISearchController) {
        query = searchController.searchBar.text ?? ""
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == clsVideo {
            return videoItems.count
        } else {
            return musicItems.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let itemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as? ItemCell else {
            return UICollectionViewCell()
        }

        let items = (collectionView == clsVideo) ? videoItems : musicItems
        let item = items[indexPath.row]

        itemCell.itemTitle.text = "\(item.safeTitle) (\(item.downloads ?? 0))"

        let imageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(item.identifier)")
        if let imageURL = imageURL {
            itemCell.itemImage.af.setImage(withURL: imageURL)
        }

        return itemCell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let items = (collectionView == clsVideo) ? videoItems : musicItems
        let identifier = items[indexPath.row].identifier

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
                    return ext == ".mp4" || ext == ".mp3"
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
                let playerViewController = AVPlayerViewController()
                playerViewController.delegate = self

                let player = AVPlayer(playerItem: playerItem)
                playerViewController.player = player

                self.present(playerViewController, animated: true) {
                    player.play()
                }

            } catch {
                AppProgressHUD.sharedManager.hide()
                let errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                Global.showAlert(title: "Error", message: errorMessage, target: self)
            }
        }
    }

    func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
        UIApplication.shared.isIdleTimerDisabled = false
        return true
    }
}
