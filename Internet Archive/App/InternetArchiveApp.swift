//
//  InternetArchiveApp.swift
//  Internet Archive
//
//  SwiftUI App entry point for tvOS
//

import SwiftUI

/// The main entry point for the Internet Archive tvOS app.
///
/// This SwiftUI App provides access to Internet Archive's media collections
/// including movies, music, and more. It uses a tab-based navigation structure
/// with five main sections: Videos, Music, Search, Favorites, and Account.
///
/// The app integrates with existing ViewModels and services from the UIKit
/// implementation, providing a gradual migration path to SwiftUI.
@main
struct InternetArchiveApp: App {
    /// Shared app state for authentication and user preferences
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
