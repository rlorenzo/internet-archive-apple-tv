//
//  YearsVC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//

import UIKit
import AlamofireImage

class YearsVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var lblTitle: UILabel!

    var name = ""
    var identifier = ""
    var collection = ""
    var sortedData: [String: [[String: Any]]] = [:]
    var sortedKeys = [String]()

    private var selectedRow = 0
    private let screenSize = UIScreen.main.bounds.size

    override func viewDidLoad() {
        super.viewDidLoad()

        self.sortedData.removeAll()
        self.tableView.isHidden = true
        self.collectionView.isHidden = true
        self.lblTitle.isHidden = true
        self.lblTitle.text = name

        AppProgressHUD.sharedManager.show(view: self.view)

        APIManager.sharedManager.getCollections(collection: identifier, resultType: collection, limit: 5000) { _, data, _ in

            AppProgressHUD.sharedManager.hide()

            if let data = data {
                for item in data {
                    var year = "Undated"

                    // Handle year as either String or Int
                    if let yearStr = item["year"] as? String {
                        year = yearStr
                    } else if let yearInt = item["year"] as? Int {
                        year = String(yearInt)
                    }

                    if var yearData = self.sortedData[year] {
                        yearData.append(item)
                        self.sortedData[year] = yearData
                    } else {
                        self.sortedData[year] = [item]
                    }
                }

                self.sortedKeys = self.sortedData.keys.sorted(by: { year1, year2 -> Bool in
                    year1 > year2
                })

                self.tableView.reloadData()
                self.tableView.isHidden = false
                self.collectionView.isHidden = false
                self.lblTitle.isHidden = false
            } else {
                Global.showAlert(title: "Error", message: "An error occurred while downloading items. Please try again later.", target: self)
            }
        }
    }

    // MARK: - UITableView datasource, delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sortedKeys.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let yearCell = tableView.dequeueReusableCell(withIdentifier: "YearCell", for: indexPath) as? YearCell else {
            return UITableViewCell()
        }
        yearCell.lblYear.text = sortedKeys[indexPath.row]
        yearCell.lblYear.textColor = .label

        return yearCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRow = indexPath.row
        collectionView.reloadData()
    }

    // MARK: - UICollectionView datasource, delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if sortedData.isEmpty {
            return 0
        } else {
            return sortedData[sortedKeys[selectedRow]]?.count ?? 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let itemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as? ItemCell,
              let yearData = sortedData[sortedKeys[selectedRow]],
              indexPath.row < yearData.count else {
            return UICollectionViewCell()
        }

        let data = yearData[indexPath.row]
        itemCell.itemTitle.text = data["title"] as? String
        itemCell.itemTitle.textColor = .label
        if let identifier = data["identifier"] as? String,
           let imageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(identifier)") {
            itemCell.itemImage.af_setImage(withURL: imageURL)
        }

        return itemCell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let yearData = sortedData[sortedKeys[selectedRow]],
              indexPath.row < yearData.count else {
            return
        }

        let data = yearData[indexPath.row]
        let identifier = data["identifier"] as? String
        let title = data["title"] as? String
        let archivedBy = data["creator"] as? String
        let date = Global.formatDate(string: data["date"] as? String)
        let description = data["description"] as? String
        let mediaType = data["mediatype"] as? String

        var imageURL: URL?
        if let identifierString = data["identifier"] as? String {
            imageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(identifierString)")
        }

        guard let itemVC = self.storyboard?.instantiateViewController(withIdentifier: "ItemVC") as? ItemVC else {
            return
        }

        itemVC.iIdentifier = identifier
        itemVC.iTitle = title ?? ""
        itemVC.iArchivedBy = archivedBy ?? ""
        itemVC.iDate = date ?? ""
        itemVC.iDescription = description ?? ""
        itemVC.iMediaType = mediaType ?? ""
        itemVC.iImageURL = imageURL

        self.present(itemVC, animated: true, completion: nil)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (screenSize.width / 4) - 100
        let height = width + 115
        let cellSize = CGSize(width: width, height: height)
        return cellSize
    }
}
