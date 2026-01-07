//
//  AppInfoFooter.swift
//  Internet Archive
//
//  Reusable app info footer displaying app name and version
//

import SwiftUI

/// A footer view displaying app name and version information.
///
/// Used at the bottom of screens like Account to show app metadata.
///
/// ## Usage
/// ```swift
/// VStack {
///     // Content
///     Spacer()
///     AppInfoFooter()
/// }
/// ```
struct AppInfoFooter: View {
    /// The app display name
    private let appName = "Internet Archive for Apple TV"

    /// The current version string
    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0"
        return "Version \(version)"
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(appName)
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text(versionString)
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        AppInfoFooter()
    }
}
