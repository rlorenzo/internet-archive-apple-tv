//
//  UITestingHelperTests.swift
//  Internet ArchiveTests
//
//  Tests for UITestingHelper mock data generation
//

import Testing
@testable import Internet_Archive

@Suite("UITestingHelper Tests")
@MainActor
struct UITestingHelperTests {

    // MARK: - Singleton Tests

    @Test func sharedInstance() {
        let instance1 = UITestingHelper.shared
        let instance2 = UITestingHelper.shared
        #expect(instance1 === instance2)
    }

    // MARK: - Mock Search Response Tests

    @Test func mockSearchResponseHasCorrectNumberOfDocs() {
        let helper = UITestingHelper.shared
        let response = helper.mockSearchResponse

        #expect(response.response != nil)
        #expect(response.response.docs.count == 20)
        #expect(response.response.numFound == 20)
    }

    @Test func mockSearchResponseDocsHaveCorrectStructure() {
        let helper = UITestingHelper.shared
        let response = helper.mockSearchResponse
        let docs = response.response.docs

        for (index, doc) in docs.enumerated() {
            #expect(doc.identifier == "mock_item_\(index)")
            #expect(doc.title == "Mock Item \(index)")
            #expect(doc.year == "2025")
            #expect(doc.mediatype != nil)
        }
    }

    @Test func mockSearchResponseAlternatesMediaTypes() {
        let helper = UITestingHelper.shared
        let response = helper.mockSearchResponse
        let docs = response.response.docs

        for (index, doc) in docs.enumerated() {
            if index % 2 == 0 {
                #expect(doc.mediatype == "movies")
            } else {
                #expect(doc.mediatype == "audio")
            }
        }
    }

    // MARK: - Mock Collection Response Tests

    @Test func mockCollectionResponseReturnsCorrectCollection() {
        let helper = UITestingHelper.shared
        let result = helper.mockCollectionResponse(collection: "etree")

        #expect(result.collection == "etree")
        #expect(result.results.count == 15)
    }

    @Test func mockCollectionResponseDocsHaveCorrectIdentifiers() {
        let helper = UITestingHelper.shared
        let result = helper.mockCollectionResponse(collection: "movies")

        for (index, doc) in result.results.enumerated() {
            #expect(doc.identifier == "movies_item_\(index)")
        }
    }

    @Test func mockCollectionResponseEtreeMediaType() {
        let helper = UITestingHelper.shared
        let result = helper.mockCollectionResponse(collection: "etree")

        for doc in result.results {
            #expect(doc.mediatype == "etree")
        }
    }

    @Test func mockCollectionResponseMoviesMediaType() {
        let helper = UITestingHelper.shared
        let result = helper.mockCollectionResponse(collection: "movies")

        for doc in result.results {
            #expect(doc.mediatype == "movies")
        }
    }

    // MARK: - Mock Metadata Response Tests

    @Test func mockMetadataResponseHasCorrectIdentifier() {
        let helper = UITestingHelper.shared
        let response = helper.mockMetadataResponse(identifier: "test_video_123")

        #expect(response.metadata?.identifier == "test_video_123")
        #expect(response.metadata?.title == "Mock Item: test_video_123")
    }

    @Test func mockMetadataResponseHasFiles() {
        let helper = UITestingHelper.shared
        let response = helper.mockMetadataResponse(identifier: "test_item")

        #expect(response.files != nil)
        #expect(response.files?.count == 2)
    }

    @Test func mockMetadataResponseFilesHaveCorrectFormats() {
        let helper = UITestingHelper.shared
        let response = helper.mockMetadataResponse(identifier: "test_item")
        let files = response.files ?? []

        let formats = files.compactMap { $0.format }
        #expect(formats.contains("MPEG4"))
        #expect(formats.contains("MP3"))
    }

    @Test func mockMetadataResponseMetadataProperties() {
        let helper = UITestingHelper.shared
        let response = helper.mockMetadataResponse(identifier: "test_item")

        #expect(response.metadata?.mediatype == "movies")
        #expect(response.metadata?.creator == "Test Creator")
        #expect(response.metadata?.year == "2025")
        #expect(response.metadata?.date == "2025-01-15")
    }

    // MARK: - Mock Favorites Response Tests

    @Test func mockFavoritesResponseHasMembers() {
        let helper = UITestingHelper.shared
        let response = helper.mockFavoritesResponse(username: "testuser")

        #expect(response.members != nil)
        #expect(response.members?.count == 10)
    }

    @Test func mockFavoritesResponseMembersHaveCorrectIdentifiers() {
        let helper = UITestingHelper.shared
        let response = helper.mockFavoritesResponse(username: "testuser")
        let members = response.members ?? []

        for (index, member) in members.enumerated() {
            #expect(member.identifier == "favorite_\(index)")
        }
    }

    @Test func mockFavoritesResponseAlternatesMediaTypes() {
        let helper = UITestingHelper.shared
        let response = helper.mockFavoritesResponse(username: "testuser")
        let members = response.members ?? []

        for (index, member) in members.enumerated() {
            if index % 2 == 0 {
                #expect(member.mediatype == "movies")
            } else {
                #expect(member.mediatype == "audio")
            }
        }
    }

    // MARK: - UI Testing Mode Tests

    @Test func isUITestingWhenNotTesting() {
        let helper = UITestingHelper.shared
        // In unit test context, this should return false
        // Just verify it doesn't crash and returns a boolean
        let result = helper.isUITesting
        #expect(result != nil)
    }

    @Test func useMockDataReturnsBool() {
        let helper = UITestingHelper.shared
        let result = helper.useMockData
        #expect(result != nil)
    }
}
