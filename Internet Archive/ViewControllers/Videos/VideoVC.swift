//
//  VideoVC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//
//  Updated for Sprint 6: Async/await migration with typed models
//

import UIKit
import AlamofireImage

@MainActor
class VideoVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!

    var items: [SearchResult] = []
    var collection = "movies"

    private let screenSize = UIScreen.main.bounds.size

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure collection view for dark mode support
        self.collectionView.backgroundColor = .clear
        self.view.backgroundColor = .clear

        AppProgressHUD.sharedManager.show(view: self.view)

        Task {
            do {
                let result = try await APIManager.sharedManager.getCollectionsTyped(
                    collection: collection,
                    resultType: "collection",
                    limit: nil as Int?
                )

                AppProgressHUD.sharedManager.hide()

                self.collection = result.collection
                self.items = result.results.sorted { item1, item2 -> Bool in
                    (item1.downloads ?? 0) > (item2.downloads ?? 0)
                }
                self.collectionView?.reloadData()

            } catch {
                AppProgressHUD.sharedManager.hide()
                NSLog("VideoVC Error: \(error)")
                if let decodingError = error as? DecodingError {
                    NSLog("Decoding error details: \(decodingError)")
                }
                Global.showServiceUnavailableAlert(target: self)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let itemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as? ItemCell else {
            return UICollectionViewCell()
        }

        let item = items[indexPath.row]
        itemCell.itemTitle.text = item.safeTitle
        itemCell.itemTitle.textColor = .label

        let imageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(item.identifier)")
        if let imageURL = imageURL {
            itemCell.itemImage.af_setImage(withURL: imageURL)
        }

        return itemCell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let yearsVC = self.storyboard?.instantiateViewController(withIdentifier: "YearsVC") as? YearsVC else {
            return
        }

        let item = items[indexPath.row]
        yearsVC.collection = collection
        yearsVC.name = item.title ?? item.identifier
        yearsVC.identifier = item.identifier

        self.present(yearsVC, animated: true, completion: nil)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (screenSize.width / 5) - 100
        let height = width + 115
        let cellSize = CGSize(width: width, height: height)
        return cellSize
    }
}
