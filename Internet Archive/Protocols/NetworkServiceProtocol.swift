//
//  NetworkServiceProtocol.swift
//  Internet Archive
//
//  Protocol-based dependency injection for networking layer
//

import Foundation

/// Protocol defining the network service interface for dependency injection
@MainActor
protocol NetworkServiceProtocol {
    // MARK: - Authentication

    func register(params: [String: Any]) async throws -> AuthResponse
    func login(email: String, password: String) async throws -> AuthResponse
    func getAccountInfo(email: String) async throws -> AccountInfoResponse

    // MARK: - Search & Collections

    func search(query: String, options: [String: String]) async throws -> SearchResponse
    func getCollections(collection: String, resultType: String, limit: Int?) async throws -> (collection: String, results: [SearchResult])

    // MARK: - Metadata

    func getMetadata(identifier: String) async throws -> ItemMetadataResponse

    // MARK: - Favorites

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
