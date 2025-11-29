//
//  RequestModels.swift
//  Internet Archive
//
//
//  Sendable-compliant request models for Internet Archive API
//

import Foundation

/// Registration request parameters
struct RegisterRequest: Encodable, Sendable {
    let access: String
    let secret: String
    let version: Int

    // Additional fields from params dictionary
    let email: String?
    let password: String?
    let screenname: String?

    private enum CodingKeys: String, CodingKey {
        case access, secret, version
        case email, password, screenname
    }

    /// Create from dictionary (for backward compatibility)
    init(params: [String: Any], access: String, secret: String, version: Int) {
        self.access = access
        self.secret = secret
        self.version = version
        self.email = params["email"] as? String
        self.password = params["password"] as? String
        self.screenname = params["screenname"] as? String
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(access, forKey: .access)
        try container.encode(secret, forKey: .secret)
        try container.encode(version, forKey: .version)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(password, forKey: .password)
        try container.encodeIfPresent(screenname, forKey: .screenname)
    }
}

/// Login request parameters
struct LoginRequest: Encodable, Sendable {
    let email: String
    let password: String
    let access: String
    let secret: String
    let version: Int
}

/// Account info request parameters
struct AccountInfoRequest: Encodable, Sendable {
    let email: String
    let access: String
    let secret: String
    let version: Int
}
