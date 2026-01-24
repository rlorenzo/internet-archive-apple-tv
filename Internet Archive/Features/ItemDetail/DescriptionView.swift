//
//  DescriptionView.swift
//  Internet Archive
//
//  SwiftUI view for displaying expandable descriptions with TvOSTextViewer
//

import SwiftUI
import TvOSTextViewer
import UIKit

/// A SwiftUI view that renders HTML content with expandable full-screen viewer.
///
/// Displays truncated text that expands to full-screen TvOSTextViewer when
/// the "Read More" button is pressed.
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
    var collapsedLineLimit: Int = 5

    // MARK: - State

    /// Whether to show the full text viewer
    @State private var showFullText = false

    /// Whether the text is actually being truncated (detected via geometry)
    @State private var isTruncated = false

    // MARK: - Computed Properties

    /// Plain text converted from HTML
    private var plainText: String {
        HTMLToAttributedString.shared.stripHTML(htmlContent)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Truncated description text with geometry-based truncation detection
            TruncationDetectingText(
                text: plainText,
                lineLimit: collapsedLineLimit,
                isTruncated: $isTruncated
            )

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
            }
        }
        .fullScreenCover(isPresented: $showFullText) {
            FullTextViewerWrapper(text: plainText) {
                showFullText = false
            }
        }
    }
}

// MARK: - Full Text Viewer Wrapper

/// UIViewControllerRepresentable wrapper for TvOSTextViewerViewController
private struct FullTextViewerWrapper: UIViewControllerRepresentable {
    let text: String
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let textViewerController = TvOSTextViewerViewController()
        textViewerController.text = text
        textViewerController.textEdgeInsets = UIEdgeInsets(top: 100, left: 250, bottom: 100, right: 250)

        // Wrap in a container that handles dismissal
        let container = TextViewerContainerController(
            textViewer: textViewerController,
            onDismiss: onDismiss
        )
        return container
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Text Viewer Container

/// Container controller that wraps TvOSTextViewerViewController and handles dismissal
private final class TextViewerContainerController: UIViewController {
    private let textViewer: TvOSTextViewerViewController
    private let onDismiss: () -> Void

    init(textViewer: TvOSTextViewerViewController, onDismiss: @escaping () -> Void) {
        self.textViewer = textViewer
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add text viewer as child
        addChild(textViewer)
        textViewer.view.frame = view.bounds
        textViewer.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(textViewer.view)
        textViewer.didMove(toParent: self)

        // Add menu button gesture to dismiss
        let menuPressRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleMenuPress))
        menuPressRecognizer.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
        view.addGestureRecognizer(menuPressRecognizer)
    }

    @objc private func handleMenuPress() {
        onDismiss()
    }
}

// MARK: - Preview

#Preview("Short Description") {
    DescriptionView(htmlContent: "This is a short description.")
        .padding(50)
        .background(Color.black)
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
        .background(Color.black)
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
        .background(Color.black)
}

// MARK: - Truncation Detecting Text

/// A text view that detects whether its content is being truncated.
///
/// Uses geometry measurement to compare the full text height against the
/// line-limited height to determine if truncation is occurring.
private struct TruncationDetectingText: View {
    let text: String
    let lineLimit: Int
    @Binding var isTruncated: Bool

    @State private var fullHeight: CGFloat = 0
    @State private var truncatedHeight: CGFloat = 0

    var body: some View {
        Text(text)
            .font(.system(size: 29))
            .foregroundStyle(.white)
            .lineLimit(lineLimit)
            .lineSpacing(6)
            .background(
                GeometryReader { truncatedGeometry in
                    Color.clear
                        .onAppear { truncatedHeight = truncatedGeometry.size.height }
                        .onChange(of: truncatedGeometry.size.height) { _, newHeight in
                            truncatedHeight = newHeight
                            updateTruncationState()
                        }
                }
            )
            .background(
                // Hidden full-height text to measure actual required height
                Text(text)
                    .font(.system(size: 29))
                    .lineSpacing(6)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    .background(
                        GeometryReader { fullGeometry in
                            Color.clear
                                .onAppear { fullHeight = fullGeometry.size.height }
                                .onChange(of: fullGeometry.size.height) { _, newHeight in
                                    fullHeight = newHeight
                                    updateTruncationState()
                                }
                        }
                    )
            )
            .onAppear {
                // Delay check to ensure geometry is measured
                DispatchQueue.main.async {
                    updateTruncationState()
                }
            }
    }

    private func updateTruncationState() {
        // Add small threshold to account for rounding differences
        let threshold: CGFloat = 2
        isTruncated = fullHeight > truncatedHeight + threshold
    }
}
