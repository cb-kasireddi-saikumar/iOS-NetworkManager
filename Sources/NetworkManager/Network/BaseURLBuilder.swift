//
//  URLBuilder.swift
//  AlamofireWrapper
//
//  Created by Mayur G on 08/06/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation

/**
 `URLBuilder` constructs resulting URL by calling `URLByAppendingPathComponent` method on baseURL.
 */
open class BaseURLBuilder : URLBuildable {
    
    /// Base URL string
    public let baseURLString : String
    
    /**
     Initialize URL builder with Base URL String
     
     - parameter baseURL: base URL string
     */
    public init(baseURL: String) {
        self.baseURLString = baseURL
    }
    
    /**
     Construct URL with given path
     
     - parameter path: relative path
     
     - returns constructed URL
     */
    open func url(forPath path: String) -> URL {
        return URL(string: baseURLString)?.appendingPathComponent(path) ?? URL(string:"1")!
    }
}
