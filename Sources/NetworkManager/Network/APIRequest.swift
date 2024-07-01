//
//  CBZWatchAPIRequest.swift
//  WatchApp Extension
//
//  Created by Sandeep GS on 12/10/20.
//  Copyright © 2020 Cricbuzz. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift

open class APIRequest<Model>: BaseRequest<Model> {
    
    /// Serializes received response into APIResponse<Model>
    open var responseParser : ResponseParser
    
    /// Alamofire request
    open weak var urlRequest: Request?
    
    /// CBZRoute value
    open var route: NetworkRoute
    
    /// maximum number of retries
    private var retryAttempts = 0
    
    /// indicate if request has been cancelled
    private var isCancelled = false
    
    private var cbzNetworkDelegate: NetworkManager? {
        return networkDelegate as? NetworkManager
    }
    
    /// Creates `APIRequest`, filling `responseParser` and `errorParser` properties
    public init<Serializer : NetworkDataResponseSerializerProtocol>(route: NetworkRoute, network: BaseNetworkManager, responseSerializer: Serializer)
        where Serializer.SerializedObject == Model
    {
        self.route = route
        self.responseParser = { request, response, data, error in
            responseSerializer.serializeResponse(request,response,data,error)
        }
        
        super.init(path: "", network: network)

    }
    
    override func alamofireRequest(from manager: SessionManager, for url: URL? = nil) -> Request {
        var headersList: [String: String]
        let requestUrl: URL = url ?? requestingURL(checkValidity: false)!
        
        if let headerBuilder = headerBuilder as? HeaderBuilder {
            headersList = headerBuilder.headers(forAuthorizationRequirement: authorizationRequirement, forURL: requestUrl, including: headers)
        } else {
            headersList = headerBuilder.headers(forAuthorizationRequirement: authorizationRequirement, including: headers)
        }
        
        if let data = httpBody {
            urlRequest = manager.upload(data, to: requestUrl, method: method, headers: headersList)
        } else {
            urlRequest = manager.request(requestUrl,
                                         method: method,
                                         parameters: parameters,
                                         encoding: parameterEncoding,
                                         headers: headersList)
        }
        
        return urlRequest!
    }
    
    private func requestingURL(checkValidity: Bool = true) -> URL? {
        var requestUrl: URL
        if let urlBuilder = urlBuilder as? URLBuilder {
            requestUrl = urlBuilder.url(forRoute: route)
        } else {
            requestUrl = urlBuilder.url(forPath: path)
        }
        
        guard checkValidity else {
            return requestUrl
        }
        
        guard let host = requestUrl.host, !host.isEmpty else { return nil }
        
        return requestUrl
    }
    
    /**
     Send current request.
     
     - parameter successBlock: Success block to be executed when request finished
     
     - parameter failureBlock: Failure block to be executed if request fails. Nil by default.
     
     - returns: Alamofire.Request or nil if request was stubbed.
     */
    @discardableResult
    open func perform(withSuccess successBlock: ((APIResponse<Model>) -> Void)? = nil, failure failureBlock: ((Error) -> Void)? = nil) -> Self
    {
        checkSettingsAndPerform {
            self.callSuccessFailureBlocks(successBlock, failure: failureBlock, response: $0)
        }
        return self
    }
    
    /**
     Perform current request with completion block, that contains Alamofire.Response.
     
     - parameter completion: Alamofire.Response completion block.
     
     - returns: Alamofire.Request or nil if request was stubbed.
     */
    @discardableResult
    open func perform(withCompletion completion: @escaping ((APIResponse<Model>) -> Void)) -> Self
    {
        checkSettingsAndPerform(completion)
        return self
    }
    
    /// Cancels the request.
    open func cancel() {
        urlRequest?.cancel()
        isCancelled = true
    }
    
    private func checkSettingsAndPerform(_ completion : @escaping (APIResponse<Model>) -> Void) {
        isCancelled = false
        
        if let network = cbzNetworkDelegate, (network.serverConfigManager.serverEndpoints == nil ||  network.serverConfigManager.serverEndpoints?.isEndpointsEmpty() == true) {
            
            print("Endpoints missing")
            network.serverConfigManager.fetchServerConfigFromStorage { _ in
                self.performAlamofireRequest(completion)
            }
            
        } else {
            performAlamofireRequest(completion)
        }
    }
    
    private func performAlamofireRequest(_ completion : @escaping (APIResponse<Model>) -> Void)
    {
        if isCancelled {
            return
        }
        
        //
        guard let url = requestingURL() else {
            print("requesting url is invalid, ignoring it...")
            return
        }

        guard let manager = networkDelegate?.manager else {
            fatalError("Manager cannot be nil while performing APIRequest")
        }
        
        willSendRequest()
        guard let request = alamofireRequest(from: manager, for: url) as? DataRequest else {
            fatalError("Failed to receive DataRequest")
        }
        willSendAlamofireRequest(request)
        if !networkDelegate!.manager.startRequestsImmediately {
            request.resume()
        }
        didSendAlamofireRequest(request)
        
        request
            .validate(statusCode: 200..<300)
            .response(
                queue: resultDeliveryQueue,
                responseSerializer: dataResponseSerializer(with: request),
                completionHandler: { dataResponse in
                    self.didReceiveDataResponse(dataResponse, forRequest: request)
            
                    if self.isCancelled {
                        return
                    }
                    
                    if false == self.allowRetryRequestFor(dataResponse: dataResponse, withCompletion: completion) {
                        let result = APIResponse(request: dataResponse.request,
                                                 response: dataResponse.response,
                                                 data: dataResponse.data,
                                                 error: dataResponse.error,
                                                 value: dataResponse.value,
                                                 timeline: dataResponse.timeline)
                        
                        DispatchQueue.main.async {
                            completion(result)
                        }
                    }
            })
    }
    
    // retry request if needed
    private func allowRetryRequestFor(dataResponse: DataResponse<Model>, withCompletion completion: @escaping (APIResponse<Model>) -> Void) -> Bool {
        
        var shouldRetry = false
        
        if let error = dataResponse.error {
            // if offline then no need to retry
            if (error as? URLError)?.code == URLError.notConnectedToInternet {
                return false
            }
        } else {
            return false
        }
        
        let err = dataResponse.error! as NSError
        
        let code = dataResponse.response?.statusCode
                    ?? err.code
        
        print("error:\(err) and its code:\(code)")
        
        var shouldRetryForErrorResponse = true
        if let _ = dataResponse.error, let data = dataResponse.data {
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : Any] {
                    let customError = CustomError(json: jsonObject, forceFetchEndpoints: false, errorRetryInfo: nil)
                    shouldRetryForErrorResponse = customError.errorCode.shouldRetryRequest
                }
            } catch {
                    //
            }
        }
        
        // do not retry for these conditions
        if shouldRetryForErrorResponse, let urlBuilder = urlBuilder as? URLBuilder, code.shouldRetryRequest {
            var urlPath, host: String
            
            urlPath = route.nodeValue
            host = urlBuilder.url(forRoute: route).host ?? ""
            
            let isDomainChanged = urlBuilder.serverConfigManager.cachedEndpoints?.switchDomainIfNeededFor(path: urlPath, previousHost: host) ?? false
            let isHeaderChanged = handleRetry(response: dataResponse.response)
            
            shouldRetry = isHeaderChanged || isDomainChanged
            
            /// this case will execute when the requested url is not the appurl's
            if let totalAppURLCount = urlBuilder.serverConfigManager.serverEndpoints?.appUrls.count,
                (retryAttempts > (totalAppURLCount*2)) {
                shouldRetry = false
            }

            if shouldRetry == true {
                retryAttempts += 1
                self.performAlamofireRequest(completion)
            }
        }
        
        return shouldRetry
    }
    
    // handle failed request
    private func handleRetry(response: HTTPURLResponse?) -> Bool {
        
        // If request failed due to Forbidden, must be due to time difference
        if let headerBuilder = headerBuilder as? HeaderBuilder, response?.statusCode == 403 {
            
            // Number of retry must be maximum 3
            if retryAttempts > 3 {
                retryAttempts = 0
                return false
            }
            
            // get response date from it's headers
            let resDateString = response?.allHeaderFields["Date"] as? String
            guard let responseDate = self.date(string: resDateString) else {
                return false
            }
            
            // find UTA difference respect to your device time
            let systemInterval = Date().timeIntervalSince1970.rounded()
            let responseInterval = responseDate.timeIntervalSince1970.rounded()
            headerBuilder.requestUTADiff = Int(responseInterval - systemInterval)
            
            return false
            
        } else {
            return false
        }
    }
    
    internal func dataResponseSerializer(with request: Request) -> Alamofire.DataResponseSerializer<Model> {
        return DataResponseSerializer<Model> { urlRequest, response, data, error in
            
            self.willProcessResponse((urlRequest,response,data,error), for: request)
            var result : Alamofire.Result<Model>
            var apiError : Error?
            var parsedModel : Model?
            
            if let error = error {
                apiError = error
                result = .failure(error)
            } else {
                result = self.responseParser(urlRequest, response, data, error)
                if let model = result.value {
                    parsedModel = model
                    result = .success(model)
                } else if let err = result.error {
                    apiError = err
                    result = .failure(err)
                }
            }
            if let error = apiError {
                self.didReceiveError(error, for: (urlRequest,response,data,error), request: request)
            } else if let model = parsedModel {
                self.didSuccessfullyParseResponse((urlRequest,response,data,error), creating: model, forRequest: request)
            }
            
            return result
        }
    }
    
    // String to Date conversion
    private func date(string dateString: String?) -> Date? {
        
        if let dateStr = dateString {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, dd LLL yyyy HH:mm:ss zzz"
            return dateFormatter.date(from: dateStr)
        } else {
            return nil
        }
    }
    
}

extension APIRequest {
    
    /**
     Creates on Observable of success Model type. It starts a request each time it's subscribed to.
     
     - returns: Observable<Model>
     */
    public func rxResult() -> Observable<APIResponse<Model>> {
        return Observable.create({ observer in
            let token = self.perform(withSuccess: { result in
                observer.onNext(result)
                observer.onCompleted()
            }, failure: { error in
                observer.onError(error)
            })
            return Disposables.create {
                token.cancel()
            }
        })
    }
}

//
fileprivate extension Int {
    
    var shouldRetryRequest: Bool {
        var shouldRetry: Bool = true
            switch self {
                case 304, 417, 429: shouldRetry = false
                default: break
            }
        return shouldRetry
    }
}
