//
//  FavoritesView.swift
//  Internet Archive
//
//  Favorites and followed creators management
//

import SwiftUI

/// The favorites management screen displaying saved items and followed creators.
///
/// This view shows three sections:
/// - Favorite Videos
/// - Favorite Music
/// - Followed Creators/People
///
/// ## Future Implementation
/// This placeholder will be replaced with a full implementation using:
/// - Integration with `APIManager.getFavoriteItemsTyped()`
/// - Local favorites from `Global.getFavoriteData()`
/// - Navigation to creator detail views
struct FavoritesView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            if appState.isAuthenticated {
                authenticatedContent()
            } else {
                unauthenticatedContent()
            }
        }
    }

    // MARK: - Content Views

    private func authenticatedContent() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Favorite Videos Section
                SectionHeader("Favorite Videos")
                videosGrid()

                // Favorite Music Section
                SectionHeader("Favorite Music")
                musicGrid()

                // Followed Creators Section
                SectionHeader("Followed Creators")
                creatorsPlaceholder()
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 40)
        }
        .navigationTitle("Favorites")
    }

    private func unauthenticatedContent() -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.slash")
                .font(.system(size: 80))
                .foregroundStyle(.tertiary)

            Text("Sign In Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Sign in to your Internet Archive account to view and manage your favorites.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 500)

            Button("Sign In") {
                // TODO: Navigate to account tab or show login sheet
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)

            Spacer()
        }
        .padding()
        .navigationTitle("Favorites")
    }

    // MARK: - Helper Views

    private func videosGrid() -> some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 250, maximum: 320), spacing: 40)
        ], spacing: 40) {
            ForEach(0..<4, id: \.self) { _ in
                PlaceholderCard.video
            }
        }
    }

    private func musicGrid() -> some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 250, maximum: 320), spacing: 40)
        ], spacing: 40) {
            ForEach(0..<4, id: \.self) { _ in
                PlaceholderCard.music
            }
        }
    }

    private func creatorsPlaceholder() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 30) {
                ForEach(0..<5, id: \.self) { _ in
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 150, height: 150)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 18)
                    }
                    .focusable()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FavoritesView()
        .environmentObject(AppState())
}

#Preview("Authenticated") {
    let appState = AppState()
    appState.setLoggedIn(email: "test@example.com", username: "TestUser")
    return FavoritesView()
        .environmentObject(appState)
}
