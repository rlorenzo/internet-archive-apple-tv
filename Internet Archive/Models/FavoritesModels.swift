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
    let dir: String?
    let filesCount: Int?
    let itemSize: Int?
    let members: [FavoriteItem]?
    let server: String?
    let workableServers: [String]?

    enum CodingKeys: String, CodingKey {
        case created, d1, dir, members, server
        case filesCount = "files_count"
        case itemSize = "item_size"
        case workableServers = "workable_servers"
    }

    /// Memberwise initializer for testing
    init(
        created: Int? = nil,
        d1: String? = nil,
        dir: String? = nil,
        filesCount: Int? = nil,
        itemSize: Int? = nil,
        members: [FavoriteItem]? = nil,
        server: String? = nil,
        workableServers: [String]? = nil
    ) {
        self.created = created
        self.d1 = d1
        self.dir = dir
        self.filesCount = filesCount
        self.itemSize = itemSize
        self.members = members
        self.server = server
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
