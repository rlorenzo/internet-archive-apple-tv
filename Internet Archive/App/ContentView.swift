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

    /// Track if Video tab has navigation history
    @State private var videoHasNavigation = false

    /// Track if Music tab has navigation history
    @State private var musicHasNavigation = false

    /// Track if Search tab has navigation history
    @State private var searchHasNavigation = false

    var body: some View {
        TabView(selection: $selectedTab) {
            VideoHomeView(hasNavigationHistory: $videoHasNavigation)
                .tabItem {
                    Label("Videos", systemImage: "film")
                }
                .tag(Tab.videos)

            MusicHomeView(hasNavigationHistory: $musicHasNavigation)
                .tabItem {
                    Label("Music", systemImage: "music.note")
                }
                .tag(Tab.music)

            SearchView(hasNavigationHistory: $searchHasNavigation)
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
        .onExitCommand {
            // Handle Menu button at TabView level
            // If the current tab has navigation history, pop it back
            switch selectedTab {
            case .videos:
                if videoHasNavigation {
                    NotificationCenter.default.post(name: .popVideoNavigation, object: nil)
                }
            case .music:
                if musicHasNavigation {
                    NotificationCenter.default.post(name: .popMusicNavigation, object: nil)
                }
            case .search:
                if searchHasNavigation {
                    NotificationCenter.default.post(name: .popSearchNavigation, object: nil)
                }
            default:
                // Other tabs don't have navigation stacks yet
                break
            }
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
