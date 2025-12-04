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
import Combine

@MainActor
class SearchResultVC: UIViewController, UISearchResultsUpdating, UICollectionViewDelegate {

    @IBOutlet weak var clsVideo: UICollectionView!
    @IBOutlet weak var clsMusic: UICollectionView!
    @IBOutlet weak var lblMovies: UILabel!
    @IBOutlet weak var lblMusic: UILabel!

    private var videoDataSource: ItemDataSource!
    private var musicDataSource: ItemDataSource!
    private var videoPrefetcher: ImagePrefetcher!
    private var musicPrefetcher: ImagePrefetcher!

    // MARK: - ViewModel

    private lazy var viewModel: SearchViewModel = {
        SearchViewModel(searchService: DefaultSearchService())
    }()

    private var cancellables = Set<AnyCancellable>()
    private var lastQuery = ""

    // Computed properties from ViewModel state
    var videoItems: [SearchResult] {
        viewModel.state.videoResults
    }

    var musicItems: [SearchResult] {
        viewModel.state.musicResults
    }

    var query = "" {
        didSet {
            let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
            guard trimmedQuery != lastQuery else { return }
            lastQuery = trimmedQuery

            if trimmedQuery.isEmpty {
                viewModel.clearResults()
                return
            }

            performSearch(query: trimmedQuery)
        }
    }

    private func performSearch(query: String) {
        AppProgressHUD.sharedManager.show(view: self.view)
        clsVideo.isHidden = true
        clsMusic.isHidden = true
        lblMovies.isHidden = true
        lblMusic.isHidden = true

        Task {
            await viewModel.searchMoviesAndMusic(query: query)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureVideoCollectionView()
        configureMusicCollectionView()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clsVideo.isHidden = true
        clsMusic.isHidden = true
        lblMovies.isHidden = true
        lblMusic.isHidden = true
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }

    private func handleStateChange(_ state: SearchViewState) {
        if state.isLoading {
            return // Wait for results
        }

        AppProgressHUD.sharedManager.hide()

        if let errorMessage = state.errorMessage {
            let context = ErrorContext(
                operation: .search,
                userFacingTitle: "Search Failed",
                additionalInfo: ["query": lastQuery]
            )
            Global.showAlert(title: context.userFacingTitle, message: errorMessage, target: self)
            return
        }

        // Show collections if we have results
        let hasResults = !state.results.isEmpty
        clsVideo.isHidden = !hasResults
        clsMusic.isHidden = !hasResults
        lblMovies.isHidden = !hasResults
        lblMusic.isHidden = !hasResults

        // Apply snapshots
        Task {
            await applyVideoSnapshot()
            await applyMusicSnapshot()
        }
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

}

// MARK: - AVPlayerViewControllerDelegate
@MainActor
extension SearchResultVC: @preconcurrency AVPlayerViewControllerDelegate {
    func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
        UIApplication.shared.isIdleTimerDisabled = false
        return true
    }
}
