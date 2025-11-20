//
//  FavoritesModels.swift
//  Internet Archive
//
//  Created for Sprint 5: Data Models & Codable
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

    // Convert to dictionary for backward compatibility (temporary)
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["identifier": identifier]
        if let mediatype = mediatype { dict["mediatype"] = mediatype }
        if let title = title { dict["title"] = title }
        return dict
    }
}
