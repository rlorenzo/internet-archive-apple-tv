//
//  FavoritesModels.swift
//  Internet Archive
//
//
//  Type-safe models for Internet Archive favorites/bookmarks API
//

import Foundation

/// Response from the favorites API (fav-username endpoint)
struct FavoritesResponse: Codable, Sendable {
    let created: Int?
    let d1: String?
    let d2: String?
    let dir: String?
    let files: [FileInfo]?
    let filesCount: Int?
    let itemSize: Int?
    let metadata: FavoriteMetadata?
    let members: [FavoriteItem]?
    let server: String?
    let uniq: Int?
    let workableServers: [String]?

    enum CodingKeys: String, CodingKey {
        case created, d1, d2, dir, files, metadata, members, server, uniq
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
        metadata: FavoriteMetadata? = nil,
        members: [FavoriteItem]? = nil,
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
        self.members = members
        self.server = server
        self.uniq = uniq
        self.workableServers = workableServers
    }
}

/// Metadata for favorites collection
struct FavoriteMetadata: Codable, Sendable {
    let identifier: String?
    let mediatype: String?
    let title: String?
    let description: String?
    let subject: String?
}

/// Individual favorite item
struct FavoriteItem: Codable, Sendable {
    let identifier: String
    let mediatype: String?
    let title: String?

    /// Memberwise initializer for testing
    init(
        identifier: String,
        mediatype: String? = nil,
        title: String? = nil
    ) {
        self.identifier = identifier
        self.mediatype = mediatype
        self.title = title
    }

    // Convert to dictionary for backward compatibility (temporary)
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["identifier": identifier]
        if let mediatype = mediatype { dict["mediatype"] = mediatype }
        if let title = title { dict["title"] = title }
        return dict
    }
}
