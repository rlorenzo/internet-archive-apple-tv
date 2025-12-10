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

    /// Check if running in test environment
    private static var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }

    private var logoImageView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupLogoWatermark()

        // Hide Account and Favorites tabs if API credentials are not configured (read-only mode)
        if !AppConfiguration.shared.isConfigured {
            if let viewControllers = viewControllers {
                // Remove Account and Favorites tabs (both require authentication)
                // Keep only: Videos, Music, Search
                self.viewControllers = viewControllers.filter { controller in
                    !(controller is AccountNC) && !(controller is FavoriteNC)
                }
            }

            // Suppress log during tests
            if !Self.isRunningTests {
                NSLog("ℹ️ Running in read-only mode. Account and Favorites features disabled (no API credentials).")
            }
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

    // MARK: - Appearance

    private func setupAppearance() {
        // Set background color to match logo (#222222)
        view.backgroundColor = UIColor(red: 0.133, green: 0.133, blue: 0.133, alpha: 1.0)
    }

    // MARK: - Logo Watermark

    private func setupLogoWatermark() {
        guard let logoImage = UIImage(named: "logo") else { return }

        let imageView = UIImageView(image: logoImage)
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.7
        imageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalToConstant: 50),
            imageView.heightAnchor.constraint(equalToConstant: 60)
        ])

        logoImageView = imageView
    }

}
