//
//  VideoVC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//

import UIKit
import AlamofireImage

class VideoVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var items = [[String: Any]]()
    var collection = "movies"
    
    private let screenSize = UIScreen.main.bounds.size
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppProgressHUD.sharedManager.show(view: self.view)

        APIManager.sharedManager.getCollections(collection: collection, result_type: "collection", limit: nil) { (collection, data, err) in
            AppProgressHUD.sharedManager.hide()

            if let data = data {
                self.collection = collection
                self.items = data.sorted(by: { (a, b) -> Bool in
                    return a["downloads"] as! Int > b["downloads"] as! Int
                })
                self.collectionView?.reloadData()
            } else {
                Global.showAlert(title: "Error", message: "Error occurred while downloading data", target: self)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
//        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let itemCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath as IndexPath) as! ItemCell
        
        itemCell.itemTitle.text = "\(items[indexPath.row]["title"]!)"
        let imageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(items[indexPath.row]["identifier"]!)")

        itemCell.itemImage.af_setImage(withURL: imageURL!)
        
        return itemCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let yearsVC = self.storyboard?.instantiateViewController(withIdentifier: "YearsVC") as! YearsVC
        yearsVC.collection = collection
        yearsVC.name = (items[indexPath.row]["title"] as? String)!
        yearsVC.identifier = (items[indexPath.row]["identifier"] as? String)!
        
        self.present(yearsVC, animated: true, completion: nil)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (screenSize.width / 5) - 100
        let height = width + 115
        let cellSize = CGSize(width: width, height: height)
        return cellSize
    }
}

