//
//  AuthModels.swift
//  Internet Archive
//
//  Created for Sprint 5: Data Models & Codable
//  Type-safe models for Internet Archive authentication API
//

import Foundation

/// Response from authentication API (login, register)
public struct AuthResponse: Codable {
    let success: Bool?
    let version: Int?
    let values: AuthValues?
    let error: String?

    /// Authentication values returned on success
    public struct AuthValues: Codable {
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
struct AccountInfoResponse: Codable {
    let success: Bool?
    let version: Int?
    let values: AccountValues?
    let error: String?

    /// Account information values
    struct AccountValues: Codable {
        let email: String?
        let itemname: String?
        let screenname: String?
        let verified: Bool?
        let privs: [String]?
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
