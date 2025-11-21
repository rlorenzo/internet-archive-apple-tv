//
//  SearchResultVC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//
//  Updated for Sprint 6: Async/await migration with typed models
//  Updated for Sprint 9: Modern UIKit patterns with DiffableDataSource
//

import UIKit
import AVKit

@MainActor
class SearchResultVC: UIViewController, UISearchResultsUpdating, UICollectionViewDelegate, AVPlayerViewControllerDelegate {

    @IBOutlet weak var clsVideo: UICollectionView!
    @IBOutlet weak var clsMusic: UICollectionView!
    @IBOutlet weak var lblMovies: UILabel!
    @IBOutlet weak var lblMusic: UILabel!

    private var videoDataSource: ItemDataSource!
    private var musicDataSource: ItemDataSource!
    private var videoPrefetcher: ImagePrefetcher!
    private var musicPrefetcher: ImagePrefetcher!

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
                Task {
                    await applyVideoSnapshot()
                    await applyMusicSnapshot()
                }
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

                    // Apply snapshots with modern diffable data sources
                    await self.applyVideoSnapshot()
                    await self.applyMusicSnapshot()

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
        configureVideoCollectionView()
        configureMusicCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clsVideo.isHidden = true
        clsMusic.isHidden = true
        lblMovies.isHidden = true
        lblMusic.isHidden = true
    }

    // MARK: - Configuration

    private func configureVideoCollectionView() {
        // Set up modern compositional layout
        clsVideo.collectionViewLayout = CompositionalLayoutBuilder.standardGrid

        // Register modern cell
        clsVideo.register(
            ModernItemCell.self,
            forCellWithReuseIdentifier: ModernItemCell.reuseIdentifier
        )

        // Configure diffable data source
        videoDataSource = ItemDataSource(collectionView: clsVideo) { collectionView, indexPath, itemViewModel in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ModernItemCell",
                for: indexPath
            ) as? ModernItemCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: itemViewModel)

            return cell
        }

        // Set up image prefetching
        videoPrefetcher = ImagePrefetcher(collectionView: clsVideo, dataSource: videoDataSource)
    }

    private func configureMusicCollectionView() {
        // Set up modern compositional layout
        clsMusic.collectionViewLayout = CompositionalLayoutBuilder.standardGrid

        // Register modern cell
        clsMusic.register(
            ModernItemCell.self,
            forCellWithReuseIdentifier: ModernItemCell.reuseIdentifier
        )

        // Configure diffable data source
        musicDataSource = ItemDataSource(collectionView: clsMusic) { collectionView, indexPath, itemViewModel in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ModernItemCell",
                for: indexPath
            ) as? ModernItemCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: itemViewModel)

            return cell
        }

        // Set up image prefetching
        musicPrefetcher = ImagePrefetcher(collectionView: clsMusic, dataSource: musicDataSource)
    }

    private func applyVideoSnapshot() async {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.videos])
        let viewModels = videoItems.map { ItemViewModel(item: $0, section: .videos) }
        snapshot.appendItems(viewModels, toSection: .videos)
        await videoDataSource.apply(snapshot, animatingDifferences: true)
    }

    private func applyMusicSnapshot() async {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.music])
        let viewModels = musicItems.map { ItemViewModel(item: $0, section: .music) }
        snapshot.appendItems(viewModels, toSection: .music)
        await musicDataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        query = searchController.searchBar.text ?? ""
    }

    // MARK: - UICollectionViewDelegate

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
