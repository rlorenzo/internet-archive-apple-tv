//
//  SearchResultVC.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//
//

import UIKit
import Combine

// MARK: - Search Filter

enum SearchFilter: Int, CaseIterable {
    case all = 0
    case video = 1
    case music = 2

    var title: String {
        switch self {
        case .all: return "All"
        case .video: return "Video"
        case .music: return "Music"
        }
    }
}

// MARK: - Search Section

enum SearchSection: Int, CaseIterable {
    case videos
    case music

    var title: String {
        switch self {
        case .videos: return "Videos"
        case .music: return "Music"
        }
    }
}

// MARK: - Section Header View

final class SectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "SectionHeaderView"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with title: String) {
        titleLabel.text = title
    }
}

@MainActor
class SearchResultVC: UIViewController, UISearchResultsUpdating, UICollectionViewDelegate {

    @IBOutlet weak var clsVideo: UICollectionView!
    @IBOutlet weak var clsMusic: UICollectionView!
    @IBOutlet weak var lblMovies: UILabel!
    @IBOutlet weak var lblMusic: UILabel!

    private var videoDataSource: ItemDataSource!
    private var musicDataSource: ItemDataSource!
    private var videoPrefetcher: ImagePrefetcher!
    private var musicPrefetcher: ImagePrefetcher!

    // MARK: - Filter UI

    private var currentFilter: SearchFilter = .all

    /// Combined collection view for "All" filter mode
    private lazy var combinedCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createCombinedLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.register(
            ModernItemCell.self,
            forCellWithReuseIdentifier: ModernItemCell.reuseIdentifier
        )
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier
        )
        return collectionView
    }()

    private var combinedDataSource: UICollectionViewDiffableDataSource<SearchSection, ItemViewModel>!

    private lazy var filterSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: SearchFilter.allCases.map { $0.title })
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(filterChanged(_:)), for: .valueChanged)
        return control
    }()

    // MARK: - ViewModel

    private lazy var viewModel: SearchViewModel = {
        SearchViewModel(searchService: DefaultSearchService())
    }()

    private var cancellables = Set<AnyCancellable>()
    private var lastQuery = ""

    // Debounce search input
    private let searchSubject = PassthroughSubject<String, Never>()
    private static let debounceInterval: TimeInterval = 0.5

    // Computed properties from ViewModel state
    var videoItems: [SearchResult] {
        viewModel.state.videoResults
    }

    var musicItems: [SearchResult] {
        viewModel.state.musicResults
    }

    var query = "" {
        didSet {
            let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
            guard trimmedQuery != lastQuery else { return }
            lastQuery = trimmedQuery

            if trimmedQuery.isEmpty {
                viewModel.clearResults()
                return
            }

            performSearch(query: trimmedQuery)
        }
    }

    private func performSearch(query: String) {
        AppProgressHUD.sharedManager.show(view: self.view)
        clsVideo.isHidden = true
        clsMusic.isHidden = true
        lblMovies.isHidden = true
        lblMusic.isHidden = true

        Task {
            await viewModel.searchMoviesAndMusic(query: query)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFilterControl()
        setupCombinedCollectionView()
        configureVideoCollectionView()
        configureMusicCollectionView()
        configureCombinedDataSource()
        bindViewModel()
        setupSearchDebounce()
    }

    private func setupFilterControl() {
        view.addSubview(filterSegmentedControl)
        NSLayoutConstraint.activate([
            filterSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            filterSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterSegmentedControl.widthAnchor.constraint(equalToConstant: 400),
            filterSegmentedControl.heightAnchor.constraint(equalToConstant: 70)
        ])
        filterSegmentedControl.isHidden = true

        // Set up focus guide to help navigate to/from the segmented control
        let focusGuide = UIFocusGuide()
        view.addLayoutGuide(focusGuide)
        NSLayoutConstraint.activate([
            focusGuide.topAnchor.constraint(equalTo: filterSegmentedControl.bottomAnchor),
            focusGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            focusGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            focusGuide.heightAnchor.constraint(equalToConstant: 40)
        ])
        focusGuide.preferredFocusEnvironments = [filterSegmentedControl]
    }

    private func setupCombinedCollectionView() {
        view.addSubview(combinedCollectionView)
        NSLayoutConstraint.activate([
            combinedCollectionView.topAnchor.constraint(equalTo: filterSegmentedControl.bottomAnchor, constant: 40),
            combinedCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 90),
            combinedCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -90),
            combinedCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        combinedCollectionView.isHidden = true
        combinedCollectionView.remembersLastFocusedIndexPath = true

        // Add focus guide from combined collection to filter control
        setupFocusGuideFromCollection(combinedCollectionView)
    }

    private func createCombinedLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            // Item
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute(270),
                heightDimension: .absolute(380)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)

            // Group - horizontal row
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(380)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 40, trailing: 0)
            section.orthogonalScrollingBehavior = .continuous

            // Header
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(60)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]

            return section
        }
        return layout
    }

    private func configureCombinedDataSource() {
        combinedDataSource = UICollectionViewDiffableDataSource<SearchSection, ItemViewModel>(
            collectionView: combinedCollectionView
        ) { collectionView, indexPath, itemViewModel in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ModernItemCell.reuseIdentifier,
                for: indexPath
            ) as? ModernItemCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: itemViewModel)
            return cell
        }

        combinedDataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader,
                  let header = collectionView.dequeueReusableSupplementaryView(
                      ofKind: kind,
                      withReuseIdentifier: SectionHeaderView.reuseIdentifier,
                      for: indexPath
                  ) as? SectionHeaderView else {
                return UICollectionReusableView()
            }

            let section = SearchSection(rawValue: indexPath.section)
            header.configure(with: section?.title ?? "")
            return header
        }
    }

    @objc private func filterChanged(_ sender: UISegmentedControl) {
        currentFilter = SearchFilter(rawValue: sender.selectedSegmentIndex) ?? .all
        updateVisibleCollections()
    }

    private func setupSearchDebounce() {
        searchSubject
            .debounce(for: .seconds(Self.debounceInterval), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.query = searchText
            }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideAllResults()
    }

    // MARK: - Focus Management

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        // When filter is visible and we have results, prefer the collection views first
        if !filterSegmentedControl.isHidden {
            if !combinedCollectionView.isHidden {
                return [combinedCollectionView, filterSegmentedControl]
            } else if !clsVideo.isHidden {
                return [clsVideo, filterSegmentedControl]
            } else if !clsMusic.isHidden {
                return [clsMusic, filterSegmentedControl]
            }
            return [filterSegmentedControl]
        }
        return super.preferredFocusEnvironments
    }

    private func setupFocusGuideFromCollection(_ collectionView: UICollectionView) {
        let focusGuide = UIFocusGuide()
        view.addLayoutGuide(focusGuide)
        NSLayoutConstraint.activate([
            focusGuide.bottomAnchor.constraint(equalTo: collectionView.topAnchor),
            focusGuide.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            focusGuide.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            focusGuide.heightAnchor.constraint(equalToConstant: 20)
        ])
        focusGuide.preferredFocusEnvironments = [filterSegmentedControl]
    }

    private func hideAllResults() {
        clsVideo.isHidden = true
        clsMusic.isHidden = true
        lblMovies.isHidden = true
        lblMusic.isHidden = true
        combinedCollectionView.isHidden = true
        filterSegmentedControl.isHidden = true
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

    private func handleStateChange(_ state: SearchViewState) {
        if state.isLoading {
            return // Wait for results
        }

        AppProgressHUD.sharedManager.hide()

        if let errorMessage = state.errorMessage {
            let context = ErrorContext(
                operation: .search,
                userFacingTitle: "Search Failed",
                additionalInfo: ["query": lastQuery]
            )
            Global.showAlert(title: context.userFacingTitle, message: errorMessage, target: self)
            return
        }

        // Show filter and results if we have any
        let hasResults = !state.results.isEmpty
        filterSegmentedControl.isHidden = !hasResults

        if hasResults {
            updateVisibleCollections()
        } else {
            hideAllResults()
        }

        // Apply snapshots for all modes
        Task {
            await applyVideoSnapshot()
            await applyMusicSnapshot()
            await applyCombinedSnapshot()
        }
    }

    private func updateVisibleCollections() {
        let hasVideoResults = !videoItems.isEmpty
        let hasMusicResults = !musicItems.isEmpty

        switch currentFilter {
        case .all:
            // Show combined collection view
            clsVideo.isHidden = true
            clsMusic.isHidden = true
            lblMovies.isHidden = true
            lblMusic.isHidden = true
            combinedCollectionView.isHidden = false

        case .video:
            // Show only video collection
            clsVideo.isHidden = !hasVideoResults
            lblMovies.isHidden = !hasVideoResults
            clsMusic.isHidden = true
            lblMusic.isHidden = true
            combinedCollectionView.isHidden = true

        case .music:
            // Show only music collection
            clsVideo.isHidden = true
            lblMovies.isHidden = true
            clsMusic.isHidden = !hasMusicResults
            lblMusic.isHidden = !hasMusicResults
            combinedCollectionView.isHidden = true
        }
    }

    private func applyCombinedSnapshot() async {
        var snapshot = NSDiffableDataSourceSnapshot<SearchSection, ItemViewModel>()

        // Add video section if we have video results
        if !videoItems.isEmpty {
            snapshot.appendSections([.videos])
            let videoViewModels = videoItems.map { ItemViewModel(item: $0, section: .videos) }
            snapshot.appendItems(videoViewModels, toSection: .videos)
        }

        // Add music section if we have music results
        if !musicItems.isEmpty {
            snapshot.appendSections([.music])
            let musicViewModels = musicItems.map { ItemViewModel(item: $0, section: .music) }
            snapshot.appendItems(musicViewModels, toSection: .music)
        }

        await combinedDataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Configuration

    private func configureVideoCollectionView() {
        // Set up modern compositional layout
        clsVideo.collectionViewLayout = CompositionalLayoutBuilder.standardGrid

        // Register modern cell
        clsVideo.register(
            ModernItemCell.self,
            forCellWithReuseIdentifier: ModernItemCell.reuseIdentifier
        )

        // Configure diffable data source
        videoDataSource = ItemDataSource(collectionView: clsVideo) { collectionView, indexPath, itemViewModel in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ModernItemCell",
                for: indexPath
            ) as? ModernItemCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: itemViewModel)

            return cell
        }

        // Set up image prefetching
        videoPrefetcher = ImagePrefetcher(collectionView: clsVideo, dataSource: videoDataSource)
    }

    private func configureMusicCollectionView() {
        // Set up modern compositional layout
        clsMusic.collectionViewLayout = CompositionalLayoutBuilder.standardGrid

        // Register modern cell
        clsMusic.register(
            ModernItemCell.self,
            forCellWithReuseIdentifier: ModernItemCell.reuseIdentifier
        )

        // Configure diffable data source
        musicDataSource = ItemDataSource(collectionView: clsMusic) { collectionView, indexPath, itemViewModel in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ModernItemCell",
                for: indexPath
            ) as? ModernItemCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: itemViewModel)

            return cell
        }

        // Set up image prefetching
        musicPrefetcher = ImagePrefetcher(collectionView: clsMusic, dataSource: musicDataSource)
    }

    private func applyVideoSnapshot() async {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.videos])
        let viewModels = videoItems.map { ItemViewModel(item: $0, section: .videos) }
        snapshot.appendItems(viewModels, toSection: .videos)
        await videoDataSource.apply(snapshot, animatingDifferences: true)
    }

    private func applyMusicSnapshot() async {
        var snapshot = ItemSnapshot()
        snapshot.appendSections([.music])
        let viewModels = musicItems.map { ItemViewModel(item: $0, section: .music) }
        snapshot.appendItems(viewModels, toSection: .music)
        await musicDataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        searchSubject.send(searchController.searchBar.text ?? "")
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let items: [SearchResult]

        if collectionView == combinedCollectionView {
            // Get items from the appropriate section in combined view
            let section = SearchSection(rawValue: indexPath.section)
            items = (section == .videos) ? videoItems : musicItems
        } else {
            items = (collectionView == clsVideo) ? videoItems : musicItems
        }

        guard indexPath.row < items.count else { return }
        let item = items[indexPath.row]

        // Navigate to ItemVC to show the info card
        navigateToItemDetail(item: item)
    }

    private func navigateToItemDetail(item: SearchResult) {
        guard let itemVC = storyboard?.instantiateViewController(withIdentifier: "ItemVC") as? ItemVC else {
            return
        }

        let imageURL = URL(string: "https://archive.org/services/get-item-image.php?identifier=\(item.identifier)")

        itemVC.iIdentifier = item.identifier
        itemVC.iTitle = item.title ?? item.identifier
        itemVC.iArchivedBy = item.creator ?? ""
        itemVC.iDate = Global.formatDate(string: item.date) ?? ""
        itemVC.iDescription = item.description ?? ""
        itemVC.iMediaType = item.mediatype ?? ""
        itemVC.iImageURL = imageURL
        itemVC.iLicenseURL = item.licenseurl

        present(itemVC, animated: true, completion: nil)
    }

}
