//
//  NukeIntegrationTests.swift
//  Internet ArchiveTests
//
//  Tests for the Nuke image loading pipeline integration
//

import XCTest
import Nuke
import NukeExtensions
@testable import Internet_Archive

@MainActor
final class NukeIntegrationTests: XCTestCase {

    // MARK: - Pipeline Configuration Tests

    func testSharedPipeline_matchesImageCacheManager() {
        // ImageCacheManager sets itself as the shared pipeline
        let managerPipeline = ImageCacheManager.shared.pipeline
        XCTAssertTrue(ImagePipeline.shared === managerPipeline)
    }

    func testPipeline_hasDataCache() {
        let pipeline = ImageCacheManager.shared.pipeline
        XCTAssertNotNil(pipeline.configuration.dataCache)
    }

    func testPipeline_hasImageCache() {
        let pipeline = ImageCacheManager.shared.pipeline
        XCTAssertNotNil(pipeline.configuration.imageCache)
    }

    func testPipeline_dataCachePolicy_isAutomatic() {
        let pipeline = ImageCacheManager.shared.pipeline
        XCTAssertEqual(pipeline.configuration.dataCachePolicy, .automatic)
    }

    // MARK: - Cache Subscript Tests

    func testCacheSubscript_returnsNilForUncached() {
        let url = URL(string: "https://archive.org/services/img/nuke_test_uncached")!
        let request = ImageRequest(url: url)
        let cached = ImageCacheManager.shared.pipeline.cache[request]
        XCTAssertNil(cached)
    }

    func testCacheSubscript_matchesCachedImageMethod() {
        let url = URL(string: "https://archive.org/services/img/nuke_test_consistency")!
        let viaMethod = ImageCacheManager.shared.cachedImage(for: url)
        let request = ImageRequest(url: url)
        let viaSubscript = ImageCacheManager.shared.pipeline.cache[request]?.image
        // Both should be nil for uncached URL
        XCTAssertNil(viaMethod)
        XCTAssertNil(viaSubscript)
    }

    // MARK: - ImageRequest Tests

    func testImageRequest_lowPriority() {
        let url = URL(string: "https://archive.org/services/img/priority_test")!
        let request = ImageRequest(url: url, priority: .low)
        XCTAssertEqual(request.priority, .low)
    }

    func testImageRequest_normalPriority() {
        let url = URL(string: "https://archive.org/services/img/priority_test")!
        let request = ImageRequest(url: url)
        XCTAssertEqual(request.priority, .normal)
    }

    // MARK: - UIImageView Nuke Extension Tests

    func testLoadImage_setsPlaceholder() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let placeholder = UIImage(systemName: "film")!
        let url = URL(string: "https://archive.org/services/img/nuke_placeholder_test")!

        imageView.loadImage(from: url, placeholder: placeholder)

        // Placeholder should be set synchronously before the async load completes.
        XCTAssertEqual(imageView.image, placeholder)
    }

    func testLoadImage_withNilURL_keepsPlaceholder() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let placeholder = UIImage(systemName: "film")!

        imageView.loadImage(from: nil, placeholder: placeholder)

        XCTAssertEqual(imageView.image, placeholder)
    }

    func testLoadImage_withNilURL_andNilPlaceholder_setsNil() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        imageView.loadImage(from: nil, placeholder: nil)

        XCTAssertNil(imageView.image)
    }

    func testCancelRequest_doesNotCrash() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let url = URL(string: "https://archive.org/services/img/cancel_test")!

        imageView.loadImage(from: url)
        NukeExtensions.cancelRequest(for: imageView)

        XCTAssertNotNil(imageView)
    }

    func testCancelRequest_onUnloadedImageView() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        // Cancel without ever loading — should not crash
        NukeExtensions.cancelRequest(for: imageView)
        XCTAssertNotNil(imageView)
    }

    // MARK: - Cell Image Loading Tests

    func testAlbumArtView_setImageURL_thenNil() {
        let view = AlbumArtView(size: 300)
        let url = URL(string: "https://archive.org/services/img/album_test")!

        view.setImage(url: url)
        view.setImage(url: nil)

        XCTAssertEqual(view.accessibilityLabel, "Album artwork placeholder")
    }

    // MARK: - Prefetch Tests

    func testPrefetchImages_createsNukePrefetcher() {
        let urls = [
            URL(string: "https://archive.org/services/img/prefetch_nuke_1")!,
            URL(string: "https://archive.org/services/img/prefetch_nuke_2")!
        ]

        // Should not crash — uses Nuke's ImagePrefetcher internally
        ImageCacheManager.shared.prefetchImages(for: urls)
        XCTAssertNotNil(ImageCacheManager.shared)
    }

    func testPrefetchImages_emptyArray_earlyReturns() {
        // Empty array should early-return and not invoke the long-lived prefetcher.
        ImageCacheManager.shared.prefetchImages(for: [])
        XCTAssertNotNil(ImageCacheManager.shared)
    }

    // MARK: - Clear Cache Tests

    func testClearCache_removesMemoryAndDiskCache() {
        ImageCacheManager.shared.clearCache()

        let url = URL(string: "https://archive.org/services/img/clear_test")!
        let cached = ImageCacheManager.shared.cachedImage(for: url)
        XCTAssertNil(cached)

        let usage = ImageCacheManager.shared.cacheMemoryUsage
        XCTAssertEqual(usage, 0)
    }

    // MARK: - Memory Cache Size Tests

    func testImageCache_costLimit_isDeviceAware() {
        if let cache = ImageCacheManager.shared.pipeline.configuration.imageCache as? ImageCache {
            let costLimit = cache.costLimit
            // Should be between 50MB and 150MB
            XCTAssertGreaterThanOrEqual(costLimit, 50_000_000)
            XCTAssertLessThanOrEqual(costLimit, 150_000_000)
        } else {
            XCTFail("Expected ImageCache as image cache")
        }
    }

    // MARK: - Data Cache Tests

    func testDataCache_sizeLimit_is500MB() {
        if let dataCache = ImageCacheManager.shared.pipeline.configuration.dataCache as? DataCache {
            XCTAssertEqual(dataCache.sizeLimit, 500_000_000)
        } else {
            XCTFail("Expected DataCache as data cache")
        }
    }
}
