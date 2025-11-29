//
//  SearchModelsTests.swift
//  Internet ArchiveTests
//
//  Unit tests for search data models
//

import XCTest
@testable import Internet_Archive

final class SearchModelsTests: XCTestCase {

    // MARK: - SearchResult Tests

    func testSearchResultDecoding() throws {
        let json = """
        {
            "identifier": "test_001",
            "title": "Test Title",
            "mediatype": "movies",
            "creator": "Test Creator",
            "description": "Test description",
            "date": "2025-01-01",
            "year": "2025",
            "downloads": 1000,
            "subject": ["test", "movies"],
            "collection": ["test_collection"]
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let result = try decoder.decode(SearchResult.self, from: data)

        XCTAssertEqual(result.identifier, "test_001")
        XCTAssertEqual(result.title, "Test Title")
        XCTAssertEqual(result.mediatype, "movies")
        XCTAssertEqual(result.creator, "Test Creator")
        XCTAssertEqual(result.description, "Test description")
        XCTAssertEqual(result.date, "2025-01-01")
        XCTAssertEqual(result.year, "2025")
        XCTAssertEqual(result.downloads, 1000)
        XCTAssertEqual(result.subject, ["test", "movies"])
        XCTAssertEqual(result.collection, ["test_collection"])
    }

    func testSearchResultYearAsInteger() throws {
        let json = """
        {
            "identifier": "test_001",
            "title": "Test Title",
            "year": 2025
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let result = try decoder.decode(SearchResult.self, from: data)

        XCTAssertEqual(result.year, "2025")
    }

    func testSearchResultSafeMediaType() {
        let result = SearchResult(identifier: "test_001", title: "Test", mediatype: "movies")
        XCTAssertEqual(result.safeMediaType, "movies")

        let resultNoMedia = SearchResult(identifier: "test_002", title: "Test")
        XCTAssertEqual(resultNoMedia.safeMediaType, "unknown")
    }

    func testSearchResultSafeTitle() {
        let result = SearchResult(identifier: "test_001", title: "Test Title")
        XCTAssertEqual(result.safeTitle, "Test Title")

        let resultNoTitle = SearchResult(identifier: "test_002")
        XCTAssertEqual(resultNoTitle.safeTitle, "Untitled")
    }

    // MARK: - SearchResponse Tests

    func testSearchResponseDecoding() throws {
        let json = """
        {
            "responseHeader": {
                "status": 0,
                "QTime": 10
            },
            "response": {
                "numFound": 2,
                "start": 0,
                "docs": [
                    {
                        "identifier": "test_001",
                        "title": "Test 1",
                        "mediatype": "movies"
                    },
                    {
                        "identifier": "test_002",
                        "title": "Test 2",
                        "mediatype": "audio"
                    }
                ]
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SearchResponse.self, from: data)

        XCTAssertEqual(response.responseHeader?.status, 0)
        XCTAssertEqual(response.responseHeader?.QTime, 10)
        XCTAssertEqual(response.response.numFound, 2)
        XCTAssertEqual(response.response.start, 0)
        XCTAssertEqual(response.response.docs.count, 2)
        XCTAssertEqual(response.response.docs[0].identifier, "test_001")
        XCTAssertEqual(response.response.docs[1].identifier, "test_002")
    }

    func testSearchResponseWithEmptyResults() throws {
        let json = """
        {
            "response": {
                "numFound": 0,
                "start": 0,
                "docs": []
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(SearchResponse.self, from: data)

        XCTAssertEqual(response.response.numFound, 0)
        XCTAssertEqual(response.response.docs.count, 0)
    }
}
