//
//  MetadataModels.swift
//  Internet Archive
//
//  Created for Sprint 5: Data Models & Codable
//  Type-safe models for Internet Archive metadata API
//

import Foundation

/// Response from the Internet Archive metadata API
struct ItemMetadataResponse: Codable {
    let created: Int?
    let d1: String?
    let d2: String?
    let dir: String?
    let files: [FileInfo]?
    let filesCount: Int?
    let itemSize: Int?
    let metadata: ItemMetadata?
    let server: String?
    let uniq: Int?
    let workableServers: [String]?

    enum CodingKeys: String, CodingKey {
        case created, d1, d2, dir, files, metadata, server, uniq
        case filesCount = "files_count"
        case itemSize = "item_size"
        case workableServers = "workable_servers"
    }
}

/// Metadata information for an item
struct ItemMetadata: Codable {
    let identifier: String?
    let title: String?
    let mediatype: String?
    let creator: String?
    let description: String?
    let date: String?
    let year: String?
    let subject: SubjectValue?
    let collection: CollectionValue?
    let publicdate: String?
    let addeddate: String?
    let uploader: String?

    // Subject and collection can be either String or [String]
    enum SubjectValue: Codable {
        case string(String)
        case array([String])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self = .string(string)
            } else if let array = try? container.decode([String].self) {
                self = .array(array)
            } else {
                throw DecodingError.typeMismatch(
                    SubjectValue.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Expected String or [String]"
                    )
                )
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .array(let value):
                try container.encode(value)
            }
        }

        var asArray: [String] {
            switch self {
            case .string(let value):
                return [value]
            case .array(let value):
                return value
            }
        }
    }

    typealias CollectionValue = SubjectValue
}

/// File information from metadata
struct FileInfo: Codable {
    let name: String
    let source: String?
    let format: String?
    let original: String?
    let size: String?
    let md5: String?
    let crc32: String?
    let sha1: String?
    let mtime: String?
    let length: String?
    let height: String?
    let width: String?

    // Computed properties for type-safe access
    var sizeInBytes: Int64? {
        guard let size = size else { return nil }
        return Int64(size)
    }

    var durationInSeconds: Double? {
        guard let length = length else { return nil }
        return Double(length)
    }

    // Convert to dictionary for backward compatibility (temporary)
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["name": name]
        if let source = source { dict["source"] = source }
        if let format = format { dict["format"] = format }
        if let original = original { dict["original"] = original }
        if let size = size { dict["size"] = size }
        if let md5 = md5 { dict["md5"] = md5 }
        if let crc32 = crc32 { dict["crc32"] = crc32 }
        if let sha1 = sha1 { dict["sha1"] = sha1 }
        if let mtime = mtime { dict["mtime"] = mtime }
        if let length = length { dict["length"] = length }
        if let height = height { dict["height"] = height }
        if let width = width { dict["width"] = width }
        return dict
    }
}
