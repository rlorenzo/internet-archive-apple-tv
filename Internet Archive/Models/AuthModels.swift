//
//  AuthModels.swift
//  Internet Archive
//
//
//  Type-safe models for Internet Archive authentication API
//

import Foundation

/// Response from authentication API (login, register)
public struct AuthResponse: Codable, Sendable {
    let success: Bool?
    let version: Int?
    let values: AuthValues?
    let error: String?

    /// Authentication values returned on success
    public struct AuthValues: Codable, Sendable {
        let email: String?
        let itemname: String?
        let screenname: String?
        let verified: Bool?
        let privs: [String]?
        let signedin: String?

        // Computed property for safe access
        var isVerified: Bool {
            verified ?? false
        }

        /// Memberwise initializer for testing
        init(
            email: String? = nil,
            itemname: String? = nil,
            screenname: String? = nil,
            verified: Bool? = nil,
            privs: [String]? = nil,
            signedin: String? = nil
        ) {
            self.email = email
            self.itemname = itemname
            self.screenname = screenname
            self.verified = verified
            self.privs = privs
            self.signedin = signedin
        }
    }

    /// Memberwise initializer for testing
    init(
        success: Bool? = nil,
        version: Int? = nil,
        values: AuthValues? = nil,
        error: String? = nil
    ) {
        self.success = success
        self.version = version
        self.values = values
        self.error = error
    }

    // Computed property to check if auth was successful
    var isSuccess: Bool {
        success == true && error == nil
    }

    // Convert to dictionary for backward compatibility (temporary)
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let success = success { dict["success"] = success }
        if let version = version { dict["version"] = version }
        if let error = error { dict["error"] = error }
        if let values = values {
            var valuesDict: [String: Any] = [:]
            if let email = values.email { valuesDict["email"] = email }
            if let itemname = values.itemname { valuesDict["itemname"] = itemname }
            if let screenname = values.screenname { valuesDict["screenname"] = screenname }
            if let verified = values.verified { valuesDict["verified"] = verified }
            if let privs = values.privs { valuesDict["privs"] = privs }
            if let signedin = values.signedin { valuesDict["signedin"] = signedin }
            dict["values"] = valuesDict
        }
        return dict
    }
}

/// Account information response
struct AccountInfoResponse: Codable, Sendable {
    let success: Bool?
    let version: Int?
    let values: AccountValues?
    let error: String?

    /// Account information values
    struct AccountValues: Codable, Sendable {
        let email: String?
        let itemname: String?
        let screenname: String?
        let verified: Bool?
        let privs: [String]?

        /// Memberwise initializer for testing
        init(
            email: String? = nil,
            itemname: String? = nil,
            screenname: String? = nil,
            verified: Bool? = nil,
            privs: [String]? = nil
        ) {
            self.email = email
            self.itemname = itemname
            self.screenname = screenname
            self.verified = verified
            self.privs = privs
        }
    }

    /// Memberwise initializer for testing
    init(
        success: Bool? = nil,
        version: Int? = nil,
        values: AccountValues? = nil,
        error: String? = nil
    ) {
        self.success = success
        self.version = version
        self.values = values
        self.error = error
    }

    // Convert to dictionary for backward compatibility (temporary)
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let success = success { dict["success"] = success }
        if let version = version { dict["version"] = version }
        if let error = error { dict["error"] = error }
        if let values = values {
            var valuesDict: [String: Any] = [:]
            if let email = values.email { valuesDict["email"] = email }
            if let itemname = values.itemname { valuesDict["itemname"] = itemname }
            if let screenname = values.screenname { valuesDict["screenname"] = screenname }
            if let verified = values.verified { valuesDict["verified"] = verified }
            if let privs = values.privs { valuesDict["privs"] = privs }
            dict["values"] = valuesDict
        }
        return dict
    }
}
