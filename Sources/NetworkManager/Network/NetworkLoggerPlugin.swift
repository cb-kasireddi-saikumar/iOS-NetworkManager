//
//  NetworkLogger.swift
//  CricbuzzMobile
//
//  Created by Mayur G on 21/06/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation
import Alamofire

/**
 Plugin, that can be used to log network success and failure responses.
 */
open class NetworkLoggerPlugin : Plugin {
    
    public init() {}
    
    public func willSendAlamofireRequest<Model>(_ request: Request, formedFrom networkRequest: BaseRequest<Model>) {
        print("request -> \(request.request?.url?.absoluteString ?? "unknown")")
    }
}
