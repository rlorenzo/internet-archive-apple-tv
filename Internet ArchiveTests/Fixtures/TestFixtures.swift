//
//  TestFixtures.swift
//  Internet ArchiveTests
//
//  Test fixtures for API responses
//

import Foundation
@testable import Internet_Archive

enum TestFixtures {

    // MARK: - Search Results

    static let movieSearchResult = SearchResult(
        identifier: "test_movie_001",
        title: "Test Movie",
        mediatype: "movies",
        creator: "Test Creator",
        description: "A test movie for unit testing",
        date: "2025-01-01",
        year: "2025",
        downloads: 1000,
        subject: ["test", "movies"],
        collection: ["test_collection"]
    )

    static let audioSearchResult = SearchResult(
        identifier: "test_audio_001",
        title: "Test Audio",
        mediatype: "audio",
        creator: "Test Artist",
        description: "A test audio file",
        date: "2025-01-01",
        year: "2025",
        downloads: 500,
        subject: ["test", "music"],
        collection: ["test_collection"]
    )

    static let searchResponse = SearchResponse(
        responseHeader: SearchResponse.ResponseHeader(status: 0, QTime: 10),
        response: SearchResponse.SearchResults(
            numFound: 2,
            start: 0,
            docs: [movieSearchResult, audioSearchResult]
        )
    )

    // MARK: - Authentication

    static let authResponse = AuthResponse(
        success: true,
        version: 1,
        values: AuthResponse.AuthValues(
            email: "test@example.com",
            itemname: "@test_user",
            screenname: "Test User",
            verified: true,
            privs: nil,
            signedin: nil
        ),
        error: nil
    )

    static let successfulAuthResponse = AuthResponse(
        success: true,
        version: 1,
        values: AuthResponse.AuthValues(
            email: "test@example.com",
            itemname: "@test_user",
            screenname: "Test User",
            verified: true,
            privs: nil,
            signedin: nil
        ),
        error: nil
    )

    static let failedAuthResponse = AuthResponse(
        success: false,
        version: 1,
        values: nil,
        error: "Invalid credentials"
    )

    static let accountInfoResponse = AccountInfoResponse(
        success: true,
        version: 1,
        values: AccountInfoResponse.AccountValues(
            email: "test@example.com",
            itemname: "@test_user",
            screenname: "Test User",
            verified: true,
            privs: nil
        ),
        error: nil
    )

    // MARK: - Metadata

    static let fileInfo = FileInfo(
        name: "test_file.mp4",
        source: "original",
        format: "MPEG4",
        size: "1000000"
    )

    static let itemMetadata = ItemMetadata(
        identifier: "test_item_001",
        title: "Test Item",
        mediatype: "movies",
        creator: "Test Creator",
        description: "Test description",
        date: "2025-01-01",
        year: "2025",
        subject: .array(["test"]),
        collection: .array(["test_collection"]),
        publicdate: "2025-01-01T00:00:00Z",
        addeddate: "2025-01-01T00:00:00Z",
        uploader: "test_uploader"
    )

    static let itemMetadataResponse = ItemMetadataResponse(
        files: [fileInfo],
        metadata: itemMetadata
    )

    static let movieMetadataResponse = ItemMetadataResponse(
        files: [fileInfo],
        metadata: itemMetadata
    )

    // MARK: - Metadata Factories

    /// Creates an ItemMetadataResponse for video content.
    /// - Parameters:
    ///   - identifier: Item identifier
    ///   - title: Video title
    ///   - fileCount: Number of video files to include
    /// - Returns: ItemMetadataResponse configured as video content
    static func makeVideoMetadataResponse(
        identifier: String = "test_video",
        title: String = "Test Video",
        fileCount: Int = 1
    ) -> ItemMetadataResponse {
        let files = (0..<fileCount).map { index in
            FileInfo(
                name: "video_\(index).mp4",
                source: "original",
                format: "MPEG4",
                size: "\(1_000_000 * (index + 1))"
            )
        }

        let metadata = ItemMetadata(
            identifier: identifier,
            title: title,
            mediatype: "movies",
            creator: "Test Video Creator",
            description: "A test video for unit testing",
            date: "2025-01-01",
            year: "2025",
            subject: .array(["test", "video"]),
            collection: .array(["test_collection"]),
            publicdate: "2025-01-01T00:00:00Z",
            addeddate: "2025-01-01T00:00:00Z",
            uploader: "test_uploader"
        )

        return ItemMetadataResponse(files: files, metadata: metadata)
    }

    /// Creates an ItemMetadataResponse for music/audio content.
    /// - Parameters:
    ///   - identifier: Item identifier
    ///   - title: Album/concert title
    ///   - trackCount: Number of audio tracks to include
    /// - Returns: ItemMetadataResponse configured as music content
    static func makeMusicMetadataResponse(
        identifier: String = "test_music",
        title: String = "Test Album",
        trackCount: Int = 3
    ) -> ItemMetadataResponse {
        let files = (0..<trackCount).map { index in
            FileInfo(
                name: "track_\(index + 1).mp3",
                source: "original",
                format: "VBR MP3",
                size: "\(5_000_000 + index * 1_000_000)"
            )
        }

        let metadata = ItemMetadata(
            identifier: identifier,
            title: title,
            mediatype: "etree",
            creator: "Test Band",
            description: "A test concert for unit testing",
            date: "2025-01-01",
            year: "2025",
            subject: .array(["test", "music", "live"]),
            collection: .array(["etree"]),
            publicdate: "2025-01-01T00:00:00Z",
            addeddate: "2025-01-01T00:00:00Z",
            uploader: "test_uploader"
        )

        return ItemMetadataResponse(files: files, metadata: metadata)
    }

    // MARK: - Favorites

    static let favoriteItem = FavoriteItem(
        identifier: "test_favorite_001",
        mediatype: "movies",
        title: "Test Favorite"
    )

    static let favoritesResponse = FavoritesResponse(
        members: [favoriteItem]
    )

    // MARK: - Helper Methods

    static let musicSearchResult = SearchResult(
        identifier: "test_music_001",
        title: "Test Concert",
        mediatype: "etree",
        creator: "Test Band",
        description: "A test concert recording",
        date: "2025-01-01",
        year: "2025",
        downloads: 750,
        subject: ["test", "music"],
        collection: ["etree"]
    )

    static func makeSearchResult(
        identifier: String = "test_001",
        title: String? = "Test Item",
        mediatype: String? = "movies",
        creator: String? = "Test Creator",
        description: String? = "Test description",
        date: String? = "2025-01-01",
        year: String? = "2025",
        downloads: Int? = 100
    ) -> SearchResult {
        SearchResult(
            identifier: identifier,
            title: title,
            mediatype: mediatype,
            creator: creator,
            description: description,
            date: date,
            year: year,
            downloads: downloads,
            subject: ["test"],
            collection: ["test_collection"]
        )
    }

    static func makeSearchResponse(
        numFound: Int? = nil,
        docs: [SearchResult]
    ) -> SearchResponse {
        SearchResponse(
            responseHeader: SearchResponse.ResponseHeader(status: 0, QTime: 10),
            response: SearchResponse.SearchResults(
                numFound: numFound ?? docs.count,
                start: 0,
                docs: docs
            )
        )
    }

    // MARK: - Network Error Factories

    /// Creates a NetworkError for testing error handling code paths.
    /// - Parameter type: The type of error to create
    /// - Returns: A NetworkError instance
    static func makeNetworkError(_ type: NetworkErrorType = .noConnection) -> NetworkError {
        switch type {
        case .noConnection:
            return .noConnection
        case .timeout:
            return .timeout
        case .unauthorized:
            return .unauthorized
        case .invalidCredentials:
            return .invalidCredentials
        case .invalidResponse:
            return .invalidResponse
        case .decodingFailed:
            return .decodingFailed(NSError(domain: "TestError", code: 1, userInfo: nil))
        case .serverError(let code):
            return .serverError(statusCode: code)
        case .resourceNotFound:
            return .resourceNotFound
        case .apiError(let message):
            return .apiError(message: message)
        case .contentFiltered:
            return .contentFiltered
        case .requestFailed:
            return .requestFailed(NSError(domain: "TestError", code: 2, userInfo: nil))
        case .unknown:
            return .unknown(nil)
        }
    }

    /// Types of NetworkError that can be created via the factory.
    enum NetworkErrorType {
        case noConnection
        case timeout
        case unauthorized
        case invalidCredentials
        case invalidResponse
        case decodingFailed
        case serverError(code: Int)
        case resourceNotFound
        case apiError(message: String)
        case contentFiltered
        case requestFailed
        case unknown
    }

    // MARK: - Batch Result Factories

    /// Creates an array of video SearchResults for testing.
    /// - Parameters:
    ///   - count: Number of results to create
    ///   - startIndex: Starting index for unique identifiers
    /// - Returns: Array of SearchResult with mediatype "movies"
    static func makeVideoResults(count: Int, startIndex: Int = 0) -> [SearchResult] {
        (0..<count).map { index in
            makeSearchResult(
                identifier: "video_\(startIndex + index)",
                title: "Video \(startIndex + index)",
                mediatype: "movies",
                creator: "Video Creator \(index)",
                downloads: 1000 - index * 10
            )
        }
    }

    /// Creates an array of music SearchResults for testing.
    /// - Parameters:
    ///   - count: Number of results to create
    ///   - startIndex: Starting index for unique identifiers
    /// - Returns: Array of SearchResult with mediatype "etree" (live music)
    static func makeMusicResults(count: Int, startIndex: Int = 0) -> [SearchResult] {
        (0..<count).map { index in
            makeSearchResult(
                identifier: "music_\(startIndex + index)",
                title: "Concert \(startIndex + index)",
                mediatype: "etree",
                creator: "Band \(index)",
                downloads: 500 - index * 5
            )
        }
    }

    /// Creates an array of audio SearchResults for testing.
    /// - Parameters:
    ///   - count: Number of results to create
    ///   - startIndex: Starting index for unique identifiers
    /// - Returns: Array of SearchResult with mediatype "audio"
    static func makeAudioResults(count: Int, startIndex: Int = 0) -> [SearchResult] {
        (0..<count).map { index in
            makeSearchResult(
                identifier: "audio_\(startIndex + index)",
                title: "Audio Track \(startIndex + index)",
                mediatype: "audio",
                creator: "Audio Creator \(index)",
                downloads: 250 - index * 3
            )
        }
    }

    /// Creates a mixed array of video and music results for testing.
    /// - Parameters:
    ///   - videoCount: Number of video results
    ///   - musicCount: Number of music results
    /// - Returns: Interleaved array of video and music SearchResults
    static func makeMixedResults(videoCount: Int, musicCount: Int) -> [SearchResult] {
        var results: [SearchResult] = []
        let maxCount = max(videoCount, musicCount)

        for index in 0..<maxCount {
            if index < videoCount {
                results.append(makeSearchResult(
                    identifier: "video_\(index)",
                    title: "Video \(index)",
                    mediatype: "movies"
                ))
            }
            if index < musicCount {
                results.append(makeSearchResult(
                    identifier: "music_\(index)",
                    title: "Music \(index)",
                    mediatype: "etree"
                ))
            }
        }

        return results
    }

    // MARK: - PlaybackProgress Factory

    /// Creates a PlaybackProgress for testing continue watching/listening.
    /// - Parameters:
    ///   - identifier: Item identifier
    ///   - progress: Progress percentage (0.0 to 1.0)
    ///   - isAudio: Whether this is audio content
    ///   - title: Display title (defaults based on isAudio)
    ///   - lastWatchedDate: When the item was last watched (defaults to now)
    /// - Returns: PlaybackProgress instance
    static func makePlaybackProgress(
        identifier: String = "progress_item",
        progress: Double = 0.5,
        isAudio: Bool = false,
        title: String? = nil,
        lastWatchedDate: Date = Date()
    ) -> PlaybackProgress {
        let duration: TimeInterval = 3600  // 1 hour
        let currentTime = duration * progress

        return PlaybackProgress(
            itemIdentifier: identifier,
            filename: isAudio ? "track.mp3" : "video.mp4",
            currentTime: currentTime,
            duration: duration,
            lastWatchedDate: lastWatchedDate,
            title: title ?? (isAudio ? "Test Album" : "Test Video"),
            mediaType: isAudio ? "etree" : "movies",
            imageURL: nil
        )
    }

    // MARK: - Favorite Item Factory

    /// Creates a FavoriteItem for testing favorites functionality.
    /// - Parameters:
    ///   - identifier: Item identifier
    ///   - title: Display title
    ///   - mediatype: Media type string
    /// - Returns: FavoriteItem instance
    static func makeFavoriteItem(
        identifier: String = "fav-item-1",
        title: String = "Favorite Item",
        mediatype: String = "movies"
    ) -> FavoriteItem {
        FavoriteItem(
            identifier: identifier,
            mediatype: mediatype,
            title: title
        )
    }

    /// Creates a FavoritesResponse with the given items.
    /// - Parameter items: Favorite items to include (defaults to a single test item)
    /// - Returns: FavoritesResponse instance
    static func makeFavoritesResponse(
        items: [FavoriteItem]? = nil
    ) -> FavoritesResponse {
        FavoritesResponse(
            members: items ?? [makeFavoriteItem()]
        )
    }

    // MARK: - Batch Favorite Factories

    /// Creates an array of FavoriteItems for testing.
    /// - Parameters:
    ///   - count: Number of items to create
    ///   - mediatype: Media type for all items
    /// - Returns: Array of FavoriteItem with unique identifiers
    static func makeFavoriteItems(
        count: Int,
        mediatype: String = "movies"
    ) -> [FavoriteItem] {
        (0..<count).map { index in
            makeFavoriteItem(
                identifier: "fav-\(index)",
                title: "Favorite \(index)",
                mediatype: mediatype
            )
        }
    }

    // MARK: - PlaybackProgress Batch Factory

    /// Creates an array of PlaybackProgress items for testing continue watching/listening.
    /// - Parameters:
    ///   - count: Number of items to create
    ///   - isAudio: Whether these are audio items
    /// - Returns: Array of PlaybackProgress with unique identifiers
    static func makePlaybackProgressItems(
        count: Int,
        isAudio: Bool = false
    ) -> [PlaybackProgress] {
        (0..<count).map { index in
            makePlaybackProgress(
                identifier: "\(isAudio ? "audio" : "video")_\(index)",
                progress: Double(index + 1) / Double(count + 1),
                isAudio: isAudio,
                title: isAudio ? "Album \(index)" : "Video \(index)",
                lastWatchedDate: Date().addingTimeInterval(Double(-index * 3600))
            )
        }
    }
}
