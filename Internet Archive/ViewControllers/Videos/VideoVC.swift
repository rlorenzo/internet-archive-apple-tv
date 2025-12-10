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
import Combine

@MainActor
class VideoVC: UIViewController {

    // MARK: - Properties

    @IBOutlet weak var collectionView: UICollectionView?

    /// Public property for setting collection (for storyboard usage)
    var collection: String {
        get { viewModel.state.collection }
        set { viewModel.setCollection(newValue) }
    }

    // MARK: - Dependencies

    /// ViewModel - can be replaced for testing via `setViewModel(_:)` before viewDidLoad
    private(set) lazy var viewModel: VideoViewModel = {
        VideoViewModel(
            collectionService: DefaultCollectionService(),
            collection: "movies"
        )
    }()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Properties

    private var dataSource: ItemDataSource?
    private var imagePrefetcher: ImagePrefetcher?

    // MARK: - Testing Support

    /// Allows injecting a mock ViewModel for testing - must be called before viewDidLoad
    func setViewModel(_ viewModel: VideoViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        guard collectionView != nil else {
            // Skip setup if collectionView is not connected (testing without storyboard)
            return
        }

        configureCollectionView()
        configureDataSource()
        configureImagePrefetching()
        bindViewModel()
        loadData()
    }

    // MARK: - Configuration

    func configureCollectionView() {
        guard let collectionView = collectionView else { return }

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

    func configureDataSource() {
        guard let collectionView = collectionView else { return }

        dataSource = ItemDataSource(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, itemViewModel in
            guard let self = self else { return UICollectionViewCell() }

            // Return skeleton cell if loading
            if self.viewModel.state.isLoading {
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

    func configureImagePrefetching() {
        guard let collectionView = collectionView, let dataSource = dataSource else { return }
        imagePrefetcher = ImagePrefetcher(collectionView: collectionView, dataSource: dataSource)
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }

    private func handleStateChange(_ state: VideoViewState) {
        if state.isLoading {
            hideEmptyState()
            showSkeletonLoading()
        } else if let errorMessage = state.errorMessage {
            displayEmptyState(.networkError())
            Global.showServiceUnavailableAlert(target: self)
            NSLog("VideoVC Error: \(errorMessage)")
        } else if state.hasLoaded && state.items.isEmpty {
            displayEmptyState(.noItems())
        } else if !state.items.isEmpty {
            hideEmptyState()
            Task {
                await applySnapshot(items: state.items)
            }
        }
    }

    // MARK: - Data Loading

    func loadData() {
        Task {
            await viewModel.loadCollection()
        }
    }

    // MARK: - Snapshot Management

    private func applySnapshot(items: [SearchResult]) async {
        guard let dataSource = dataSource else { return }

        var snapshot = ItemSnapshot()
        snapshot.appendSections([.main])

        let viewModels = items.map { ItemViewModel(item: $0, section: .main) }
        snapshot.appendItems(viewModels, toSection: .main)

        await dataSource.apply(snapshot, animatingDifferences: true)
    }

    func showSkeletonLoading() {
        guard let dataSource = dataSource else { return }

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

    func displayEmptyState(_ emptyStateView: EmptyStateView) {
        hideEmptyState()
        showEmptyState(emptyStateView)
    }

    // MARK: - Testing Helpers

    /// Expose state for testing
    var currentState: VideoViewState {
        viewModel.state
    }

    /// Expose items count for testing
    var itemCount: Int {
        viewModel.state.itemCount
    }
}

// MARK: - UICollectionViewDelegate

extension VideoVC: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Don't allow selection while loading
        guard !viewModel.state.isLoading else { return }

        // Get navigation data from ViewModel
        guard let navData = viewModel.navigationData(for: indexPath.item) else { return }

        // Check if this is the special "Subtitled Videos" entry
        if navData.identifier == subtitledVideosIdentifier {
            let subtitledVC = SubtitledVideosVC()
            present(subtitledVC, animated: true, completion: nil)
            return
        }

        // Navigate to YearsVC for normal collections
        guard let yearsVC = storyboard?.instantiateViewController(
            withIdentifier: "YearsVC"
        ) as? YearsVC else {
            return
        }

        yearsVC.collection = navData.collection
        yearsVC.name = navData.name
        yearsVC.identifier = navData.identifier

        present(yearsVC, animated: true, completion: nil)
    }
}
