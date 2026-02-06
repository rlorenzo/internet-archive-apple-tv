//
//  MediaHomeErrorView.swift
//  Internet Archive
//
//  Reusable error view for media home screens
//

import SwiftUI

/// A reusable error view for media home screens
///
/// Displays an error message with a retry button, centered in the available space.
/// Used by both MusicHomeView and VideoHomeView.
struct MediaHomeErrorView: View {
    let message: String
    let onRetry: () async -> Void

    var body: some View {
        VStack {
            Spacer()
            ErrorContentView(
                message: message,
                onRetry: {
                    Task {
                        await onRetry()
                    }
                }
            )
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    MediaHomeErrorView(
        message: "Unable to load content. Please check your connection.",
        onRetry: {}
    )
}
