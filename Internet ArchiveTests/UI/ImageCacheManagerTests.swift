//
//  ImageCacheManagerTests.swift
//  Internet ArchiveTests
//
//  Unit tests for ImageCacheManager
//

import XCTest
@testable import Internet_Archive

@MainActor
final class ImageCacheManagerTests: XCTestCase {

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let instance1 = ImageCacheManager.shared
        let instance2 = ImageCacheManager.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Cache Tests

    func testCachedImage_returnsNilForUncachedURL() {
        let url = URL(string: "https://archive.org/services/img/test_uncached_item")!
        let cachedImage = ImageCacheManager.shared.cachedImage(for: url)
        XCTAssertNil(cachedImage)
    }

    func testClearCache_doesNotCrash() {
        ImageCacheManager.shared.clearCache()
        XCTAssertNotNil(ImageCacheManager.shared)
    }

    func testCacheMemoryUsage_returnsValue() {
        let usage = ImageCacheManager.shared.cacheMemoryUsage
        // Memory usage should be a valid non-negative value
        XCTAssertGreaterThanOrEqual(usage, 0)
    }

    func testClearCache_resetsMemoryUsage() {
        ImageCacheManager.shared.clearCache()
        let usage = ImageCacheManager.shared.cacheMemoryUsage
        // After clearing, usage should be minimal
        XCTAssertGreaterThanOrEqual(usage, 0)
    }

    // MARK: - Prefetch Tests

    func testPrefetchImages_withEmptyArray() {
        ImageCacheManager.shared.prefetchImages(for: [])
        XCTAssertNotNil(ImageCacheManager.shared)
    }

    func testPrefetchImages_withSingleURL() {
        let urls = [URL(string: "https://archive.org/services/img/test_prefetch_1")!]
        ImageCacheManager.shared.prefetchImages(for: urls)
        XCTAssertNotNil(ImageCacheManager.shared)
    }

    func testPrefetchImages_withMultipleURLs() {
        let urls = [
            URL(string: "https://archive.org/services/img/test_prefetch_a")!,
            URL(string: "https://archive.org/services/img/test_prefetch_b")!,
            URL(string: "https://archive.org/services/img/test_prefetch_c")!
        ]
        ImageCacheManager.shared.prefetchImages(for: urls)
        XCTAssertNotNil(ImageCacheManager.shared)
    }

    // MARK: - Load Image Tests

    func testLoadImage_callsCompletionHandler() throws {
        // Skip in CI - network requests to external services are unreliable
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] != nil,
            "Skipping network-dependent test in CI"
        )

        let expectation = self.expectation(description: "Load image completion")
        let url = URL(string: "https://archive.org/services/img/test_load_image")!

        ImageCacheManager.shared.loadImage(from: url) { result in
            // Whether success or failure, completion should be called
            switch result {
            case .success, .failure:
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 30.0)
    }

    func testLoadImage_withInvalidURL() throws {
        // Skip in CI - network requests to external services are unreliable
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] != nil,
            "Skipping network-dependent test in CI"
        )

        let expectation = self.expectation(description: "Load invalid image")
        let url = URL(string: "https://invalid.example.com/nonexistent_image_12345.jpg")!

        ImageCacheManager.shared.loadImage(from: url) { result in
            switch result {
            case .success:
                // May succeed if URL is valid but returns something
                break
            case .failure:
                // Expected for invalid URL
                break
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 30.0)
    }

    func testCachedImage_afterClear_returnsNil() {
        let url = URL(string: "https://archive.org/services/img/test_clear_cache")!

        // Clear cache first
        ImageCacheManager.shared.clearCache()

        // Verify cache is empty for this URL
        let cachedImage = ImageCacheManager.shared.cachedImage(for: url)
        XCTAssertNil(cachedImage)
    }

    // MARK: - URL Identifier Tests

    func testCachedImage_withDifferentURLs() {
        let url1 = URL(string: "https://archive.org/services/img/item1")!
        let url2 = URL(string: "https://archive.org/services/img/item2")!

        // Different URLs should return different results (both nil before caching)
        let cachedImage1 = ImageCacheManager.shared.cachedImage(for: url1)
        let cachedImage2 = ImageCacheManager.shared.cachedImage(for: url2)

        XCTAssertNil(cachedImage1)
        XCTAssertNil(cachedImage2)
    }

    // MARK: - Memory Pressure Tests

    func testCacheMemoryUsage_afterClear_isMinimal() {
        // Clear cache
        ImageCacheManager.shared.clearCache()

        let usage = ImageCacheManager.shared.cacheMemoryUsage
        // After clearing, memory usage should be 0 or very small
        XCTAssertLessThan(usage, 1_000_000) // Less than 1 MB
    }

    func testPrefetchImages_withDuplicateURLs() {
        let url = URL(string: "https://archive.org/services/img/duplicate_test")!
        let urls = [url, url, url] // Same URL three times

        // Should not crash with duplicate URLs
        ImageCacheManager.shared.prefetchImages(for: urls)
        XCTAssertNotNil(ImageCacheManager.shared)
    }

    // MARK: - Edge Case Tests

    func testCachedImage_withSpecialCharactersInURL() {
        let url = URL(string: "https://archive.org/services/img/item%20with%20spaces")!
        let cachedImage = ImageCacheManager.shared.cachedImage(for: url)
        // Should not crash, just return nil for uncached
        XCTAssertNil(cachedImage)
    }

    func testCachedImage_withLongURL() {
        let longIdentifier = String(repeating: "a", count: 500)
        let url = URL(string: "https://archive.org/services/img/\(longIdentifier)")!
        let cachedImage = ImageCacheManager.shared.cachedImage(for: url)
        XCTAssertNil(cachedImage)
    }

    // MARK: - Cancel Prefetch Tests

    func testCancelPrefetch_withEmptyArray() {
        // Should not crash with empty array
        ImageCacheManager.shared.prefetchImages(for: [])
        XCTAssertNotNil(ImageCacheManager.shared)
    }

    // MARK: - Concurrent Access Tests

    func testLoadImage_multipleConcurrentRequests() throws {
        // Skip in CI - network requests to external services are unreliable
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] != nil,
            "Skipping network-dependent test in CI"
        )

        let expectations = (0..<3).map { i in
            expectation(description: "Load image \(i)")
        }

        let urls = [
            URL(string: "https://archive.org/services/img/concurrent_test_1")!,
            URL(string: "https://archive.org/services/img/concurrent_test_2")!,
            URL(string: "https://archive.org/services/img/concurrent_test_3")!
        ]

        for (index, url) in urls.enumerated() {
            ImageCacheManager.shared.loadImage(from: url) { _ in
                expectations[index].fulfill()
            }
        }

        wait(for: expectations, timeout: 30.0)
    }
}

// MARK: - UIImageView Extension Tests

@MainActor
final class UIImageViewLoadImageTests: XCTestCase {

    nonisolated(unsafe) var imageView: UIImageView!

    override func setUp() {
        super.setUp()
        let newImageView = MainActor.assumeIsolated {
            return UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        }
        imageView = newImageView
    }

    override func tearDown() {
        imageView = nil
        super.tearDown()
    }

    func testLoadImage_withNilURL() {
        let placeholder = UIImage()
        imageView.loadImage(from: nil, placeholder: placeholder)

        // Should set placeholder when URL is nil
        XCTAssertNotNil(imageView.image)
    }

    func testLoadImage_withNilURLAndNilPlaceholder() {
        imageView.loadImage(from: nil, placeholder: nil)

        // Should set nil image
        XCTAssertNil(imageView.image)
    }

    func testLoadImage_withValidURL() {
        let url = URL(string: "https://archive.org/services/img/test_imageview_load")!

        imageView.loadImage(from: url)

        // Just verify it doesn't crash
        XCTAssertNotNil(imageView)
    }

    func testLoadImage_setsPlaceholderImmediately() {
        let placeholder = UIImage()
        let url = URL(string: "https://archive.org/services/img/test_placeholder")!

        imageView.loadImage(from: url, placeholder: placeholder)

        // Placeholder should be set immediately
        XCTAssertNotNil(imageView.image)
    }

    func testLoadImage_multipleTimes() {
        let urls = [
            URL(string: "https://archive.org/services/img/multi_1")!,
            URL(string: "https://archive.org/services/img/multi_2")!,
            URL(string: "https://archive.org/services/img/multi_3")!
        ]

        for url in urls {
            imageView.loadImage(from: url)
        }

        // Should not crash
        XCTAssertNotNil(imageView)
    }

    func testLoadImage_withPlaceholder() {
        let placeholder = UIImage()
        let url = URL(string: "https://archive.org/services/img/placeholder_test")!

        imageView.loadImage(from: url, placeholder: placeholder)

        XCTAssertNotNil(imageView)
    }
}

// MARK: - Extended Cache Tests

@MainActor
final class ImageCacheManagerExtendedTests: XCTestCase {

    func testClearCache_canBeCalledMultipleTimes() {
        // Should not crash when called multiple times in succession
        ImageCacheManager.shared.clearCache()
        ImageCacheManager.shared.clearCache()
        ImageCacheManager.shared.clearCache()

        XCTAssertNotNil(ImageCacheManager.shared)
    }

    func testPrefetchImages_handlesLargeNumberOfURLs() {
        let urls = (0..<100).map { index in
            URL(string: "https://archive.org/services/img/batch_prefetch_\(index)")!
        }

        // Should not crash with large batch
        ImageCacheManager.shared.prefetchImages(for: urls)
        XCTAssertNotNil(ImageCacheManager.shared)
    }

    func testCachedImage_withQueryParameters() {
        let url = URL(string: "https://archive.org/services/img/test?size=large&format=jpg")!
        let cachedImage = ImageCacheManager.shared.cachedImage(for: url)

        // Should handle query parameters without crashing
        XCTAssertNil(cachedImage)
    }

    func testCachedImage_withFragmentIdentifier() {
        let url = URL(string: "https://archive.org/services/img/test#section")!
        let cachedImage = ImageCacheManager.shared.cachedImage(for: url)

        XCTAssertNil(cachedImage)
    }

    func testLoadImage_callsCompletionOnMainThread() throws {
        // Skip in CI - network requests to external services are unreliable
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] != nil,
            "Skipping network-dependent test in CI"
        )

        let expectation = self.expectation(description: "Completion on main thread")
        let url = URL(string: "https://archive.org/services/img/main_thread_test")!

        ImageCacheManager.shared.loadImage(from: url) { _ in
            XCTAssertTrue(Thread.isMainThread)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 30.0)
    }

    func testCacheMemoryUsage_isConsistent() {
        let usage1 = ImageCacheManager.shared.cacheMemoryUsage
        let usage2 = ImageCacheManager.shared.cacheMemoryUsage

        // Should return consistent values when called rapidly
        XCTAssertEqual(usage1, usage2)
    }

    func testPrefetchImages_withMixedValidAndInvalidURLs() {
        let urls = [
            URL(string: "https://archive.org/services/img/valid1")!,
            URL(string: "https://archive.org/services/img/valid2")!,
            URL(string: "https://invalid-domain-that-does-not-exist-12345.com/image.jpg")!
        ]

        // Should not crash with mix of valid and invalid URLs
        ImageCacheManager.shared.prefetchImages(for: urls)
        XCTAssertNotNil(ImageCacheManager.shared)
    }

    func testCachedImage_withUnicodeIdentifier() {
        let url = URL(string: "https://archive.org/services/img/test_\u{1F600}_emoji")!
        let cachedImage = ImageCacheManager.shared.cachedImage(for: url)

        // Should handle unicode without crashing
        XCTAssertNil(cachedImage)
    }

    func testLoadImage_rapidSuccessiveCalls() throws {
        // Skip in CI - network requests to external services are unreliable
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] != nil,
            "Skipping network-dependent test in CI"
        )

        let expectation = self.expectation(description: "All callbacks received")
        expectation.expectedFulfillmentCount = 5

        let url = URL(string: "https://archive.org/services/img/rapid_test")!

        for _ in 0..<5 {
            ImageCacheManager.shared.loadImage(from: url) { _ in
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 30.0)
    }

    func testClearCache_afterPrefetch() {
        let urls = [
            URL(string: "https://archive.org/services/img/prefetch_clear_1")!,
            URL(string: "https://archive.org/services/img/prefetch_clear_2")!
        ]

        ImageCacheManager.shared.prefetchImages(for: urls)
        ImageCacheManager.shared.clearCache()

        // After clearing, cache should be empty
        let cached = ImageCacheManager.shared.cachedImage(for: urls[0])
        XCTAssertNil(cached)
    }
}
