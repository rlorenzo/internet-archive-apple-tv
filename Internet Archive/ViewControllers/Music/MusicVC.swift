//
//  MusicVC.swift
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
class MusicVC: UIViewController {

    // MARK: - Properties

    @IBOutlet weak var collectionView: UICollectionView?

    /// Public property for setting collection (for storyboard usage)
    var collection: String {
        get { viewModel.state.collection }
        set { viewModel.setCollection(newValue) }
    }

    // MARK: - Dependencies

    /// ViewModel - can be replaced for testing via `setViewModel(_:)` before viewDidLoad
    private(set) lazy var viewModel: MusicViewModel = {
        MusicViewModel(
            collectionService: DefaultCollectionService(),
            collection: "etree"
        )
    }()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Properties

    private var homeDataSource: HomeDataSource?
    private var continueListeningItems: [PlaybackProgress] = []

    // MARK: - Testing Support

    /// Allows injecting a mock ViewModel for testing - must be called before viewDidLoad
    func setViewModel(_ viewModel: MusicViewModel) {
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
        bindViewModel()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Refresh Continue Listening each time the tab appears
        loadContinueListening()
    }

    // MARK: - Configuration

    func configureCollectionView() {
        guard let collectionView = collectionView else { return }

        // Configure appearance
        collectionView.backgroundColor = .clear
        view.backgroundColor = .clear

        // Set modern compositional layout (will be updated based on Continue Listening)
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

        // Register Continue Listening cell
        collectionView.register(
            ContinueWatchingCell.self,
            forCellWithReuseIdentifier: ContinueWatchingCell.reuseIdentifier
        )

        // Register section header
        collectionView.register(
            ContinueSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ContinueSectionHeaderView.reuseIdentifier
        )

        // Set delegate for selection
        collectionView.delegate = self
    }

    func configureDataSource() {
        guard let collectionView = collectionView else { return }

        homeDataSource = HomeDataSource(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, item in
            guard let self = self else { return UICollectionViewCell() }

            switch item {
            case .progress(let progress):
                // Continue Listening cell
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ContinueWatchingCell.reuseIdentifier,
                    for: indexPath
                ) as? ContinueWatchingCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: progress)
                return cell

            case .item(let itemViewModel):
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

        // Configure supplementary view (section header)
        homeDataSource?.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }

            guard let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: ContinueSectionHeaderView.reuseIdentifier,
                for: indexPath
            ) as? ContinueSectionHeaderView else {
                return nil
            }

            // Determine section title
            let hasContinueListening = !(self?.continueListeningItems.isEmpty ?? true)
            if hasContinueListening && indexPath.section == 0 {
                header.configure(with: "Continue Listening")
            }

            return header
        }
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

    private func handleStateChange(_ state: MusicViewState) {
        if state.isLoading {
            hideEmptyState()
            showSkeletonLoading()
        } else if let errorMessage = state.errorMessage {
            displayEmptyState(.networkError())
            Global.showServiceUnavailableAlert(target: self)
            NSLog("MusicVC Error: \(errorMessage)")
        } else if state.hasLoaded && state.items.isEmpty {
            displayEmptyState(.noItems())
        } else if !state.items.isEmpty {
            hideEmptyState()
            Task {
                await applySnapshot(items: state.items, continueListening: continueListeningItems)
            }
        }
    }

    // MARK: - Data Loading

    func loadData() {
        Task {
            await viewModel.loadCollection()
        }
    }

    private func loadContinueListening() {
        let items = PlaybackProgressManager.shared.getContinueListeningItems()
        let hasChanged = items != continueListeningItems
        continueListeningItems = items

        // Update layout if Continue Listening status changed
        if hasChanged {
            updateLayout()

            // Refresh snapshot if we have data
            if !viewModel.state.isLoading && !viewModel.state.items.isEmpty {
                Task {
                    await applySnapshot(items: viewModel.state.items, continueListening: continueListeningItems)
                }
            }
        }
    }

    private func updateLayout() {
        guard let collectionView = collectionView else { return }
        let hasContinueListening = !continueListeningItems.isEmpty
        collectionView.collectionViewLayout = CompositionalLayoutBuilder.createMusicHomeLayout(
            hasContinueListening: hasContinueListening
        )
    }

    // MARK: - Snapshot Management

    private func applySnapshot(items: [SearchResult], continueListening: [PlaybackProgress]) async {
        guard let homeDataSource = homeDataSource else { return }

        var snapshot = HomeSnapshot()

        // Add Continue Listening section if we have items
        if !continueListening.isEmpty {
            snapshot.appendSections([.continueListening])
            let progressItems = continueListening.map { HomeScreenItem.progress($0) }
            snapshot.appendItems(progressItems, toSection: .continueListening)
        }

        // Add main section
        snapshot.appendSections([.main])
        let viewModels = items.map { HomeScreenItem.item(ItemViewModel(item: $0, section: .main)) }
        snapshot.appendItems(viewModels, toSection: .main)

        await homeDataSource.apply(snapshot, animatingDifferences: true)
    }

    func showSkeletonLoading() {
        guard let homeDataSource = homeDataSource else { return }

        var snapshot = HomeSnapshot()

        // Include Continue Listening section if we have items (keeps layout consistent)
        if !continueListeningItems.isEmpty {
            snapshot.appendSections([.continueListening])
            let progressItems = continueListeningItems.map { HomeScreenItem.progress($0) }
            snapshot.appendItems(progressItems, toSection: .continueListening)
        }

        snapshot.appendSections([.main])

        // Create 20 placeholder items for skeleton
        let placeholders = (0..<20).map { index -> HomeScreenItem in
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
            return HomeScreenItem.item(ItemViewModel(item: placeholder, section: .main))
        }
        snapshot.appendItems(placeholders, toSection: .main)

        Task { @MainActor in
            await homeDataSource.apply(snapshot, animatingDifferences: false)
        }
    }

    // MARK: - Empty State

    func displayEmptyState(_ emptyStateView: EmptyStateView) {
        hideEmptyState()
        showEmptyState(emptyStateView)
    }

    // MARK: - Continue Listening Actions

    private func navigateToItem(with progress: PlaybackProgress) {
        // Navigate to ItemVC with the progress item
        guard let itemVC = storyboard?.instantiateViewController(
            withIdentifier: "ItemVC"
        ) as? ItemVC else {
            return
        }

        // Set item properties
        itemVC.iIdentifier = progress.itemIdentifier
        itemVC.iTitle = progress.title
        itemVC.iMediaType = progress.mediaType
        if let thumbnailURL = progress.thumbnailURL {
            itemVC.iImageURL = thumbnailURL
        }

        present(itemVC, animated: true, completion: nil)
    }

    // MARK: - Testing Helpers

    /// Expose state for testing
    var currentState: MusicViewState {
        viewModel.state
    }

    /// Expose items count for testing
    var itemCount: Int {
        viewModel.state.itemCount
    }
}

// MARK: - UICollectionViewDelegate

extension MusicVC: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Don't allow selection while loading
        guard !viewModel.state.isLoading else { return }

        // Check if this is a Continue Listening item
        let hasContinueListening = !continueListeningItems.isEmpty
        if hasContinueListening && indexPath.section == 0 {
            // Continue Listening section
            guard indexPath.item < continueListeningItems.count else { return }
            let progress = continueListeningItems[indexPath.item]
            navigateToItem(with: progress)
            return
        }

        // Main section
        let mainIndex = indexPath.item

        // Get navigation data from ViewModel
        guard let navData = viewModel.navigationData(for: mainIndex) else { return }

        // Navigate to YearsVC
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
