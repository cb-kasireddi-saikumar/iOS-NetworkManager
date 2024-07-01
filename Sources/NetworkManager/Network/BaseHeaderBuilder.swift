//
//  HeaderBuilder.swift
//  AlamofireWrapper
//
//  Created by Mayur G on 08/06/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation

/**
 `HeaderBuilder` class is used to construct HTTP headers for URLRequest.
 */
open class BaseHeaderBuilder: HeaderBuildableProtocol {
    
    /// Default headers to be included in all requests
    open var defaultHeaders : [String:String]
    
    /**
     Initialize with defaultHeaders
     
     - parameter defaultHeaders: Default headers to be added.
     */
    public init(defaultHeaders: [String:String]) {
        self.defaultHeaders = defaultHeaders
    }
    
    /**
     Construct headers for specific request.
     
     - parameter requirement: Authorization requirement of current request
     
     - parameter headers : headers to be included in this specific request
     
     - returns: HTTP headers for current request
     */
    open func headers(forAuthorizationRequirement requirement: AuthorizationRequirement, including headers: [String : String]) -> [String : String] {
        var combinedHeaders = defaultHeaders
        headers.forEach {
            combinedHeaders[$0.0] = $0.1
        }
        return combinedHeaders
    }
}
