//
//  Plugin.swift
//  AlamofireWrapper
//
//  Created by Mayur G on 08/06/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation
import Alamofire

/**
 Protocol that serves to provide plugin functionality to `Network`.
 */
public protocol Plugin {
    
    /// Queue, on which all plugin calls will be performed
    var dispatchQueue : DispatchQueue { get }
    
    /// Notifies that `request` is about to be converted to Alamofire.Request
    ///
    /// - parameter request: Network BaseRequest
    func willSendRequest<Model>(_ request: BaseRequest<Model>)
    
    
    /// Notifies that `request` formed from `networkRequest`, is about to be sent.
    ///
    /// - parameter request: Alamofire.Request instance
    /// - parameter formedFrom: Network.BaseRequest instance or one of the subclasses
    func willSendAlamofireRequest<Model>(_ request: Request, formedFrom networkRequest: BaseRequest<Model>)
    
    /// Notifies that `request`, formed from `networkRequest`, was sent.
    ///
    /// - parameter request:     Alamofire.Request instance
    /// - parameter networkRequest: Network.BaseRequest or one of the subclasses
    func didSendAlamofireRequest<Model>(_ request : Request, formedFrom networkRequest: BaseRequest<Model>)
    
    /// Notifies that `response` was received for `request`, formed from `networkRequest`.
    ///
    /// - parameter response:    Tuple with (URLRequest?, HTTPURLResponse?, Data?, Error?)
    /// - parameter request:     Alamofire.Request instance
    /// - parameter networkRequest: Network.BaseRequest or one of the subclasses
    func willProcessResponse<Model>(response: (URLRequest?, HTTPURLResponse?, Data?, Error?),
                             forRequest request: Request,
                             formedFrom networkRequest: BaseRequest<Model>)
    
    /// Notifies that `response` for `request`, formed from `networkRequest`, was successfully parsed into `result`.
    ///
    /// - parameter response:    Tuple with (URLRequest?, HTTPURLResponse?, Data?, Error?)
    /// - parameter result:      parsed Model
    /// - parameter request:     Alamofire.Request instance
    /// - parameter networkRequest: Network.BaseRequest or one of the subclasses
    func didSuccessfullyParseResponse<Model>(_ response: (URLRequest?, HTTPURLResponse?, Data?, Error?),
                                      creating result: Model,
                                      forRequest request: Request,
                                      formedFrom networkRequest: BaseRequest<Model>)
    
    /// Notifies that request processed response and created `APIError<ErrorModel>` instance.
    ///
    /// - parameter error:       parsed APIError<ErrorModel> instance
    /// - parameter response:    Tuple with (URLRequest?, HTTPURLResponse?, Data?, Error?)
    /// - parameter request:     Alamofire.Request instance
    /// - parameter networkRequest: Network.BaseRequest or one of the subclasses
    func didReceiveError<Model>(_ error: Error,
                         forResponse response : (URLRequest?, HTTPURLResponse?, Data?, Error?),
                         request: Alamofire.Request,
                         formedFrom networkRequest: BaseRequest<Model>)
    
    /// Notifies about data `response` that was received for `request`, formed from `networkRequest`. This method is called after parsing has completed.
    ///
    /// - parameter response:    DataResponse instance
    /// - parameter request:     Alamofire.Request instance
    /// - parameter networkRequest: Network.BaseRequest or one of the subclasses
    func didReceiveDataResponse<Model>(_ response: DataResponse<Model>, forRequest request: Alamofire.Request, formedFrom networkRequest: BaseRequest<Model>)
    
    
    /// Notifies about download `response` that was received for `request`, formed from `networkRequest`. This method is called after parsing has completed.
    ///
    /// - parameter _response:   DownloadResponse instance
    /// - parameter request:     Alamofire.Request instance
    /// - parameter networkRequest: Network.BaseRequest or one of the subclasses.
    func didReceiveDownloadResponse<Model>(_ response: DownloadResponse<Model>, forRequest request: Alamofire.DownloadRequest, formedFrom networkRequest: BaseRequest<Model>)
}

public extension Plugin {
    
    var dispatchQueue: DispatchQueue {
        return .main
    }
    
    func willSendRequest<Model>(_ request: BaseRequest<Model>) {
        
    }
    
    func willSendAlamofireRequest<Model>(_ request: Request, formedFrom networkRequest: BaseRequest<Model>) {
        
    }
    
    func didSendAlamofireRequest<Model>(_ request : Request, formedFrom networkRequest: BaseRequest<Model>) {
        
    }
    
    func willProcessResponse<Model>(response: (URLRequest?, HTTPURLResponse?, Data?, Error?), forRequest request: Request, formedFrom networkRequest: BaseRequest<Model>) {
        
    }
    
    func didSuccessfullyParseResponse<Model>(_ response: (URLRequest?, HTTPURLResponse?, Data?, Error?),
                                      creating result: Model,
                                      forRequest request: Request,
                                      formedFrom networkRequest: BaseRequest<Model>){
        
    }
    
    func didReceiveError<Model>(_ error: Error,
                         forResponse response : (URLRequest?, HTTPURLResponse?, Data?, Error?),
                         request: Alamofire.Request,
                         formedFrom networkRequest: BaseRequest<Model>){
        
    }
    
    func didReceiveDataResponse<Model>(_ response: DataResponse<Model>, forRequest request: Alamofire.Request, formedFrom networkRequest: BaseRequest<Model>) {
        
    }
    
    func didReceiveDownloadResponse<Model>(_ response: DownloadResponse<Model>, forRequest request: Alamofire.DownloadRequest, formedFrom networkRequest: BaseRequest<Model>) {
        
    }
}
