//
//  SearchModels.swift
//  Internet Archive
//
//  Created for Sprint 5: Data Models & Codable
//  Type-safe models for Internet Archive search API
//

import Foundation

/// Response from the Internet Archive advanced search API
struct SearchResponse: Codable {
    let response: SearchResults

    struct SearchResults: Codable {
        let numFound: Int
        let start: Int
        let docs: [SearchResult]
    }
}

/// Individual search result item
struct SearchResult: Codable {
    let identifier: String
    let title: String?
    let mediatype: String?
    let creator: String?
    let description: String?
    let date: String?
    let year: String?
    let downloads: Int?
    let subject: [String]?
    let collection: [String]?

    // Computed property for safe mediatype access
    var safeMediaType: String {
        return mediatype ?? "unknown"
    }

    // Computed property for safe title access
    var safeTitle: String {
        return title ?? "Untitled"
    }

    // Convert to dictionary for backward compatibility (temporary)
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["identifier": identifier]
        if let title = title { dict["title"] = title }
        if let mediatype = mediatype { dict["mediatype"] = mediatype }
        if let creator = creator { dict["creator"] = creator }
        if let description = description { dict["description"] = description }
        if let date = date { dict["date"] = date }
        if let year = year { dict["year"] = year }
        if let downloads = downloads { dict["downloads"] = downloads }
        if let subject = subject { dict["subject"] = subject }
        if let collection = collection { dict["collection"] = collection }
        return dict
    }
}
