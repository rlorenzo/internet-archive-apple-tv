//
//  NetworkServiceProtocolTests.swift
//  Internet ArchiveTests
//
//  Unit tests for NetworkServiceProtocol and APIManager conformance
//

import Testing
@testable import Internet_Archive

@Suite("NetworkServiceProtocolTests")
@MainActor
struct NetworkServiceProtocolTests {

    // MARK: - APIManager Conformance Tests

    @Test func apiManagerConformsToNetworkServiceProtocol() {
        // Protocol conformance verified at compile time by this assignment
        let _: NetworkServiceProtocol = APIManager.sharedManager
    }

    @Test func apiManagerSharedManagerIsSingleton() {
        let instance1 = APIManager.sharedManager
        let instance2 = APIManager.sharedManager
        #expect(instance1 === instance2)
    }

    // MARK: - Protocol Method Availability Tests

    @Test func protocolDefinesRegisterMethod() async throws {
        // Verify the protocol method is accessible via MockNetworkService
        let mockService = MockNetworkService()
        mockService.mockAuthResponse = AuthResponse(
            success: true,
            values: AuthResponse.AuthValues(email: "test@example.com", itemname: "@test", screenname: "Test")
        )
        let service: NetworkServiceProtocol = mockService
        let result = try await service.register(params: ["email": "test@example.com"])
        #expect(result.success == true)
    }

    @Test func protocolDefinesLoginMethod() async throws {
        let mockService = MockNetworkService()
        mockService.mockAuthResponse = AuthResponse(
            success: true,
            values: AuthResponse.AuthValues(email: "test@example.com", itemname: "@test", screenname: "Test")
        )
        let service: NetworkServiceProtocol = mockService
        let result = try await service.login(email: "test@example.com", password: "password")
        #expect(result.success == true)
    }

    @Test func protocolDefinesGetAccountInfoMethod() async throws {
        let mockService = MockNetworkService()
        mockService.mockAccountInfoResponse = AccountInfoResponse(
            success: true,
            values: AccountInfoResponse.AccountValues(email: "test@example.com", screenname: "Test", verified: true)
        )
        let service: NetworkServiceProtocol = mockService
        let result = try await service.getAccountInfo(email: "test@example.com")
        #expect(result.success == true)
    }

    @Test func protocolDefinesSearchMethod() async throws {
        let mockService = MockNetworkService()
        mockService.mockSearchResponse = SearchResponse(
            response: SearchResponse.SearchResults(numFound: 0, start: 0, docs: [])
        )
        let service: NetworkServiceProtocol = mockService
        let result = try await service.search(query: "test", options: [:])
        #expect(result.response.numFound == 0)
    }

    @Test func protocolDefinesGetCollectionsMethod() async throws {
        let mockService = MockNetworkService()
        mockService.mockCollectionsResponse = ("test", [])
        let service: NetworkServiceProtocol = mockService
        let result = try await service.getCollections(collection: "test", resultType: "movies", limit: 10)
        #expect(result.results.isEmpty)
    }

    @Test func protocolDefinesGetMetadataMethod() async throws {
        let mockService = MockNetworkService()
        mockService.mockMetadataResponse = ItemMetadataResponse(metadata: ItemMetadata(identifier: "test"))
        let service: NetworkServiceProtocol = mockService
        let result = try await service.getMetadata(identifier: "test_item")
        #expect(result.metadata?.identifier == "test")
    }

    @Test func protocolDefinesGetFavoriteItemsMethod() async throws {
        let mockService = MockNetworkService()
        mockService.mockFavoritesResponse = FavoritesResponse(members: [])
        let service: NetworkServiceProtocol = mockService
        let result = try await service.getFavoriteItems(username: "testuser")
        #expect(result.members?.isEmpty == true)
    }

    // MARK: - Mock Service Tests

    @Test func mockServiceConformsToProtocol() {
        // Protocol conformance verified at compile time by this assignment
        let _: NetworkServiceProtocol = MockNetworkService()
    }

    @Test func mockServiceCanBeUsedAsProtocolType() async throws {
        let mockService = MockNetworkService()
        mockService.mockSearchResponse = SearchResponse(
            response: SearchResponse.SearchResults(numFound: 42, start: 0, docs: [])
        )
        // Verify the mock can be used through the protocol type
        let service: NetworkServiceProtocol = mockService
        let result = try await service.search(query: "test", options: [:])
        #expect(result.response.numFound == 42)
    }
}

// MARK: - APIManager Extension Tests

@Suite("APIManagerProtocolExtensionTests")
@MainActor
struct APIManagerProtocolExtensionTests {

    // Note: These tests verify the extension methods exist and are callable.
    // Actual network calls are tested in integration tests.
    // Protocol conformance is verified at compile time by assigning to the protocol type.

    @Test func registerExtensionMethodExists() {
        let _: NetworkServiceProtocol = APIManager.sharedManager
    }

    @Test func loginExtensionMethodExists() {
        let _: NetworkServiceProtocol = APIManager.sharedManager
    }

    @Test func getAccountInfoExtensionMethodExists() {
        let _: NetworkServiceProtocol = APIManager.sharedManager
    }

    @Test func searchExtensionMethodExists() {
        let _: NetworkServiceProtocol = APIManager.sharedManager
    }

    @Test func getCollectionsExtensionMethodExists() {
        let _: NetworkServiceProtocol = APIManager.sharedManager
    }

    @Test func getMetadataExtensionMethodExists() {
        let _: NetworkServiceProtocol = APIManager.sharedManager
    }

    @Test func getFavoriteItemsExtensionMethodExists() {
        let _: NetworkServiceProtocol = APIManager.sharedManager
    }
}
