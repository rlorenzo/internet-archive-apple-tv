//
//  DescriptionView.swift
//  Internet Archive
//
//  SwiftUI wrapper for TvOSMoreButton with TvOSTextViewer expansion
//

import SwiftUI
import TvOSMoreButton
import TvOSTextViewer
import UIKit

/// A SwiftUI view that renders HTML content using TvOSMoreButton.
///
/// Displays truncated text with ellipsis that expands to full-screen
/// TvOSTextViewer when selected - matching the existing UIKit UX.
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

    // MARK: - Computed Properties

    /// Calculate appropriate height based on number of lines
    /// Font size 29pt with line spacing gives roughly 40pt per line
    private var estimatedHeight: CGFloat {
        let lineHeight: CGFloat = 40
        let padding: CGFloat = 20
        return CGFloat(collapsedLineLimit) * lineHeight + padding
    }

    // MARK: - Body

    var body: some View {
        TvOSMoreButtonWrapper(
            htmlContent: htmlContent,
            numberOfLines: collapsedLineLimit
        )
        .frame(height: estimatedHeight)
    }
}

// MARK: - TvOSMoreButton Wrapper

/// UIViewRepresentable wrapper for TvOSMoreButton
struct TvOSMoreButtonWrapper: UIViewControllerRepresentable {
    let htmlContent: String
    let numberOfLines: Int

    func makeUIViewController(context: Context) -> TvOSMoreButtonHostController {
        TvOSMoreButtonHostController(
            htmlContent: htmlContent,
            numberOfLines: numberOfLines
        )
    }

    func updateUIViewController(_ uiViewController: TvOSMoreButtonHostController, context: Context) {
        uiViewController.updateContent(htmlContent: htmlContent, numberOfLines: numberOfLines)
    }
}

// MARK: - Host Controller

/// Container view controller that hosts TvOSMoreButton and presents TvOSTextViewer
final class TvOSMoreButtonHostController: UIViewController {
    private var htmlContent: String
    private var numberOfLines: Int
    private var moreButton: TvOSMoreButton!
    private var plainText: String = ""

    init(htmlContent: String, numberOfLines: Int) {
        self.htmlContent = htmlContent
        self.numberOfLines = numberOfLines
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMoreButton()
    }

    private func setupMoreButton() {
        moreButton = TvOSMoreButton()
        moreButton.translatesAutoresizingMaskIntoConstraints = false

        // Style configuration
        moreButton.textColor = .white
        moreButton.font = .systemFont(ofSize: 29)
        moreButton.ellipsesString = "..."
        moreButton.trailingTextColor = .systemBlue
        moreButton.trailingText = " More"

        // Button press handler
        moreButton.buttonWasPressed = { [weak self] _ in
            self?.showFullDescription()
        }

        view.addSubview(moreButton)

        NSLayoutConstraint.activate([
            moreButton.topAnchor.constraint(equalTo: view.topAnchor),
            moreButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            moreButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            moreButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        updateButtonContent()
    }

    func updateContent(htmlContent: String, numberOfLines: Int) {
        self.htmlContent = htmlContent
        self.numberOfLines = numberOfLines
        updateButtonContent()
    }

    private func updateButtonContent() {
        guard let moreButton = moreButton else { return }

        // Note: TvOSMoreButton doesn't have a numberOfLines property.
        // It truncates based on view bounds, controlled by the frame height
        // set in DescriptionView.estimatedHeight based on collapsedLineLimit.

        // Convert HTML to plain text for display
        plainText = HTMLToAttributedString.shared.stripHTML(htmlContent)
        moreButton.text = plainText
    }

    private func showFullDescription() {
        guard !plainText.isEmpty else { return }

        let textViewerController = TvOSTextViewerViewController()
        textViewerController.text = plainText
        textViewerController.textEdgeInsets = UIEdgeInsets(top: 100, left: 250, bottom: 100, right: 250)
        present(textViewerController, animated: true)
    }
}

// MARK: - Preview

#Preview("Short Description") {
    DescriptionView(htmlContent: "This is a short description.")
        .frame(height: 100)
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
        .frame(height: 200)
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
        .frame(height: 200)
        .padding(50)
        .background(Color.black)
}
