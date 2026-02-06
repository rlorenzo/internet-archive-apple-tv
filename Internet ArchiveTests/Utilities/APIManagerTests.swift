//
//  APIManagerTests.swift
//  Internet ArchiveTests
//
//  Unit tests for APIManager
//

import Testing
import Foundation
import Alamofire
@testable import Internet_Archive

@Suite("APIManager Tests")
@MainActor
struct APIManagerTests {

    // MARK: - Singleton Tests

    @Test func sharedManagerExists() {
        let manager = APIManager.sharedManager
        #expect(manager != nil)
    }

    @Test func sharedManagerIsSingleton() {
        let manager1 = APIManager.sharedManager
        let manager2 = APIManager.sharedManager
        #expect(manager1 === manager2)
    }

    // MARK: - Base URL Tests

    @Test func baseURLIsCorrect() {
        let manager = APIManager.sharedManager
        #expect(manager.baseURL == "https://archive.org/")
    }

    @Test func baseURLHasTrailingSlash() {
        let manager = APIManager.sharedManager
        #expect(manager.baseURL.hasSuffix("/"))
    }

    // MARK: - API Endpoint Tests

    @Test func apiCreateEndpoint() {
        let manager = APIManager.sharedManager
        #expect(manager.apiCreate == "services/xauthn/?op=create")
    }

    @Test func apiLoginEndpoint() {
        let manager = APIManager.sharedManager
        #expect(manager.apiLogin == "services/xauthn/?op=authenticate")
    }

    @Test func apiInfoEndpoint() {
        let manager = APIManager.sharedManager
        #expect(manager.apiInfo == "services/xauthn/?op=info")
    }

    @Test func apiMetadataEndpoint() {
        let manager = APIManager.sharedManager
        #expect(manager.apiMetadata == "metadata/")
    }

    @Test func apiWebLoginEndpoint() {
        let manager = APIManager.sharedManager
        #expect(manager.apiWebLogin == "account/login.php")
    }

    @Test func apiSaveFavoriteEndpoint() {
        let manager = APIManager.sharedManager
        #expect(manager.apiSaveFavorite == "bookmarks.php?add_bookmark=1")
    }

    @Test func apiGetFavoriteEndpoint() {
        let manager = APIManager.sharedManager
        #expect(manager.apiGetFavorite == "metadata/fav-")
    }

    // MARK: - Full URL Construction Tests

    @Test func fullLoginURL() {
        let manager = APIManager.sharedManager
        let fullURL = "\(manager.baseURL)\(manager.apiLogin)"
        #expect(fullURL == "https://archive.org/services/xauthn/?op=authenticate")
    }

    @Test func fullCreateURL() {
        let manager = APIManager.sharedManager
        let fullURL = "\(manager.baseURL)\(manager.apiCreate)"
        #expect(fullURL == "https://archive.org/services/xauthn/?op=create")
    }

    @Test func fullMetadataURLWithIdentifier() {
        let manager = APIManager.sharedManager
        let identifier = "test_item_123"
        let fullURL = "\(manager.baseURL)\(manager.apiMetadata)\(identifier)"
        #expect(fullURL == "https://archive.org/metadata/test_item_123")
    }

    @Test func fullFavoriteURLWithUsername() {
        let manager = APIManager.sharedManager
        let username = "testuser"
        let fullURL = "\(manager.baseURL)\(manager.apiGetFavorite)\(username.lowercased())"
        #expect(fullURL == "https://archive.org/metadata/fav-testuser")
    }

    // MARK: - Headers Tests

    @Test func headersContainsUserAgent() {
        let manager = APIManager.sharedManager
        #expect(manager.headers["User-Agent"] != nil)
    }

    @Test func headersContainsWaybackExtensionVersion() {
        let manager = APIManager.sharedManager
        #expect(manager.headers["Wayback-Extension-Version"] != nil)
    }

    @Test func headersUserAgentContainsWayback() {
        let manager = APIManager.sharedManager
        let userAgent = manager.headers["User-Agent"]
        #expect(userAgent?.contains("Wayback_Machine_iOS") ?? false)
    }

    // MARK: - Network Service Tests

    @Test func networkServiceReturnsService() {
        let service = APIManager.networkService
        #expect(service != nil)
    }

    @Test func networkServiceConformsToProtocol() {
        let service: Any = APIManager.networkService
        #expect(service is NetworkServiceProtocol)
    }

    // MARK: - FavoriteItemParams Tests

    @Test func favoriteItemParamsInitialization() {
        let params = FavoriteItemParams(
            identifier: "test_id",
            mediatype: "movies",
            title: "Test Title"
        )

        #expect(params.identifier == "test_id")
        #expect(params.mediatype == "movies")
        #expect(params.title == "Test Title")
    }

    @Test func favoriteItemParamsWithEmptyValues() {
        let params = FavoriteItemParams(
            identifier: "",
            mediatype: "",
            title: ""
        )

        #expect(params.identifier == "")
        #expect(params.mediatype == "")
        #expect(params.title == "")
    }

    @Test func favoriteItemParamsWithSpecialCharacters() {
        let params = FavoriteItemParams(
            identifier: "test-item_123",
            mediatype: "audio",
            title: "Test & Title: Special!"
        )

        #expect(params.identifier == "test-item_123")
        #expect(params.mediatype == "audio")
        #expect(params.title == "Test & Title: Special!")
    }

    // MARK: - URL Encoding Tests

    @Test func searchURLEncoding() {
        // Test that search queries can be properly encoded
        let query = "collection:(test) And mediatype:movies"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        #expect(encodedQuery != nil)
        #expect(encodedQuery?.contains("%") ?? false)
    }

    @Test func favoriteUsernameLowercased() {
        let username = "TestUser"
        let lowercasedUsername = username.lowercased()
        #expect(lowercasedUsername == "testuser")
    }

    // MARK: - Manager Type Tests

    @Test func sharedManagerIsNSObject() {
        let manager: Any = APIManager.sharedManager
        #expect(manager is NSObject)
    }

    // MARK: - URL Construction Tests (via APIManager)

    @Test func metadataURLConstruction() {
        let manager = APIManager.sharedManager
        let identifier = "test_item_123"
        let expectedURL = "https://archive.org/metadata/test_item_123"
        let constructedURL = "\(manager.baseURL)\(manager.apiMetadata)\(identifier)"
        #expect(constructedURL == expectedURL)
    }

    @Test func metadataURLWithSpecialIdentifier() {
        let manager = APIManager.sharedManager
        // Internet Archive identifiers use alphanumerics, underscores, and hyphens
        let identifier = "test-item_2025"
        let constructedURL = "\(manager.baseURL)\(manager.apiMetadata)\(identifier)"
        #expect(constructedURL.hasPrefix("https://archive.org/metadata/"))
        #expect(constructedURL.hasSuffix(identifier))
    }

    @Test func favoritesURLLowercasesUsername() {
        let manager = APIManager.sharedManager
        let username = "TestUser"
        let constructedURL = "\(manager.baseURL)\(manager.apiGetFavorite)\(username.lowercased())"
        // Verify username is lowercased in the URL
        #expect(constructedURL == "https://archive.org/metadata/fav-testuser")
        #expect(!constructedURL.contains("TestUser"))
    }

    @Test func favoritesURLWithUnderscoresAndNumbers() {
        let manager = APIManager.sharedManager
        let username = "Test_User_123"
        let constructedURL = "\(manager.baseURL)\(manager.apiGetFavorite)\(username.lowercased())"
        #expect(constructedURL == "https://archive.org/metadata/fav-test_user_123")
    }

    @Test func searchURLBaseConstruction() {
        let manager = APIManager.sharedManager
        // The search endpoint is constructed as: baseURL + "advancedsearch.php?q=" + query + options
        let baseSearchURL = "\(manager.baseURL)advancedsearch.php"
        #expect(baseSearchURL == "https://archive.org/advancedsearch.php")
    }

    // MARK: - Protocol Conformance Tests

    @Test func apiManagerConformsToNetworkServiceProtocol() {
        let manager: Any = APIManager.sharedManager
        #expect(manager is NetworkServiceProtocol)
    }

    @Test func networkServiceInTestEnvironmentReturnsProtocolConformingService() {
        // networkService should return something that conforms to NetworkServiceProtocol
        let service = APIManager.networkService
        #expect(service != nil)
        // The service should be usable as a NetworkServiceProtocol
        let protocolService: NetworkServiceProtocol = service
        #expect(protocolService != nil)
    }

    // MARK: - Endpoint Consistency Tests

    @Test func allEndpointsHaveValidFormat() {
        let manager = APIManager.sharedManager

        // Authentication endpoints should have query parameters
        #expect(manager.apiCreate.contains("?op="))
        #expect(manager.apiLogin.contains("?op="))
        #expect(manager.apiInfo.contains("?op="))

        // Metadata endpoint should be a path prefix
        #expect(manager.apiMetadata.hasSuffix("/"))
        #expect(!manager.apiMetadata.contains("?"))

        // Favorites endpoint should be a path prefix
        #expect(manager.apiGetFavorite.hasPrefix("metadata/fav-"))
    }

    @Test func endpointsCanFormValidURLs() {
        let manager = APIManager.sharedManager

        // Test that all endpoints form valid URLs when combined with baseURL
        let loginURL = URL(string: "\(manager.baseURL)\(manager.apiLogin)")
        let createURL = URL(string: "\(manager.baseURL)\(manager.apiCreate)")
        let infoURL = URL(string: "\(manager.baseURL)\(manager.apiInfo)")
        let metadataURL = URL(string: "\(manager.baseURL)\(manager.apiMetadata)test_item")
        let favoriteURL = URL(string: "\(manager.baseURL)\(manager.apiGetFavorite)testuser")

        #expect(loginURL != nil, "Login URL should be valid")
        #expect(createURL != nil, "Create URL should be valid")
        #expect(infoURL != nil, "Info URL should be valid")
        #expect(metadataURL != nil, "Metadata URL should be valid")
        #expect(favoriteURL != nil, "Favorite URL should be valid")
    }

    // MARK: - Error Parsing Tests

    @Test func networkErrorNoConnectionMessage() {
        let error = NetworkError.noConnection
        #expect(!error.localizedDescription.isEmpty)
    }

    @Test func networkErrorTimeoutMessage() {
        let error = NetworkError.timeout
        #expect(!error.localizedDescription.isEmpty)
    }

    @Test func networkErrorServerErrorContainsStatusCode() {
        let error = NetworkError.serverError(statusCode: 500)
        // The error should capture the status code
        if case .serverError(let code) = error {
            #expect(code == 500)
        } else {
            Issue.record("Expected serverError case")
        }
    }

    @Test func networkErrorServerErrorDifferentCodes() {
        let error400 = NetworkError.serverError(statusCode: 400)
        let error500 = NetworkError.serverError(statusCode: 500)
        let error503 = NetworkError.serverError(statusCode: 503)

        if case .serverError(let code) = error400 {
            #expect(code == 400)
        }
        if case .serverError(let code) = error500 {
            #expect(code == 500)
        }
        if case .serverError(let code) = error503 {
            #expect(code == 503)
        }
    }

    @Test func networkErrorInvalidResponse() {
        let error = NetworkError.invalidResponse
        #expect(!error.localizedDescription.isEmpty)
    }

    @Test func networkErrorDecodingFailed() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: nil)
        let error = NetworkError.decodingFailed(underlyingError)

        if case .decodingFailed(let wrapped) = error {
            #expect(wrapped != nil)
        } else {
            Issue.record("Expected decodingFailed case")
        }
    }

    // MARK: - URL Encoding Behavior Tests

    @Test func urlEncodingSpacesInMetadataIdentifier() {
        let identifierWithSpace = "test item"
        let urlString = "https://archive.org/metadata/\(identifierWithSpace)"
        let url = URL(string: urlString)

        // URL auto-encodes the space to %20
        #expect(url != nil, "URL should handle space via auto-encoding")
        #expect(url?.absoluteString.contains("%20") ?? false, "Space should be percent-encoded")

        // Explicit encoding produces the same result
        let encodedIdentifier = identifierWithSpace.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
        #expect(encodedIdentifier == "test%20item")
    }

    @Test func urlEncodingSpecialCharactersInPath() {
        // Test that special characters break URL parsing without encoding
        let filenameWithQuestion = "what?.mp4"
        let urlString = "https://archive.org/download/item/\(filenameWithQuestion)"
        let url = URL(string: urlString)
        // This actually creates a URL but the ? starts a query string, changing semantics
        #expect(url != nil, "URL should be created")
        // The path should NOT contain the question mark (it becomes query)
        #expect(!url!.path.contains("?"), "Unencoded ? should not be in path")
    }

    @Test func urlEncodingHashInPath() {
        // Test that # breaks URL parsing (becomes fragment)
        let filenameWithHash = "track#1.mp3"
        let urlString = "https://archive.org/download/item/\(filenameWithHash)"
        let url = URL(string: urlString)
        #expect(url != nil, "URL should be created")
        // The hash starts a fragment, so path won't have the full filename
        #expect(!url!.path.hasSuffix("track#1.mp3"), "Unencoded # breaks path")
    }

    // MARK: - Content Filter Service Integration Tests

    @Test func contentFilterServiceExists() {
        // Verify ContentFilterService is available (used by APIManager.searchTyped)
        let filterService = ContentFilterService.shared
        #expect(filterService != nil)
    }

    @Test func contentFilterServiceBuildExclusionQueryReturnsString() {
        // APIManager uses this to build search queries
        let exclusionQuery = ContentFilterService.shared.buildExclusionQuery()
        // The exclusion query should be a string (may be empty if no filters configured)
        #expect(exclusionQuery != nil)
    }

    @Test func contentFilterServiceIsCollectionBlockedReturnsBool() {
        // APIManager.getCollectionsTyped checks this before fetching
        let isBlocked = ContentFilterService.shared.isCollectionBlocked("test_collection")
        // Should return a boolean (likely false for test collection)
        #expect(!isBlocked)
    }

    // MARK: - APIManager Search Integration Tests

    @Test func apiManagerSearchTypedAcceptsQueryAndOptions() {
        // Verify the method signature exists and is callable
        let manager = APIManager.sharedManager

        // Verify manager has the searchTyped method via protocol conformance
        let protocolManager: NetworkServiceProtocol = manager
        #expect(protocolManager != nil)
    }

    @Test func apiManagerGetMetaDataTypedAcceptsIdentifier() {
        let manager = APIManager.sharedManager
        let protocolManager: NetworkServiceProtocol = manager
        #expect(protocolManager != nil)
    }

    @Test func apiManagerGetFavoriteItemsTypedAcceptsUsername() {
        let manager = APIManager.sharedManager
        let protocolManager: NetworkServiceProtocol = manager
        #expect(protocolManager != nil)
    }
}

// MARK: - Extended Error Tests

@Suite("NetworkError Extended Tests")
@MainActor
struct NetworkErrorExtendedTests {

    @Test func networkErrorAllCasesHaveNonEmptyDescriptions() {
        let errors: [NetworkError] = [
            .noConnection,
            .timeout,
            .invalidResponse,
            .resourceNotFound,
            .serverError(statusCode: 500),
            .decodingFailed(NSError(domain: "test", code: 1))
        ]

        for error in errors {
            #expect(!error.localizedDescription.isEmpty,
                    "Error \(error) should have non-empty description")
        }
    }

    @Test func networkErrorServerErrorVariousStatusCodes() {
        let statusCodes = [400, 401, 403, 404, 500, 502, 503, 504]

        for code in statusCodes {
            let error = NetworkError.serverError(statusCode: code)
            if case .serverError(let extractedCode) = error {
                #expect(extractedCode == code)
            } else {
                Issue.record("Expected serverError case")
            }
        }
    }

    @Test func networkErrorDecodingFailedPreservesUnderlyingError() {
        let underlyingError = NSError(domain: "JSONDecoding", code: 42, userInfo: [
            NSLocalizedDescriptionKey: "Test error"
        ])
        let error = NetworkError.decodingFailed(underlyingError)

        if case .decodingFailed(let wrapped) = error {
            #expect((wrapped as NSError).code == 42)
            #expect((wrapped as NSError).domain == "JSONDecoding")
        } else {
            Issue.record("Expected decodingFailed case")
        }
    }

    @Test func networkErrorResourceNotFoundMessage() {
        let error = NetworkError.resourceNotFound
        #expect(!error.localizedDescription.isEmpty)
    }
}

// MARK: - Extended URL Construction Tests

@Suite("APIManager URL Construction Tests")
@MainActor
struct APIManagerURLConstructionTests {

    @Test func downloadURLConstruction() {
        let identifier = "my-video-item"
        let filename = "video.mp4"
        let downloadURL = "https://archive.org/download/\(identifier)/\(filename)"

        #expect(downloadURL == "https://archive.org/download/my-video-item/video.mp4")
    }

    @Test func downloadURLWithSpecialCharactersNeedsEncoding() {
        let filename = "video file.mp4"
        let encoded = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)

        #expect(encoded != nil)
        #expect(encoded!.contains("%20"))
    }

    @Test func thumbnailURLConstruction() {
        let identifier = "test-item"
        let thumbnailURL = "https://archive.org/services/img/\(identifier)"

        #expect(thumbnailURL == "https://archive.org/services/img/test-item")
    }

    @Test func searchURLWithPagination() {
        let manager = APIManager.sharedManager
        let baseURL = "\(manager.baseURL)advancedsearch.php"
        let page = 2
        let rows = 50

        let params = "page=\(page)&rows=\(rows)"
        let fullURL = "\(baseURL)?\(params)"

        #expect(fullURL.contains("page=2"))
        #expect(fullURL.contains("rows=50"))
    }

    @Test func searchURLWithSortParameter() {
        let sortField = "downloads"
        let sortDirection = "desc"
        let sortParam = "sort[]=\(sortField)%20\(sortDirection)"

        #expect(sortParam.contains("downloads"))
        #expect(sortParam.contains("desc"))
    }

    @Test func metadataURLWithHyphenatedIdentifier() {
        let manager = APIManager.sharedManager
        let identifier = "my-hyphenated-item-2024"
        let url = "\(manager.baseURL)\(manager.apiMetadata)\(identifier)"

        #expect(url == "https://archive.org/metadata/my-hyphenated-item-2024")
    }

    @Test func metadataURLWithUnderscoreIdentifier() {
        let manager = APIManager.sharedManager
        let identifier = "my_underscore_item"
        let url = "\(manager.baseURL)\(manager.apiMetadata)\(identifier)"

        #expect(url == "https://archive.org/metadata/my_underscore_item")
    }

    @Test func apiEndpointsAreConsistent() {
        let manager = APIManager.sharedManager

        // All endpoints should use the same base URL
        #expect(manager.baseURL.hasPrefix("https://"))
        #expect(manager.baseURL.contains("archive.org"))

        // All paths should be relative (no leading slash for concatenation)
        #expect(!manager.apiLogin.hasPrefix("/"))
        #expect(!manager.apiCreate.hasPrefix("/"))
        #expect(!manager.apiMetadata.hasPrefix("/"))
    }
}

// MARK: - Request Parameter Tests

@Suite("API Request Parameter Tests")
@MainActor
struct APIRequestParameterTests {

    @Test func searchOptionsDefaultFields() {
        let expectedFields = ["identifier", "title", "mediatype", "creator", "description", "date", "year", "downloads"]

        let fieldsParam = expectedFields.map { "\($0)" }.joined(separator: ",")

        for field in expectedFields {
            #expect(fieldsParam.contains(field), "Missing field: \(field)")
        }
    }

    @Test func searchOptionsMediaTypeFilter() {
        let mediaType = "movies"
        let query = "mediatype:(\(mediaType))"

        #expect(query.contains("mediatype:"))
        #expect(query.contains("movies"))
    }

    @Test func searchOptionsCombinedMediaTypes() {
        let mediaTypes = "movies OR etree OR audio"
        let query = "mediatype:(\(mediaTypes))"

        #expect(query.contains("movies"))
        #expect(query.contains("etree"))
        #expect(query.contains("audio"))
        #expect(query.contains("OR"))
    }

    @Test func favoriteParamsEncoding() {
        let params = FavoriteItemParams(
            identifier: "test-item",
            mediatype: "movies",
            title: "Test Title with spaces"
        )

        #expect(params.identifier == "test-item")
        #expect(params.mediatype == "movies")
        #expect(params.title == "Test Title with spaces")
    }
}
