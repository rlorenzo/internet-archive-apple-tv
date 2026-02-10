//
//  MockFavoritesService.swift
//  Internet ArchiveTests
//
//  Mock favorites service for testing FavoritesViewModel and related code
//

import Foundation
@testable import Internet_Archive

/// Mock implementation of `FavoritesServiceProtocol` for testing.
///
/// Provides configurable responses, error injection, and call tracking
/// for testing favorites-related view models and services.
///
/// ## Example Usage
///
/// ```swift
/// let mockService = MockFavoritesService()
/// mockService.mockResponse = FavoritesResponse(members: [testItem])
/// let viewModel = FavoritesViewModel(service: mockService)
/// ```
final class MockFavoritesService: FavoritesServiceProtocol, @unchecked Sendable {

    // MARK: - Call Tracking

    var getFavoriteItemsCalled = false
    var lastUsername: String?

    // MARK: - Mock Configuration

    var mockResponse: FavoritesResponse?
    var errorToThrow: Error?

    // MARK: - FavoritesServiceProtocol

    func getFavoriteItems(username: String) async throws -> FavoritesResponse {
        getFavoriteItemsCalled = true
        lastUsername = username

        if let error = errorToThrow {
            throw error
        }

        guard let response = mockResponse else {
            throw NetworkError.invalidResponse
        }

        return response
    }

    // MARK: - Helper Methods

    func reset() {
        getFavoriteItemsCalled = false
        lastUsername = nil
        mockResponse = nil
        errorToThrow = nil
    }
}
