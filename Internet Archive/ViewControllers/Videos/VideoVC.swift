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

    private var homeDataSource: HomeDataSource?
    private var continueWatchingItems: [PlaybackProgress] = []

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
        bindViewModel()
        setupAccessibility()
        loadData()
    }

    // MARK: - Accessibility

    private func setupAccessibility() {
        // Collection view accessibility
        collectionView?.accessibilityLabel = "Video collections"
    }

    /// Announce loading state for VoiceOver users
    private func announceLoadingState() {
        UIAccessibility.post(notification: .announcement, argument: "Loading videos")
    }

    /// Announce content loaded for VoiceOver users
    private func announceContentLoaded(itemCount: Int, continueWatchingCount: Int) {
        var announcement: String
        if continueWatchingCount > 0 {
            announcement = "\(continueWatchingCount) item\(continueWatchingCount == 1 ? "" : "s") to continue watching, \(itemCount) video collection\(itemCount == 1 ? "" : "s") available"
        } else {
            announcement = "\(itemCount) video collection\(itemCount == 1 ? "" : "s") available"
        }
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Refresh Continue Watching each time the tab appears
        loadContinueWatching()
    }

    // MARK: - Configuration

    func configureCollectionView() {
        guard let collectionView = collectionView else { return }

        // Configure appearance
        collectionView.backgroundColor = .clear
        view.backgroundColor = .clear

        // Set modern compositional layout (will be updated based on Continue Watching)
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

        // Register Continue Watching cell
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
                // Continue Watching cell
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
            let hasContinueWatching = !(self?.continueWatchingItems.isEmpty ?? true)
            if hasContinueWatching && indexPath.section == 0 {
                header.configure(with: "Continue Watching")
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

    private func handleStateChange(_ state: VideoViewState) {
        if state.isLoading {
            hideEmptyState()
            showSkeletonLoading()
            announceLoadingState()
        } else if let errorMessage = state.errorMessage {
            displayEmptyState(.networkError())
            Global.showServiceUnavailableAlert(target: self)
            NSLog("VideoVC Error: \(errorMessage)")
        } else if state.hasLoaded && state.items.isEmpty {
            displayEmptyState(.noItems())
        } else if !state.items.isEmpty {
            hideEmptyState()
            Task {
                await applySnapshot(items: state.items, continueWatching: continueWatchingItems)
            }
            announceContentLoaded(itemCount: state.items.count, continueWatchingCount: continueWatchingItems.count)
        }
    }

    // MARK: - Data Loading

    func loadData() {
        Task {
            await viewModel.loadCollection()
        }
    }

    private func loadContinueWatching() {
        let items = PlaybackProgressManager.shared.getContinueWatchingItems()
        let hasChanged = items != continueWatchingItems
        continueWatchingItems = items

        // Update layout if Continue Watching status changed
        if hasChanged {
            updateLayout()

            // Refresh snapshot if we have data
            if !viewModel.state.isLoading && !viewModel.state.items.isEmpty {
                Task {
                    await applySnapshot(items: viewModel.state.items, continueWatching: continueWatchingItems)
                }
            }
        }
    }

    private func updateLayout() {
        guard let collectionView = collectionView else { return }
        let hasContinueWatching = !continueWatchingItems.isEmpty
        collectionView.collectionViewLayout = CompositionalLayoutBuilder.createVideoHomeLayout(
            hasContinueWatching: hasContinueWatching
        )
    }

    // MARK: - Snapshot Management

    private func applySnapshot(items: [SearchResult], continueWatching: [PlaybackProgress]) async {
        guard let homeDataSource = homeDataSource else { return }

        var snapshot = HomeSnapshot()

        // Add Continue Watching section if we have items
        if !continueWatching.isEmpty {
            snapshot.appendSections([.continueWatching])
            let progressItems = continueWatching.map { HomeScreenItem.progress($0) }
            snapshot.appendItems(progressItems, toSection: .continueWatching)
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

        // Include Continue Watching section if we have items (keeps layout consistent)
        if !continueWatchingItems.isEmpty {
            snapshot.appendSections([.continueWatching])
            let progressItems = continueWatchingItems.map { HomeScreenItem.progress($0) }
            snapshot.appendItems(progressItems, toSection: .continueWatching)
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

    // MARK: - Continue Watching Actions

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

        // Check if this is a Continue Watching item
        let hasContinueWatching = !continueWatchingItems.isEmpty
        if hasContinueWatching && indexPath.section == 0 {
            // Continue Watching section
            guard indexPath.item < continueWatchingItems.count else { return }
            let progress = continueWatchingItems[indexPath.item]
            navigateToItem(with: progress)
            return
        }

        // Main section - adjust index if we have Continue Watching section
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
