//
//  FavoriteVC.swift
//  Internet Archive
//
//  Created by mac-admin on 5/30/18.
//  Copyright © 2018 mac-admin. All rights reserved.
//
//  Updated for Sprint 6: Async/await migration with typed models
//  Updated for Sprint 9: Modern UIKit patterns with DiffableDataSource
//

import UIKit

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

    var movieItems: [SearchResult] = []
    var musicItems: [SearchResult] = []
    var peoples: [SearchResult] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        configureMovieCollectionView()
        configureMusicCollectionView()
        configurePeopleCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.clsMovie.isHidden = true
        self.clsMusic.isHidden = true
        self.clsPeople.isHidden = true
        self.lblMovies.isHidden = true
        self.lblMusic.isHidden = true
        self.lblPeople.isHidden = true

        guard Global.isLoggedIn(),
              let userData = Global.getUserData(),
              let username = userData["username"] as? String else {
            Global.showAlert(title: "Error", message: "Login is required", target: self)
            return
        }

        AppProgressHUD.sharedManager.show(view: self.view)

        Task {
            do {
                let favoritesResponse = try await APIManager.sharedManager.getFavoriteItemsTyped(username: username)

                guard let favorites = favoritesResponse.members, !favorites.isEmpty else {
                    AppProgressHUD.sharedManager.hide()
                    return
                }

                let identifiers = favorites.compactMap { item -> String? in
                    guard let mediaType = item.mediatype,
                          ["movies", "audio", "account"].contains(mediaType) else {
                        return nil
                    }
                    return item.identifier
                }

                guard !identifiers.isEmpty else {
                    AppProgressHUD.sharedManager.hide()
                    return
                }

                let options = [
                    "fl[]": "identifier,title,year,downloads,date,creator,description,mediatype",
                    "sort[]": "date+desc"
                ]

                let query = identifiers.joined(separator: " OR ")
                let searchResponse = try await APIManager.sharedManager.searchTyped(
                    query: "identifier:(\(query))",
                    options: options
                )

                self.movieItems.removeAll()
                self.musicItems.removeAll()
                self.peoples.removeAll()

                for item in searchResponse.response.docs {
                    switch item.safeMediaType {
                    case "movies":
                        self.movieItems.append(item)
                    case "audio":
                        self.musicItems.append(item)
                    case "account":
                        self.peoples.append(item)
                    default:
                        break
                    }
                }

                // Apply snapshots with modern diffable data sources
                await self.applyMovieSnapshot()
                await self.applyMusicSnapshot()
                await self.applyPeopleSnapshot()

                self.clsMovie.isHidden = false
                self.clsMusic.isHidden = false
                self.clsPeople.isHidden = false
                self.lblMovies.isHidden = false
                self.lblMusic.isHidden = false
                self.lblPeople.isHidden = false

                AppProgressHUD.sharedManager.hide()

            } catch {
                AppProgressHUD.sharedManager.hide()
                let errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                Global.showAlert(title: "Error", message: "Error occurred while downloading favorites\n\(errorMessage)", target: self)
            }
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
