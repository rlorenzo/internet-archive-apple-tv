//
//  SubtitledVideosVC.swift
//  Internet Archive
//
//  A view controller that displays videos with subtitles for testing CC functionality
//

import UIKit

@MainActor
class SubtitledVideosVC: UIViewController, UICollectionViewDelegate {

    // MARK: - UI Elements

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Videos with Subtitles"
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: CompositionalLayoutBuilder.standardGrid
        )
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.register(
            ModernItemCell.self,
            forCellWithReuseIdentifier: ModernItemCell.reuseIdentifier
        )
        return collectionView
    }()

    // MARK: - Data Source

    private var dataSource: ItemDataSource!
    private var items: [SearchResult] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupUI()
        configureDataSource()
        loadSubtitledVideos()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 90),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -90),

            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 90),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -90),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureDataSource() {
        dataSource = ItemDataSource(collectionView: collectionView) { collectionView, indexPath, itemViewModel in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ModernItemCell.reuseIdentifier,
                for: indexPath
            ) as? ModernItemCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: itemViewModel)
            return cell
        }
    }

    // MARK: - Data Loading

    private func loadSubtitledVideos() {
        AppProgressHUD.sharedManager.show(view: view)

        Task {
            do {
                items = try await APIManager.sharedManager.getVideosWithSubtitles(limit: 50)
                AppProgressHUD.sharedManager.hide()

                if items.isEmpty {
                    showEmptyState()
                } else {
                    await applySnapshot()
                }
            } catch {
                AppProgressHUD.sharedManager.hide()
                Global.showServiceUnavailableAlert(target: self)
                NSLog("SubtitledVideosVC Error: \(error)")
            }
        }
    }

    private func applySnapshot() async {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.main])
        let viewModels = items.map { ItemViewModel(item: $0, section: .main) }
        snapshot.appendItems(viewModels, toSection: .main)
        await dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func showEmptyState() {
        let emptyLabel = UILabel()
        emptyLabel.text = "No subtitled videos found"
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < items.count else { return }
        let item = items[indexPath.row]

        // Load storyboard directly since this VC is created programmatically
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let itemVC = mainStoryboard.instantiateViewController(withIdentifier: "ItemVC") as? ItemVC else {
            return
        }

        let imageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(item.identifier)")

        itemVC.iIdentifier = item.identifier
        itemVC.iTitle = item.title ?? item.identifier
        itemVC.iArchivedBy = item.creator ?? ""
        itemVC.iDate = Global.formatDate(string: item.date) ?? ""
        itemVC.iDescription = item.description ?? ""
        itemVC.iMediaType = item.mediatype ?? "movies"
        itemVC.iImageURL = imageURL
        itemVC.iLicenseURL = item.licenseurl

        present(itemVC, animated: true, completion: nil)
    }
}
