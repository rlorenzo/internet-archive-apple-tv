//
//  PeopleVC.swift
//  Internet Archive
//
//  Created by mac-admin on 6/14/18.
//  Copyright © 2018 mac-admin. All rights reserved.
//
//

import UIKit

@MainActor
class PeopleVC: UIViewController, UICollectionViewDelegate {

    @IBOutlet weak var lblMovies: UILabel!
    @IBOutlet weak var lblMusic: UILabel!
    @IBOutlet weak var clsMovies: UICollectionView!
    @IBOutlet weak var clsMusic: UICollectionView!

    private var movieDataSource: ItemDataSource!
    private var musicDataSource: ItemDataSource!
    private var moviePrefetcher: ImagePrefetcher!
    private var musicPrefetcher: ImagePrefetcher!

    var identifier: String?
    var name: String?
    var movieItems: [SearchResult] = []
    var musicItems: [SearchResult] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        configureMovieCollectionView()
        configureMusicCollectionView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.clsMovies.isHidden = true
        self.clsMusic.isHidden = true
        self.lblMovies.isHidden = true
        self.lblMusic.isHidden = true

        loadData()
    }

    // MARK: - Configuration

    private func configureMovieCollectionView() {
        // Set up modern compositional layout
        clsMovies.collectionViewLayout = CompositionalLayoutBuilder.standardGrid

        // Register modern cell
        clsMovies.register(
            ModernItemCell.self,
            forCellWithReuseIdentifier: ModernItemCell.reuseIdentifier
        )

        // Configure diffable data source
        movieDataSource = ItemDataSource(collectionView: clsMovies) { collectionView, indexPath, itemViewModel in
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
        moviePrefetcher = ImagePrefetcher(collectionView: clsMovies, dataSource: movieDataSource)
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

    // MARK: - Data Loading

    private func loadData() {
        guard let identifier = identifier else { return }

        let username = identifier.suffix(identifier.count - 1)

        AppProgressHUD.sharedManager.show(view: self.view)

        Task {
            do {
                let favoritesResponse = try await APIManager.sharedManager.getFavoriteItemsTyped(username: String(username))

                guard let favorites = favoritesResponse.members, !favorites.isEmpty else {
                    AppProgressHUD.sharedManager.hide()
                    return
                }

                let identifiers = favorites.compactMap { item -> String? in
                    guard let mediaType = item.mediatype,
                          ["movies", "audio"].contains(mediaType) else {
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

                for item in searchResponse.response.docs {
                    switch item.safeMediaType {
                    case "movies":
                        self.movieItems.append(item)
                    case "audio":
                        self.musicItems.append(item)
                    default:
                        break
                    }
                }

                // Apply snapshots with modern diffable data sources
                await self.applyMovieSnapshot()
                await self.applyMusicSnapshot()

                self.clsMovies.isHidden = false
                self.clsMusic.isHidden = false
                self.lblMovies.isHidden = false
                self.lblMusic.isHidden = false

                AppProgressHUD.sharedManager.hide()

            } catch {
                AppProgressHUD.sharedManager.hide()
                let errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                Global.showAlert(title: "Error", message: "Error occurred while downloading favorites\n\(errorMessage)", target: self)
            }
        }
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let items: [SearchResult] = (collectionView == clsMovies) ? movieItems : musicItems
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
        itemVC.iLicenseURL = item.licenseurl

        self.present(itemVC, animated: true, completion: nil)
    }
}
