//
//  DescriptionView.swift
//  Internet Archive
//
//  SwiftUI view for displaying expandable descriptions with native full-screen viewer
//

import SwiftUI

/// A SwiftUI view that renders HTML content with expandable full-screen viewer.
///
/// Displays truncated text that expands to a native full-screen scrollable text view
/// when the "Read More" button is pressed.
///
/// ## Usage
/// ```swift
/// DescriptionView(htmlContent: "<p>This is <b>formatted</b> text.</p>")
/// ```
struct DescriptionView: View {
    // MARK: - Properties

    /// The HTML content to render
    let htmlContent: String

    /// Maximum number of lines when collapsed (default 5)
    let collapsedLineLimit: Int

    /// Plain text converted from HTML, computed once at init so the SwiftSoup
    /// parse in `stripHTML` runs a single time per render instead of on each
    /// reference (truncation check, body Text, accessibility value, viewer).
    private let plainText: String

    // MARK: - Environment

    @Environment(\.isCompactLayout) private var isCompactLayout

    // MARK: - State

    /// Whether to show the full text viewer
    @State private var showFullText = false

    // MARK: - Initialization

    init(htmlContent: String, collapsedLineLimit: Int = 5) {
        self.htmlContent = htmlContent
        self.collapsedLineLimit = collapsedLineLimit
        self.plainText = HTMLToAttributedString.shared.stripHTML(htmlContent)
    }

    /// Whether the text is long enough to require truncation.
    ///
    /// Uses a length-based heuristic for characters-per-line. A phone-width
    /// column fits far fewer characters than the ~1000pt tvOS / iPad detail
    /// pane, so the threshold must shrink on compact width — otherwise a
    /// visibly truncated description never offers "Read More" and the full
    /// text becomes unreachable.
    private var isTruncated: Bool {
        let charsPerLine = isCompactLayout == true ? 40 : 80
        return plainText.count > collapsedLineLimit * charsPerLine
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(plainText)
                .font(.body)
                .foregroundStyle(.white)
                .lineSpacing(6)
                .lineLimit(collapsedLineLimit)
                .accessibilityLabel(isTruncated ? "Description, truncated" : "Description")
                .accessibilityValue(plainText)

            // Read More button - only show when text is actually truncated
            if isTruncated {
                Button {
                    showFullText = true
                } label: {
                    HStack(spacing: 8) {
                        Text("Read More")
                            .font(.callout)
                            .fontWeight(.medium)
                        Image(systemName: "arrow.up.right.square")
                            .font(.callout)
                    }
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Read full description")
                .accessibilityHint("Double-tap to view the complete description")
            }
        }
        .fullScreenCover(isPresented: $showFullText) {
            FullTextViewer(text: plainText) {
                showFullText = false
            }
        }
    }
}

// MARK: - Full Text Viewer

/// Native SwiftUI full-screen scrollable text viewer
private struct FullTextViewer: View {
    let text: String
    let onDismiss: () -> Void

    #if os(tvOS)
    @FocusState private var isTextFocused: Bool
    #else
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        ZStack {
            Color.libraryCharcoal.ignoresSafeArea()

            ScrollView {
                #if os(tvOS)
                Text(text)
                    .font(.callout)
                    .foregroundStyle(.white)
                    .lineSpacing(8)
                    .padding(EdgeInsets(top: 100, leading: 250, bottom: 100, trailing: 250))
                    .focusable()
                    .focused($isTextFocused)
                #else
                Text(text)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .lineSpacing(6)
                    .padding(.horizontal, PlatformMetrics.horizontalPadding(
                        compact: horizontalSizeClass.map { $0 == .compact }
                    ))
                    .padding(.vertical, 40)
                #endif
            }

            // Dismiss button overlay for non-tvOS (tvOS uses Menu/Back remote button)
            #if !os(tvOS)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding()
                    }
                }
                Spacer()
            }
            #endif
        }
        #if os(tvOS)
        .onExitCommand {
            onDismiss()
        }
        .onAppear {
            isTextFocused = true
        }
        #endif
        .accessibilityLabel("Full description")
    }
}

// MARK: - Preview

#Preview("Short Description") {
    DescriptionView(htmlContent: "This is a short description.")
        .padding(50)
        .background(Color.libraryCharcoal)
}

#Preview("HTML Description") {
    DescriptionView(htmlContent: """
        <p>This is a <b>formatted</b> description with <i>HTML</i> tags.</p>
        <p>It includes multiple paragraphs and formatting.</p>
        <ul>
            <li>List item one</li>
            <li>List item two</li>
        </ul>
        """)
        .padding(50)
        .background(Color.libraryCharcoal)
}

#Preview("Long Description") {
    DescriptionView(htmlContent: """
        <p>This is a very long description that should trigger the "Read More" functionality.</p>
        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt \
        ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco \
        laboris nisi ut aliquip ex ea commodo consequat.</p>
        <p>Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat \
        nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia \
        deserunt mollit anim id est laborum.</p>
        <p>Additional paragraph with more content to ensure the description is long enough to require \
        expansion and the Read More button appears.</p>
        """, collapsedLineLimit: 4)
        .padding(50)
        .background(Color.libraryCharcoal)
}
