//
//  AppDelegate.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//

import UIKit

// Note: @main removed - SwiftUI App lifecycle is now in InternetArchiveApp.swift
// This class is kept for reference during migration and can be removed after Sprint 19 completion.
@MainActor
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        if let tabController = window?.rootViewController as? UITabBarController {
            tabController.viewControllers?.insert(packagedSearchController(), at: 2)
        }

        setTabbarStyle()

        return true
    }

    // MARK: - Convenience

    /*
     A method demonstrating how to encapsulate a `UISearchController` for presentation in, for example, a `UITabBarController`
     */
    func packagedSearchController() -> UIViewController {
        // Load a `SearchResultsViewController` from its storyboard.
        guard let searchResultVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchResultVC") as? SearchResultVC else {
            fatalError("Unable to instatiate a SearchResultVC from the storyboard.")
        }

        /*
         Create a UISearchController, passing the `searchResultsController` to
         use to display search results.
         */
        let searchController = UISearchController(searchResultsController: searchResultVC)
        searchController.searchResultsUpdater = searchResultVC
        searchController.searchBar.placeholder = NSLocalizedString("Enter keyword", comment: "")

        // Contain the `UISearchController` in a `UISearchContainerViewController`.
        let searchContainer = UISearchContainerViewController(searchController: searchController)
        searchContainer.title = NSLocalizedString("Search", comment: "")

        // Finally contain the `UISearchContainerViewController` in a `UINavigationController`.
        let searchNavigationController = UINavigationController(rootViewController: searchContainer)
        return searchNavigationController
    }

    func setTabbarStyle() {
        let appearance = UITabBarItem.appearance()
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 42)]
        appearance.setTitleTextAttributes(attributes, for: .normal)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}
