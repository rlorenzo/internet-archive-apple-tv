//
//  TabbarController.swift
//  Internet Archive
//
//  Created by mac-admin on 6/5/18.
//  Copyright © 2018 mac-admin. All rights reserved.
//

import UIKit

@MainActor
class TabbarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide Account and Favorites tabs if API credentials are not configured (read-only mode)
        if !AppConfiguration.shared.isConfigured {
            if let viewControllers = viewControllers {
                // Remove Account and Favorites tabs (both require authentication)
                // Keep only: Videos, Music, Search
                self.viewControllers = viewControllers.filter { controller in
                    !(controller is AccountNC) && !(controller is FavoriteNC)
                }
            }

            NSLog("ℹ️ Running in read-only mode. Account and Favorites features disabled (no API credentials).")
            return
        }

        // Only run login/sync if credentials are configured
        loginCheck()
        syncFavorites()
    }

    private func syncFavorites() {
        if !Global.isLoggedIn() {
            return
        }

        if let userData = Global.getUserData(),
           let username = userData["username"] as? String {

            Task {
                do {
                    let response = try await APIManager.sharedManager.getFavoriteItemsTyped(username: username)

                    guard let favorites = Global.getFavoriteData() else {
                        Global.resetFavoriteData()
                        return
                    }

                    guard let members = response.members else {
                        return
                    }

                    for item in members {
                        let identifier = item.identifier
                        guard favorites.contains(identifier) else {
                            Global.saveFavoriteData(identifier: identifier)
                            return
                        }
                    }
                } catch {
                    Global.showAlert(title: "Error", message: errors[302] ?? "Login failed", target: self)
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

            Task {
                do {
                    let response = try await APIManager.sharedManager.loginTyped(email: email, password: password)

                    if response.success != true {
                        Global.showAlert(title: "Error", message: errors[302] ?? "Login failed", target: self)
                    }
                } catch {
                    Global.showAlert(title: "Error", message: errors[400] ?? "Cannot connect to server", target: self)
                }
            }
        }
    }

}
