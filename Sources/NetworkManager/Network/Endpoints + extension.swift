//
//  Endpoints + extension.swift
//  CricbuzzMobile
//
//  Created by Mayur G on 30/05/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation

/**
 * Header Authentication type
 */
internal enum AuthType: String {
    case cf = "CF"
    case cb = "CB"
    case aws = "AWS"
    case akamai = "AK"
    case awsc = "AWSC"
    case unknown = "UNKNOWN"
}

extension Endpoints {
    
    func getAuthTypeFor(host: String) -> AuthType? {
        
        let hostWithDash = host.replacingOccurrences(of: ".", with: "-")
        if let authMap = (self.auth.filter{ $0.key == hostWithDash }).first, authMap.auth.enabled == true {
            return AuthType(rawValue: authMap.auth.authType.uppercased())
        }
        
        return nil
    }
    
    func isEndpointsEmpty() -> Bool {
        return self.textFormatString().count == 0 || self.appUrls.count == 0 || self.modules.count == 0
    }
}

extension Array where Element == Module {
    
    var home: Module? {
        return filter{ $0.name.lowercased() == "home" }.first
    }
    
}
