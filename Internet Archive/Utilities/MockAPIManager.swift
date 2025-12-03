//
//  MockAPIManager.swift
//  Internet Archive
//
//  Mock API Manager for UI testing - returns predefined mock data
//

import Foundation

/// Mock API Manager that returns predefined data for UI testing
/// This allows UI tests to run without network dependencies
@MainActor
final class MockAPIManager: NetworkServiceProtocol {

    // MARK: - Singleton

    static let shared = MockAPIManager()

    // MARK: - Properties

    private let helper = UITestingHelper.shared

    // MARK: - NetworkServiceProtocol Implementation

    func register(params: [String: Any]) async throws -> AuthResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        return AuthResponse(
            success: true,
            values: AuthResponse.AuthValues(
                email: params["email"] as? String ?? "test@example.com",
                itemname: "@testuser",
                screenname: params["screenname"] as? String ?? "TestUser"
            )
        )
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        try await Task.sleep(nanoseconds: 500_000_000)

        // Simulate login failure for specific test case
        if email == "fail@test.com" {
            throw NetworkError.invalidCredentials
        }

        return AuthResponse(
            success: true,
            values: AuthResponse.AuthValues(
                email: email,
                itemname: "@testuser",
                screenname: "TestUser"
            )
        )
    }

    func getAccountInfo(email: String) async throws -> AccountInfoResponse {
        try await Task.sleep(nanoseconds: 300_000_000)

        return AccountInfoResponse(
            success: true,
            values: AccountInfoResponse.AccountValues(
                email: email,
                screenname: "TestUser",
                verified: true
            )
        )
    }

    func search(query: String, options: [String: String]) async throws -> SearchResponse {
        try await Task.sleep(nanoseconds: 800_000_000)

        return helper.mockSearchResponse
    }

    func getCollections(collection: String, resultType: String, limit: Int?) async throws -> (collection: String, results: [SearchResult]) {
        try await Task.sleep(nanoseconds: 800_000_000)

        return helper.mockCollectionResponse(collection: collection)
    }

    func getMetadata(identifier: String) async throws -> ItemMetadataResponse {
        try await Task.sleep(nanoseconds: 600_000_000)

        return helper.mockMetadataResponse(identifier: identifier)
    }

    func getFavoriteItems(username: String) async throws -> FavoritesResponse {
        try await Task.sleep(nanoseconds: 500_000_000)

        return helper.mockFavoritesResponse(username: username)
    }

    // MARK: - Initialization

    private init() {}
}
