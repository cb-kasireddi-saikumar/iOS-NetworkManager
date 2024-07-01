//
//  CBZWatchNetwork.swift
//  WatchApp Extension
//
//  Created by Sandeep GS on 12/10/20.
//  Copyright © 2020 Cricbuzz. All rights reserved.
//

import Foundation

open class NetworkManager: BaseNetworkManager {
    
    // shared instance
    public static let shared = NetworkManager()
    
    public var cbzUrlBuilder: URLBuilder? {
        return urlBuilder as? URLBuilder
    }
    
    /// convience property to get CBZHeaderBuilder
    public var cbzHeaderBuilder: HeaderBuilder? {
        return headerBuilder as? HeaderBuilder
    }
    
    /// A class which responsible for fetching server configurations
    public var serverConfigManager: ServerConfigManager
    
    /// User defaults
    private let userDefaults: UserDefaults
    
    /**
     Initializes `CBZNetwork`
     
     - overrides urlBuilder and headerBuilde
     */
    public init(urlBuilder: URLBuilder = URLBuilder(),
                headerBuilder: HeaderBuilder = HeaderBuilder(defaultHeaders: [:]),
                userDefaults: UserDefaults = UserDefaults.standard,
                serverConfigManager: ServerConfigManager = ServerConfigManager.shared)
    {
        self.userDefaults = userDefaults
        self.serverConfigManager = serverConfigManager
        
        super.init(baseURL: "", plugins: [NetworkLoggerPlugin()])
        
        // override values
        self.urlBuilder = urlBuilder
        self.headerBuilder = headerBuilder
        
        // this is singleton instance, so refresh configs if required
        self.serverConfigManager.fetchServerConfigFromStorage { _ in }
    }
    
    /// clear cache in CBZNetwork module
    public func burstCache() {
        print("burst cache CBZNetwork")
        
        cbzHeaderBuilder?.burstCache()
        
        URLCache.shared.removeAllCachedResponses()
        
        serverConfigManager.burstCache()
    }
}

extension NetworkManager {
    
    /**
     Creates APIRequest with specified relative path and type RequestType.Default.
     
     - parameter path: Path, that will be appended to current `baseURL`.
     
     - returns: APIRequest instance.
     */
    @discardableResult
    public func request<Model: ProtoBufDecodable>(_ route: NetworkRoute, _ completion: ((APIResponse<Model>) -> Void)? = nil) -> APIRequest<Model>
    {
        let request: APIRequest<Model> = APIRequest(route: route, network: self, responseSerializer: ProtobufDecodableParser())
        
        request.headers = ["Accept": "application/x-protobuf"]
        request.authorizationRequirement = .required
        
        if let completion = completion {
            request.perform(withCompletion: { (result: APIResponse<Model>) in
                completion(result)
            })
        }
        
        return request
    }
}

public class NetworkAPI: NSObject {
    class public func setGlobalHeader(headers: [String: String]) {
        (NetworkManager.shared.headerBuilder as? HeaderBuilder)?.defaultHeaders = headers
    }
    
    class public func checkNetworkBurstCacheIfNeeded(with lastEndpointsUpdated: TimeInterval?,
                                                     endpointURLType: ConfigRequestURLType? = nil,
                                                     lastSettingsUpdated: TimeInterval? = nil,
                                                     isFetchSuccessful: ((Bool)->())? = nil) {
        NetworkManager.shared.serverConfigManager.checkBurstCacheIfNeeded(with: lastEndpointsUpdated,
                                                                           lastSettingsUpdated: lastSettingsUpdated,
                                                                           endpointURLType: endpointURLType,
                                                                           isFetchSuccessful: isFetchSuccessful)
    }
    
    class public func fetchGeoLocation(_ withHandler: @escaping (String?, String?) -> Void) {
        NetworkManager.shared.serverConfigManager.fetchGeoLocation(withHandler)
    }
}

extension NetworkManager {
    public static var serverSettings: Settings? {
        return NetworkManager.shared.serverConfigManager.serverSettings
    }
    
    public static var serverEndpoints: Endpoints? {
        return NetworkManager.shared.serverConfigManager.serverEndpoints
    }
}
