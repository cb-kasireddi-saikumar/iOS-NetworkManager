//
//  APIResponse.swift
//  AlamofireWrapper
//
//  Created by Mayur G on 08/06/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation
import Alamofire

/// `APIResponse<T>` is used as a generic wrapper for all kinds of response.
public struct APIResponse<T> {
    
    /// URLRequest that was unsuccessful
    public let request : URLRequest?
    
    /// Response received from web service
    public let response : HTTPURLResponse?
    
    /// Error instance, created by Foundation Loading System or Alamofire.
    public let error : Error?
    
    /// Parsed model
    public var value : T?
    
    /// The timeline of the complete lifecycle of the request.
    public let timeline: Timeline?
    
    /// The value indicates whether request is triggered with the duplicate call
    public var isSkippedRequest: Bool = false
    
    /// It contains information about error codes when request is failed
    public var responseData: Data?
    
    /// Includes custom error information
    public var customError: CustomError?
    
    /// Informs delegate to fetch the endpoints again in case of authentication failure of all domains
    public var forceFetchEndpoints: Bool = false
    
    /**
     Initialize `APIResponse` with request info.
     
     - parameter request: URLRequest that was requested
     
     - parameter response: response received from web service
     
     - parameter data: data, contained in response
     
     - parameter error: response error, created by Foundation Loading System or Alamofire.
     
     - parameter value: serialised object
     
     - parameter timeline: contains all matric related request i.e. parsing time, response time etc.
     
     - response: Serialised response object
     */
    public init(request : URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?, value: T?, timeline: Timeline?, isSkipped: Bool = false, forceFetchEndpoints: Bool = false, retryInfo: [CBZAPIRetryRequestInfo]? = nil)
    {
        self.request = request
        self.response = response
        self.responseData = data
        self.error = error
        self.value = value
        self.timeline = timeline
        self.isSkippedRequest = isSkipped
        self.forceFetchEndpoints = forceFetchEndpoints
        if let errorJSON = errorResponseJSON {
            self.customError = CustomError(json: errorJSON, forceFetchEndpoints: forceFetchEndpoints, errorRetryInfo: retryInfo)
        } else if forceFetchEndpoints {
            self.customError = CustomError(error: error, forceFetchEndpoints: forceFetchEndpoints, errorRetryInfo: retryInfo)
        }
    }    
}

extension APIResponse {
    
    var errorResponseJSON: [String : Any]? {
        if let _ = error,
           let data = responseData {
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : Any] {
                    print("error json\(jsonObject)")
                    return jsonObject
                }
            } catch let parsingErr {
                print(parsingErr)
                return nil
            }
        }
        return nil
    }
}

public struct CBZAPIRetryRequestInfo {
    
    public var hostURL: String
    public var statusCode: Int
    public var remoteIPAddress: String?
    
    init(host: String, code: Int, remoteIP: String?) {
        self.hostURL = host
        self.statusCode = code
        self.remoteIPAddress = remoteIP
    }
}

public struct CustomError: Error {
    
    static let kMessageKey: String = "message"
    static let kErrorCodeKey: String = "errorCode"
    
    public var errorJSON: [String : Any] = [:]
    public var errorCode: CustomErrorCode = .unknown
    public var message: String?
    public var shouldFetchEndpoints: Bool = false
    public var originalError: Error?
    public var requestRetryInfo: [CBZAPIRetryRequestInfo]?
    
    public enum CustomErrorCode: String {
        case serverError = "15002"
        case accessTokenRevoked = "14001"
        case activeUserError = "14409"
        case dataNotFound = "15000"
        case requestLimitExceed = "14290"
        case sessionTimeOutResendOTP = "14011"
        case invalidOTP = "14013"
        case unknown = "unknown"
        
        var shouldRetryRequest: Bool {
            switch self {
                case .sessionTimeOutResendOTP, .invalidOTP, .requestLimitExceed: return false
                default: return true
            }
        }
    }
    
    init(json: [String : Any], forceFetchEndpoints: Bool, errorRetryInfo: [CBZAPIRetryRequestInfo]?) {
        self.errorJSON = json
        if let errorCode = errorJSON[CustomError.kErrorCodeKey] as? String, !errorCode.isEmpty {
            self.errorCode = CustomErrorCode(rawValue: errorCode) ?? .unknown
        } else if let errorCode = errorJSON[CustomError.kErrorCodeKey] as? Int {
            self.errorCode = CustomErrorCode(rawValue: "\(errorCode)") ?? .unknown
        }
        self.message = errorJSON[CustomError.kMessageKey] as? String
        self.shouldFetchEndpoints = forceFetchEndpoints
        self.requestRetryInfo = errorRetryInfo
    }
    
    init(error: Error?, forceFetchEndpoints: Bool, errorRetryInfo: [CBZAPIRetryRequestInfo]?) {
        self.originalError = error
        self.shouldFetchEndpoints = forceFetchEndpoints
        self.requestRetryInfo = errorRetryInfo
    }
}
