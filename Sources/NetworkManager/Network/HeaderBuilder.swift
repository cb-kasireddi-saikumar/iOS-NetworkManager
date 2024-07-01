//
//  CBZWatchHeaderBuilder.swift
//  WatchApp Extension
//
//  Created by Sandeep G S on 10/10/19.
//  Copyright © 2019 Cricbuzz. All rights reserved.
//

import Foundation
import CryptoSwift

protocol HeaderBuildable: HeaderBuildableProtocol {
    func headers(forAuthorizationRequirement requirement: AuthorizationRequirement, forURL url: URL, including headers: [String: String]) -> [String: String]
}

private let kUTADifferencKey = "CBZUTADifference"
private let kAuthenticationHeader = "Authentication"
private let kAuthenticationCookieHeader = "Cookie"

open class HeaderBuilder: BaseHeaderBuilder {
    
    /// Default headers to be included in all requests
    internal let serverConfigs: ServerConfigManager
    
    /// Userdefault proxy
    internal let userDefaults: UserDefaults
    
    // It indicates UTA time difference and track your device time as well if it's either ahead or behind
    internal var requestUTADiff: Int = (UserDefaults.standard.value(forKey: kUTADifferencKey) as? Int) ?? 0 {
        didSet {
            userDefaults.set(requestUTADiff, forKey: kUTADifferencKey)
            userDefaults.synchronize()
        }
    }
    
    /**
     Initialize with defaultHeaders
     
     - parameter defaultHeaders: Default headers to be added.
     
     - parameter defaultHeaders: Default headers to be added.
     */
    public init(defaultHeaders: [String:String],
         serverConfigs: ServerConfigManager = ServerConfigManager.shared,
         userDefaults: UserDefaults = UserDefaults.standard)
    {
        self.serverConfigs = serverConfigs
        self.userDefaults = userDefaults
        
        super.init(defaultHeaders: defaultHeaders)
    }
    
    internal func burstCache() {
        print("burst cache CBZHeaderBuilder")
        userDefaults.set(0, forKey: kUTADifferencKey)
        userDefaults.synchronize()
    }
 
    open class func applyAuthenticationHeader(to url: URL, authTypeValue: String) -> [String : String]? {
        if let authType: AuthType = AuthType(rawValue: authTypeValue), let headerBuilder = NetworkManager.shared.cbzHeaderBuilder {
            return headerBuilder.authenticationHeaderValue(for: url, authType: authType)
        }
        
        return nil
    }
}

extension HeaderBuilder: HeaderBuildable {

    /**
     Construct headers for specific request.
     
     - parameter requirement: Authorization requirement of current request
     
     - parameter headers : headers to be included in this specific request
     
     - returns: HTTP headers for current request
     */
    func headers(forAuthorizationRequirement requirement: AuthorizationRequirement, forURL url: URL, including headers: [String : String]) -> [String : String] {
        var combinedHeaders = defaultHeaders
        headers.forEach {
            combinedHeaders[$0.0] = $0.1
        }
        
        if requirement == .required {
            let authType = serverConfigs.serverEndpoints?.getAuthTypeFor(host: url.host ?? "")
            return applyAuthentication(to: url, authType: authType, additionalHeaders: headers)
        }
        
        return combinedHeaders
    }
    
    func applyAuthentication(to url: URL, authType: AuthType?, additionalHeaders: [String : String]) -> [String : String] {
        var combinedHeaders = defaultHeaders
        additionalHeaders.forEach {
            combinedHeaders[$0.0] = $0.1
        }
        
        if let authType = authType {
            authenticationHeaderValue(for: url, authType: authType).forEach {
                combinedHeaders[$0.0] = $0.1
            }
        }
        
        return combinedHeaders
    }
    
    internal func authenticationHeaderValue(for url: URL, authType: AuthType) -> [String : String] {
        var authHeader: [String : String] = [:]

        switch authType {
            case .cf, .cb:
                // remove scheme and host from url
                let uri = extractPath(url)
                let token = generateHttpHeaderToken(uri: uri)
                authHeader[kAuthenticationHeader] = token
            case .aws:
                let uri = "/aws-authentication"
                let token = generateHttpHeaderToken(uri: uri)
                authHeader[kAuthenticationHeader] = token
//            case .awsc:
//                let uri = url.absoluteString
//                let token = generateAwsHttpHeaderCookie(for: uri) ?? ""
//                authHeader[kAuthenticationCookieHeader] = token
            case .akamai:
                let token = AkamaiAuthenticator.generate_token()
                authHeader[kAuthenticationHeader] = token
            case .unknown: break
            default: break
        }
        return authHeader
    }
    
    // Generate auth token
    private func generateHttpHeaderToken (uri: String) -> String? {
        
        var time: Int = 0
        let currentTime = Int(Date().timeIntervalSince1970.rounded())
        let flexTime = 10 // Todo: Need to fetch it from Settings
        
        time = currentTime - flexTime + requestUTADiff
        
        let secret = CBZEncryptor.authSecret.decrypt()
        let message = "\(uri)\(time)"
        
        if let token = message.hmac(key: secret) {
            return "\(time)-\(token)"
        } else {
            return nil
        }
        
    }
//    
//    private func generateAwsHttpHeaderCookie(for uri: String) -> String? {
//        
//        let currentTime = Int(Date().timeIntervalSince1970)
//        let flexTime = (60 * 10)
//        
//        let time: Int = currentTime + flexTime
//        
//        let policyString = "{\"Statement\":[{\"Resource\":\"" + uri + "\",\"Condition\":{\"DateLessThan\":{\"AWS:EpochTime\":\(time)}}}]}"
//        
//        let pemString: String = CBZEncryptor.awscPemKey.decrypt() ?? ""
//        guard var token = CBZEncryptor.sign(message: policyString, using: pemString, digestType: .sha1) else {
//            return nil
//        }
//        
//        token = token.replacingOccurrences(of: "+", with: "-")
//        token = token.replacingOccurrences(of: "=", with: "_")
//        token = token.replacingOccurrences(of: "/", with: "~")
//        
//        // To Do: fetch it from Firestore and make it accessible to global as this function will call very frequently
//        let key_pair_id = CBZEncryptor.awscKeyPairId.decrypt() ?? ""
//        let cookie = "CloudFront-Expires=\(time);CloudFront-Signature=" + token + ";CloudFront-Key-Pair-Id=" + key_pair_id
//        
//        return cookie
//    }
    
    // get relative path from URL: path + query
    private func extractPath(_ fromURL: URL) -> String {
        
        let uri = fromURL.absoluteString
        let scheme = fromURL.scheme ?? ""
        let host = fromURL.host ?? ""
        return uri.replacingOccurrences(of: (scheme + "://" + host), with: "")
        
    }
    
}

fileprivate extension String {
    func rstrip(str: Character = " ") -> String {
        var newStr = self
        
        while newStr.last == str {
            newStr = String(newStr[newStr.startIndex..<newStr.index(before: newStr.endIndex)])
        }
        
        return newStr
    }
}

fileprivate extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

class AkamaiAuthenticator {
    
    private static let default_token_name = "Authentication"
    private static let default_acl = "/*"
    private static let default_algo: HMAC.Variant = .sha1
    private static let default_window: Int =  300
    private static let default_key = CBZEncryptor.akamaiSecret.decrypt() ?? ""
    
    private static let default_field_delimiter = "~"
    private static let default_acl_delimiter = "!"
    
    static func get_end_time(window: Int) -> Int {
        let seconds = Int(Date().timeIntervalSince1970)
        return seconds + window
    }
    
    public static func generate_token(key: String = default_key,
                                      window: Int = default_window,
                                      acl: String = default_acl,
                                      algo: HMAC.Variant = default_algo) -> String
    {
        var new_token = ""
        
        new_token += "exp=" + "\(get_end_time(window: window))" + default_field_delimiter
        new_token += "acl=" + acl + default_field_delimiter
        
        do {
            let source = new_token.rstrip(str: "~")
            let hash = try HMAC(key: Array(hex: key), variant: algo).authenticate(Array(source.utf8))
            new_token += "hmac=" + hash.toHexString()
        } catch {
            new_token = ""
        }
        
        return new_token
    }
    
}
