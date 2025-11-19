//
//  APIManager.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//
//  Updated for Sprint 4: Alamofire 5.x migration with async/await support
//  Updated for Sprint 5: Added Codable model support
//  Updated for Sprint 7: Removed hardcoded credentials, using secure configuration
//

import Foundation
import Alamofire

struct FavoriteItemParams {
    let identifier: String
    let mediatype: String
    let title: String
}

class APIManager: NSObject {
    static let sharedManager = APIManager()

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

    // MARK: - Initialization

    override private init() {
        // Load credentials from secure configuration
        self.access = AppConfiguration.shared.apiAccessKey
        self.secret = AppConfiguration.shared.apiSecretKey
        self.apiVersion = AppConfiguration.shared.apiVersion

        super.init()

        // Warn if configuration is not properly set up
        if !AppConfiguration.shared.isConfigured {
            NSLog("⚠️ Warning: API credentials not configured. Please set up Configuration.plist")
        }
    }

    // MARK: - Private Helper Methods (Updated for Alamofire 5.x)

    private func sendDataToService(params: [String: Any], operation: String, completion: @escaping ([String: Any]?) -> Void) {

        var parameters = params
        parameters["access"] = access
        parameters["secret"] = secret
        parameters["version"] = apiVersion

        AF.request("\(baseURL)\(operation)",
                   method: .post,
                   parameters: parameters,
                   encoding: URLEncoding.default,
                   headers: headers)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    completion(value as? [String: Any])
                case .failure:
                    completion(nil)
                }
            }
    }

    private func getCookieData(email: String, password: String, completion: @escaping ([String: Any]?) -> Void) {
        var params = [String: Any]()
        params["username"] = email
        params["password"] = password
        params["action"] = "login"

        let cookieProps: [HTTPCookiePropertyKey: Any] = [
            HTTPCookiePropertyKey.version: 0,
            HTTPCookiePropertyKey.name: "test-cookie",
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.value: "1",
            HTTPCookiePropertyKey.domain: ".archive.org",
            HTTPCookiePropertyKey.secure: false,
            HTTPCookiePropertyKey.expires: Date(timeIntervalSinceNow: 86400 * 20)
        ]

        if let cookie = HTTPCookie(properties: cookieProps) {
            Session.default.session.configuration.httpCookieStorage?.setCookie(cookie)
        }

        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "application/x-www-form-urlencoded")

        AF.request(baseURL + apiWebLogin,
                   method: .post,
                   parameters: params,
                   encoding: URLEncoding.default,
                   headers: headers)
            .responseString { response in
                switch response.result {
                case .success:
                    if let cookies = HTTPCookieStorage.shared.cookies {
                        var cookieData = [String: Any]()

                        for cookie in cookies {
                            if cookie.name == "logged-in-sig" {
                                cookieData["logged-in-sig"] = cookie
                            } else if cookie.name == "logged-in-user" {
                                cookieData["logged-in-user"] = cookie
                            }
                        }

                        completion(cookieData)
                    } else {
                        completion(nil)
                    }
                case .failure:
                    completion(nil)
                }
            }
    }

    // MARK: - Legacy Completion-Based Methods (Backward Compatibility)

    // Register new Account
    func register(params: [String: Any], completion: @escaping ([String: Any]?) -> Void) {
        sendDataToService(params: params, operation: apiCreate, completion: completion)
    }

    // Login
    func login(email: String, password: String, completion: @escaping ([String: Any]?) -> Void) {
        sendDataToService(
            params: [
                "email": email,
                "password": password
            ],
            operation: apiLogin,
            completion: completion
        )
    }

    // Get Account Info
    func getAccountInfo(email: String, completion: @escaping ([String: Any]?) -> Void) {
        sendDataToService(params: ["email": email], operation: apiInfo, completion: completion)
    }

    func search(query: String, options: [String: String], completion: @escaping (_ data: [String: Any]?, _ err: Int?) -> Void) {
        var strOption = "&output=json"

        for (key, value) in options {
            strOption += "&\(key)=\(value)"
        }

        let url = "\(baseURL)advancedsearch.php?q=\(query)\(strOption)"
        guard let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(nil, 0)
            return
        }

        AF.request(encodedURL,
                   method: .get,
                   encoding: URLEncoding.default,
                   headers: headers)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let result = value as? [String: Any],
                       let data = result["response"] as? [String: Any] {
                        completion(data, nil)
                    } else {
                        completion(nil, 0)
                    }
                case .failure:
                    completion(nil, 0)
                }
            }
    }

    func getCollections(collection: String, resultType: String, limit: Int?, completion: @escaping (_ collection: String, _ data: [[String: Any]]?, _ err: Int?) -> Void) {
        var options = [
            "rows": "1",
            "fl[]": "identifier,title,year,downloads,date,creator,description,mediatype"
        ]

        if let unwrappedLimit = limit {
            options["rows"] = "\(unwrappedLimit)"
        }

        search(query: "collection:(\(collection)) And mediatype:\(resultType)", options: options) { data, err in
            guard let data = data else {
                completion(collection, nil, err)
                return
            }

            if limit == nil, let numFound = data["numFound"] as? Int {
                if numFound == 0 {
                    // API.GetCollections - fail
                    completion(collection, nil, 0)
                } else {
                    self.getCollections(collection: collection, resultType: resultType, limit: numFound, completion: completion)
                }
            } else {
                completion(collection, data["docs"] as? [[String: Any]], nil)
            }
        }
    }

    func getMetaData(identifier: String, completion: @escaping (_ data: [String: Any]?, _ err: Int?) -> Void) {
        AF.request("\(baseURL)\(apiMetadata)\(identifier)",
                   method: .get,
                   encoding: URLEncoding.default,
                   headers: headers)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    completion(value as? [String: Any], nil)
                case .failure:
                    completion(nil, 0)
                }
            }
    }

    func getFavoriteItems(username: String,
                          completion: @escaping (_ success: Bool, _ err: Int?, _ items: [[String: Any]]?) -> Void) {
        let url = "\(baseURL)\(apiGetFavorite)\(username.lowercased())"

        AF.request(url, method: .get, encoding: URLEncoding.default)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let jsonData = value as? [String: Any],
                       let items = jsonData["members"] as? [[String: Any]] {
                        completion(true, nil, items)
                    } else {
                        completion(true, nil, nil)
                    }
                case .failure:
                    completion(false, response.response?.statusCode, nil)
                }
            }
    }

    func saveFavoriteItem(email: String, password: String, item: FavoriteItemParams, completion: @escaping (_ success: Bool, _ err: Int?) -> Void) {

        getCookieData(email: email, password: password) { data in
            guard let data = data else {
                completion(false, 301)
                return
            }

            guard let loggedInSig = data["logged-in-sig"] as? HTTPCookie,
                  let loggedInUser = data["logged-in-user"] as? HTTPCookie else {
                completion(false, 301)
                return
            }

                Session.default.session.configuration.httpCookieStorage?.setCookie(loggedInSig)
                Session.default.session.configuration.httpCookieStorage?.setCookie(loggedInUser)

                let url = "\(self.baseURL)\(self.apiSaveFavorite)&mediatype=\(item.mediatype)&identifier=\(item.identifier)&title=\(item.title)"
                guard let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                    completion(false, 0)
                    return
                }

                AF.request(encodedURL, method: .get, encoding: URLEncoding.default)
                    .responseString { response in
                        switch response.result {
                        case .success:
                            completion(true, nil)
                        case .failure:
                            completion(false, response.response?.statusCode)
                        }
                    }
        }
    }

    // MARK: - Modern Async/Await Methods

    /// Register new account (async/await)
    func register(params: [String: Any]) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            register(params: params) { data in
                if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NetworkError.apiError(message: "Registration failed"))
                }
            }
        }
    }

    /// Login (async/await)
    func login(email: String, password: String) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            login(email: email, password: password) { data in
                if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NetworkError.invalidCredentials)
                }
            }
        }
    }

    /// Get account info (async/await)
    func getAccountInfo(email: String) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            getAccountInfo(email: email) { data in
                if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NetworkError.apiError(message: "Failed to get account info"))
                }
            }
        }
    }

    /// Search (async/await)
    func search(query: String, options: [String: String]) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            search(query: query, options: options) { data, err in
                if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NetworkError.serverError(statusCode: err ?? 0))
                }
            }
        }
    }

    /// Get collections (async/await)
    func getCollections(collection: String, resultType: String, limit: Int? = nil) async throws -> (collection: String, data: [[String: Any]]) {
        try await withCheckedThrowingContinuation { continuation in
            getCollections(collection: collection, resultType: resultType, limit: limit) { collection, data, err in
                if let data = data {
                    continuation.resume(returning: (collection, data))
                } else {
                    continuation.resume(throwing: NetworkError.serverError(statusCode: err ?? 0))
                }
            }
        }
    }

    /// Get metadata (async/await)
    func getMetaData(identifier: String) async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            getMetaData(identifier: identifier) { data, err in
                if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NetworkError.serverError(statusCode: err ?? 0))
                }
            }
        }
    }

    /// Get favorite items (async/await)
    func getFavoriteItems(username: String) async throws -> [[String: Any]]? {
        try await withCheckedThrowingContinuation { continuation in
            getFavoriteItems(username: username) { success, err, items in
                if success {
                    continuation.resume(returning: items)
                } else {
                    continuation.resume(throwing: NetworkError.serverError(statusCode: err ?? 0))
                }
            }
        }
    }

    /// Save favorite item (async/await)
    func saveFavoriteItem(email: String, password: String, item: FavoriteItemParams) async throws {
        try await withCheckedThrowingContinuation { continuation in
            saveFavoriteItem(email: email, password: password, item: item) { success, err in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NetworkError.serverError(statusCode: err ?? 0))
                }
            }
        }
    }

    // MARK: - Type-Safe Async/Await Methods (Codable Models)

    /// Register new account with typed response (async/await)
    func registerTyped(params: [String: Any]) async throws -> AuthResponse {
        var parameters = params
        parameters["access"] = access
        parameters["secret"] = secret
        parameters["version"] = apiVersion

        return try await AF.request("\(baseURL)\(apiCreate)",
                                    method: .post,
                                    parameters: parameters,
                                    encoding: URLEncoding.default,
                                    headers: headers)
            .serializingDecodable(AuthResponse.self)
            .value
    }

    /// Login with typed response (async/await)
    func loginTyped(email: String, password: String) async throws -> AuthResponse {
        let params: [String: Any] = [
            "email": email,
            "password": password,
            "access": access,
            "secret": secret,
            "version": apiVersion
        ]

        return try await AF.request("\(baseURL)\(apiLogin)",
                                    method: .post,
                                    parameters: params,
                                    encoding: URLEncoding.default,
                                    headers: headers)
            .serializingDecodable(AuthResponse.self)
            .value
    }

    /// Get account info with typed response (async/await)
    func getAccountInfoTyped(email: String) async throws -> AccountInfoResponse {
        let params: [String: Any] = [
            "email": email,
            "access": access,
            "secret": secret,
            "version": apiVersion
        ]

        return try await AF.request("\(baseURL)\(apiInfo)",
                                    method: .post,
                                    parameters: params,
                                    encoding: URLEncoding.default,
                                    headers: headers)
            .serializingDecodable(AccountInfoResponse.self)
            .value
    }

    /// Search with typed response (async/await)
    func searchTyped(query: String, options: [String: String]) async throws -> SearchResponse {
        var strOption = "&output=json"

        for (key, value) in options {
            strOption += "&\(key)=\(value)"
        }

        let url = "\(baseURL)advancedsearch.php?q=\(query)\(strOption)"
        guard let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw NetworkError.invalidParameters
        }

        return try await AF.request(encodedURL,
                                    method: .get,
                                    encoding: URLEncoding.default,
                                    headers: headers)
            .serializingDecodable(SearchResponse.self)
            .value
    }

    /// Get collections with typed response (async/await)
    func getCollectionsTyped(collection: String, resultType: String, limit: Int? = nil) async throws -> (collection: String, results: [SearchResult]) {
        var options = [
            "rows": limit.map { "\($0)" } ?? "1",
            "fl[]": "identifier,title,year,downloads,date,creator,description,mediatype"
        ]

        let response = try await searchTyped(query: "collection:(\(collection)) And mediatype:\(resultType)", options: options)

        // If first call to get count, make second call with actual limit
        if limit == nil {
            let numFound = response.response.numFound
            if numFound == 0 {
                return (collection, [])
            }
            return try await getCollectionsTyped(collection: collection, resultType: resultType, limit: numFound)
        }

        return (collection, response.response.docs)
    }

    /// Get metadata with typed response (async/await)
    func getMetaDataTyped(identifier: String) async throws -> ItemMetadataResponse {
        try await AF.request("\(baseURL)\(apiMetadata)\(identifier)",
                             method: .get,
                             encoding: URLEncoding.default,
                             headers: headers)
            .serializingDecodable(ItemMetadataResponse.self)
            .value
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
