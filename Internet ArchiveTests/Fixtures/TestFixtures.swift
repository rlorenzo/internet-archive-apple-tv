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
}
