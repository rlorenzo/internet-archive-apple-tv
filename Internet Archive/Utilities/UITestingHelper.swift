//
//  UITestingHelper.swift
//  Internet Archive
//
//  Helper for UI testing with mock data support
//

import Foundation

/// Helper class to detect UI testing mode and provide mock data
@MainActor
final class UITestingHelper {

    // MARK: - Singleton

    static let shared = UITestingHelper()

    // MARK: - Properties

    /// Check if running in UI testing mode
    var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    /// Check if should use mock data
    var useMockData: Bool {
        ProcessInfo.processInfo.environment["USE_MOCK_DATA"] == "true" || isUITesting
    }

    // MARK: - Mock Data

    /// Mock search response for UI tests
    var mockSearchResponse: SearchResponse {
        let docs = (0..<20).map { index in
            SearchResult(
                identifier: "mock_item_\(index)",
                title: "Mock Item \(index)",
                mediatype: index.isMultiple(of: 2) ? "movies" : "audio",
                creator: "Test Creator \(index)",
                description: "This is a mock item for UI testing purposes.",
                date: "2025-01-\(String(format: "%02d", index + 1))",
                year: "2025",
                downloads: 1000 - index * 10
            )
        }

        return SearchResponse(
            response: SearchResponse.SearchResults(numFound: docs.count, start: 0, docs: docs)
        )
    }

    /// Mock collection response for UI tests
    func mockCollectionResponse(collection: String) -> (collection: String, results: [SearchResult]) {
        let docs = (0..<15).map { index in
            SearchResult(
                identifier: "\(collection)_item_\(index)",
                title: "\(collection.capitalized) Item \(index)",
                mediatype: collection == "etree" ? "etree" : "movies",
                creator: "Artist \(index)",
                description: "Mock \(collection) content for testing.",
                date: "2024-\(String(format: "%02d", (index % 12) + 1))-15",
                year: "2024",
                downloads: 500 + index * 20
            )
        }

        return (collection, docs)
    }

    /// Mock metadata response for UI tests
    func mockMetadataResponse(identifier: String) -> ItemMetadataResponse {
        let files = [
            FileInfo(
                name: "video.mp4",
                source: "original",
                format: "MPEG4",
                size: "1234567890",
                length: "3600"
            ),
            FileInfo(
                name: "audio.mp3",
                source: "derivative",
                format: "MP3",
                size: "12345678",
                length: "180"
            )
        ]

        let metadata = ItemMetadata(
            identifier: identifier,
            title: "Mock Item: \(identifier)",
            mediatype: "movies",
            creator: "Test Creator",
            description: "This is a mock item for UI testing. It contains sample media files.",
            date: "2025-01-15",
            year: "2025",
            collection: .array(["test_collection"])
        )

        return ItemMetadataResponse(
            files: files,
            metadata: metadata
        )
    }

    /// Mock favorites response for UI tests
    func mockFavoritesResponse(username: String) -> FavoritesResponse {
        let members = (0..<10).map { index in
            FavoriteItem(
                identifier: "favorite_\(index)",
                mediatype: index.isMultiple(of: 2) ? "movies" : "audio",
                title: "Favorite Item \(index)"
            )
        }

        return FavoritesResponse(members: members)
    }

    // MARK: - Initialization

    private init() {}
}
