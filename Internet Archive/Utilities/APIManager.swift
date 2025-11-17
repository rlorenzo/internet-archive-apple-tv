//
//  APIManager.swift
//  Internet Archive
//
//  Created by Eagle19243 on 5/8/18.
//  Copyright © 2018 Eagle19243. All rights reserved.
//

import Foundation
import Alamofire

class APIManager: NSObject {
    static let sharedManager = APIManager()
    
    let BASE_URL = "https://archive.org/"
    let API_CREATE = "services/xauthn/?op=create"
    let API_LOGIN = "services/xauthn/?op=authenticate"
    let API_INFO = "services/xauthn/?op=info"
    let API_METADATA = "metadata/"
    let API_WEB_LOGIN = "account/login.php"
    let API_SAVE_FAVORITE = "bookmarks.php?add_bookmark=1"
    let API_GET_FAVORITE = "metadata/fav-"
    
    let ACCESS = "trS8dVjP8dzaE296"
    let SECRET = "ICXDO78cnzUlPAt1"
    let API_VERSION = 1
    
    let HEADERS = [
        "User-Agent": "Wayback_Machine_iOS/\(Bundle.main.infoDictionary!["CFBundleShortVersionString"]!)",
        "Wayback-Extension-Version": "Wayback_Machine_iOS/\(Bundle.main.infoDictionary!["CFBundleShortVersionString"]!)"]
    
    private func SendDataToService(params: [String: Any], operation: String, completion: @escaping ([String: Any]?) -> Void) {
        
        var parameters          = params
        parameters["access"]    = ACCESS
        parameters["secret"]    = SECRET
        parameters["version"]   = API_VERSION
        
        Alamofire
            .request("\(BASE_URL)\(operation)", method: .post, parameters: parameters, encoding: URLEncoding.default, headers: HEADERS)
            .responseJSON{ (response) in
            
            switch response.result {
            case .success:
                if let json = response.result.value {
                    completion(json as? [String: Any])
                }
            case .failure:
                completion(nil)
                
            }
        }
    }
    
    private func GetCookieData(email: String, password: String, completion: @escaping([String: Any]?) -> Void) {
        var params = [String: Any]()
        params["username"] = email
        params["password"] = password
        params["action"] = "login"
        
        let cookieProps: [HTTPCookiePropertyKey: Any] = [
            HTTPCookiePropertyKey.version: 0,
            HTTPCookiePropertyKey.name: "test-cookie",
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.value: "1",
            HTTPCookiePropertyKey.domain: ".archive.org",
            HTTPCookiePropertyKey.secure: false,
            HTTPCookiePropertyKey.expires: Date(timeIntervalSinceNow: 86400 * 20)
        ]
        
        if let cookie = HTTPCookie(properties: cookieProps) {
            Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(cookie)
        }
        
        Alamofire.request(BASE_URL + API_WEB_LOGIN, method: .post, parameters: params, encoding: URLEncoding.default, headers: ["Content-Type": "application/x-www-form-urlencoded"]).responseString{ (response) in
            
            switch response.result {
            case .success:
                if let cookies = HTTPCookieStorage.shared.cookies {
                    var cookieData = [String: Any]()
                    
                    for cookie in cookies {
                        if cookie.name == "logged-in-sig" {
                            cookieData["logged-in-sig"] = cookie
                        } else if cookie.name == "logged-in-user" {
                            cookieData["logged-in-user"] = cookie
                        }
                    }
                    
                    completion(cookieData)
                } else {
                    completion(nil)
                }
            case .failure:
                completion(nil)
                
            }
        }
    }
    
    // Register new Account
    func register(params: [String: Any], completion: @escaping ([String: Any]?) -> Void) {
        SendDataToService(params: params, operation: API_CREATE, completion: completion)
    }
    
    // Login
    func login(email: String, password: String, completion: @escaping ([String: Any]?) -> Void) {
        SendDataToService(params: [
            "email"     : email,
            "password"  : password
            ], operation: API_LOGIN, completion: completion)
    }
    
    // Get Account Info
    func getAccountInfo(email: String, completion: @escaping ([String: Any]?) -> Void) {
        SendDataToService(params: ["email": email], operation: API_INFO, completion: completion)
    }
    
//    // Get Username
//    func getUsername(itemname: String, completion: @escaping (String?) -> Void) {
//        SendDataToService(params: ["itemname": itemname], operation: API_INFO, completion: { (data) in
//            print(data)
//        })
//    }
    
    func search(query: String, options: [String: String], completion: @escaping (_ data: [String: Any]?, _ err: Int?) -> Void) {
        var str_option = "&output=json"
        
        for (key, value) in options {
            str_option += "&\(key)=\(value)"
        }
        
        let url = "\(BASE_URL)advancedsearch.php?q=\(query)\(str_option)"
        let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        Alamofire
            .request(encodedURL!, method: .get, encoding: URLEncoding.default, headers: HEADERS)
            .responseJSON{ (response) in
                
            switch response.result {
            case .success:
                if let json = response.result.value, let result = json as? [String: Any], let data = result["response"] as? [String: Any] {
                    completion(data, nil)
                }
            case .failure:
                completion(nil, 0)
            }
        }
    }
    
    func getCollections(collection: String, result_type: String, limit: Int?, completion: @escaping (_ collection: String, _ data: [[String: Any]]?, _ err: Int?) -> Void) {
        var options = [
            "rows" : "1",
            "fl[]" : "identifier,title,year,downloads,date,creator,description,mediatype"]
        
        if limit != nil {
            options["rows"] = "\(limit!)"
        }
        
        search(query: "collection:(\(collection)) And mediatype:\(result_type)", options: options) { (data, err) in
            if data != nil {
                if limit == nil, let numFound = data!["numFound"] as? Int {
                    if numFound == 0 {
                        // API.GetCollections - fail
                        completion(collection, nil, 0)
                    } else {
                        self.getCollections(collection: collection, result_type: result_type, limit: numFound, completion: completion)
                    }
                } else {
                    completion(collection, data!["docs"] as? [[String : Any]], nil)
                }
            } else {
                completion(collection, nil, err)
            }
        }

    }
    
    func getMetaData(identifier: String, completion: @escaping (_ data: [String: Any]?, _ err: Int?) -> Void) {
        Alamofire
            .request("\(BASE_URL)\(API_METADATA)\(identifier)", method: .get, encoding: URLEncoding.default, headers: HEADERS)
            .responseJSON{ (response) in
                
            switch response.result {
            case .success:
                if let json = response.result.value {
                    completion(json as? [String: Any], nil)
                }
            case .failure:
                completion(nil, 0)
            }
        }
    }
    
    func getFavoriteItems(username: String,
                          completion: @escaping(_ success: Bool, _ err: Int?, _ items: [[String: Any]]?) -> Void) {
        let url = "\(BASE_URL)\(API_GET_FAVORITE)\(username.lowercased())"
        
        Alamofire.request(url, method: .get, encoding: URLEncoding.default).responseJSON { (data) in
            switch data.result {
            case .success:
                if let jsonData = data.result.value as? [String: Any],
                    let items = jsonData["members"] as? [[String: Any]]{
                    completion(true, nil, items)
                } else {
                    completion(true, nil, nil)
                }
            case .failure:
                completion(false, data.response?.statusCode, nil)
            }
        }
    }
    
    func saveFavoriteItem(email: String, password: String, identifier: String, mediatype: String, title: String, completion: @escaping(_ success: Bool, _ err: Int?) -> Void) {
        
        GetCookieData(email: email, password: password) { (data) in
            if data != nil {
                
                let loggedInSig = data!["logged-in-sig"] as! HTTPCookie
                let loggedInUser = data!["logged-in-user"] as! HTTPCookie
                
                Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(loggedInSig)
                Alamofire.SessionManager.default.session.configuration.httpCookieStorage?.setCookie(loggedInUser)
                
                let url = "\(self.BASE_URL)\(self.API_SAVE_FAVORITE)&mediatype=\(mediatype)&identifier=\(identifier)&title=\(title)"
                let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                
                Alamofire.request(encodedURL!, method: .get, encoding: URLEncoding.default)
                    .responseString {(response) in
                    
                        switch response.result {
                        case .success:
                            completion(true, nil)
                        case .failure:
                            completion(false, response.response?.statusCode)
                    
                    }
                }
                
            } else {
                completion(false, 301)
            }
        }
        
    }
    
}


