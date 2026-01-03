//
//  MetadataModels.swift
//  Internet Archive
//
//
//  Type-safe models for Internet Archive metadata API
//

import Foundation

/// Response from the Internet Archive metadata API
struct ItemMetadataResponse: Codable, Sendable {
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

    /// Memberwise initializer for testing
    init(
        created: Int? = nil,
        d1: String? = nil,
        d2: String? = nil,
        dir: String? = nil,
        files: [FileInfo]? = nil,
        filesCount: Int? = nil,
        itemSize: Int? = nil,
        metadata: ItemMetadata? = nil,
        server: String? = nil,
        uniq: Int? = nil,
        workableServers: [String]? = nil
    ) {
        self.created = created
        self.d1 = d1
        self.d2 = d2
        self.dir = dir
        self.files = files
        self.filesCount = filesCount
        self.itemSize = itemSize
        self.metadata = metadata
        self.server = server
        self.uniq = uniq
        self.workableServers = workableServers
    }
}

/// Metadata information for an item
public struct ItemMetadata: Codable, Sendable {
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
    let licenseurl: String?

    /// Memberwise initializer for testing
    init(
        identifier: String? = nil,
        title: String? = nil,
        mediatype: String? = nil,
        creator: String? = nil,
        description: String? = nil,
        date: String? = nil,
        year: String? = nil,
        subject: SubjectValue? = nil,
        collection: CollectionValue? = nil,
        publicdate: String? = nil,
        addeddate: String? = nil,
        uploader: String? = nil,
        licenseurl: String? = nil
    ) {
        self.identifier = identifier
        self.title = title
        self.mediatype = mediatype
        self.creator = creator
        self.description = description
        self.date = date
        self.year = year
        self.subject = subject
        self.collection = collection
        self.publicdate = publicdate
        self.addeddate = addeddate
        self.uploader = uploader
        self.licenseurl = licenseurl
    }

    // Subject and collection can be either String or [String]
    enum SubjectValue: Codable, Sendable {
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
struct FileInfo: Codable, Sendable {
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

    // Audio track metadata (from Internet Archive API)
    let track: String?      // Track number (e.g., "01", "02", "1/12")
    let title: String?      // Track title (e.g., "Let The Good Times Roll")
    let album: String?      // Album name (e.g., "1989-12-08 - Great Western LA Forum")
    let creator: String?    // Artist name (e.g., "Grateful Dead")

    /// Memberwise initializer for testing
    init(
        name: String,
        source: String? = nil,
        format: String? = nil,
        original: String? = nil,
        size: String? = nil,
        md5: String? = nil,
        crc32: String? = nil,
        sha1: String? = nil,
        mtime: String? = nil,
        length: String? = nil,
        height: String? = nil,
        width: String? = nil,
        track: String? = nil,
        title: String? = nil,
        album: String? = nil,
        creator: String? = nil
    ) {
        self.name = name
        self.source = source
        self.format = format
        self.original = original
        self.size = size
        self.md5 = md5
        self.crc32 = crc32
        self.sha1 = sha1
        self.mtime = mtime
        self.length = length
        self.height = height
        self.width = width
        self.track = track
        self.title = title
        self.album = album
        self.creator = creator
    }

    // Computed properties for type-safe access
    var sizeInBytes: Int64? {
        guard let size = size else { return nil }
        return Int64(size)
    }

    var durationInSeconds: Double? {
        guard let length = length else { return nil }

        // Try parsing as plain seconds first (e.g., "312.45")
        if let seconds = Double(length) {
            return seconds
        }

        // Parse MM:SS or HH:MM:SS format (e.g., "06:21" or "1:23:45")
        let components = length.split(separator: ":")
        switch components.count {
        case 2:
            // MM:SS format
            guard let minutes = Double(components[0]),
                  let seconds = Double(components[1]) else { return nil }
            return minutes * 60 + seconds
        case 3:
            // HH:MM:SS format
            guard let hours = Double(components[0]),
                  let minutes = Double(components[1]),
                  let seconds = Double(components[2]) else { return nil }
            return hours * 3600 + minutes * 60 + seconds
        default:
            return nil
        }
    }

    /// Parse track number from various formats ("01", "1", "01/12")
    var trackNumber: Int? {
        guard let track = track else { return nil }
        // Handle "01/12" format - take the first part
        let cleanTrack = track.components(separatedBy: "/").first ?? track
        return Int(cleanTrack.trimmingCharacters(in: .whitespaces))
    }

    /// Display title - use track title if available, otherwise derive from filename
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        // Fall back to filename without extension
        return name
            .replacingOccurrences(of: ".mp3", with: "")
            .replacingOccurrences(of: ".flac", with: "")
            .replacingOccurrences(of: ".ogg", with: "")
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
        if let track = track { dict["track"] = track }
        if let title = title { dict["title"] = title }
        if let album = album { dict["album"] = album }
        if let creator = creator { dict["creator"] = creator }
        return dict
    }
}
