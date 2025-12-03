//
//  MetadataModelsTests.swift
//  Internet ArchiveTests
//
//  Unit tests for metadata data models
//

import XCTest
@testable import Internet_Archive

final class MetadataModelsTests: XCTestCase {

    // MARK: - ItemMetadataResponse Tests

    func testItemMetadataResponseDecoding() throws {
        let json = """
        {
            "created": 1704067200,
            "d1": "ia123456.us.archive.org",
            "d2": "ia234567.us.archive.org",
            "dir": "/1/items/test_item",
            "files_count": 5,
            "item_size": 1000000,
            "server": "ia123456.us.archive.org",
            "uniq": 12345,
            "workable_servers": ["ia123456.us.archive.org", "ia234567.us.archive.org"],
            "metadata": {
                "identifier": "test_item",
                "title": "Test Item",
                "mediatype": "movies"
            },
            "files": [
                {
                    "name": "test.mp4",
                    "format": "MPEG4",
                    "size": "1000000"
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(ItemMetadataResponse.self, from: data)

        XCTAssertEqual(response.created, 1704067200)
        XCTAssertEqual(response.d1, "ia123456.us.archive.org")
        XCTAssertEqual(response.d2, "ia234567.us.archive.org")
        XCTAssertEqual(response.dir, "/1/items/test_item")
        XCTAssertEqual(response.filesCount, 5)
        XCTAssertEqual(response.itemSize, 1000000)
        XCTAssertEqual(response.server, "ia123456.us.archive.org")
        XCTAssertEqual(response.uniq, 12345)
        XCTAssertEqual(response.workableServers?.count, 2)
        XCTAssertEqual(response.metadata?.identifier, "test_item")
        XCTAssertEqual(response.files?.count, 1)
    }

    func testItemMetadataResponseMemberwiseInit() {
        let response = ItemMetadataResponse(
            created: 1234567890,
            d1: "server1.archive.org",
            files: [FileInfo(name: "test.mp4")],
            filesCount: 1,
            server: "server1.archive.org"
        )

        XCTAssertEqual(response.created, 1234567890)
        XCTAssertEqual(response.d1, "server1.archive.org")
        XCTAssertEqual(response.files?.count, 1)
        XCTAssertEqual(response.filesCount, 1)
    }

    // MARK: - ItemMetadata Tests

    func testItemMetadataDecoding() throws {
        let json = """
        {
            "identifier": "test_item_001",
            "title": "Test Movie",
            "mediatype": "movies",
            "creator": "Test Director",
            "description": "A great movie",
            "date": "2025-01-01",
            "year": "2025",
            "publicdate": "2025-01-01T00:00:00Z",
            "addeddate": "2025-01-01T00:00:00Z",
            "uploader": "test_uploader"
        }
        """

        let data = json.data(using: .utf8)!
        let metadata = try JSONDecoder().decode(ItemMetadata.self, from: data)

        XCTAssertEqual(metadata.identifier, "test_item_001")
        XCTAssertEqual(metadata.title, "Test Movie")
        XCTAssertEqual(metadata.mediatype, "movies")
        XCTAssertEqual(metadata.creator, "Test Director")
        XCTAssertEqual(metadata.description, "A great movie")
        XCTAssertEqual(metadata.date, "2025-01-01")
        XCTAssertEqual(metadata.year, "2025")
        XCTAssertEqual(metadata.uploader, "test_uploader")
    }

    func testItemMetadataMemberwiseInit() {
        let metadata = ItemMetadata(
            identifier: "test",
            title: "Test Title",
            mediatype: "audio",
            creator: "Test Creator"
        )

        XCTAssertEqual(metadata.identifier, "test")
        XCTAssertEqual(metadata.title, "Test Title")
        XCTAssertEqual(metadata.mediatype, "audio")
        XCTAssertEqual(metadata.creator, "Test Creator")
        XCTAssertNil(metadata.subject)
        XCTAssertNil(metadata.collection)
    }

    // MARK: - SubjectValue Tests

    func testSubjectValueAsString() throws {
        let json = """
        {
            "identifier": "test",
            "subject": "single_subject"
        }
        """

        let data = json.data(using: .utf8)!
        let metadata = try JSONDecoder().decode(ItemMetadata.self, from: data)

        XCTAssertEqual(metadata.subject?.asArray, ["single_subject"])
    }

    func testSubjectValueAsArray() throws {
        let json = """
        {
            "identifier": "test",
            "subject": ["subject1", "subject2", "subject3"]
        }
        """

        let data = json.data(using: .utf8)!
        let metadata = try JSONDecoder().decode(ItemMetadata.self, from: data)

        XCTAssertEqual(metadata.subject?.asArray, ["subject1", "subject2", "subject3"])
    }

    func testSubjectValueAsArrayComputed_fromString() {
        let subjectValue = ItemMetadata.SubjectValue.string("test_subject")
        XCTAssertEqual(subjectValue.asArray, ["test_subject"])
    }

    func testSubjectValueAsArrayComputed_fromArray() {
        let subjectValue = ItemMetadata.SubjectValue.array(["a", "b", "c"])
        XCTAssertEqual(subjectValue.asArray, ["a", "b", "c"])
    }

    func testSubjectValueEncoding() throws {
        let metadata = ItemMetadata(
            identifier: "test",
            subject: .array(["tag1", "tag2"])
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)
        let decoded = try JSONDecoder().decode(ItemMetadata.self, from: data)

        XCTAssertEqual(decoded.subject?.asArray, ["tag1", "tag2"])
    }

    // MARK: - CollectionValue Tests

    func testCollectionValueAsString() throws {
        let json = """
        {
            "identifier": "test",
            "collection": "single_collection"
        }
        """

        let data = json.data(using: .utf8)!
        let metadata = try JSONDecoder().decode(ItemMetadata.self, from: data)

        XCTAssertEqual(metadata.collection?.asArray, ["single_collection"])
    }

    func testCollectionValueAsArray() throws {
        let json = """
        {
            "identifier": "test",
            "collection": ["collection1", "collection2"]
        }
        """

        let data = json.data(using: .utf8)!
        let metadata = try JSONDecoder().decode(ItemMetadata.self, from: data)

        XCTAssertEqual(metadata.collection?.asArray, ["collection1", "collection2"])
    }

    // MARK: - FileInfo Tests

    func testFileInfoDecoding() throws {
        let json = """
        {
            "name": "movie.mp4",
            "source": "original",
            "format": "MPEG4",
            "size": "1000000",
            "md5": "abc123",
            "crc32": "def456",
            "sha1": "ghi789",
            "mtime": "1704067200",
            "length": "3600.5",
            "height": "1080",
            "width": "1920"
        }
        """

        let data = json.data(using: .utf8)!
        let fileInfo = try JSONDecoder().decode(FileInfo.self, from: data)

        XCTAssertEqual(fileInfo.name, "movie.mp4")
        XCTAssertEqual(fileInfo.source, "original")
        XCTAssertEqual(fileInfo.format, "MPEG4")
        XCTAssertEqual(fileInfo.size, "1000000")
        XCTAssertEqual(fileInfo.md5, "abc123")
        XCTAssertEqual(fileInfo.crc32, "def456")
        XCTAssertEqual(fileInfo.sha1, "ghi789")
        XCTAssertEqual(fileInfo.mtime, "1704067200")
        XCTAssertEqual(fileInfo.length, "3600.5")
        XCTAssertEqual(fileInfo.height, "1080")
        XCTAssertEqual(fileInfo.width, "1920")
    }

    func testFileInfoMemberwiseInit() {
        let fileInfo = FileInfo(
            name: "test.mp4",
            source: "derivative",
            format: "h.264",
            size: "500000",
            length: "1800"
        )

        XCTAssertEqual(fileInfo.name, "test.mp4")
        XCTAssertEqual(fileInfo.source, "derivative")
        XCTAssertEqual(fileInfo.format, "h.264")
        XCTAssertEqual(fileInfo.size, "500000")
        XCTAssertEqual(fileInfo.length, "1800")
        XCTAssertNil(fileInfo.md5)
        XCTAssertNil(fileInfo.height)
    }

    func testFileInfoSizeInBytes() {
        let fileInfo = FileInfo(name: "test.mp4", size: "1234567890")
        XCTAssertEqual(fileInfo.sizeInBytes, 1234567890)

        let fileInfoNoSize = FileInfo(name: "test.mp4")
        XCTAssertNil(fileInfoNoSize.sizeInBytes)

        let fileInfoInvalidSize = FileInfo(name: "test.mp4", size: "invalid")
        XCTAssertNil(fileInfoInvalidSize.sizeInBytes)
    }

    func testFileInfoDurationInSeconds() {
        let fileInfo = FileInfo(name: "test.mp4", length: "3600.5")
        XCTAssertEqual(fileInfo.durationInSeconds ?? 0, 3600.5, accuracy: 0.01)

        let fileInfoNoLength = FileInfo(name: "test.mp4")
        XCTAssertNil(fileInfoNoLength.durationInSeconds)

        let fileInfoInvalidLength = FileInfo(name: "test.mp4", length: "invalid")
        XCTAssertNil(fileInfoInvalidLength.durationInSeconds)
    }

    func testFileInfoToDictionary() {
        let fileInfo = TestFixtures.fileInfo
        let dict = fileInfo.toDictionary()

        XCTAssertEqual(dict["name"] as? String, "test_file.mp4")
        XCTAssertEqual(dict["source"] as? String, "original")
        XCTAssertEqual(dict["format"] as? String, "MPEG4")
        XCTAssertEqual(dict["size"] as? String, "1000000")
    }

    func testFileInfoToDictionaryOmitsNilValues() {
        let fileInfo = FileInfo(name: "minimal.mp4")
        let dict = fileInfo.toDictionary()

        XCTAssertEqual(dict["name"] as? String, "minimal.mp4")
        XCTAssertNil(dict["source"])
        XCTAssertNil(dict["format"])
        XCTAssertNil(dict["size"])
        XCTAssertNil(dict["md5"])
    }

    // MARK: - Integration Test with TestFixtures

    func testItemMetadataResponseFromFixtures() {
        let response = TestFixtures.itemMetadataResponse

        XCTAssertNotNil(response.files)
        XCTAssertEqual(response.files?.count, 1)
        XCTAssertEqual(response.files?.first?.name, "test_file.mp4")

        XCTAssertNotNil(response.metadata)
        XCTAssertEqual(response.metadata?.identifier, "test_item_001")
        XCTAssertEqual(response.metadata?.title, "Test Item")
        XCTAssertEqual(response.metadata?.mediatype, "movies")
    }
}
