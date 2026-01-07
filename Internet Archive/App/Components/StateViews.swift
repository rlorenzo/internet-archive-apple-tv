//
//  StateViews.swift
//  Internet Archive
//
//  SwiftUI state views for empty, error, and loading states
//

import SwiftUI

// MARK: - Empty Content View

/// A SwiftUI view displayed when a section or screen has no content.
///
/// Use this view to provide context and guidance when:
/// - A search returns no results
/// - A favorites list is empty
/// - Continue Watching has no items
/// - A collection has no items
///
/// ## Usage
/// ```swift
/// // Simple empty state
/// EmptyContentView(
///     icon: "heart",
///     title: "No Favorites Yet",
///     message: "Items you favorite will appear here."
/// )
///
/// // Empty state with action button
/// EmptyContentView(
///     icon: "magnifyingglass",
///     title: "No Results",
///     message: "Try adjusting your search terms.",
///     buttonTitle: "Clear Search"
/// ) {
///     // Clear search action
/// }
/// ```
struct EmptyContentView: View {
    // MARK: - Properties

    /// SF Symbol name for the icon
    let icon: String

    /// Primary title text
    let title: String

    /// Secondary message text
    let message: String

    /// Optional button title
    let buttonTitle: String?

    /// Optional button action
    let buttonAction: (() -> Void)?

    // MARK: - Initialization

    init(
        icon: String,
        title: String,
        message: String,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            if let buttonTitle = buttonTitle, let action = buttonAction {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.callout)
                        .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
        }
        .padding(40)
    }
}

// MARK: - Empty Content View Presets

extension EmptyContentView {
    /// Empty state for no search results
    static func noSearchResults(onClearSearch: (() -> Void)? = nil) -> EmptyContentView {
        EmptyContentView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "Try searching with different keywords or check your spelling.",
            buttonTitle: onClearSearch != nil ? "Clear Search" : nil,
            buttonAction: onClearSearch
        )
    }

    /// Empty state for empty favorites
    static func noFavorites(onBrowse: (() -> Void)? = nil) -> EmptyContentView {
        EmptyContentView(
            icon: "heart",
            title: "No Favorites Yet",
            message: "Items you add to favorites will appear here for quick access.",
            buttonTitle: onBrowse != nil ? "Browse Content" : nil,
            buttonAction: onBrowse
        )
    }

    /// Empty state for no continue watching items
    static var noContinueWatching: EmptyContentView {
        EmptyContentView(
            icon: "play.circle",
            title: "Nothing to Continue",
            message: "Videos you start watching will appear here so you can pick up where you left off."
        )
    }

    /// Empty state for no continue listening items
    static var noContinueListening: EmptyContentView {
        EmptyContentView(
            icon: "music.note",
            title: "Nothing to Continue",
            message: "Albums you start listening to will appear here so you can pick up where you left off."
        )
    }

    /// Empty state for empty collection
    static func emptyCollection(collectionName: String) -> EmptyContentView {
        EmptyContentView(
            icon: "folder",
            title: "No Items",
            message: "The \(collectionName) collection is empty or unavailable."
        )
    }

    /// Empty state for login required
    static func loginRequired(onLogin: @escaping () -> Void) -> EmptyContentView {
        EmptyContentView(
            icon: "person.crop.circle",
            title: "Sign In Required",
            message: "Sign in to access your favorites and personalized content.",
            buttonTitle: "Sign In",
            buttonAction: onLogin
        )
    }
}

// MARK: - Error Content View

/// A SwiftUI view displayed when an error occurs loading content.
///
/// This view provides:
/// - Error icon and message
/// - Optional retry button
/// - Consistent styling across the app
///
/// ## Usage
/// ```swift
/// // Simple error
/// ErrorContentView(message: "Unable to load content")
///
/// // Error with retry action
/// ErrorContentView(
///     message: "Failed to load videos",
///     onRetry: { await viewModel.loadVideos() }
/// )
///
/// // Network error with custom title
/// ErrorContentView(
///     title: "Connection Error",
///     message: "Please check your internet connection.",
///     onRetry: { await viewModel.retry() }
/// )
/// ```
struct ErrorContentView: View {
    // MARK: - Properties

    /// SF Symbol name for the icon
    let icon: String

    /// Primary title text
    let title: String

    /// Error message to display
    let message: String

    /// Retry button action (nil to hide button)
    let onRetry: (() -> Void)?

    // MARK: - Initialization

    init(
        icon: String = "exclamationmark.triangle",
        title: String = "Something Went Wrong",
        message: String,
        onRetry: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.onRetry = onRetry
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.red.opacity(0.8))

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }

            if let retry = onRetry {
                Button(action: retry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.callout)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
        }
        .padding(40)
    }
}

// MARK: - Error Content View Presets

extension ErrorContentView {
    /// Network connection error
    static func networkError(onRetry: (() -> Void)? = nil) -> ErrorContentView {
        ErrorContentView(
            icon: "wifi.slash",
            title: "No Connection",
            message: "Please check your internet connection and try again.",
            onRetry: onRetry
        )
    }

    /// Server error
    static func serverError(onRetry: (() -> Void)? = nil) -> ErrorContentView {
        ErrorContentView(
            icon: "server.rack",
            title: "Server Error",
            message: "The Internet Archive is temporarily unavailable. Please try again later.",
            onRetry: onRetry
        )
    }

    /// Content not found
    static func notFound(itemType: String = "content") -> ErrorContentView {
        ErrorContentView(
            icon: "questionmark.folder",
            title: "Not Found",
            message: "The requested \(itemType) could not be found. It may have been removed or is unavailable."
        )
    }

    /// Loading failed with generic message
    static func loadingFailed(
        contentType: String = "content",
        onRetry: (() -> Void)? = nil
    ) -> ErrorContentView {
        ErrorContentView(
            icon: "exclamationmark.triangle",
            title: "Failed to Load",
            message: "Unable to load \(contentType). Please try again.",
            onRetry: onRetry
        )
    }

    /// Playback error
    static func playbackError(onRetry: (() -> Void)? = nil) -> ErrorContentView {
        ErrorContentView(
            icon: "play.slash",
            title: "Playback Error",
            message: "Unable to play this item. The media file may be unavailable or in an unsupported format.",
            onRetry: onRetry
        )
    }

    /// Authentication error
    static func authError(onRetry: (() -> Void)? = nil) -> ErrorContentView {
        ErrorContentView(
            icon: "person.crop.circle.badge.exclamationmark",
            title: "Authentication Failed",
            message: "Unable to sign in. Please check your credentials and try again.",
            onRetry: onRetry
        )
    }
}

// MARK: - Convenience Initializer from NetworkError

extension ErrorContentView {
    /// Create an error content view from a NetworkError
    init(networkError: NetworkError, onRetry: (() -> Void)? = nil) {
        switch networkError {
        case .noConnection, .timeout:
            self = .networkError(onRetry: onRetry)
        case .serverError:
            self = .serverError(onRetry: onRetry)
        case .resourceNotFound:
            self = .notFound()
        case .unauthorized, .authenticationFailed, .invalidCredentials:
            self = .authError(onRetry: onRetry)
        default:
            self.init(
                message: ErrorPresenter.shared.userFriendlyMessage(for: networkError),
                onRetry: onRetry
            )
        }
    }
}

// MARK: - Previews

#Preview("Empty - No Search Results") {
    EmptyContentView.noSearchResults {
        print("Clear search")
    }
}

#Preview("Empty - No Favorites") {
    EmptyContentView.noFavorites {
        print("Browse content")
    }
}

#Preview("Empty - Continue Watching") {
    EmptyContentView.noContinueWatching
}

#Preview("Empty - Login Required") {
    EmptyContentView.loginRequired {
        print("Sign in")
    }
}

#Preview("Error - Network") {
    ErrorContentView.networkError {
        print("Retry")
    }
}

#Preview("Error - Server") {
    ErrorContentView.serverError {
        print("Retry")
    }
}

#Preview("Error - Not Found") {
    ErrorContentView.notFound(itemType: "video")
}

#Preview("Error - Loading Failed") {
    ErrorContentView.loadingFailed(contentType: "videos") {
        print("Retry")
    }
}
