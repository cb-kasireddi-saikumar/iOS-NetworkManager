//
//  CBZNetworkUtils.swift
//  CricbuzzMobile
//
//  Created by Mayur G on 22/05/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation

internal let networkBundle = Bundle(identifier: "com.sports.iCric.NetworkManager")
private var _httpScheme: String?
private var _endpointURL: String?

/**
 * Utils
 */

internal func TrailingSlash(_ str: String?) -> String {
    if let url = str, url.count > 0 {
        return url[url.index(before: url.endIndex)] == "/" ? url : url + "/"
    } else {
        return "/"
    }
}

internal var endpointURL: String {
    if _endpointURL != nil {
        return _endpointURL!
    }
    if let serverURL = ServerConfigManager.shared.dependencies?.serverURL {
        _endpointURL = serverURL
    }
    return _endpointURL!
}

internal var httpScheme: String {
    if _httpScheme != nil {
        return _httpScheme!
    }
    if let httpScheme = ServerConfigManager.shared.dependencies?.httpScheme {
        _httpScheme = httpScheme
    }
    return _httpScheme!
}

internal func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    
    #if DEBUG
        
        var idx = items.startIndex
        let endIdx = items.endIndex
        
        repeat {
            Swift.print("[CBZNetwork] \(items[idx])\n", separator: separator, terminator: idx == endIdx ? terminator : separator)
            idx += 1
        }
            while idx < endIdx
        
    #endif
}

extension Dictionary where Key == String, Value: Hashable {
    
    var queryString: String {
        var output: String = ""
        for (key, value) in self {
            if output == "" {
                output += "?\(key)=\(value)"
            } else {
                output += "&" + "\(key)=\(value)"
            }
        }
        return output
    }
}
