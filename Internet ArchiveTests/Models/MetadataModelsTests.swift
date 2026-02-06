//
//  MetadataModelsTests.swift
//  Internet ArchiveTests
//
//  Unit tests for metadata data models
//

import Testing
import Foundation
@testable import Internet_Archive

@Suite("MetadataModels Tests")
struct MetadataModelsTests {

    // MARK: - ItemMetadataResponse Tests

    @Test func itemMetadataResponseDecoding() throws {
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

        let data = try #require(json.data(using: .utf8))
        let response = try JSONDecoder().decode(ItemMetadataResponse.self, from: data)

        #expect(response.created == 1704067200)
        #expect(response.d1 == "ia123456.us.archive.org")
        #expect(response.d2 == "ia234567.us.archive.org")
        #expect(response.dir == "/1/items/test_item")
        #expect(response.filesCount == 5)
        #expect(response.itemSize == 1000000)
        #expect(response.server == "ia123456.us.archive.org")
        #expect(response.uniq == 12345)
        #expect(response.workableServers?.count == 2)
        #expect(response.metadata?.identifier == "test_item")
        #expect(response.files?.count == 1)
    }

    @Test func itemMetadataResponseMemberwiseInit() {
        let response = ItemMetadataResponse(
            created: 1234567890,
            d1: "server1.archive.org",
            files: [FileInfo(name: "test.mp4")],
            filesCount: 1,
            server: "server1.archive.org"
        )

        #expect(response.created == 1234567890)
        #expect(response.d1 == "server1.archive.org")
        #expect(response.files?.count == 1)
        #expect(response.filesCount == 1)
    }

    // MARK: - ItemMetadata Tests

    @Test func itemMetadataDecoding() throws {
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

        let data = try #require(json.data(using: .utf8))
        let metadata = try JSONDecoder().decode(ItemMetadata.self, from: data)

        #expect(metadata.identifier == "test_item_001")
        #expect(metadata.title == "Test Movie")
        #expect(metadata.mediatype == "movies")
        #expect(metadata.creator == "Test Director")
        #expect(metadata.description == "A great movie")
        #expect(metadata.date == "2025-01-01")
        #expect(metadata.year == "2025")
        #expect(metadata.uploader == "test_uploader")
    }

    @Test func itemMetadataMemberwiseInit() {
        let metadata = ItemMetadata(
            identifier: "test",
            title: "Test Title",
            mediatype: "audio",
            creator: "Test Creator"
        )

        #expect(metadata.identifier == "test")
        #expect(metadata.title == "Test Title")
        #expect(metadata.mediatype == "audio")
        #expect(metadata.creator == "Test Creator")
        #expect(metadata.subject == nil)
        #expect(metadata.collection == nil)
    }

    // MARK: - SubjectValue Tests

    @Test func subjectValueAsString() throws {
        let json = """
        {
            "identifier": "test",
            "subject": "single_subject"
        }
        """

        let data = try #require(json.data(using: .utf8))
        let metadata = try JSONDecoder().decode(ItemMetadata.self, from: data)

        #expect(metadata.subject?.asArray == ["single_subject"])
    }

    @Test func subjectValueAsArray() throws {
        let json = """
        {
            "identifier": "test",
            "subject": ["subject1", "subject2", "subject3"]
        }
        """

        let data = try #require(json.data(using: .utf8))
        let metadata = try JSONDecoder().decode(ItemMetadata.self, from: data)

        #expect(metadata.subject?.asArray == ["subject1", "subject2", "subject3"])
    }

    @Test func subjectValueAsArrayComputedFromString() {
        let subjectValue = ItemMetadata.SubjectValue.string("test_subject")
        #expect(subjectValue.asArray == ["test_subject"])
    }

    @Test func subjectValueAsArrayComputedFromArray() {
        let subjectValue = ItemMetadata.SubjectValue.array(["a", "b", "c"])
        #expect(subjectValue.asArray == ["a", "b", "c"])
    }

    @Test func subjectValueEncoding() throws {
        let metadata = ItemMetadata(
            identifier: "test",
            subject: .array(["tag1", "tag2"])
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)
        let decoded = try JSONDecoder().decode(ItemMetadata.self, from: data)

        #expect(decoded.subject?.asArray == ["tag1", "tag2"])
    }

    // MARK: - CollectionValue Tests

    @Test func collectionValueAsString() throws {
        let json = """
        {
            "identifier": "test",
            "collection": "single_collection"
        }
        """

        let data = try #require(json.data(using: .utf8))
        let metadata = try JSONDecoder().decode(ItemMetadata.self, from: data)

        #expect(metadata.collection?.asArray == ["single_collection"])
    }

    @Test func collectionValueAsArray() throws {
        let json = """
        {
            "identifier": "test",
            "collection": ["collection1", "collection2"]
        }
        """

        let data = try #require(json.data(using: .utf8))
        let metadata = try JSONDecoder().decode(ItemMetadata.self, from: data)

        #expect(metadata.collection?.asArray == ["collection1", "collection2"])
    }

    // MARK: - FileInfo Tests

    @Test func fileInfoDecoding() throws {
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

        let data = try #require(json.data(using: .utf8))
        let fileInfo = try JSONDecoder().decode(FileInfo.self, from: data)

        #expect(fileInfo.name == "movie.mp4")
        #expect(fileInfo.source == "original")
        #expect(fileInfo.format == "MPEG4")
        #expect(fileInfo.size == "1000000")
        #expect(fileInfo.md5 == "abc123")
        #expect(fileInfo.crc32 == "def456")
        #expect(fileInfo.sha1 == "ghi789")
        #expect(fileInfo.mtime == "1704067200")
        #expect(fileInfo.length == "3600.5")
        #expect(fileInfo.height == "1080")
        #expect(fileInfo.width == "1920")
    }

    @Test func fileInfoMemberwiseInit() {
        let fileInfo = FileInfo(
            name: "test.mp4",
            source: "derivative",
            format: "h.264",
            size: "500000",
            length: "1800"
        )

        #expect(fileInfo.name == "test.mp4")
        #expect(fileInfo.source == "derivative")
        #expect(fileInfo.format == "h.264")
        #expect(fileInfo.size == "500000")
        #expect(fileInfo.length == "1800")
        #expect(fileInfo.md5 == nil)
        #expect(fileInfo.height == nil)
    }

    @Test func fileInfoSizeInBytes() {
        let fileInfo = FileInfo(name: "test.mp4", size: "1234567890")
        #expect(fileInfo.sizeInBytes == 1234567890)

        let fileInfoNoSize = FileInfo(name: "test.mp4")
        #expect(fileInfoNoSize.sizeInBytes == nil)

        let fileInfoInvalidSize = FileInfo(name: "test.mp4", size: "invalid")
        #expect(fileInfoInvalidSize.sizeInBytes == nil)
    }

    @Test func fileInfoDurationInSeconds() {
        let fileInfo = FileInfo(name: "test.mp4", length: "3600.5")
        #expect(fileInfo.durationInSeconds != nil)
        if let duration = fileInfo.durationInSeconds {
            #expect(abs(duration - 3600.5) < 0.01)
        }

        let fileInfoNoLength = FileInfo(name: "test.mp4")
        #expect(fileInfoNoLength.durationInSeconds == nil)

        let fileInfoInvalidLength = FileInfo(name: "test.mp4", length: "invalid")
        #expect(fileInfoInvalidLength.durationInSeconds == nil)
    }

    @Test func fileInfoToDictionary() {
        let fileInfo = TestFixtures.fileInfo
        let dict = fileInfo.toDictionary()

        #expect(dict["name"] as? String == "test_file.mp4")
        #expect(dict["source"] as? String == "original")
        #expect(dict["format"] as? String == "MPEG4")
        #expect(dict["size"] as? String == "1000000")
    }

    @Test func fileInfoToDictionaryOmitsNilValues() {
        let fileInfo = FileInfo(name: "minimal.mp4")
        let dict = fileInfo.toDictionary()

        #expect(dict["name"] as? String == "minimal.mp4")
        #expect(dict["source"] == nil)
        #expect(dict["format"] == nil)
        #expect(dict["size"] == nil)
        #expect(dict["md5"] == nil)
    }

    // MARK: - Integration Test with TestFixtures

    @Test func itemMetadataResponseFromFixtures() {
        let response = TestFixtures.itemMetadataResponse

        #expect(response.files != nil)
        #expect(response.files?.count == 1)
        #expect(response.files?.first?.name == "test_file.mp4")

        #expect(response.metadata != nil)
        #expect(response.metadata?.identifier == "test_item_001")
        #expect(response.metadata?.title == "Test Item")
        #expect(response.metadata?.mediatype == "movies")
    }
}
