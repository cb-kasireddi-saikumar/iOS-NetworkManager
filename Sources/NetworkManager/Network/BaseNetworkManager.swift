//
//  CBZNetwork.swift
//  AlamofireWrapper
//
//  Created by Mayur G on 08/06/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation
import Alamofire

/**
 `NetworkManager` is a root object, that serves as a provider for single API endpoint. It is used to create and configure instances of `APIRequest` and `MultipartAPIRequest`.
 
 You need to hold strong reference to `Network` instance while your network requests are running.
 */
open class BaseNetworkManager: NetworkDelegate {
    
    /// Header builder to be used by default in all requests. Can be overridden for specific requests.
    open var headerBuilder : HeaderBuildableProtocol = BaseHeaderBuilder(defaultHeaders: ["Accept":"application/json"])
    
    /// URL builder to be used by default in all requests. Can be overridden for specific requests.
    open var urlBuilder : URLBuildable
    
    /// Global plugins, that will receive events from all requests, created from current Network instance.
    open var plugins : [Plugin] = []
    
    /// Default parameter encoding, that will be set on all APIRequests. Can be overrided by setting new value on APIRequest.parameterEncoding property.
    /// Default value - URLEncoding.default
    open var parameterEncoding: Alamofire.ParameterEncoding = URLEncoding.default
    
    /// Queue, used for processing response, received from the server. Defaults to QOS_CLASS_USER_INITIATED queue
    open var processingQueue = DispatchQueue.global(qos: .userInitiated)
    
    /// Queue, used to deliver result completion blocks. Defaults to dispatch_get_main_queue().
    open var resultDeliveryQueue = DispatchQueue.main
    
    /// Alamofire.Manager instance used to send network requests
    public let manager : Alamofire.SessionManager
    
    /**
     Initializes `Network` with given base URL, Alamofire.Manager instance, and array of global plugins.
     
     - parameter baseURL: Base URL to be used
     
     - parameter manager: Alamofire.Manager instance that will send requests created by current `CBZNetwork`
     
     - parameter plugins: Array of plugins, that will receive events from requests, created and managed by current `Network` instance.
     */
    public init(baseURL: String,
                manager: Alamofire.SessionManager = BaseNetworkManager.defaultAlamofireManager(),
                plugins : [Plugin] = [])
    {
        self.urlBuilder = BaseURLBuilder(baseURL: baseURL)
        self.manager = manager
        self.plugins = plugins
    }
    
    /**
     Default Alamofire.Manager instance to be used by `CBZNetwork`.
     
     - returns Alamofire.Manager instance initialized with NSURLSessionConfiguration.defaultSessionConfiguration().
     */
    public static func defaultAlamofireManager() -> SessionManager {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 75
        let manager = SessionManager(configuration: configuration)
        return manager
    }
    
    /**
     Creates APIRequest with specified relative path and type RequestType.Default.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - parameter responseSerializer: object used to serialize response.
     
     - returns: APIRequest instance.
     */
    /*open func request<Model, Serializer: NetworkDataResponseSerializerProtocol>
        (_ path: String, responseSerializer : Serializer) -> CBZAPIRequest<Model>
        where Serializer.SerializedObject == Model
    {
        return CBZAPIRequest(path: path, network: self, responseSerializer: responseSerializer)
    }*/
}
