//
//  SectionHeader.swift
//  Internet Archive
//
//  Reusable section header for content grids
//

import SwiftUI

/// A standardized section header for content browsing screens.
///
/// Provides consistent styling for section titles with an optional "See All" button.
///
/// ## Usage
/// ```swift
/// // Simple header
/// SectionHeader("Featured Collections")
///
/// // Header with See All button
/// SectionHeader("Continue Watching", showSeeAll: true) {
///     // Navigate to full list
/// }
///
/// // Header with custom button text
/// SectionHeader("Browse by Year", seeAllText: "View All Years") {
///     // Navigate to year browser
/// }
/// ```
struct SectionHeader: View {
    // MARK: - Properties

    let title: String
    let showSeeAll: Bool
    let seeAllText: String
    let onSeeAllTap: (() -> Void)?

    // MARK: - Initialization

    /// Creates a section header with title only
    init(_ title: String) {
        self.title = title
        self.showSeeAll = false
        self.seeAllText = "See All"
        self.onSeeAllTap = nil
    }

    /// Creates a section header with an optional "See All" button
    init(
        _ title: String,
        showSeeAll: Bool,
        seeAllText: String = "See All",
        onSeeAllTap: @escaping () -> Void
    ) {
        self.title = title
        self.showSeeAll = showSeeAll
        self.seeAllText = seeAllText
        self.onSeeAllTap = onSeeAllTap
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            if showSeeAll, let action = onSeeAllTap {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(seeAllText)
                            .font(.callout)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(seeAllText) for \(title)")
                .accessibilityHint("Double-tap to view all items in this section")
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#Preview("Simple Headers") {
    VStack(alignment: .leading, spacing: 20) {
        SectionHeader("Continue Watching")
        SectionHeader("Featured Collections")
        SectionHeader("Browse by Year")
    }
    .padding()
}

#Preview("Headers with See All") {
    VStack(alignment: .leading, spacing: 20) {
        SectionHeader("Continue Watching", showSeeAll: true) {
            print("See all continue watching")
        }

        SectionHeader("Featured Collections", showSeeAll: true, seeAllText: "Browse All") {
            print("Browse all collections")
        }

        SectionHeader("Browse by Year", showSeeAll: false, seeAllText: "") {}
    }
    .padding(80)
}
