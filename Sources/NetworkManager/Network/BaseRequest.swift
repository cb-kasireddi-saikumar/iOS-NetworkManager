//
//  BaseRequest.swift
//  AlamofireWrapper
//
//  Created by Mayur G on 08/06/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation
import Alamofire

/**
 Protocol, that defines how URL is constructed by consumer.
 */
public protocol URLBuildable {
    
    /**
     Construct URL with given path
     
     - parameter path: relative path
     
     - returns constructed URL
     */
    func url(forPath path: String) -> URL
}

/**
 Protocol, that defines how headers should be constructed by consumer.
 */
public protocol HeaderBuildableProtocol {
    
    /**
     Construct headers for specific request.
     
     - parameter requirement: Authorization requirement of current request
     
     - parameter headers : headers to be included in this specific request
     
     - returns: HTTP headers for current request
     */
    func headers(forAuthorizationRequirement requirement: AuthorizationRequirement, including headers: [String:String]) -> [String: String]
}

/**
 Authorization requirement for current request.
 */
public enum AuthorizationRequirement {
    
    /// Request does not need authorization
    case none
    
    /// Request requires authorization
    case required
}

/// Protocol used to allow `APIRequest` to communicate with `CBZNetwork` instance.
public protocol NetworkDelegate: AnyObject {
    
    /// Alamofire.Manager used to send requests
    var manager: Alamofire.SessionManager { get }
    
    /// Global array of plugins on `CBZNetwork` instance
    var plugins : [Plugin] { get }

}

/// Base class, that contains common functionality, extracted from `APIRequest` and `MultipartAPIRequest`.
open class BaseRequest<Model> {
    
    /// Serializes Data into Model
    public typealias ResponseParser = (_ request: URLRequest?, _ response: HTTPURLResponse?, _ data: Data?, _ error: Error?) -> Result<Model>
    
    /// Relative path of current request
    public let path: String
    
    /// HTTP method
    open var method: Alamofire.HTTPMethod = .get
    
    // HTTP body for the post request
    open var httpBody: Data?
    
    /// Parameters of current request.
    open var parameters: [String: Any] = [:]
    
    /// Defines how parameters are encoded.
    open var parameterEncoding : Alamofire.ParameterEncoding
    
    /// Headers, that should be used for current request.
    /// - Note: Resulting headers may include global headers from `Network` instance and `Alamofire.Manager` defaultHTTPHeaders.
    open var headers : [String:String] = [:]
    
    /// Authorization requirement for current request
    open var authorizationRequirement = AuthorizationRequirement.none
    
    /// Header builder for current request
    open var headerBuilder: HeaderBuildableProtocol
    
    /// URL builder for current request
    open var urlBuilder: URLBuildable
    
    /// Queue, used to deliver result completion blocks. Defaults to Network.resultDeliveryQueue queue.
    open var resultDeliveryQueue : DispatchQueue
    
    /// Delegate property that is used to communicate with `Network` instance.
    weak var networkDelegate : NetworkDelegate?
    
    /// Array of plugins for current `APIRequest`.
    open var plugins : [Plugin] = []
    
    private var allPlugins : [Plugin] {
        return plugins + (networkDelegate?.plugins ?? [])
    }
    
    /// Creates `BaseRequest` instance, initialized with several `Network` properties.
    public init(path: String, network: BaseNetworkManager) {
        self.path = path
        self.networkDelegate = network
        self.headerBuilder = network.headerBuilder
        self.urlBuilder = network.urlBuilder
        self.resultDeliveryQueue = network.resultDeliveryQueue
        self.parameterEncoding = network.parameterEncoding
    }
    
    internal func alamofireRequest(from manager: Alamofire.SessionManager, for url: URL? = nil) -> Alamofire.Request? {
        fatalError("Needs to be implemented in subclasses")
    }
    
    internal func callSuccessFailureBlocks(_ success: ((APIResponse<Model>) -> Void)?,
                                           failure: ((Error) -> Void)?,
                                           response: APIResponse<Model>)
    {
        if let _ = response.value {
            success?(response)
        } else if let error = response.customError {
            failure?(error)
        } else if let error = response.error {
            failure?(error)
        }
        
        let defaultSessionError = NSError(domain: "com.sports.iCric.CBZNetwork.callSuccessFailureBlocks", code: 1, userInfo: nil)
        failure?(defaultSessionError)
    }
    
    internal func willSendRequest() {
        allPlugins.forEach { plugin in
            plugin.dispatchQueue.async {
                plugin.willSendRequest(self)
            }
        }
    }
    
    internal func willSendAlamofireRequest(_ request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.dispatchQueue.async {
                plugin.willSendAlamofireRequest(request, formedFrom: self)
            }
        }
    }
    
    internal func didSendAlamofireRequest(_ request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.dispatchQueue.async {
                plugin.didSendAlamofireRequest(request, formedFrom: self)
            }
        }
    }
    
    internal func willProcessResponse(_ response: (URLRequest?, HTTPURLResponse?, Data?, Error?), for request: Request) {
        allPlugins.forEach { plugin in
            plugin.dispatchQueue.async {
                plugin.willProcessResponse(response: response, forRequest: request, formedFrom: self)
            }
        }
    }
    
    internal func didSuccessfullyParseResponse(_ response: (URLRequest?, HTTPURLResponse?, Data?, Error?), creating result: Model, forRequest request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.dispatchQueue.async {
                plugin.didSuccessfullyParseResponse(response, creating: result, forRequest: request, formedFrom: self)
            }
        }
    }
    
    internal func didReceiveError(_ error: Error, for response: (URLRequest?, HTTPURLResponse?, Data?, Error?), request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.dispatchQueue.async {
                plugin.didReceiveError(error, forResponse: response, request: request, formedFrom: self)
            }
        }
    }
    
    internal func didReceiveDataResponse(_ response: DataResponse<Model>, forRequest request: Alamofire.Request) {
        allPlugins.forEach { plugin in
            plugin.dispatchQueue.async {
                plugin.didReceiveDataResponse(response, forRequest: request, formedFrom: self)
            }
        }
    }
    
    internal func didReceiveDownloadResponse(_ response: DownloadResponse<Model>, forRequest request: Alamofire.DownloadRequest) {
        allPlugins.forEach { plugin in
            plugin.dispatchQueue.async {
                plugin.didReceiveDownloadResponse(response, forRequest: request, formedFrom: self)
            }
        }
    }
    
}

//
fileprivate extension Int {
    
    var shouldRetryRequest: Bool {
        var shouldRetry: Bool = true
            switch self {
                case 304, 417, 429, 404: shouldRetry = false
                default: break
            }
        return shouldRetry
    }
}
