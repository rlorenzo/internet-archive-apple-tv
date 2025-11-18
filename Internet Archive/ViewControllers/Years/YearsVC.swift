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
    var sortedData:[String: [[String: Any]]] = [:]
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
        
        APIManager.sharedManager.getCollections(collection: identifier, resultType: collection, limit: 5000) { (collection, data, err) in
            
            AppProgressHUD.sharedManager.hide()
            
            if let data = data {
                for item in data {
                    var year = "Undated"
                    
                    if let yearStr = item["year"] as? String {
                        year = yearStr
                    }
                    
                    if self.sortedData[year] == nil {
                        self.sortedData[year] = [[String: Any]]()
                    }
                    
                    self.sortedData[year]!.append(item)
                }
                
                self.sortedKeys = self.sortedData.keys.sorted(by: { (a, b) -> Bool in
                    return a > b
                })
                
                self.tableView.reloadData()
                self.tableView.isHidden = false
                self.collectionView.isHidden = false
                self.lblTitle.isHidden = false
            } else {
                Global.showAlert(title: "Error", message: "Error occurred while downloading videos", target: self)
            }
        }
    }
    
    // MARK: - UITableView datasource, delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedKeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let yearCell = tableView.dequeueReusableCell(withIdentifier: "YearCell", for: indexPath) as! YearCell
        yearCell.lblYear.text = sortedKeys[indexPath.row]
        
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
            return (sortedData[sortedKeys[selectedRow]]?.count)!
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let itemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as! ItemCell
        
        let data = sortedData[sortedKeys[selectedRow]]![indexPath.row]
        itemCell.itemTitle.text = data["title"] as? String
        let imageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(data["identifier"] as! String)")
        itemCell.itemImage.af_setImage(withURL: imageURL!)
        
        return itemCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let data = sortedData[sortedKeys[selectedRow]]![indexPath.row]
        let identifier = data["identifier"] as? String
        let title = data["title"] as? String
        let archivedBy = data["creator"] as? String
        let date = Global.formatDate(string: data["date"] as? String)
        let description = data["description"] as? String
        let mediaType = data["mediatype"] as? String
        let imageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(data["identifier"] as! String)")
        
        let itemVC = self.storyboard?.instantiateViewController(withIdentifier: "ItemVC") as! ItemVC
        
        itemVC.iIdentifier = identifier
        itemVC.iTitle = (title != nil) ? title! : ""
        itemVC.iArchivedBy = (archivedBy != nil) ? archivedBy! : ""
        itemVC.iDate = (date != nil) ? date! : ""
        itemVC.iDescription = (description != nil) ? description! : ""
        itemVC.iMediaType = (mediaType != nil) ? mediaType! : ""
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


