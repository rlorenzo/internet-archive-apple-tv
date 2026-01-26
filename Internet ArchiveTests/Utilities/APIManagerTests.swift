//
//  APIManagerTests.swift
//  Internet ArchiveTests
//
//  Unit tests for APIManager
//

import XCTest
import Alamofire
@testable import Internet_Archive

@MainActor
final class APIManagerTests: XCTestCase {

    // MARK: - Singleton Tests

    func testSharedManager_exists() {
        let manager = APIManager.sharedManager
        XCTAssertNotNil(manager)
    }

    func testSharedManager_isSingleton() {
        let manager1 = APIManager.sharedManager
        let manager2 = APIManager.sharedManager
        XCTAssertTrue(manager1 === manager2)
    }

    // MARK: - Base URL Tests

    func testBaseURL_isCorrect() {
        let manager = APIManager.sharedManager
        XCTAssertEqual(manager.baseURL, "https://archive.org/")
    }

    func testBaseURL_hasTrailingSlash() {
        let manager = APIManager.sharedManager
        XCTAssertTrue(manager.baseURL.hasSuffix("/"))
    }

    // MARK: - API Endpoint Tests

    func testApiCreate_endpoint() {
        let manager = APIManager.sharedManager
        XCTAssertEqual(manager.apiCreate, "services/xauthn/?op=create")
    }

    func testApiLogin_endpoint() {
        let manager = APIManager.sharedManager
        XCTAssertEqual(manager.apiLogin, "services/xauthn/?op=authenticate")
    }

    func testApiInfo_endpoint() {
        let manager = APIManager.sharedManager
        XCTAssertEqual(manager.apiInfo, "services/xauthn/?op=info")
    }

    func testApiMetadata_endpoint() {
        let manager = APIManager.sharedManager
        XCTAssertEqual(manager.apiMetadata, "metadata/")
    }

    func testApiWebLogin_endpoint() {
        let manager = APIManager.sharedManager
        XCTAssertEqual(manager.apiWebLogin, "account/login.php")
    }

    func testApiSaveFavorite_endpoint() {
        let manager = APIManager.sharedManager
        XCTAssertEqual(manager.apiSaveFavorite, "bookmarks.php?add_bookmark=1")
    }

    func testApiGetFavorite_endpoint() {
        let manager = APIManager.sharedManager
        XCTAssertEqual(manager.apiGetFavorite, "metadata/fav-")
    }

    // MARK: - Full URL Construction Tests

    func testFullLoginURL() {
        let manager = APIManager.sharedManager
        let fullURL = "\(manager.baseURL)\(manager.apiLogin)"
        XCTAssertEqual(fullURL, "https://archive.org/services/xauthn/?op=authenticate")
    }

    func testFullCreateURL() {
        let manager = APIManager.sharedManager
        let fullURL = "\(manager.baseURL)\(manager.apiCreate)"
        XCTAssertEqual(fullURL, "https://archive.org/services/xauthn/?op=create")
    }

    func testFullMetadataURL_withIdentifier() {
        let manager = APIManager.sharedManager
        let identifier = "test_item_123"
        let fullURL = "\(manager.baseURL)\(manager.apiMetadata)\(identifier)"
        XCTAssertEqual(fullURL, "https://archive.org/metadata/test_item_123")
    }

    func testFullFavoriteURL_withUsername() {
        let manager = APIManager.sharedManager
        let username = "testuser"
        let fullURL = "\(manager.baseURL)\(manager.apiGetFavorite)\(username.lowercased())"
        XCTAssertEqual(fullURL, "https://archive.org/metadata/fav-testuser")
    }

    // MARK: - Headers Tests

    func testHeaders_containsUserAgent() {
        let manager = APIManager.sharedManager
        XCTAssertNotNil(manager.headers["User-Agent"])
    }

    func testHeaders_containsWaybackExtensionVersion() {
        let manager = APIManager.sharedManager
        XCTAssertNotNil(manager.headers["Wayback-Extension-Version"])
    }

    func testHeaders_userAgentContainsWayback() {
        let manager = APIManager.sharedManager
        let userAgent = manager.headers["User-Agent"]
        XCTAssertTrue(userAgent?.contains("Wayback_Machine_iOS") ?? false)
    }

    // MARK: - Network Service Tests

    func testNetworkService_returnsService() {
        let service = APIManager.networkService
        XCTAssertNotNil(service)
    }

    func testNetworkService_conformsToProtocol() {
        let service: Any = APIManager.networkService
        XCTAssertTrue(service is NetworkServiceProtocol)
    }

    // MARK: - FavoriteItemParams Tests

    func testFavoriteItemParams_initialization() {
        let params = FavoriteItemParams(
            identifier: "test_id",
            mediatype: "movies",
            title: "Test Title"
        )

        XCTAssertEqual(params.identifier, "test_id")
        XCTAssertEqual(params.mediatype, "movies")
        XCTAssertEqual(params.title, "Test Title")
    }

    func testFavoriteItemParams_withEmptyValues() {
        let params = FavoriteItemParams(
            identifier: "",
            mediatype: "",
            title: ""
        )

        XCTAssertEqual(params.identifier, "")
        XCTAssertEqual(params.mediatype, "")
        XCTAssertEqual(params.title, "")
    }

    func testFavoriteItemParams_withSpecialCharacters() {
        let params = FavoriteItemParams(
            identifier: "test-item_123",
            mediatype: "audio",
            title: "Test & Title: Special!"
        )

        XCTAssertEqual(params.identifier, "test-item_123")
        XCTAssertEqual(params.mediatype, "audio")
        XCTAssertEqual(params.title, "Test & Title: Special!")
    }

    // MARK: - URL Encoding Tests

    func testSearchURL_encoding() {
        // Test that search queries can be properly encoded
        let query = "collection:(test) And mediatype:movies"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        XCTAssertNotNil(encodedQuery)
        XCTAssertTrue(encodedQuery?.contains("%") ?? false)
    }

    func testFavoriteUsername_lowercased() {
        let username = "TestUser"
        let lowercasedUsername = username.lowercased()
        XCTAssertEqual(lowercasedUsername, "testuser")
    }

    // MARK: - Manager Type Tests

    func testSharedManager_isNSObject() {
        let manager: Any = APIManager.sharedManager
        XCTAssertTrue(manager is NSObject)
    }
}
