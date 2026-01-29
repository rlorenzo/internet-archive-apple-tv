//
//  SubtitleSelectionViewController.swift
//  Internet Archive
//
//  View controller for selecting subtitle tracks in video playback
//

import UIKit

/// Delegate protocol for subtitle selection events
@MainActor
protocol SubtitleSelectionDelegate: AnyObject {
    /// Called when a subtitle track is selected
    func subtitleSelection(_ controller: SubtitleSelectionViewController, didSelect track: SubtitleTrack)

    /// Called when subtitles are turned off
    func subtitleSelectionDidTurnOff(_ controller: SubtitleSelectionViewController)
}

/// View controller for displaying and selecting subtitle tracks
@MainActor
final class SubtitleSelectionViewController: UIViewController {

    // MARK: - Properties

    /// Available subtitle tracks
    private let tracks: [SubtitleTrack]

    /// Currently selected track (nil if subtitles are off)
    private var selectedTrack: SubtitleTrack?

    /// Delegate for selection events
    weak var delegate: SubtitleSelectionDelegate?

    /// Table view for displaying tracks
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(SubtitleTrackCell.self, forCellReuseIdentifier: SubtitleTrackCell.reuseIdentifier)
        table.backgroundColor = .clear
        table.rowHeight = 66
        return table
    }()

    /// Title label
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Subtitles"
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    /// Container view with blur effect
    private lazy var containerView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        view.clipsToBounds = true
        return view
    }()

    // MARK: - Initialization

    init(tracks: [SubtitleTrack], selectedTrack: SubtitleTrack?) {
        self.tracks = tracks
        self.selectedTrack = selectedTrack
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overCurrentContext
        self.modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAccessibility()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        view.addSubview(containerView)
        containerView.contentView.addSubview(titleLabel)
        containerView.contentView.addSubview(tableView)

        let containerWidth: CGFloat = 600
        let containerHeight = min(CGFloat((tracks.count + 1) * 66 + 80), 500)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: containerWidth),
            containerView.heightAnchor.constraint(equalToConstant: containerHeight),

            titleLabel.topAnchor.constraint(equalTo: containerView.contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.contentView.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor)
        ])
    }

    private func setupAccessibility() {
        view.accessibilityViewIsModal = true
        titleLabel.accessibilityTraits = .header
    }

    // MARK: - Actions

    @objc private func dismissSelection() {
        dismiss(animated: true)
    }

    // MARK: - Focus

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [tableView]
    }
}

// MARK: - UITableViewDataSource

extension SubtitleSelectionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // +1 for "Off" option
        tracks.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SubtitleTrackCell.reuseIdentifier,
            for: indexPath
        ) as? SubtitleTrackCell else {
            return UITableViewCell()
        }

        if indexPath.row == 0 {
            // "Off" option
            cell.configure(
                title: "Off",
                subtitle: nil,
                isSelected: selectedTrack == nil,
                accessibilityHint: "Turn off subtitles"
            )
        } else {
            let track = tracks[indexPath.row - 1]
            let subtitle = track.format == .srt ? "SRT" : "WebVTT"
            cell.configure(
                title: track.languageDisplayName,
                subtitle: subtitle,
                isSelected: selectedTrack?.identifier == track.identifier,
                accessibilityHint: "Select \(track.languageDisplayName) subtitles"
            )
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension SubtitleSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row == 0 {
            // "Off" selected
            selectedTrack = nil
            delegate?.subtitleSelectionDidTurnOff(self)
        } else {
            let track = tracks[indexPath.row - 1]
            selectedTrack = track
            delegate?.subtitleSelection(self, didSelect: track)
        }

        // Reload to update checkmarks
        tableView.reloadData()

        // Dismiss after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}

// MARK: - Subtitle Track Cell

/// Table view cell for displaying a subtitle track option
@MainActor
final class SubtitleTrackCell: UITableViewCell {

    static let reuseIdentifier = "SubtitleTrackCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        return label
    }()

    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "checkmark")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .default

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(checkmarkImageView)

        // Ensure child elements don't interfere with cell accessibility
        titleLabel.isAccessibilityElement = false
        subtitleLabel.isAccessibilityElement = false
        checkmarkImageView.isAccessibilityElement = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 30),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -8),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),

            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -30),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 30),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    func configure(title: String, subtitle: String?, isSelected: Bool, accessibilityHint: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
        checkmarkImageView.isHidden = !isSelected

        // Accessibility - treat cell as single accessible element
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityValue = isSelected ? "Selected" : nil
        self.accessibilityHint = accessibilityHint
        accessibilityTraits = isSelected ? [.button, .selected] : .button
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        coordinator.addCoordinatedAnimations { [weak self] in
            if self?.isFocused == true {
                self?.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self?.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            } else {
                self?.transform = .identity
                self?.backgroundColor = .clear
            }
        }
    }
}
