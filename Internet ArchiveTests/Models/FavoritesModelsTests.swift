//
//  FavoritesModelsTests.swift
//  Internet ArchiveTests
//
//  Unit tests for favorites data models
//

import XCTest
@testable import Internet_Archive

final class FavoritesModelsTests: XCTestCase {

    // MARK: - FavoritesResponse Tests

    func testFavoritesResponseDecoding() throws {
        let json = """
        {
            "created": 1704067200,
            "d1": "ia123456.us.archive.org",
            "d2": "ia234567.us.archive.org",
            "dir": "/1/items/fav-testuser",
            "files_count": 3,
            "item_size": 5000,
            "server": "ia123456.us.archive.org",
            "uniq": 12345,
            "workable_servers": ["ia123456.us.archive.org"],
            "metadata": {
                "identifier": "fav-testuser",
                "mediatype": "account",
                "title": "testuser's favorites",
                "description": "Favorites collection",
                "subject": "favorites"
            },
            "members": [
                {
                    "identifier": "test_item_001",
                    "mediatype": "movies",
                    "title": "Test Movie"
                },
                {
                    "identifier": "test_item_002",
                    "mediatype": "audio",
                    "title": "Test Audio"
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(FavoritesResponse.self, from: data)

        XCTAssertEqual(response.created, 1704067200)
        XCTAssertEqual(response.d1, "ia123456.us.archive.org")
        XCTAssertEqual(response.dir, "/1/items/fav-testuser")
        XCTAssertEqual(response.filesCount, 3)
        XCTAssertEqual(response.itemSize, 5000)
        XCTAssertEqual(response.server, "ia123456.us.archive.org")
        XCTAssertEqual(response.workableServers?.count, 1)
        XCTAssertEqual(response.members?.count, 2)
    }

    func testFavoritesResponseMemberwiseInit() {
        let favorite = FavoriteItem(identifier: "test", mediatype: "movies", title: "Test")
        let response = FavoritesResponse(
            created: 1234567890,
            members: [favorite]
        )

        XCTAssertEqual(response.created, 1234567890)
        XCTAssertEqual(response.members?.count, 1)
        XCTAssertEqual(response.members?.first?.identifier, "test")
    }

    func testFavoritesResponseWithEmptyMembers() throws {
        let json = """
        {
            "members": []
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(FavoritesResponse.self, from: data)

        XCTAssertNotNil(response.members)
        XCTAssertEqual(response.members?.count, 0)
    }

    func testFavoritesResponseWithNilMembers() throws {
        let json = """
        {
            "created": 1234567890
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(FavoritesResponse.self, from: data)

        XCTAssertNil(response.members)
    }

    // MARK: - FavoriteMetadata Tests

    func testFavoriteMetadataDecoding() throws {
        let json = """
        {
            "identifier": "fav-username",
            "mediatype": "account",
            "title": "username's favorites",
            "description": "User favorites collection",
            "subject": "favorites"
        }
        """

        let data = json.data(using: .utf8)!
        let metadata = try JSONDecoder().decode(FavoriteMetadata.self, from: data)

        XCTAssertEqual(metadata.identifier, "fav-username")
        XCTAssertEqual(metadata.mediatype, "account")
        XCTAssertEqual(metadata.title, "username's favorites")
        XCTAssertEqual(metadata.description, "User favorites collection")
        XCTAssertEqual(metadata.subject, "favorites")
    }

    // MARK: - FavoriteItem Tests

    func testFavoriteItemDecoding() throws {
        let json = """
        {
            "identifier": "test_item_001",
            "mediatype": "movies",
            "title": "Test Movie"
        }
        """

        let data = json.data(using: .utf8)!
        let item = try JSONDecoder().decode(FavoriteItem.self, from: data)

        XCTAssertEqual(item.identifier, "test_item_001")
        XCTAssertEqual(item.mediatype, "movies")
        XCTAssertEqual(item.title, "Test Movie")
    }

    func testFavoriteItemMemberwiseInit() {
        let item = FavoriteItem(
            identifier: "fav_001",
            mediatype: "audio",
            title: "Test Audio"
        )

        XCTAssertEqual(item.identifier, "fav_001")
        XCTAssertEqual(item.mediatype, "audio")
        XCTAssertEqual(item.title, "Test Audio")
    }

    func testFavoriteItemWithOptionalFields() throws {
        let json = """
        {
            "identifier": "test_item_001"
        }
        """

        let data = json.data(using: .utf8)!
        let item = try JSONDecoder().decode(FavoriteItem.self, from: data)

        XCTAssertEqual(item.identifier, "test_item_001")
        XCTAssertNil(item.mediatype)
        XCTAssertNil(item.title)
    }

    func testFavoriteItemToDictionary() {
        let item = TestFixtures.favoriteItem
        let dict = item.toDictionary()

        XCTAssertEqual(dict["identifier"] as? String, "test_favorite_001")
        XCTAssertEqual(dict["mediatype"] as? String, "movies")
        XCTAssertEqual(dict["title"] as? String, "Test Favorite")
    }

    func testFavoriteItemToDictionaryOmitsNilValues() {
        let item = FavoriteItem(identifier: "minimal")
        let dict = item.toDictionary()

        XCTAssertEqual(dict["identifier"] as? String, "minimal")
        XCTAssertNil(dict["mediatype"])
        XCTAssertNil(dict["title"])
    }

    // MARK: - Integration Test with TestFixtures

    func testFavoritesResponseFromFixtures() {
        let response = TestFixtures.favoritesResponse

        XCTAssertNotNil(response.members)
        XCTAssertEqual(response.members?.count, 1)
        XCTAssertEqual(response.members?.first?.identifier, "test_favorite_001")
        XCTAssertEqual(response.members?.first?.mediatype, "movies")
    }
}
