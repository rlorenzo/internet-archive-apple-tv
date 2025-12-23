//
//  DescriptionTextView.swift
//  Internet Archive
//
//  Custom focusable description view with "Read More" expansion
//  Replaces TvOSMoreButton for HTML-formatted descriptions
//

import UIKit

/// A focusable description view that displays formatted text with "Read More" expansion
@MainActor
final class DescriptionTextView: UIView {

    // MARK: - Configuration

    /// The number of lines to show before truncating
    var numberOfLines: Int = 6 {
        didSet { updateTruncation() }
    }

    /// The trailing text shown when truncated
    var trailingText: String = "... More"

    /// Callback when the "Read More" action is triggered
    var onReadMorePressed: (() -> Void)?

    // MARK: - Properties

    /// The attributed text to display
    var attributedText: NSAttributedString? {
        didSet { updateContent() }
    }

    /// Plain text version for accessibility and TvOSTextViewer
    var plainText: String? {
        didSet { updateAccessibility() }
    }

    /// Whether the text is currently truncated
    private(set) var isTruncated: Bool = false

    // MARK: - Private Views

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 6
        label.lineBreakMode = .byTruncatingTail
        label.textColor = .label
        label.font = .systemFont(ofSize: 29)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let moreIndicator: UILabel = {
        let label = UILabel()
        label.text = "... More"
        label.textColor = .systemBlue
        label.font = .systemFont(ofSize: 29, weight: .medium)
        label.isHidden = true
        return label
    }()

    private let focusedBackgroundView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .light)
        let view = UIVisualEffectView(effect: blur)
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
        setupAccessibility()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupGestures()
        setupAccessibility()
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        // Add background for focus state
        addSubview(focusedBackgroundView)

        // Add content stack
        addSubview(contentStackView)
        contentStackView.addArrangedSubview(textLabel)
        contentStackView.addArrangedSubview(moreIndicator)

        NSLayoutConstraint.activate([
            // Background fills the view with padding
            focusedBackgroundView.topAnchor.constraint(equalTo: topAnchor, constant: -16),
            focusedBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -16),
            focusedBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 16),
            focusedBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 16),

            // Content stack
            contentStackView.topAnchor.constraint(equalTo: topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupGestures() {
        // Tap gesture for pressing select
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        addGestureRecognizer(tapGesture)
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = [.staticText]
        accessibilityHint = "Double-tap to expand and read full description"
    }

    // MARK: - Public Methods

    /// Set the description from an HTML string
    /// - Parameter html: HTML string to parse and display
    func setDescription(_ html: String) {
        let converter = HTMLToAttributedString.shared
        attributedText = converter.convert(html)
        plainText = converter.stripHTML(html)
    }

    /// Set the description from plain text
    /// - Parameter text: Plain text to display
    func setPlainText(_ text: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 29),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]

        attributedText = NSAttributedString(string: text, attributes: attributes)
        plainText = text
    }

    // MARK: - Focus Handling

    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        coordinator.addCoordinatedAnimations { [weak self] in
            guard let self = self else { return }

            if self.isFocused {
                // Show focus state
                self.focusedBackgroundView.alpha = 1
                self.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
                self.moreIndicator.textColor = .white

                // Announce for VoiceOver when truncated
                if self.isTruncated {
                    UIAccessibility.post(notification: .announcement, argument: "Press select to read more")
                }
            } else {
                // Hide focus state
                self.focusedBackgroundView.alpha = 0
                self.transform = .identity
                self.moreIndicator.textColor = .systemBlue
            }
        }
    }

    // MARK: - Press Handling

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses where press.type == .select {
            // Visual feedback
            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            }
            return
        }
        super.pressesBegan(presses, with: event)
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses where press.type == .select {
            UIView.animate(withDuration: 0.1) {
                self.transform = self.isFocused
                    ? CGAffineTransform(scaleX: 1.02, y: 1.02)
                    : .identity
            }
            triggerReadMore()
            return
        }
        super.pressesEnded(presses, with: event)
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        UIView.animate(withDuration: 0.1) {
            self.transform = self.isFocused ?
                CGAffineTransform(scaleX: 1.02, y: 1.02) : .identity
        }
        super.pressesCancelled(presses, with: event)
    }

    // MARK: - Private Methods

    @objc private func handleTap() {
        triggerReadMore()
    }

    private func triggerReadMore() {
        onReadMorePressed?()
    }

    private func updateContent() {
        textLabel.attributedText = attributedText
        textLabel.numberOfLines = numberOfLines
        updateTruncation()
        updateAccessibility()
    }

    private func updateTruncation() {
        guard let attributedText = attributedText else {
            isTruncated = false
            moreIndicator.isHidden = true
            return
        }

        // Calculate if text is truncated
        let textHeight = attributedText.boundingRect(
            with: CGSize(
                width: textLabel.bounds.width > 0 ? textLabel.bounds.width : UIScreen.main.bounds.width - 200,
                height: .greatestFiniteMagnitude
            ),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height

        let lineHeight = textLabel.font.lineHeight
        let maxHeight = lineHeight * CGFloat(numberOfLines) + (CGFloat(numberOfLines - 1) * 6) // 6pt line spacing

        isTruncated = textHeight > maxHeight
        moreIndicator.isHidden = !isTruncated
        moreIndicator.text = trailingText

        // Update accessibility traits based on truncation
        if isTruncated {
            accessibilityTraits = [.staticText, .button]
        } else {
            accessibilityTraits = [.staticText]
        }
    }

    private func updateAccessibility() {
        if let text = plainText, !text.isEmpty {
            accessibilityLabel = text
        } else if let attrText = attributedText?.string, !attrText.isEmpty {
            accessibilityLabel = attrText
        } else {
            accessibilityLabel = "No description available"
        }

        if isTruncated {
            accessibilityHint = "Double-tap to expand and read full description"
        } else {
            accessibilityHint = nil
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateTruncation()
    }
}
