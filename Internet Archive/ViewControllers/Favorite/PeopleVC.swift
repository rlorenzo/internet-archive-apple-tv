//
//  PeopleVC.swift
//  Internet Archive
//
//  Created by mac-admin on 6/14/18.
//  Copyright © 2018 mac-admin. All rights reserved.
//
//  Updated for Sprint 6: Async/await migration with typed models
//

import UIKit

@MainActor
class PeopleVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var lblMovies: UILabel!
    @IBOutlet weak var lblMusic: UILabel!
    @IBOutlet weak var clsMovies: UICollectionView!
    @IBOutlet weak var clsMusic: UICollectionView!

    var identifier: String?
    var name: String?
    var movieItems: [SearchResult] = []
    var musicItems: [SearchResult] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clsMovies.isHidden = true
        self.clsMusic.isHidden = true
        self.lblMovies.isHidden = true
        self.lblMusic.isHidden = true

        loadData()
    }

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

                // Reload the collection view to reflect the changes.
                self.clsMovies.reloadData()
                self.clsMusic.reloadData()
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

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == clsMovies {
            return movieItems.count
        } else if collectionView == clsMusic {
            return musicItems.count
        } else {
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let itemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as? ItemCell else {
            return UICollectionViewCell()
        }

        let items: [SearchResult] = (collectionView == clsMovies) ? movieItems : musicItems
        let item = items[indexPath.row]

        itemCell.itemTitle.text = item.safeTitle

        let imageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(item.identifier)")
        if let imageURL = imageURL {
            itemCell.itemImage.af_setImage(withURL: imageURL)
        }

        return itemCell
    }

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

        self.present(itemVC, animated: true, completion: nil)
    }
}
