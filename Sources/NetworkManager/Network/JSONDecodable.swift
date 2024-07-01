//
//  JSONDecodable.swift
//  AlamofireWrapper
//
//  Created by Mayur G on 08/06/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation
import Alamofire

/**
 Protocol for creating model from JSON object.
 */
public protocol JSONDecodable  {
    
    /// Creates model object from SwiftyJSON.JSON struct.
    init(response: HTTPURLResponse, representation: Any, responseData: Data?) throws

}

/// `JSONDecodable` data response parser
public struct JSONDecodableParser<Model: JSONDecodable> : NetworkDataResponseSerializerProtocol
{
    public init() {}
    
    /// A closure used by response handlers that takes a request, response, data and error and returns a result.
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<Model> {
        return { request, response, data, error in
            guard error == nil else { return .failure(error!) }
            
            let jsonResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonResponseSerializer.serializeResponse(request, response, data, nil)
            
            guard case let .success(jsonObject) = result else {
                let stringResponseSerializer = DataRequest.stringResponseSerializer(encoding: .utf8)
                let result = stringResponseSerializer.serializeResponse(request, response, data, nil)
                
                if case let .success(value) = result, let response = response, let responseObject = try? Model(response: response, representation: value, responseData: data) {
                    return .success(responseObject)
                }

                return .failure(result.error!)
            }
            
            guard let response = response, let responseObject = try? Model(response: response, representation: jsonObject, responseData: data) else {
                let reason = "JSON could not be serialized: \(jsonObject)"
                let err = NSError(domain: "CBZNetworkJSONParsing", code: 0, userInfo: [NSLocalizedDescriptionKey :  NSLocalizedString("JSON Parsing error", value: reason, comment: "")])
                return .failure(AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: err)))
            }
            
            return .success(responseObject)
        }
    }
}

extension String: JSONDecodable {
    
    public init(response: HTTPURLResponse, representation: Any, responseData: Data?) {
        let stringValue = representation as? String
        self.init(stringLiteral: stringValue ?? "")
    }
}

/// Parser
public protocol JSONParseable {
    func parse<T: Codable>(_ data: Data) -> T?
}

public extension JSONParseable {
    func parse<T: Codable>(_ data: Data) -> T? {
        let model = try? JSONDecoder().decode(T.self, from: data)
        return model
    }
}
