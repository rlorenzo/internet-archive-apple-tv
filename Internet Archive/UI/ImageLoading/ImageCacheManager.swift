//
//  ImageCacheManager.swift
//  Internet Archive
//
//
//  Copyright © 2025 Internet Archive. All rights reserved.
//

import UIKit
import AlamofireImage

/// Manages image caching with two-tier strategy:
/// 1. Fast in-memory cache (AutoPurgingImageCache) - 100 MB, cleared on memory warnings
/// 2. Persistent disk cache (URLCache) - 500 MB, survives app restarts
@MainActor
final class ImageCacheManager {

    // MARK: - Singleton

    static let shared = ImageCacheManager()

    // MARK: - Properties

    private let imageCache: AutoPurgingImageCache
    private let memoryCacheSize: UInt64 = 100_000_000 // 100 MB in-memory
    private let preferredMemoryUsageAfterPurge: UInt64 = 60_000_000 // 60 MB after purge

    /// Image downloader with custom configuration including disk cache
    private lazy var imageDownloader: ImageDownloader = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad

        // Configure URLCache for disk persistence (500 MB disk, 50 MB memory)
        let urlCache = URLCache(
            memoryCapacity: 50_000_000,   // 50 MB memory
            diskCapacity: 500_000_000,     // 500 MB disk
            diskPath: "image_cache"
        )
        configuration.urlCache = urlCache

        let downloader = ImageDownloader(
            configuration: configuration,
            downloadPrioritization: .fifo,
            maximumActiveDownloads: 4,
            imageCache: imageCache
        )

        return downloader
    }()

    // MARK: - Initialization

    private init() {
        // Initialize cache
        imageCache = AutoPurgingImageCache(
            memoryCapacity: memoryCacheSize,
            preferredMemoryUsageAfterPurge: preferredMemoryUsageAfterPurge
        )

        // Setup memory warning observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    /// Load image from URL with caching
    /// - Parameters:
    ///   - url: Image URL
    ///   - completion: Completion handler with image result
    func loadImage(from url: URL, completion: @escaping @Sendable (Result<UIImage, Error>) -> Void) {
        // Check cache first
        if let cachedImage = imageCache.image(withIdentifier: url.absoluteString) {
            completion(.success(cachedImage))
            return
        }

        // Download image
        let urlRequest = URLRequest(url: url)
        let urlString = url.absoluteString

        imageDownloader.download(
            urlRequest,
            completion: { [weak self] (response: AFIDataResponse<Image>) in
                Task { @MainActor in
                    switch response.result {
                    case .success(let image):
                        // Cache the image
                        self?.imageCache.add(image, withIdentifier: urlString)
                        completion(.success(image))

                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        )
    }

    /// Prefetch images for URLs
    /// - Parameter urls: Array of URLs to prefetch
    func prefetchImages(for urls: [URL]) {
        for url in urls {
            // Skip if already cached
            guard imageCache.image(withIdentifier: url.absoluteString) == nil else {
                continue
            }

            // Download with low priority
            let urlRequest = URLRequest(url: url)
            let urlString = url.absoluteString

            imageDownloader.download(
                urlRequest,
                completion: { [weak self] (response: AFIDataResponse<Image>) in
                    Task { @MainActor in
                        if case .success(let image) = response.result {
                            self?.imageCache.add(image, withIdentifier: urlString)
                        }
                    }
                }
            )
        }
    }

    /// Get cached image if available
    /// - Parameter url: Image URL
    /// - Returns: Cached image or nil
    func cachedImage(for url: URL) -> UIImage? {
        imageCache.image(withIdentifier: url.absoluteString)
    }

    /// Clear all cached images
    func clearCache() {
        imageCache.removeAllImages()
    }

    /// Get current cache memory usage
    var cacheMemoryUsage: UInt64 {
        imageCache.memoryUsage
    }

    // MARK: - Memory Management

    @objc private func handleMemoryWarning() {
        // Purge cache on memory warning
        let purgedMemory = imageCache.memoryUsage
        imageCache.removeAllImages()
        print("ImageCacheManager: Purged \(purgedMemory / 1_000_000) MB due to memory warning")
    }
}

// MARK: - UIImageView Extension

extension UIImageView {

    /// Load image with ImageCacheManager
    /// - Parameters:
    ///   - url: Image URL
    ///   - placeholder: Placeholder image
    @MainActor
    func loadImage(from url: URL?, placeholder: UIImage? = nil) {
        // Set placeholder
        self.image = placeholder

        // Load image
        guard let url = url else { return }

        ImageCacheManager.shared.loadImage(from: url) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let image):
                UIView.transition(
                    with: self,
                    duration: 0.3,
                    options: .transitionCrossDissolve,
                    animations: {
                        self.image = image
                    }
                )

            case .failure(let error):
                print("Failed to load image: \(error.localizedDescription)")
            }
        }
    }
}
