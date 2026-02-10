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

    // MARK: - Hashable Tests

    func testSearchResultHashable_equalityByIdentifier() {
        let result1 = SearchResult(identifier: "test_001", title: "Title 1", mediatype: "movies")
        let result2 = SearchResult(identifier: "test_001", title: "Different Title", mediatype: "audio")
        let result3 = SearchResult(identifier: "test_002", title: "Title 1", mediatype: "movies")

        // Same identifier = equal, regardless of other properties
        XCTAssertEqual(result1, result2)
        // Different identifier = not equal
        XCTAssertNotEqual(result1, result3)
    }

    func testSearchResultHashable_hashValueConsistency() {
        let result1 = SearchResult(identifier: "test_001", title: "Title 1")
        let result2 = SearchResult(identifier: "test_001", title: "Title 2")

        // Equal objects must have equal hash values
        XCTAssertEqual(result1.hashValue, result2.hashValue)
    }

    func testSearchResultHashable_setBehavior() {
        let result1 = SearchResult(identifier: "test_001", title: "Title 1")
        let result2 = SearchResult(identifier: "test_001", title: "Title 2")
        let result3 = SearchResult(identifier: "test_002", title: "Title 3")

        var set: Set<SearchResult> = []
        set.insert(result1)
        set.insert(result2) // Same identifier, should not increase count
        set.insert(result3)

        XCTAssertEqual(set.count, 2)
        XCTAssertTrue(set.contains(result1))
        XCTAssertTrue(set.contains(result3))
    }

    func testSearchResultHashable_dictionaryKey() {
        let result1 = SearchResult(identifier: "test_001", title: "Title 1")
        let result2 = SearchResult(identifier: "test_001", title: "Different")

        var dict: [SearchResult: String] = [:]
        dict[result1] = "First"
        dict[result2] = "Second" // Same identifier, should overwrite

        XCTAssertEqual(dict.count, 1)
        XCTAssertEqual(dict[result1], "Second")
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

    // MARK: - Additional SearchResult Tests

    func testSearchResultToDictionary() {
        let result = TestFixtures.movieSearchResult
        let dict = result.toDictionary()

        XCTAssertEqual(dict["identifier"] as? String, "test_movie_001")
        XCTAssertEqual(dict["title"] as? String, "Test Movie")
        XCTAssertEqual(dict["mediatype"] as? String, "movies")
        XCTAssertEqual(dict["creator"] as? String, "Test Creator")
        XCTAssertEqual(dict["description"] as? String, "A test movie for unit testing")
        XCTAssertEqual(dict["date"] as? String, "2025-01-01")
        XCTAssertEqual(dict["year"] as? String, "2025")
        XCTAssertEqual(dict["downloads"] as? Int, 1000)
        XCTAssertEqual(dict["subject"] as? [String], ["test", "movies"])
        XCTAssertEqual(dict["collection"] as? [String], ["test_collection"])
    }

    func testSearchResultToDictionaryOmitsNilValues() {
        let result = SearchResult(identifier: "minimal")
        let dict = result.toDictionary()

        XCTAssertEqual(dict["identifier"] as? String, "minimal")
        XCTAssertNil(dict["title"])
        XCTAssertNil(dict["mediatype"])
        XCTAssertNil(dict["creator"])
    }

    func testSearchResultMemberwiseInit() {
        let result = SearchResult(
            identifier: "test_id",
            title: "My Title",
            mediatype: "audio",
            creator: "Artist Name",
            downloads: 500
        )

        XCTAssertEqual(result.identifier, "test_id")
        XCTAssertEqual(result.title, "My Title")
        XCTAssertEqual(result.mediatype, "audio")
        XCTAssertEqual(result.creator, "Artist Name")
        XCTAssertEqual(result.downloads, 500)
        XCTAssertNil(result.date)
        XCTAssertNil(result.year)
    }

    func testSearchResultWithAllNilOptionals() {
        let result = SearchResult(identifier: "only_id")

        XCTAssertEqual(result.identifier, "only_id")
        XCTAssertNil(result.title)
        XCTAssertNil(result.mediatype)
        XCTAssertNil(result.creator)
        XCTAssertNil(result.description)
        XCTAssertNil(result.date)
        XCTAssertNil(result.year)
        XCTAssertNil(result.downloads)
        XCTAssertNil(result.subject)
        XCTAssertNil(result.collection)
    }

    func testSearchResponseMemberwiseInit() {
        let results = [
            SearchResult(identifier: "item1", title: "Item 1"),
            SearchResult(identifier: "item2", title: "Item 2")
        ]
        let header = SearchResponse.ResponseHeader(status: 0, QTime: 5)
        let searchResults = SearchResponse.SearchResults(numFound: 2, start: 0, docs: results)
        let response = SearchResponse(responseHeader: header, response: searchResults)

        XCTAssertEqual(response.responseHeader?.status, 0)
        XCTAssertEqual(response.responseHeader?.QTime, 5)
        XCTAssertEqual(response.response.numFound, 2)
        XCTAssertEqual(response.response.start, 0)
        XCTAssertEqual(response.response.docs.count, 2)
    }

    func testResponseHeaderDecoding() throws {
        let json = """
        {
            "status": 0,
            "QTime": 15
        }
        """

        let data = json.data(using: .utf8)!
        let header = try JSONDecoder().decode(SearchResponse.ResponseHeader.self, from: data)

        XCTAssertEqual(header.status, 0)
        XCTAssertEqual(header.QTime, 15)
    }

    // MARK: - TestFixtures Integration

    func testSearchResponseFromFixtures() {
        let response = TestFixtures.searchResponse

        XCTAssertEqual(response.responseHeader?.status, 0)
        XCTAssertEqual(response.response.numFound, 2)
        XCTAssertEqual(response.response.docs.count, 2)
        XCTAssertEqual(response.response.docs[0].identifier, "test_movie_001")
        XCTAssertEqual(response.response.docs[1].identifier, "test_audio_001")
    }

    func testMakeSearchResultHelper() {
        let result = TestFixtures.makeSearchResult(
            identifier: "custom_id",
            title: "Custom Title",
            mediatype: "texts"
        )

        XCTAssertEqual(result.identifier, "custom_id")
        XCTAssertEqual(result.title, "Custom Title")
        XCTAssertEqual(result.mediatype, "texts")
        XCTAssertEqual(result.creator, "Test Creator")
    }

    func testMakeSearchResponseHelper() {
        let results = [
            TestFixtures.makeSearchResult(identifier: "r1"),
            TestFixtures.makeSearchResult(identifier: "r2"),
            TestFixtures.makeSearchResult(identifier: "r3")
        ]
        let response = TestFixtures.makeSearchResponse(numFound: 100, docs: results)

        XCTAssertEqual(response.response.numFound, 100)
        XCTAssertEqual(response.response.docs.count, 3)
    }
}
