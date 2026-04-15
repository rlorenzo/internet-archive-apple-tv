//
//  ImageCacheManager.swift
//  Internet Archive
//
//
//  Copyright © 2025 Internet Archive. All rights reserved.
//

import UIKit
import Nuke
import NukeExtensions

/// Manages image caching with Nuke's two-tier strategy:
/// 1. Fast in-memory cache - device-aware (50–150 MB), cleared on memory warnings
/// 2. Persistent disk cache - 500 MB, survives app restarts
@MainActor
final class ImageCacheManager {

    // MARK: - Singleton

    static let shared = ImageCacheManager()

    // MARK: - Properties

    /// The Nuke image pipeline used for all image loading
    let pipeline: ImagePipeline

    /// Long-lived prefetcher; retained so in-flight prefetches aren't cancelled
    /// when a caller's scope ends (Nuke cancels prefetcher tasks on deinit).
    private let prefetcher: ImagePrefetcher

    /// Compute device-aware memory cache size (capped at ~5% of physical RAM)
    private static var deviceAwareMemoryCacheSize: Int {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let fivePercent = physicalMemory / 20
        // Clamp between 50 MB and 150 MB
        return Int(min(max(fivePercent, 50_000_000), 150_000_000))
    }

    // MARK: - Initialization

    private init() {
        // Configure memory cache
        let imageCache = ImageCache()
        imageCache.costLimit = ImageCacheManager.deviceAwareMemoryCacheSize

        // Configure disk cache (500 MB)
        let dataCache = try? DataCache(name: "internet_archive_images")
        dataCache?.sizeLimit = 500_000_000

        // Build pipeline
        var config = ImagePipeline.Configuration()
        config.imageCache = imageCache
        config.dataCache = dataCache
        config.dataCachePolicy = .automatic

        let pipeline = ImagePipeline(configuration: config)
        self.pipeline = pipeline
        self.prefetcher = ImagePrefetcher(pipeline: pipeline)

        // Also set as shared pipeline for NukeUI LazyImage and NukeExtensions usage
        ImagePipeline.shared = pipeline

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
        let request = ImageRequest(url: url)

        // Check cache first
        if let cached = pipeline.cache[request] {
            completion(.success(cached.image))
            return
        }

        // Download image
        pipeline.loadImage(with: request) { result in
            Task { @MainActor in
                switch result {
                case .success(let response):
                    completion(.success(response.image))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /// Prefetch images for URLs
    /// - Parameter urls: Array of URLs to prefetch
    func prefetchImages(for urls: [URL]) {
        guard !urls.isEmpty else { return }
        let requests = urls.map { ImageRequest(url: $0, priority: .low) }
        prefetcher.startPrefetching(with: requests)
    }

    /// Get cached image if available
    /// - Parameter url: Image URL
    /// - Returns: Cached image or nil
    func cachedImage(for url: URL) -> UIImage? {
        let request = ImageRequest(url: url)
        return pipeline.cache[request]?.image
    }

    /// Clear all cached images
    func clearCache() {
        pipeline.cache.removeAll()
        if let dataCache = pipeline.configuration.dataCache as? DataCache {
            dataCache.removeAll()
        }
    }

    /// Get current cache memory usage
    var cacheMemoryUsage: UInt64 {
        if let cache = pipeline.configuration.imageCache as? ImageCache {
            return UInt64(cache.totalCost)
        }
        return 0
    }

    // MARK: - Memory Management

    @objc private func handleMemoryWarning() {
        let purgedMemory = cacheMemoryUsage
        if let cache = pipeline.configuration.imageCache as? ImageCache {
            cache.removeAll()
        }
        #if DEBUG
        print("ImageCacheManager: Purged \(purgedMemory / 1_000_000) MB due to memory warning")
        #endif
    }
}

// MARK: - UIImageView Extension

extension UIImageView {

    /// Load image with Nuke pipeline
    /// - Parameters:
    ///   - url: Image URL
    ///   - placeholder: Placeholder image
    @MainActor
    func loadImage(from url: URL?, placeholder: UIImage? = nil) {
        guard let url = url else {
            self.image = placeholder
            return
        }

        let request = ImageRequest(url: url)
        NukeExtensions.loadImage(
            with: request,
            options: ImageLoadingOptions(
                placeholder: placeholder,
                transition: .fadeIn(duration: 0.3),
                failureImage: placeholder
            ),
            into: self,
            completion: { result in
                if case .failure(let error) = result {
                    _ = error
                    #if DEBUG
                    print("Failed to load image: \(error.localizedDescription)")
                    #endif
                }
            }
        )
    }
}
