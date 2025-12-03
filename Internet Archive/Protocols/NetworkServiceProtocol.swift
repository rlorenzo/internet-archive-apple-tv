//
//  NetworkServiceProtocol.swift
//  Internet Archive
//
//  Protocol-based dependency injection for networking layer
//

import Foundation

/// Protocol defining the network service interface for dependency injection.
///
/// This protocol enables testing by allowing mock implementations to be
/// substituted for the real `APIManager` in unit tests. All methods use
/// async/await and throw `NetworkError` on failure.
///
/// ## Overview
///
/// The protocol defines the complete API surface for Internet Archive operations:
/// - Authentication (register, login, account info)
/// - Content discovery (search, browse collections)
/// - Item details (metadata)
/// - User features (favorites)
///
/// ## Usage in Tests
///
/// ```swift
/// // Create mock service
/// let mockService = MockNetworkService()
/// mockService.mockSearchResponse = TestFixtures.searchResponse
///
/// // Inject into view model or controller
/// let viewModel = SearchViewModel(networkService: mockService)
///
/// // Verify calls
/// XCTAssertTrue(mockService.searchCalled)
/// ```
///
/// ## Production Usage
///
/// In production, use `APIManager.sharedManager` which conforms to this protocol:
///
/// ```swift
/// let service: NetworkServiceProtocol = APIManager.sharedManager
/// let results = try await service.search(query: "movies", options: [:])
/// ```
///
/// - Note: All methods must be called from the main actor context.
@MainActor
protocol NetworkServiceProtocol {
    // MARK: - Authentication

    /// Registers a new user account.
    /// - Parameter params: Registration parameters including email, password, and screenname.
    /// - Returns: Authentication response with user details.
    /// - Throws: `NetworkError` if registration fails.
    func register(params: [String: Any]) async throws -> AuthResponse

    /// Logs in an existing user.
    /// - Parameters:
    ///   - email: User's email address.
    ///   - password: User's password.
    /// - Returns: Authentication response with user details.
    /// - Throws: `NetworkError.invalidCredentials` if login fails.
    func login(email: String, password: String) async throws -> AuthResponse

    /// Retrieves account information for a logged-in user.
    /// - Parameter email: User's email address.
    /// - Returns: Account information including verification status.
    /// - Throws: `NetworkError.unauthorized` if not authenticated.
    func getAccountInfo(email: String) async throws -> AccountInfoResponse

    // MARK: - Search & Collections

    /// Searches the Internet Archive catalog.
    /// - Parameters:
    ///   - query: Search query string.
    ///   - options: Additional search options (e.g., mediatype, sort).
    /// - Returns: Search response with matching items.
    /// - Throws: `NetworkError` on failure.
    func search(query: String, options: [String: String]) async throws -> SearchResponse

    /// Retrieves items from a specific collection.
    /// - Parameters:
    ///   - collection: Collection identifier (e.g., "movies", "audio").
    ///   - resultType: Media type filter.
    ///   - limit: Maximum number of results (nil for default).
    /// - Returns: Tuple of collection name and matching results.
    /// - Throws: `NetworkError` on failure.
    func getCollections(collection: String, resultType: String, limit: Int?) async throws -> (collection: String, results: [SearchResult])

    // MARK: - Metadata

    /// Retrieves detailed metadata for a specific item.
    /// - Parameter identifier: Unique item identifier.
    /// - Returns: Complete item metadata including files.
    /// - Throws: `NetworkError.resourceNotFound` if item doesn't exist.
    func getMetadata(identifier: String) async throws -> ItemMetadataResponse

    // MARK: - Favorites

    /// Retrieves a user's favorite items.
    /// - Parameter username: Username (without @ prefix).
    /// - Returns: Favorites response with saved items.
    /// - Throws: `NetworkError` on failure.
    func getFavoriteItems(username: String) async throws -> FavoritesResponse
}

/// Extension to make APIManager conform to NetworkServiceProtocol
extension APIManager: NetworkServiceProtocol {
    func register(params: [String: Any]) async throws -> AuthResponse {
        try await registerTyped(params: params)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await loginTyped(email: email, password: password)
    }

    func getAccountInfo(email: String) async throws -> AccountInfoResponse {
        try await getAccountInfoTyped(email: email)
    }

    func search(query: String, options: [String: String]) async throws -> SearchResponse {
        try await searchTyped(query: query, options: options)
    }

    func getCollections(collection: String, resultType: String, limit: Int?) async throws -> (collection: String, results: [SearchResult]) {
        try await getCollectionsTyped(collection: collection, resultType: resultType, limit: limit)
    }

    func getMetadata(identifier: String) async throws -> ItemMetadataResponse {
        try await getMetaDataTyped(identifier: identifier)
    }

    func getFavoriteItems(username: String) async throws -> FavoritesResponse {
        try await getFavoriteItemsTyped(username: username)
    }
}
