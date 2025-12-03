//
//  FavoriteVC.swift
//  Internet Archive
//
//  Created by mac-admin on 5/30/18.
//  Copyright © 2018 mac-admin. All rights reserved.
//
//

import UIKit
import Combine

@MainActor
class FavoriteVC: UIViewController, UICollectionViewDelegate {

    @IBOutlet weak var clsMovie: UICollectionView!
    @IBOutlet weak var clsMusic: UICollectionView!
    @IBOutlet weak var clsPeople: UICollectionView!
    @IBOutlet weak var lblMovies: UILabel!
    @IBOutlet weak var lblMusic: UILabel!
    @IBOutlet weak var lblPeople: UILabel!

    private var movieDataSource: ItemDataSource!
    private var musicDataSource: ItemDataSource!
    private var peopleDataSource: ItemDataSource!
    private var moviePrefetcher: ImagePrefetcher!
    private var musicPrefetcher: ImagePrefetcher!
    private var peoplePrefetcher: ImagePrefetcher!

    // MARK: - ViewModel

    private lazy var viewModel: FavoritesViewModel = {
        FavoritesViewModel(favoritesService: DefaultFavoritesService())
    }()

    private var cancellables = Set<AnyCancellable>()

    // Computed properties from ViewModel state
    var movieItems: [SearchResult] {
        viewModel.state.movieResults
    }

    var musicItems: [SearchResult] {
        viewModel.state.musicResults
    }

    var peoples: [SearchResult] {
        viewModel.state.peopleResults
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureMovieCollectionView()
        configureMusicCollectionView()
        configurePeopleCollectionView()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideAllCollections()

        guard Global.isLoggedIn(),
              let userData = Global.getUserData(),
              let username = userData["username"] as? String else {
            Global.showAlert(title: "Error", message: "Login is required", target: self)
            return
        }

        loadFavorites(username: username)
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

    private func handleStateChange(_ state: FavoritesViewState) {
        if state.isLoading {
            AppProgressHUD.sharedManager.show(view: self.view)
            return
        }

        AppProgressHUD.sharedManager.hide()

        if let errorMessage = state.errorMessage {
            Global.showAlert(title: "Error", message: errorMessage, target: self)
            return
        }

        // Always apply snapshots to keep UI in sync with state
        Task {
            await applyMovieSnapshot()
            await applyMusicSnapshot()
            await applyPeopleSnapshot()
        }

        // Show or hide collections based on results
        if state.hasResults {
            showAllCollections()
        } else {
            hideAllCollections()
        }
    }

    private func hideAllCollections() {
        clsMovie.isHidden = true
        clsMusic.isHidden = true
        clsPeople.isHidden = true
        lblMovies.isHidden = true
        lblMusic.isHidden = true
        lblPeople.isHidden = true
    }

    private func showAllCollections() {
        clsMovie.isHidden = false
        clsMusic.isHidden = false
        clsPeople.isHidden = false
        lblMovies.isHidden = false
        lblMusic.isHidden = false
        lblPeople.isHidden = false
    }

    private func loadFavorites(username: String) {
        Task {
            await viewModel.loadFavoritesWithDetails(
                username: username,
                searchService: DefaultSearchService()
            )
        }
    }

    // MARK: - Configuration

    private func configureMovieCollectionView() {
        // Set up modern compositional layout
        clsMovie.collectionViewLayout = CompositionalLayoutBuilder.standardGrid

        // Register modern cell
        clsMovie.register(
            ModernItemCell.self,
            forCellWithReuseIdentifier: ModernItemCell.reuseIdentifier
        )

        // Configure diffable data source
        movieDataSource = ItemDataSource(collectionView: clsMovie) { collectionView, indexPath, itemViewModel in
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
        moviePrefetcher = ImagePrefetcher(collectionView: clsMovie, dataSource: movieDataSource)
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

    private func configurePeopleCollectionView() {
        // Set up modern compositional layout
        clsPeople.collectionViewLayout = CompositionalLayoutBuilder.standardGrid

        // Register modern cell
        clsPeople.register(
            ModernItemCell.self,
            forCellWithReuseIdentifier: ModernItemCell.reuseIdentifier
        )

        // Configure diffable data source
        peopleDataSource = ItemDataSource(collectionView: clsPeople) { collectionView, indexPath, itemViewModel in
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
        peoplePrefetcher = ImagePrefetcher(collectionView: clsPeople, dataSource: peopleDataSource)
    }

    private func applyMovieSnapshot() async {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.videos])
        let viewModels = movieItems.map { ItemViewModel(item: $0, section: .videos) }
        snapshot.appendItems(viewModels, toSection: .videos)
        await movieDataSource.apply(snapshot, animatingDifferences: true)
    }

    private func applyMusicSnapshot() async {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.music])
        let viewModels = musicItems.map { ItemViewModel(item: $0, section: .music) }
        snapshot.appendItems(viewModels, toSection: .music)
        await musicDataSource.apply(snapshot, animatingDifferences: true)
    }

    private func applyPeopleSnapshot() async {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.people])
        let viewModels = peoples.map { ItemViewModel(item: $0, section: .people) }
        snapshot.appendItems(viewModels, toSection: .people)
        await peopleDataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == clsPeople {
            let item = peoples[indexPath.row]

            guard let peopleVC = self.storyboard?.instantiateViewController(withIdentifier: "PeopleVC") as? PeopleVC else {
                return
            }

            peopleVC.identifier = item.identifier
            peopleVC.name = item.title

            self.present(peopleVC, animated: true, completion: nil)
        } else {
            let items: [SearchResult] = (collectionView == clsMovie) ? movieItems : musicItems
            let item = items[indexPath.row]

            guard let itemVC = self.storyboard?.instantiateViewController(withIdentifier: "ItemVC") as? ItemVC else {
                return
            }

            itemVC.iIdentifier = item.identifier
            itemVC.iTitle = item.title ?? ""
            itemVC.iArchivedBy = item.creator ?? ""
            itemVC.iDate = item.date ?? ""
            itemVC.iDescription = item.description ?? ""
            itemVC.iMediaType = item.mediatype ?? ""
            itemVC.iImageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(item.identifier)")

            self.present(itemVC, animated: true, completion: nil)
        }
    }
}
