//
//  VideoVC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//
//

import UIKit
import AlamofireImage

@MainActor
class VideoVC: UIViewController {

    // MARK: - Properties

    @IBOutlet weak var collectionView: UICollectionView!

    var collection = "movies"

    private var dataSource: ItemDataSource!
    private var imagePrefetcher: ImagePrefetcher!
    private var items: [SearchResult] = []
    private var isLoading = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()
        configureDataSource()
        configureImagePrefetching()
        loadData()
    }

    // MARK: - Configuration

    private func configureCollectionView() {
        // Configure appearance
        collectionView.backgroundColor = .clear
        view.backgroundColor = .clear

        // Set modern compositional layout
        collectionView.collectionViewLayout = CompositionalLayoutBuilder.standardGrid

        // Register modern cell
        collectionView.register(
            ModernItemCell.self,
            forCellWithReuseIdentifier: ModernItemCell.reuseIdentifier
        )

        // Register skeleton cell for loading
        collectionView.register(
            SkeletonItemCell.self,
            forCellWithReuseIdentifier: SkeletonItemCell.reuseIdentifier
        )

        // Set delegate for selection
        collectionView.delegate = self
    }

    private func configureDataSource() {
        dataSource = ItemDataSource(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, itemViewModel in
            // Return skeleton cell if loading
            if self?.isLoading == true {
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: SkeletonItemCell.reuseIdentifier,
                    for: indexPath
                ) as? SkeletonItemCell else {
                    return UICollectionViewCell()
                }
                cell.startAnimating()
                return cell
            }

            // Return normal cell with data
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

    private func configureImagePrefetching() {
        imagePrefetcher = ImagePrefetcher(collectionView: collectionView, dataSource: dataSource)
    }

    // MARK: - Data Loading

    private func loadData() {
        isLoading = true
        showSkeletonLoading()

        Task {
            do {
                // Use retry mechanism for network resilience
                let result = try await RetryMechanism.execute(config: .standard) {
                    try await APIManager.sharedManager.getCollectionsTyped(
                        collection: self.collection,
                        resultType: "collection",
                        limit: nil as Int?
                    )
                }

                // Update collection name
                self.collection = result.collection

                // Sort by downloads
                self.items = result.results.sorted { item1, item2 in
                    (item1.downloads ?? 0) > (item2.downloads ?? 0)
                }

                // Update data source
                isLoading = false
                await applySnapshot()

                // Show empty state if no items
                if items.isEmpty {
                    displayEmptyState(.noItems())
                }

                // Log success
                ErrorLogger.shared.logSuccess(
                    operation: .getCollections,
                    info: ["count": items.count, "collection": collection]
                )

            } catch {
                isLoading = false

                // Log error with context
                let context = ErrorContext(
                    operation: .getCollections,
                    userFacingTitle: "Unable to Load Videos",
                    additionalInfo: ["collection": collection]
                )

                // Show error empty state
                displayEmptyState(.networkError())

                // Present error with retry option
                ErrorPresenter.shared.present(
                    error,
                    context: context,
                    on: self,
                    retry: { [weak self] in
                        self?.loadData()
                    }
                )
            }
        }
    }

    // MARK: - Snapshot Management

    private func applySnapshot() async {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.main])

        let viewModels = items.map { ItemViewModel(item: $0, section: .main) }
        snapshot.appendItems(viewModels, toSection: .main)

        await dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func showSkeletonLoading() {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.main])

        // Create 20 placeholder items for skeleton
        let placeholders = (0..<20).map { index -> ItemViewModel in
            // Create placeholder SearchResult
            let placeholder = SearchResult(
                identifier: "skeleton-\(index)",
                title: "",
                mediatype: "",
                creator: "",
                description: "",
                date: "",
                year: "",
                downloads: 0,
                subject: [],
                collection: []
            )
            return ItemViewModel(item: placeholder, section: .main)
        }
        snapshot.appendItems(placeholders, toSection: .main)

        Task { @MainActor in
            await dataSource.apply(snapshot, animatingDifferences: false)
        }
    }

    // MARK: - Empty State

    private func displayEmptyState(_ emptyStateView: EmptyStateView) {
        hideEmptyState()
        showEmptyState(emptyStateView)
    }
}

// MARK: - UICollectionViewDelegate

extension VideoVC: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Don't allow selection while loading
        guard !isLoading else { return }

        // Get the selected item
        guard indexPath.item < items.count else { return }
        let item = items[indexPath.item]

        // Navigate to YearsVC
        guard let yearsVC = storyboard?.instantiateViewController(
            withIdentifier: "YearsVC"
        ) as? YearsVC else {
            return
        }

        yearsVC.collection = collection
        yearsVC.name = item.title ?? item.identifier
        yearsVC.identifier = item.identifier

        present(yearsVC, animated: true, completion: nil)
    }
}
