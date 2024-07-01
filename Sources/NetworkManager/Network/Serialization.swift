//
//  Serialization.swift
//  AlamofireWrapper
//
//  Created by Mayur G on 08/06/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation
import Alamofire

/// The type in which all data and upload response serializers must conform to in order to serialize a response.
public protocol NetworkDataResponseSerializerProtocol : DataResponseSerializerProtocol {
    
    /// A closure used by response handlers that takes a parsed result, request, response, data and error and returns a serialized error.
    var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<SerializedObject> { get }
}
