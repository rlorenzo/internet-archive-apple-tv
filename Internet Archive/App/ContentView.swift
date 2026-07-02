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
    /// The currently selected tab (persisted for focus restoration)
    @SceneStorage("selectedTab") private var selectedTab: Tab = .videos

    var body: some View {
        TabView(selection: $selectedTab) {
            VideoHomeView()
                .tabItem {
                    Label("Videos", systemImage: "film")
                }
                .tag(Tab.videos)
                .accessibilityLabel(Tab.videos.accessibilityLabel)
                .accessibilityHint(Tab.videos.accessibilityHint)

            MusicHomeView()
                .tabItem {
                    Label("Music", systemImage: "music.note")
                }
                .tag(Tab.music)
                .accessibilityLabel(Tab.music.accessibilityLabel)
                .accessibilityHint(Tab.music.accessibilityHint)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)
                .accessibilityLabel(Tab.search.accessibilityLabel)
                .accessibilityHint(Tab.search.accessibilityHint)

            if AppConfiguration.shared.isConfigured {
                FavoritesView()
                    .tabItem {
                        Label("Favorites", systemImage: "heart.fill")
                    }
                    .tag(Tab.favorites)
                    .accessibilityLabel(Tab.favorites.accessibilityLabel)
                    .accessibilityHint(Tab.favorites.accessibilityHint)

                AccountView()
                    .tabItem {
                        Label("Account", systemImage: "person.crop.circle")
                    }
                    .tag(Tab.account)
                    .accessibilityLabel(Tab.account.accessibilityLabel)
                    .accessibilityHint(Tab.account.accessibilityHint)
            }
        }
        .onAppear {
            // @SceneStorage can restore a tab that doesn't exist when the
            // app runs without API configuration - clamp to an available tab
            if !AppConfiguration.shared.isConfigured
                && (selectedTab == .favorites || selectedTab == .account) {
                selectedTab = .videos
            }
        }
    }
}

// MARK: - Tab Enum

extension ContentView {
    /// Represents the available tabs in the app's main navigation
    enum Tab: String, Hashable {
        case videos
        case music
        case search
        case favorites
        case account

        /// Accessibility label for VoiceOver
        var accessibilityLabel: String {
            switch self {
            case .videos: return "Videos tab"
            case .music: return "Music tab"
            case .search: return "Search tab"
            case .favorites: return "Favorites tab"
            case .account: return "Account tab"
            }
        }

        /// Accessibility hint for VoiceOver
        var accessibilityHint: String {
            switch self {
            case .videos: return "Browse and watch video content"
            case .music: return "Browse and listen to music"
            case .search: return "Search the Internet Archive"
            case .favorites: return "View your saved favorites"
            case .account: return "Manage your account settings"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppState())
}
