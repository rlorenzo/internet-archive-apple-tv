//
//  MockNetworkService.swift
//  Internet ArchiveTests
//
//  Mock network service for testing
//

import Foundation
@testable import Internet_Archive

/// Mock network service for testing
@MainActor
final class MockNetworkService: NetworkServiceProtocol {

    // MARK: - Mock Configuration

    var shouldThrowError = false
    var errorToThrow: Error = NetworkError.unknown(nil)

    // MARK: - Recorded Calls

    var registerCalled = false
    var loginCalled = false
    var searchCalled = false
    var getCollectionsCalled = false
    var getMetadataCalled = false
    var getFavoritesCalled = false

    // MARK: - Mock Responses

    var mockAuthResponse: AuthResponse?
    var mockAccountInfoResponse: AccountInfoResponse?
    var mockSearchResponse: SearchResponse?
    var mockCollectionsResponse: (collection: String, results: [SearchResult])?
    var mockMetadataResponse: ItemMetadataResponse?
    var mockFavoritesResponse: FavoritesResponse?
    var getAccountInfoCalled = false

    // MARK: - NetworkServiceProtocol Implementation

    func register(params: [String: Any]) async throws -> AuthResponse {
        registerCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        guard let response = mockAuthResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        loginCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        guard let response = mockAuthResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

    func getAccountInfo(email: String) async throws -> AccountInfoResponse {
        getAccountInfoCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        guard let response = mockAccountInfoResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

    func search(query: String, options: [String: String]) async throws -> SearchResponse {
        searchCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        guard let response = mockSearchResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

    func getCollections(collection: String, resultType: String, limit: Int?) async throws -> (collection: String, results: [SearchResult]) {
        getCollectionsCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        guard let response = mockCollectionsResponse else {
            return (collection, [])
        }

        return response
    }

    func getMetadata(identifier: String) async throws -> ItemMetadataResponse {
        getMetadataCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        guard let response = mockMetadataResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

    func getFavoriteItems(username: String) async throws -> FavoritesResponse {
        getFavoritesCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        guard let response = mockFavoritesResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

}
