//
//  ImagePrefetcher.swift
//  Internet Archive
//
//
//  Copyright © 2025 Internet Archive. All rights reserved.
//

import UIKit

/// Handles prefetching of images for collection views with DiffableDataSource
@MainActor
final class ImagePrefetcher: NSObject {

    // MARK: - Properties

    private weak var collectionView: UICollectionView?
    private weak var dataSource: ItemDataSource?

    // MARK: - Initialization

    init(collectionView: UICollectionView, dataSource: ItemDataSource? = nil) {
        self.collectionView = collectionView
        self.dataSource = dataSource
        super.init()
        collectionView.prefetchDataSource = self
    }

    /// Set the data source for prefetching
    /// - Parameter dataSource: The diffable data source
    func setDataSource(_ dataSource: ItemDataSource) {
        self.dataSource = dataSource
    }

    /// Extract URLs from diffable data source snapshot
    /// - Parameter indexPaths: Index paths to prefetch
    /// - Returns: Array of image URLs
    private func extractURLs(for indexPaths: [IndexPath]) -> [URL] {
        guard let dataSource = dataSource else { return [] }

        return indexPaths.compactMap { indexPath in
            // Get the item from the snapshot
            guard let itemViewModel = dataSource.itemIdentifier(for: indexPath) else {
                return nil
            }
            return itemViewModel.item.imageURL
        }
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension ImagePrefetcher: UICollectionViewDataSourcePrefetching {

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = extractURLs(for: indexPaths)
        guard !urls.isEmpty else { return }

        // Prefetch images using cache manager
        ImageCacheManager.shared.prefetchImages(for: urls)

        #if DEBUG
        print("Prefetching \(urls.count) images for index paths: \(indexPaths.map { $0.item })")
        #endif
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        // Note: AlamofireImage doesn't support canceling specific prefetch requests
        // Images will continue to download but won't block high-priority requests
        #if DEBUG
        print("Canceled prefetching for index paths: \(indexPaths.map { $0.item })")
        #endif
    }
}

// MARK: - SearchResult Extension

extension SearchResult {

    /// Computed property for image URL
    var imageURL: URL? {
        // Internet Archive image URL format:
        // https://archive.org/services/img/{identifier}
        let urlString = "https://archive.org/services/img/\(identifier)"
        return URL(string: urlString)
    }
}
