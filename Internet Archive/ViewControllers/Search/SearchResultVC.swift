//
//  SearchResultVC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//
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
                    // Use retry mechanism for network resilience
                    let searchResponse = try await RetryMechanism.execute(config: .standard) {
                        let options = [
                            "rows": "50",
                            "fl[]": "identifier,title,downloads,mediatype"
                        ]

                        return try await APIManager.sharedManager.searchTyped(
                            query: "\(trimedQuery) AND mediatype:(etree OR movies)",
                            options: options
                        )
                    }

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

                    // Log success
                    ErrorLogger.shared.logSuccess(
                        operation: .search,
                        info: ["query": trimedQuery, "results": searchResponse.response.docs.count]
                    )

                } catch {
                    // Use centralized error presenter
                    let context = ErrorContext(
                        operation: .search,
                        userFacingTitle: "Search Failed",
                        additionalInfo: ["query": trimedQuery]
                    )

                    ErrorPresenter.shared.present(
                        error,
                        context: context,
                        on: self,
                        retry: { [weak self] in
                            self?.query = trimedQuery
                        }
                    )
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
                    return ext == ".mp4" || ext == ".mp3"
                }

                guard !filesToPlay.isEmpty else {
                    let context = ErrorContext(
                        operation: .loadMedia,
                        userFacingTitle: "Playback Error",
                        additionalInfo: ["identifier": identifier, "reason": "no_playable_files"]
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
                let playerViewController = AVPlayerViewController()
                playerViewController.delegate = self

                let player = AVPlayer(playerItem: playerItem)
                playerViewController.player = player

                self.present(playerViewController, animated: true) {
                    player.play()
                }

                ErrorLogger.shared.logSuccess(
                    operation: .playVideo,
                    info: ["identifier": identifier, "filename": filename]
                )

            } catch {
                let context = ErrorContext(
                    operation: .loadMedia,
                    userFacingTitle: "Playback Error",
                    additionalInfo: ["identifier": identifier]
                )

                ErrorPresenter.shared.present(
                    error,
                    context: context,
                    on: self,
                    retry: { [weak self] in
                        self?.collectionView(collectionView, didSelectItemAt: indexPath)
                    }
                )
            }
        }
    }

    func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
        UIApplication.shared.isIdleTimerDisabled = false
        return true
    }
}
