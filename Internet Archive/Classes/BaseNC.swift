//
//  PlayerBaseNC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/10/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//

import UIKit
// import AVKit
// import AVFoundation

@MainActor
class BaseNC: UINavigationController {

    //    func gotoYearsVC(collection: String, title: String, identifier: String) -> Void {
    //        let yearsVC = self.storyboard?.instantiateViewController(withIdentifier: "YearsVC") as! YearsVC
    //        yearsVC.collection = collection
    //        yearsVC.name = title
    //        yearsVC.identifier = identifier
    //
    //        self.pushViewController(yearsVC, animated: true)
    //    }

    //    func gotoItemVC(identifier: String?, title: String?, archivedBy: String?, date: String?, description: String?, mediaType: String?, imageURL: URL?) {
    //        let itemVC = self.storyboard?.instantiateViewController(withIdentifier: "ItemVC") as! ItemVC
    //
    //        itemVC.iIdentifier = identifier
    //        itemVC.iTitle = (title != nil) ? title! : ""
    //        itemVC.iArchivedBy = (archivedBy != nil) ? archivedBy! : ""
    //        itemVC.iDate = (date != nil) ? date! : ""
    //        itemVC.iDescription = (description != nil) ? description! : ""
    //        itemVC.iMediaType = (mediaType != nil) ? mediaType! : ""
    //        itemVC.iImageURL = imageURL
    //
    //        self.pushViewController(itemVC, animated: true)
    //    }

    //    func gotoPeopleVC(identifier: String?, title: String?) {
    //        let peopleVC = self.storyboard?.instantiateViewController(withIdentifier: "PeopleVC") as! PeopleVC
    //        peopleVC.identifier = identifier
    //        peopleVC.name = title
    //
    //        // self.pushViewController(peopleVC, animated: true)
    //        self.present(peopleVC, animated: true, completion: nil)
    //    }

    //    func openPlayer(identifier: String, title: String, mediaType: String) -> Void {
    //        var filesToPlay = [[String: Any]]()
    //
    ////        let url = "https://raw.githubusercontent.com/Eagle19243/resource/master/music/001.mp3"
    ////        let mediaURL = URL(string: url)!
    ////        let asset = AVAsset(url: mediaURL)
    ////        let playerItem = AVPlayerItem(asset: asset)
    ////        let playerViewController = AVPlayerViewController()
    ////        playerViewController.delegate = self
    ////
    ////        let player = AVPlayer(playerItem: playerItem)
    ////        playerViewController.player = player
    ////
    ////        self.present(playerViewController, animated: true) {
    ////            player.play()
    ////            UIApplication.shared.isIdleTimerDisabled = true
    ////        }
    //
    //        AppProgressHUD.sharedManager.show(view: self.view)
    //
    //        APIManager.sharedManager.getMetaData(identifier: identifier) { (data, err) in
    //            AppProgressHUD.sharedManager.hide()
    //
    //            if let data = data {
    //                for file in data["files"] as! [[String: Any]] {
    //                    let filename = file["name"] as! String
    //                    let ext = filename.suffix(4)
    //
    //                    if ext == ".mp4", mediaType == "movies" {
    //                        filesToPlay.append(file)
    //                    } else if ext == ".mp3", mediaType == "etree" {
    //                        filesToPlay.append(file)
    //                    }
    //                }
    //
    //                if filesToPlay.count == 0 {
    //                    Global.showAlert(title: "Error", message: "There is no playable content", target: self)
    //                    return
    //                }
    //
    //                let filename = filesToPlay[0]["name"] as! String
    //                let url = "https://archive.org/download/\(identifier)/\(filename.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
    //                let mediaURL = URL(string: url)!
    //                let asset = AVAsset(url: mediaURL)
    //                let playerItem = AVPlayerItem(asset: asset)
    //                let playerViewController = AVPlayerViewController()
    //                playerViewController.delegate = self
    //
    //                let player = AVPlayer(playerItem: playerItem)
    //                playerViewController.player = player
    //
    //                self.present(playerViewController, animated: true) {
    //                    player.play()
    //                }
    //            } else {
    //                Global.showAlert(title: "Error", message: "Error ocurred while downloading content", target: self)
    //            }
    //        }
    //    }

    //    func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
    //        UIApplication.shared.isIdleTimerDisabled = false
    //        return true
    //    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

}
