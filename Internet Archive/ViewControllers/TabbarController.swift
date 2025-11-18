//
//  TabbarController.swift
//  Internet Archive
//
//  Created by mac-admin on 6/5/18.
//  Copyright © 2018 mac-admin. All rights reserved.
//

import UIKit

class TabbarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        loginCheck()
        syncFavorites()
    }
    
    private func syncFavorites() {
        if !Global.isLoggedIn() {
            return
        }
        
        
        if let userData = Global.getUserData(),
            let username = userData["username"] as? String {
            
            APIManager.sharedManager.getFavoriteItems(username: username) { (success, errCode, items) in
                
                if success, let items = items {
                    guard let favorites = Global.getFavoriteData() else {
                        Global.resetFavoriteData()
                        return
                    }
                    
                    for item in items {
                        let identifier = item["identifier"] as! String
                        guard favorites.contains(identifier) else {
                            Global.saveFavoriteData(identifier: identifier)
                            return
                        }
                    }
                } else {
                    Global.showAlert(title: "Error", message: errors[302]!, target: self)
                    return
                }
            }
        }
        
    }
    
    private func loginCheck() {
        if !Global.isLoggedIn() {
            return
        }
        
        if let userData = Global.getUserData(),
            let email = userData["email"] as? String,
            let password = userData["password"] as? String {
            
            APIManager.sharedManager.login(email: email, password: password) { (data) in
                
                if data == nil {
                    Global.showAlert(title: "Error", message: errors[400]!, target: self)
                    return
                }
                
                if let success = data!["success"] as? Bool, !success {
                    Global.showAlert(title: "Error", message: errors[302]!, target: self)
                    return
                }
            }
        }
    }

}
