//
//  SectionHeader.swift
//  Internet Archive
//
//  Reusable section header for content grids
//

import SwiftUI

/// A standardized section header for content browsing screens.
///
/// Provides consistent styling for section titles across the app.
///
/// ## Usage
/// ```swift
/// SectionHeader("Featured Collections")
/// SectionHeader("Continue Watching")
/// ```
struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        SectionHeader("Continue Watching")
        SectionHeader("Featured Collections")
        SectionHeader("Browse by Year")
    }
    .padding()
}
