//
//  APIManager.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//
//

import Foundation
import Alamofire

struct FavoriteItemParams {
    let identifier: String
    let mediatype: String
    let title: String
}

@MainActor
final class APIManager: NSObject {
    static let sharedManager = APIManager()

    /// Returns the appropriate network service based on testing mode
    /// In UI testing mode, returns MockAPIManager; otherwise returns real APIManager
    static var networkService: NetworkServiceProtocol {
        if UITestingHelper.shared.useMockData {
            return MockAPIManager.shared
        }
        return sharedManager
    }

    let baseURL = "https://archive.org/"
    let apiCreate = "services/xauthn/?op=create"
    let apiLogin = "services/xauthn/?op=authenticate"
    let apiInfo = "services/xauthn/?op=info"
    let apiMetadata = "metadata/"
    let apiWebLogin = "account/login.php"
    let apiSaveFavorite = "bookmarks.php?add_bookmark=1"
    let apiGetFavorite = "metadata/fav-"

    /// The API access key used for authenticating requests to Internet Archive's xauthn service.
    /// Loaded from secure configuration. This credential must be kept confidential and never hardcoded or exposed in logs or source control.
    private let access: String

    /// The API secret key used for signing or authenticating requests to Internet Archive's xauthn service.
    /// Loaded from secure configuration. This credential must be kept confidential and never hardcoded or exposed in logs or source control.
    private let secret: String

    /// The API version used for requests to ensure compatibility with the backend.
    /// Loaded from secure configuration.
    private let apiVersion: Int

    let headers: HTTPHeaders = [
        "User-Agent": "Wayback_Machine_iOS/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")",
        "Wayback-Extension-Version": "Wayback_Machine_iOS/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")"
    ]

    /// Check if running in test environment
    private static var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }

    // MARK: - Initialization

    override private init() {
        // Load credentials from secure configuration
        self.access = AppConfiguration.shared.apiAccessKey
        self.secret = AppConfiguration.shared.apiSecretKey
        self.apiVersion = AppConfiguration.shared.apiVersion

        super.init()

        // Warn if configuration is not properly set up (suppress during tests)
        if !AppConfiguration.shared.isConfigured && !Self.isRunningTests {
            NSLog("⚠️ Warning: API credentials not configured. Please set up Configuration.plist")
        }
    }

    // MARK: - Type-Safe Async/Await Methods (Codable Models, Sendable-compliant)

    /// Register new account with typed response (async/await)
    func registerTyped(params: [String: Any]) async throws -> AuthResponse {
        let request = RegisterRequest(params: params, access: access, secret: secret, version: apiVersion)

        return try await AF.request("\(baseURL)\(apiCreate)",
                                    method: .post,
                                    parameters: request,
                                    encoder: URLEncodedFormParameterEncoder.default,
                                    headers: headers)
            .serializingDecodable(AuthResponse.self)
            .value
    }

    /// Login with typed response (async/await)
    func loginTyped(email: String, password: String) async throws -> AuthResponse {
        let request = LoginRequest(
            email: email,
            password: password,
            access: access,
            secret: secret,
            version: apiVersion
        )

        return try await AF.request("\(baseURL)\(apiLogin)",
                                    method: .post,
                                    parameters: request,
                                    encoder: URLEncodedFormParameterEncoder.default,
                                    headers: headers)
            .serializingDecodable(AuthResponse.self)
            .value
    }

    /// Get account info with typed response (async/await)
    func getAccountInfoTyped(email: String) async throws -> AccountInfoResponse {
        let request = AccountInfoRequest(
            email: email,
            access: access,
            secret: secret,
            version: apiVersion
        )

        return try await AF.request("\(baseURL)\(apiInfo)",
                                    method: .post,
                                    parameters: request,
                                    encoder: URLEncodedFormParameterEncoder.default,
                                    headers: headers)
            .serializingDecodable(AccountInfoResponse.self)
            .value
    }

    /// Search with typed response (async/await)
    /// - Parameters:
    ///   - query: The search query
    ///   - options: Additional query options (rows, fl[], sort, etc.)
    ///   - applyContentFilter: Whether to apply content filtering exclusions (default: true)
    func searchTyped(
        query: String,
        options: [String: String],
        applyContentFilter: Bool = true
    ) async throws -> SearchResponse {
        var strOption = "&output=json"

        // Ensure collection and licenseurl fields are in the list for content filtering
        var modifiedOptions = options
        if applyContentFilter, let existingFields = options["fl[]"] {
            var fields = existingFields
            if !fields.contains("collection") {
                fields += ",collection"
            }
            if !fields.contains("licenseurl") {
                fields += ",licenseurl"
            }
            modifiedOptions["fl[]"] = fields
        }

        for (key, value) in modifiedOptions {
            strOption += "&\(key)=\(value)"
        }

        // Build the final query with content filter exclusions
        var finalQuery = query
        if applyContentFilter {
            let exclusionQuery = ContentFilterService.shared.buildExclusionQuery()
            if !exclusionQuery.isEmpty {
                finalQuery = "\(query) \(exclusionQuery)"
            }
        }

        let url = "\(baseURL)advancedsearch.php?q=\(finalQuery)\(strOption)"
        guard let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw NetworkError.invalidParameters
        }

        let response = try await AF.request(
            encodedURL,
            method: .get,
            encoding: URLEncoding.default,
            headers: headers
        )
        .serializingDecodable(SearchResponse.self)
        .value

        // Apply additional client-side filtering for results that may have slipped through
        if applyContentFilter {
            let originalDocs = response.response.docs
            let filteredDocs = ContentFilterService.shared.filter(originalDocs)
            let filteredCount = originalDocs.count - filteredDocs.count

            // Adjust numFound to reflect filtered results, preventing infinite pagination
            let adjustedNumFound = max(0, response.response.numFound - filteredCount)

            return SearchResponse(
                responseHeader: response.responseHeader,
                response: SearchResponse.SearchResults(
                    numFound: adjustedNumFound,
                    start: response.response.start,
                    docs: filteredDocs
                )
            )
        }

        return response
    }

    /// Get collections with typed response (async/await)
    /// - Parameters:
    ///   - collection: The collection identifier to fetch
    ///   - resultType: The media type to filter by (e.g., "movies", "audio")
    ///   - limit: Maximum number of results (nil fetches count first, then all)
    ///   - applyContentFilter: Whether to apply content filtering (default: true)
    func getCollectionsTyped(
        collection: String,
        resultType: String,
        limit: Int? = nil,
        applyContentFilter: Bool = true
    ) async throws -> (collection: String, results: [SearchResult]) {
        // Check if the collection itself is blocked
        if applyContentFilter && ContentFilterService.shared.isCollectionBlocked(collection) {
            return (collection, [])
        }

        let options = [
            "rows": limit.map { "\($0)" } ?? "1",
            "fl[]": "identifier,title,year,downloads,date,creator,description,mediatype,collection,licenseurl"
        ]

        let response = try await searchTyped(
            query: "collection:(\(collection)) And mediatype:\(resultType)",
            options: options,
            applyContentFilter: applyContentFilter
        )

        // If first call to get count, make second call with actual limit
        if limit == nil {
            let numFound = response.response.numFound
            if numFound == 0 {
                return (collection, [])
            }
            return try await getCollectionsTyped(
                collection: collection,
                resultType: resultType,
                limit: numFound,
                applyContentFilter: applyContentFilter
            )
        }

        return (collection, response.response.docs)
    }

    /// Get metadata with typed response (async/await)
    /// - Parameters:
    ///   - identifier: The item identifier
    ///   - applyContentFilter: Whether to check content filter (default: true)
    /// - Throws: NetworkError.contentFiltered if the item is blocked
    func getMetaDataTyped(identifier: String, applyContentFilter: Bool = true) async throws -> ItemMetadataResponse {
        let response = try await AF.request(
            "\(baseURL)\(apiMetadata)\(identifier)",
            method: .get,
            encoding: URLEncoding.default,
            headers: headers
        )
        .serializingDecodable(ItemMetadataResponse.self)
        .value

        // Apply content filtering if enabled
        if applyContentFilter, let metadata = response.metadata {
            let filterResult = ContentFilterService.shared.shouldFilter(metadata)
            if filterResult.isFiltered {
                throw NetworkError.contentFiltered
            }
        }

        return response
    }

    /// Get favorite items with typed response (async/await)
    func getFavoriteItemsTyped(username: String) async throws -> FavoritesResponse {
        let url = "\(baseURL)\(apiGetFavorite)\(username.lowercased())"

        return try await AF.request(url,
                                    method: .get,
                                    encoding: URLEncoding.default)
            .serializingDecodable(FavoritesResponse.self)
            .value
    }
}
