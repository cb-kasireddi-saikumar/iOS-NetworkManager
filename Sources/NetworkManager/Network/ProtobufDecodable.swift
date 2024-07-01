//
//  ProtoDecodable.swift
//  AlamofireWrapper
//
//  Created by Mayur G on 08/06/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation
import Alamofire
import SwiftProtobuf

/**
 Protocol for creating model from SwiftyProtoBuf object.
 */

public typealias ProtoBufDecodable = SwiftProtobuf.Message

/// `JSONDecodable` data response parser
public struct ProtobufDecodableParser<Model: ProtoBufDecodable> : NetworkDataResponseSerializerProtocol
{
    public init() {}
    
    /// A closure used by response handlers that takes a request, response, data and error and returns a result.
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<Model> {
        return { request, response, data, error in
            
            guard error == nil else { return .failure(error!) }
            
            let result = DataRequest.serializeResponseData(response: response, data: data, error: error)
            
            guard case let .success(dataObject) = result else {
                return .failure(result.error!)
            }
            
            do {
                let t = try Model(serializedData: dataObject)
                return .success(t)
            } catch {
                return .failure(AFError.responseSerializationFailed(reason: .inputDataNil))
            }
            
        }
    }
}
