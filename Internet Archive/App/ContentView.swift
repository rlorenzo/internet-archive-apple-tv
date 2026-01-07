//
//  ContentView.swift
//  Internet Archive
//
//  Root TabView with 5 main navigation tabs
//

import SwiftUI

/// The root view of the Internet Archive app containing the main tab navigation.
///
/// This view provides access to five main sections:
/// - **Videos**: Browse and watch video content from the Internet Archive
/// - **Music**: Browse and listen to audio content
/// - **Search**: Search across all Internet Archive collections
/// - **Favorites**: View saved favorites and followed creators
/// - **Account**: Manage authentication and user settings
struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    /// The currently selected tab
    @State private var selectedTab: Tab = .videos

    var body: some View {
        TabView(selection: $selectedTab) {
            VideoHomeView()
                .tabItem {
                    Label("Videos", systemImage: "film")
                }
                .tag(Tab.videos)

            MusicHomeView()
                .tabItem {
                    Label("Music", systemImage: "music.note")
                }
                .tag(Tab.music)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)

            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
                .tag(Tab.favorites)

            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }
                .tag(Tab.account)
        }
    }
}

// MARK: - Tab Enum

extension ContentView {
    /// Represents the available tabs in the app's main navigation
    enum Tab: Hashable {
        case videos
        case music
        case search
        case favorites
        case account
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppState())
}
