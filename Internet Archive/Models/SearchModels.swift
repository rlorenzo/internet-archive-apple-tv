//
//  SearchModels.swift
//  Internet Archive
//
//  Type-safe models for Internet Archive search API
//

import Foundation

/// Response from the Internet Archive advanced search API
public struct SearchResponse: Codable, Sendable {
    let responseHeader: ResponseHeader?
    let response: SearchResults

    public struct ResponseHeader: Codable, Sendable {
        let status: Int
        let QTime: Int?

        /// Memberwise initializer for testing
        public init(status: Int, QTime: Int? = nil) {
            self.status = status
            self.QTime = QTime
        }
    }

    public struct SearchResults: Codable, Sendable {
        let numFound: Int
        let start: Int
        let docs: [SearchResult]

        /// Memberwise initializer for testing
        public init(numFound: Int, start: Int, docs: [SearchResult]) {
            self.numFound = numFound
            self.start = start
            self.docs = docs
        }
    }

    /// Memberwise initializer for testing
    public init(responseHeader: ResponseHeader? = nil, response: SearchResults) {
        self.responseHeader = responseHeader
        self.response = response
    }
}

/// Individual search result item
public struct SearchResult: Codable, Sendable {
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
    let licenseurl: String?

    // Custom decoder to handle year as either String or Int
    enum CodingKeys: String, CodingKey {
        case identifier, title, mediatype, creator, description, date, year, downloads, subject, collection, licenseurl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        title = try? container.decode(String.self, forKey: .title)
        mediatype = try? container.decode(String.self, forKey: .mediatype)
        creator = try? container.decode(String.self, forKey: .creator)
        description = try? container.decode(String.self, forKey: .description)
        date = try? container.decode(String.self, forKey: .date)

        // Handle year as either String or Int
        if let yearString = try? container.decode(String.self, forKey: .year) {
            year = yearString
        } else if let yearInt = try? container.decode(Int.self, forKey: .year) {
            year = String(yearInt)
        } else {
            year = nil
        }

        downloads = try? container.decode(Int.self, forKey: .downloads)
        subject = try? container.decode([String].self, forKey: .subject)
        collection = try? container.decode([String].self, forKey: .collection)
        licenseurl = try? container.decode(String.self, forKey: .licenseurl)
    }

    // Memberwise initializer for creating instances programmatically
    public init(
        identifier: String,
        title: String? = nil,
        mediatype: String? = nil,
        creator: String? = nil,
        description: String? = nil,
        date: String? = nil,
        year: String? = nil,
        downloads: Int? = nil,
        subject: [String]? = nil,
        collection: [String]? = nil,
        licenseurl: String? = nil
    ) {
        self.identifier = identifier
        self.title = title
        self.mediatype = mediatype
        self.creator = creator
        self.description = description
        self.date = date
        self.year = year
        self.downloads = downloads
        self.subject = subject
        self.collection = collection
        self.licenseurl = licenseurl
    }

    // Computed property for safe mediatype access
    var safeMediaType: String {
        mediatype ?? "unknown"
    }

    // Computed property for safe title access
    var safeTitle: String {
        title ?? "Untitled"
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

// MARK: - Hashable Conformance

extension SearchResult: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    public static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.identifier == rhs.identifier
    }
}
