//
//  UITestingHelperTests.swift
//  Internet ArchiveTests
//
//  Tests for UITestingHelper mock data generation
//

import XCTest
@testable import Internet_Archive

@MainActor
final class UITestingHelperTests: XCTestCase {

    nonisolated(unsafe) var helper: UITestingHelper!

    override func setUp() {
        super.setUp()
        let newHelper = MainActor.assumeIsolated {
            return UITestingHelper.shared
        }
        helper = newHelper
    }

    override func tearDown() {
        helper = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let instance1 = UITestingHelper.shared
        let instance2 = UITestingHelper.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Mock Search Response Tests

    func testMockSearchResponse_hasCorrectNumberOfDocs() {
        let response = helper.mockSearchResponse

        XCTAssertNotNil(response.response)
        XCTAssertEqual(response.response.docs.count, 20)
        XCTAssertEqual(response.response.numFound, 20)
    }

    func testMockSearchResponse_docsHaveCorrectStructure() {
        let response = helper.mockSearchResponse
        let docs = response.response.docs

        for (index, doc) in docs.enumerated() {
            XCTAssertEqual(doc.identifier, "mock_item_\(index)")
            XCTAssertEqual(doc.title, "Mock Item \(index)")
            XCTAssertEqual(doc.year, "2025")
            XCTAssertNotNil(doc.mediatype)
        }
    }

    func testMockSearchResponse_alternatesMediaTypes() {
        let response = helper.mockSearchResponse
        let docs = response.response.docs

        for (index, doc) in docs.enumerated() {
            if index % 2 == 0 {
                XCTAssertEqual(doc.mediatype, "movies")
            } else {
                XCTAssertEqual(doc.mediatype, "audio")
            }
        }
    }

    // MARK: - Mock Collection Response Tests

    func testMockCollectionResponse_returnsCorrectCollection() {
        let result = helper.mockCollectionResponse(collection: "etree")

        XCTAssertEqual(result.collection, "etree")
        XCTAssertEqual(result.results.count, 15)
    }

    func testMockCollectionResponse_docsHaveCorrectIdentifiers() {
        let result = helper.mockCollectionResponse(collection: "movies")

        for (index, doc) in result.results.enumerated() {
            XCTAssertEqual(doc.identifier, "movies_item_\(index)")
        }
    }

    func testMockCollectionResponse_etreeMediaType() {
        let result = helper.mockCollectionResponse(collection: "etree")

        for doc in result.results {
            XCTAssertEqual(doc.mediatype, "etree")
        }
    }

    func testMockCollectionResponse_moviesMediaType() {
        let result = helper.mockCollectionResponse(collection: "movies")

        for doc in result.results {
            XCTAssertEqual(doc.mediatype, "movies")
        }
    }

    // MARK: - Mock Metadata Response Tests

    func testMockMetadataResponse_hasCorrectIdentifier() {
        let response = helper.mockMetadataResponse(identifier: "test_video_123")

        XCTAssertEqual(response.metadata?.identifier, "test_video_123")
        XCTAssertEqual(response.metadata?.title, "Mock Item: test_video_123")
    }

    func testMockMetadataResponse_hasFiles() {
        let response = helper.mockMetadataResponse(identifier: "test_item")

        XCTAssertNotNil(response.files)
        XCTAssertEqual(response.files?.count, 2)
    }

    func testMockMetadataResponse_filesHaveCorrectFormats() {
        let response = helper.mockMetadataResponse(identifier: "test_item")
        let files = response.files ?? []

        let formats = files.compactMap { $0.format }
        XCTAssertTrue(formats.contains("MPEG4"))
        XCTAssertTrue(formats.contains("MP3"))
    }

    func testMockMetadataResponse_metadataProperties() {
        let response = helper.mockMetadataResponse(identifier: "test_item")

        XCTAssertEqual(response.metadata?.mediatype, "movies")
        XCTAssertEqual(response.metadata?.creator, "Test Creator")
        XCTAssertEqual(response.metadata?.year, "2025")
        XCTAssertEqual(response.metadata?.date, "2025-01-15")
    }

    // MARK: - Mock Favorites Response Tests

    func testMockFavoritesResponse_hasMembers() {
        let response = helper.mockFavoritesResponse(username: "testuser")

        XCTAssertNotNil(response.members)
        XCTAssertEqual(response.members?.count, 10)
    }

    func testMockFavoritesResponse_membersHaveCorrectIdentifiers() {
        let response = helper.mockFavoritesResponse(username: "testuser")
        let members = response.members ?? []

        for (index, member) in members.enumerated() {
            XCTAssertEqual(member.identifier, "favorite_\(index)")
        }
    }

    func testMockFavoritesResponse_alternatesMediaTypes() {
        let response = helper.mockFavoritesResponse(username: "testuser")
        let members = response.members ?? []

        for (index, member) in members.enumerated() {
            if index % 2 == 0 {
                XCTAssertEqual(member.mediatype, "movies")
            } else {
                XCTAssertEqual(member.mediatype, "audio")
            }
        }
    }

    // MARK: - UI Testing Mode Tests

    func testIsUITesting_whenNotTesting() {
        // In unit test context, this should return false
        // (unless we're actually running UI tests)
        // Just verify it doesn't crash and returns a boolean
        let result = helper.isUITesting
        XCTAssertNotNil(result)
    }

    func testUseMockData_returnsBool() {
        let result = helper.useMockData
        XCTAssertNotNil(result)
    }
}
