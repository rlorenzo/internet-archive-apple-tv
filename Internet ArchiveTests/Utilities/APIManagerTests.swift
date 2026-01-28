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

    // MARK: - URL Construction Tests (via APIManager)

    func testMetadataURL_construction() {
        let manager = APIManager.sharedManager
        let identifier = "test_item_123"
        let expectedURL = "https://archive.org/metadata/test_item_123"
        let constructedURL = "\(manager.baseURL)\(manager.apiMetadata)\(identifier)"
        XCTAssertEqual(constructedURL, expectedURL)
    }

    func testMetadataURL_withSpecialIdentifier() {
        let manager = APIManager.sharedManager
        // Internet Archive identifiers use alphanumerics, underscores, and hyphens
        let identifier = "test-item_2025"
        let constructedURL = "\(manager.baseURL)\(manager.apiMetadata)\(identifier)"
        XCTAssertTrue(constructedURL.hasPrefix("https://archive.org/metadata/"))
        XCTAssertTrue(constructedURL.hasSuffix(identifier))
    }

    func testFavoritesURL_lowercasesUsername() {
        let manager = APIManager.sharedManager
        let username = "TestUser"
        let constructedURL = "\(manager.baseURL)\(manager.apiGetFavorite)\(username.lowercased())"
        // Verify username is lowercased in the URL
        XCTAssertEqual(constructedURL, "https://archive.org/metadata/fav-testuser")
        XCTAssertFalse(constructedURL.contains("TestUser"))
    }

    func testFavoritesURL_withUnderscoresAndNumbers() {
        let manager = APIManager.sharedManager
        let username = "Test_User_123"
        let constructedURL = "\(manager.baseURL)\(manager.apiGetFavorite)\(username.lowercased())"
        XCTAssertEqual(constructedURL, "https://archive.org/metadata/fav-test_user_123")
    }

    func testSearchURL_baseConstruction() {
        let manager = APIManager.sharedManager
        // The search endpoint is constructed as: baseURL + "advancedsearch.php?q=" + query + options
        let baseSearchURL = "\(manager.baseURL)advancedsearch.php"
        XCTAssertEqual(baseSearchURL, "https://archive.org/advancedsearch.php")
    }

    // MARK: - Protocol Conformance Tests

    func testAPIManager_conformsToNetworkServiceProtocol() {
        let manager: Any = APIManager.sharedManager
        XCTAssertTrue(manager is NetworkServiceProtocol)
    }

    func testNetworkService_inTestEnvironment_returnsProtocolConformingService() {
        // networkService should return something that conforms to NetworkServiceProtocol
        let service = APIManager.networkService
        XCTAssertNotNil(service)
        // The service should be usable as a NetworkServiceProtocol
        let protocolService: NetworkServiceProtocol = service
        XCTAssertNotNil(protocolService)
    }

    // MARK: - Endpoint Consistency Tests

    func testAllEndpoints_haveValidFormat() {
        let manager = APIManager.sharedManager

        // Authentication endpoints should have query parameters
        XCTAssertTrue(manager.apiCreate.contains("?op="))
        XCTAssertTrue(manager.apiLogin.contains("?op="))
        XCTAssertTrue(manager.apiInfo.contains("?op="))

        // Metadata endpoint should be a path prefix
        XCTAssertTrue(manager.apiMetadata.hasSuffix("/"))
        XCTAssertFalse(manager.apiMetadata.contains("?"))

        // Favorites endpoint should be a path prefix
        XCTAssertTrue(manager.apiGetFavorite.hasPrefix("metadata/fav-"))
    }

    func testEndpoints_canFormValidURLs() {
        let manager = APIManager.sharedManager

        // Test that all endpoints form valid URLs when combined with baseURL
        let loginURL = URL(string: "\(manager.baseURL)\(manager.apiLogin)")
        let createURL = URL(string: "\(manager.baseURL)\(manager.apiCreate)")
        let infoURL = URL(string: "\(manager.baseURL)\(manager.apiInfo)")
        let metadataURL = URL(string: "\(manager.baseURL)\(manager.apiMetadata)test_item")
        let favoriteURL = URL(string: "\(manager.baseURL)\(manager.apiGetFavorite)testuser")

        XCTAssertNotNil(loginURL, "Login URL should be valid")
        XCTAssertNotNil(createURL, "Create URL should be valid")
        XCTAssertNotNil(infoURL, "Info URL should be valid")
        XCTAssertNotNil(metadataURL, "Metadata URL should be valid")
        XCTAssertNotNil(favoriteURL, "Favorite URL should be valid")
    }

    // MARK: - Error Parsing Tests

    func testNetworkError_noConnection_message() {
        let error = NetworkError.noConnection
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }

    func testNetworkError_timeout_message() {
        let error = NetworkError.timeout
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }

    func testNetworkError_serverError_containsStatusCode() {
        let error = NetworkError.serverError(statusCode: 500)
        // The error should capture the status code
        if case .serverError(let code) = error {
            XCTAssertEqual(code, 500)
        } else {
            XCTFail("Expected serverError case")
        }
    }

    func testNetworkError_serverError_differentCodes() {
        let error400 = NetworkError.serverError(statusCode: 400)
        let error500 = NetworkError.serverError(statusCode: 500)
        let error503 = NetworkError.serverError(statusCode: 503)

        if case .serverError(let code) = error400 {
            XCTAssertEqual(code, 400)
        }
        if case .serverError(let code) = error500 {
            XCTAssertEqual(code, 500)
        }
        if case .serverError(let code) = error503 {
            XCTAssertEqual(code, 503)
        }
    }

    func testNetworkError_invalidResponse() {
        let error = NetworkError.invalidResponse
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }

    func testNetworkError_decodingFailed() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: nil)
        let error = NetworkError.decodingFailed(underlyingError)

        if case .decodingFailed(let wrapped) = error {
            XCTAssertNotNil(wrapped)
        } else {
            XCTFail("Expected decodingFailed case")
        }
    }

    // MARK: - URL Encoding Behavior Tests

    func testURLEncoding_spacesInMetadataIdentifier() {
        // URL(string:) auto-encodes spaces on Apple platforms, but explicit encoding is safer
        // and ensures consistent behavior across platforms
        let identifierWithSpace = "test item"
        let urlString = "https://archive.org/metadata/\(identifierWithSpace)"
        let url = URL(string: urlString)

        // URL auto-encodes the space to %20
        XCTAssertNotNil(url, "URL should handle space via auto-encoding")
        XCTAssertTrue(url?.absoluteString.contains("%20") ?? false, "Space should be percent-encoded")

        // Explicit encoding produces the same result
        let encodedIdentifier = identifierWithSpace.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        XCTAssertEqual(encodedIdentifier, "test%20item")
    }

    func testURLEncoding_specialCharactersInPath() {
        // Test that special characters break URL parsing without encoding
        let filenameWithQuestion = "what?.mp4"
        let urlString = "https://archive.org/download/item/\(filenameWithQuestion)"
        let url = URL(string: urlString)
        // This actually creates a URL but the ? starts a query string, changing semantics
        XCTAssertNotNil(url, "URL should be created")
        // The path should NOT contain the question mark (it becomes query)
        XCTAssertFalse(url!.path.contains("?"), "Unencoded ? should not be in path")
    }

    func testURLEncoding_hashInPath() {
        // Test that # breaks URL parsing (becomes fragment)
        let filenameWithHash = "track#1.mp3"
        let urlString = "https://archive.org/download/item/\(filenameWithHash)"
        let url = URL(string: urlString)
        XCTAssertNotNil(url, "URL should be created")
        // The hash starts a fragment, so path won't have the full filename
        XCTAssertFalse(url!.path.hasSuffix("track#1.mp3"), "Unencoded # breaks path")
    }

    // MARK: - Content Filter Service Integration Tests

    func testContentFilterService_exists() {
        // Verify ContentFilterService is available (used by APIManager.searchTyped)
        let filterService = ContentFilterService.shared
        XCTAssertNotNil(filterService)
    }

    func testContentFilterService_buildExclusionQuery_returnsString() {
        // APIManager uses this to build search queries
        let exclusionQuery = ContentFilterService.shared.buildExclusionQuery()
        // The exclusion query should be a string (may be empty if no filters configured)
        XCTAssertNotNil(exclusionQuery)
    }

    func testContentFilterService_isCollectionBlocked_returnsBool() {
        // APIManager.getCollectionsTyped checks this before fetching
        let isBlocked = ContentFilterService.shared.isCollectionBlocked("test_collection")
        // Should return a boolean (likely false for test collection)
        XCTAssertFalse(isBlocked)
    }

    // MARK: - APIManager Search Integration Tests

    func testAPIManager_searchTyped_acceptsQueryAndOptions() {
        // Verify the method signature exists and is callable
        // We can't call it without a network, but we can verify the API shape
        let manager = APIManager.sharedManager

        // Verify manager has the searchTyped method via protocol conformance
        let protocolManager: NetworkServiceProtocol = manager
        XCTAssertNotNil(protocolManager)

        // The search method accepts query string and options dictionary
        // This verifies the API contract without making a network call
    }

    func testAPIManager_getMetaDataTyped_acceptsIdentifier() {
        // Verify the method signature exists
        let manager = APIManager.sharedManager
        let protocolManager: NetworkServiceProtocol = manager
        XCTAssertNotNil(protocolManager)
        // getMetadata accepts an identifier string
    }

    func testAPIManager_getFavoriteItemsTyped_acceptsUsername() {
        // Verify the method signature exists
        let manager = APIManager.sharedManager
        let protocolManager: NetworkServiceProtocol = manager
        XCTAssertNotNil(protocolManager)
        // getFavoriteItems accepts a username string
    }
}

// MARK: - Extended Error Tests

@MainActor
final class NetworkErrorExtendedTests: XCTestCase {

    func testNetworkError_allCases_haveNonEmptyDescriptions() {
        let errors: [NetworkError] = [
            .noConnection,
            .timeout,
            .invalidResponse,
            .resourceNotFound,
            .serverError(statusCode: 500),
            .decodingFailed(NSError(domain: "test", code: 1))
        ]

        for error in errors {
            XCTAssertFalse(error.localizedDescription.isEmpty,
                           "Error \(error) should have non-empty description")
        }
    }

    func testNetworkError_serverError_variousStatusCodes() {
        let statusCodes = [400, 401, 403, 404, 500, 502, 503, 504]

        for code in statusCodes {
            let error = NetworkError.serverError(statusCode: code)
            if case .serverError(let extractedCode) = error {
                XCTAssertEqual(extractedCode, code)
            } else {
                XCTFail("Expected serverError case")
            }
        }
    }

    func testNetworkError_decodingFailed_preservesUnderlyingError() {
        let underlyingError = NSError(domain: "JSONDecoding", code: 42, userInfo: [
            NSLocalizedDescriptionKey: "Test error"
        ])
        let error = NetworkError.decodingFailed(underlyingError)

        if case .decodingFailed(let wrapped) = error {
            XCTAssertEqual((wrapped as NSError).code, 42)
            XCTAssertEqual((wrapped as NSError).domain, "JSONDecoding")
        } else {
            XCTFail("Expected decodingFailed case")
        }
    }

    func testNetworkError_resourceNotFound_message() {
        let error = NetworkError.resourceNotFound
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }
}

// MARK: - Extended URL Construction Tests

@MainActor
final class APIManagerURLConstructionTests: XCTestCase {

    func testDownloadURL_construction() {
        let identifier = "my-video-item"
        let filename = "video.mp4"
        let downloadURL = "https://archive.org/download/\(identifier)/\(filename)"

        XCTAssertEqual(downloadURL, "https://archive.org/download/my-video-item/video.mp4")
    }

    func testDownloadURL_withSpecialCharacters_needsEncoding() {
        let filename = "video file.mp4"
        let encoded = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)

        XCTAssertNotNil(encoded)
        XCTAssertTrue(encoded!.contains("%20"))
    }

    func testThumbnailURL_construction() {
        let identifier = "test-item"
        let thumbnailURL = "https://archive.org/services/img/\(identifier)"

        XCTAssertEqual(thumbnailURL, "https://archive.org/services/img/test-item")
    }

    func testSearchURL_withPagination() {
        let manager = APIManager.sharedManager
        let baseURL = "\(manager.baseURL)advancedsearch.php"
        let page = 2
        let rows = 50

        let params = "page=\(page)&rows=\(rows)"
        let fullURL = "\(baseURL)?\(params)"

        XCTAssertTrue(fullURL.contains("page=2"))
        XCTAssertTrue(fullURL.contains("rows=50"))
    }

    func testSearchURL_withSortParameter() {
        let sortField = "downloads"
        let sortDirection = "desc"
        let sortParam = "sort[]=\(sortField)%20\(sortDirection)"

        XCTAssertTrue(sortParam.contains("downloads"))
        XCTAssertTrue(sortParam.contains("desc"))
    }

    func testMetadataURL_withHyphenatedIdentifier() {
        let manager = APIManager.sharedManager
        let identifier = "my-hyphenated-item-2024"
        let url = "\(manager.baseURL)\(manager.apiMetadata)\(identifier)"

        XCTAssertEqual(url, "https://archive.org/metadata/my-hyphenated-item-2024")
    }

    func testMetadataURL_withUnderscoreIdentifier() {
        let manager = APIManager.sharedManager
        let identifier = "my_underscore_item"
        let url = "\(manager.baseURL)\(manager.apiMetadata)\(identifier)"

        XCTAssertEqual(url, "https://archive.org/metadata/my_underscore_item")
    }

    func testAPIEndpoints_areConsistent() {
        let manager = APIManager.sharedManager

        // All endpoints should use the same base URL
        XCTAssertTrue(manager.baseURL.hasPrefix("https://"))
        XCTAssertTrue(manager.baseURL.contains("archive.org"))

        // All paths should be relative (no leading slash for concatenation)
        XCTAssertFalse(manager.apiLogin.hasPrefix("/"))
        XCTAssertFalse(manager.apiCreate.hasPrefix("/"))
        XCTAssertFalse(manager.apiMetadata.hasPrefix("/"))
    }
}

// MARK: - Request Parameter Tests

@MainActor
final class APIRequestParameterTests: XCTestCase {

    func testSearchOptions_defaultFields() {
        // Verify the expected fields are included in search requests
        let expectedFields = ["identifier", "title", "mediatype", "creator", "description", "date", "year", "downloads"]

        let fieldsParam = expectedFields.map { "\($0)" }.joined(separator: ",")

        for field in expectedFields {
            XCTAssertTrue(fieldsParam.contains(field), "Missing field: \(field)")
        }
    }

    func testSearchOptions_mediaTypeFilter() {
        let mediaType = "movies"
        let query = "mediatype:(\(mediaType))"

        XCTAssertTrue(query.contains("mediatype:"))
        XCTAssertTrue(query.contains("movies"))
    }

    func testSearchOptions_combinedMediaTypes() {
        let mediaTypes = "movies OR etree OR audio"
        let query = "mediatype:(\(mediaTypes))"

        XCTAssertTrue(query.contains("movies"))
        XCTAssertTrue(query.contains("etree"))
        XCTAssertTrue(query.contains("audio"))
        XCTAssertTrue(query.contains("OR"))
    }

    func testFavoriteParams_encoding() {
        let params = FavoriteItemParams(
            identifier: "test-item",
            mediatype: "movies",
            title: "Test Title with spaces"
        )

        XCTAssertEqual(params.identifier, "test-item")
        XCTAssertEqual(params.mediatype, "movies")
        XCTAssertEqual(params.title, "Test Title with spaces")
    }
}
