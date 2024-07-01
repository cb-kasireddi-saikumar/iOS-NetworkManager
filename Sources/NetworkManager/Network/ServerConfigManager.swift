//
//  CBZWatchServerConfigManager.swift
//  WatchApp Extension
//
//  Created by Sandeep GS on 12/10/20.
//  Copyright © 2020 Cricbuzz. All rights reserved.
//

import Alamofire
import RxSwift
import RxCocoa
import Foundation

public typealias ConfigRequestURLType = (url: String?, authTypeValue: String?)

private let UserDefaultWatchEndpointsKey: String = "watchEndpoints"
private let UserDefaultWatchSettingsKey: String = "watchSettings"

public struct ServerConfigManagerDependencies {
    let httpScheme: String
    let serverURL: String
    let settings: String?
    let endpoints: String?
    
    public init(httpScheme: String,
                serverURL: String,
                settings: String?,
                endpoints: String?) {
        self.httpScheme = httpScheme
        self.serverURL = serverURL
        self.settings = settings
        self.endpoints = endpoints
    }
}

public class ServerConfigManager {
    
    /// shared instance
    public static let shared = ServerConfigManager()
    
    /// A list of closures which are waiting for server endpoints to be fetched from database
    private var serverReqClosuresForStorage: [(Bool)->Void] = []
    
    /// A list of closures which are waiting for server endpoints to be fetched from network
    private var serverReqClosuresForNetwork: [(Endpoints?, Settings?)->Void] = []
    
    public var dependencies: ServerConfigManagerDependencies?
    
    /// Mutual exclusive to access endpointsReq array
    //private let lock = NSLock()
    
    /// Rx disposable bag for object ownership at one place
    private var disposeBag = DisposeBag()
    
    ///
    var serverEndpoints: Endpoints? {
        didSet {
            populateCachedendpoints()
            storeEndpoints()
        }
    }
    
    ///
    public var serverSettings: Settings? {
        didSet {
            storeSettings()
        }
    }
    
    ///
    var cachedEndpoints: CachedEndpoints?
    
    private func populateCachedendpoints() {
        if let serverEndpoints = serverEndpoints {
            self.cachedEndpoints = CachedEndpoints(urls: serverEndpoints.appUrls,
                                                   modules: serverEndpoints.modules,
                                                   images: serverEndpoints.imgPath)
            
            self.cachedEndpoints?.didChangedModule = { [weak self] (module) in
                if let idx = (serverEndpoints.modules.firstIndex{ $0.name == module.name }) {
                    guard let strongSelf = self else { return }
                    var endpoints = strongSelf.serverEndpoints!
                    endpoints.modules[idx] = module
                    strongSelf.saveEndpoints(withJSONString: try? endpoints.jsonString())
                }
            }
        }
    }
    
    private func saveEndpoints(withJSONString: String?) {
        if let jsonString = withJSONString {
            UserDefaults.standard.set(jsonString, forKey: UserDefaultWatchEndpointsKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func storeEndpoints() {
        if let endpoints = serverEndpoints {
            saveEndpoints(withJSONString: try? endpoints.jsonString())
        }
    }
    
    private func saveSettings(withJSONString: String?) {
        if let jsonString = withJSONString {
            UserDefaults.standard.set(jsonString, forKey: UserDefaultWatchSettingsKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func storeSettings() {
        if let settings = serverSettings {
            saveSettings(withJSONString: try? settings.jsonString())
        }
    }
    
    // MARK:- Object life cycle
    
    public init() { }
    
    public func insertDependencies(dependencies: ServerConfigManagerDependencies) {
        self.dependencies = dependencies
    }
    
    func burstCache() {
        fetchServerConfigFromNetwork{ [weak self] (endpoints, settings) in
            guard let strongSelf = self else { return }
            strongSelf.updateEndpoints(endpoints: endpoints)
        }
    }
    
    func checkBurstCacheIfNeeded(with lastEndpointsUpdated: TimeInterval?,
                                 lastSettingsUpdated: TimeInterval? = nil,
                                 endpointURLType: ConfigRequestURLType? = nil,
                                 isFetchSuccessful: ((Bool)->())? = nil) {
        
        fetchServerConfigFromStorage { [weak self] (isSuccess) in
            
            print("Check if burst cache needed on launch")
            
            if isSuccess {
                guard let strongSelf = self else { return }
                
                var includeEndpoints = (Double(strongSelf.serverEndpoints?.lastUpdatedTime ?? 0) != lastEndpointsUpdated)
                var includeSettings = (Double(strongSelf.serverSettings?.lastUpdateTime ?? 0) != lastSettingsUpdated)
                
                if lastEndpointsUpdated == 1 { includeEndpoints = false }
                if lastSettingsUpdated == 1 { includeSettings = false }
                
                strongSelf.fetchServerConfigFromNetwork(includeEndpoints: includeEndpoints, includeSettings: includeSettings, endpointURLType: endpointURLType) { [weak self] (endpoints, settings) in
                    
                    guard let weakSelf = self else {
                        isFetchSuccessful?(false)
                        return
                    }

                    weakSelf.updateEndpoints(endpoints: endpoints)
                    weakSelf.updateSettings(settings: settings)
                    
                    if endpoints != nil, settings != nil {
                        isFetchSuccessful?(true)
                    } else {
                        isFetchSuccessful?(false)
                    }
                }
            } else {
                isFetchSuccessful?(false)
            }
        }
    }
    
    private func updateEndpoints(endpoints: Endpoints?) {
        if let ep = endpoints {
            self.serverEndpoints = ep
        }
    }

    private func updateSettings(settings: Settings?) {
        if let settingsFeed = settings {
            self.serverSettings = settingsFeed
        }
    }
    
    /**
    retrieve geo location
     - parameter handler: Closure, will be called after fetching.
     */
    func fetchGeoLocation(_ withHandler: @escaping (String?, String?) -> Void) {
        if let fetchLocation = getLocationRequest() {
            print("request -> \(fetchLocation.url?.absoluteString ?? "")")
            
            URLSession.shared.rx.json(request: fetchLocation)
                .subscribe(onNext: { (response) in
                    if let locationDict = response as? [String : String],
                        let country = locationDict["country"], !country.isEmpty {
                        let city = locationDict["city"]
                        withHandler(country, city)
                    } else {
                        withHandler(nil, nil)
                    }
                }, onError: { (error) in
                    withHandler(nil, nil)
                }, onCompleted: {
                }).disposed(by: disposeBag)
        }
    }
    
    private func getLocationRequest() -> URLRequest? {
        let reqString = TrailingSlash(endpointURL) + "geo-location"
        if let url = URL(string: reqString) {
            var request = URLRequest(url: url)
            
            var headers: [String : String] = [:]
            headers["Accept"] = "application/json"
            if let headerBuilder = NetworkManager.shared.headerBuilder as? HeaderBuilder {
                headers = headerBuilder.applyAuthentication(to: url, authType: nil, additionalHeaders: headers)
            }
            for header in headers {
                request.addValue(header.value, forHTTPHeaderField: header.key)
            }
            return request
        }
        return nil
    }
    
    // MARK:- Serve config fetch & store

    /// A bool which indicates weather server APIs are in progress or not
    private var isFetchingServerAPIsFromStorage = false
    
    /**
     retrieve server endpoints from database
     First it will try to get from Core Data, if not found will use JSON files
     
     - parameter handler: Closure, will be called after fetching.
     */
    public func fetchServerConfigFromStorage(_ withHandler: @escaping (_ isSuccess: Bool)->Void) {
        
        let handler = withHandler
        
        let endpoints = serverEndpoints
        let settings = serverSettings
        
        if endpoints != nil, settings != nil {
            handler(true)
            return
        }
        
        serverReqClosuresForStorage.append(handler)
        
        if isFetchingServerAPIsFromStorage == false {
        
            isFetchingServerAPIsFromStorage = true
            
            print("fetching server configs from storage")
            
            if let endpointsJSON = UserDefaults.standard.string(forKey: UserDefaultWatchEndpointsKey),
               !endpointsJSON.isEmpty {
                self.serverEndpoints = try? Endpoints(jsonString: endpointsJSON)
            } else {
                let jsonStr = dependencies?.endpoints
                self.serverEndpoints = try? Endpoints(jsonString: jsonStr!)
            }
            
            print("fetching server configs from storage")
            
            if let settingsJSON = UserDefaults.standard.string(forKey: UserDefaultWatchSettingsKey),
               !settingsJSON.isEmpty {
                self.serverSettings = try? Settings(jsonString: settingsJSON)
            } else {
                let jsonStr = dependencies?.settings
                self.serverSettings = try? Settings(jsonString: jsonStr!)
            }
            
            self.cleanupServerRequestsForStorage(isSuccess: serverEndpoints != nil)
            self.isFetchingServerAPIsFromStorage = false
        }
    }
    
    /// A bool which indicates weather server APIs are in progress or not
    private var isFetchingServerAPIsFromNetwork = false

    /**
     retrieve server endpoints from network
     
     - parameter handler: Closure, will be called after fetching.
     */
    public func fetchServerConfigFromNetwork( includeEndpoints: Bool = true,
                                              includeSettings: Bool = false,
                                              endpointURLType: ConfigRequestURLType? = nil,
                                              updateConfigsInDatabase: Bool = false,
                                              _ withHandler: @escaping (Endpoints?, Settings?) ->Void)
    {
        let handler = withHandler
        
        serverReqClosuresForNetwork.append(handler)
        
        if isFetchingServerAPIsFromNetwork == false {
            
            isFetchingServerAPIsFromNetwork = true
            
            // cancel previous sequence if any, by altering bag for safety
            disposeBag = DisposeBag()

            if includeEndpoints, includeSettings {
                let fetchEndpoints = getConfigRequest(isSettings: false, requestURLType: endpointURLType)
                let fetchSettings = getConfigRequest(isSettings: true)
                
                Observable.zip(
                    URLSession.shared.rx.response(request: fetchEndpoints),
                    URLSession.shared.rx.response(request: fetchSettings)
                )
                .subscribe(
                    onNext: { [weak self] (result: (endpoints: (HTTPURLResponse, Data), settings: (HTTPURLResponse, Data))) in
                        guard let strongSelf = self else { return }
                        
                        var endpoints: Endpoints? = strongSelf.serializeData(request: fetchEndpoints,
                                                                             response: result.endpoints.0,
                                                                             data: result.endpoints.1)
                        
                        let settings: Settings? = strongSelf.serializeData(request: fetchSettings,
                                                                           response: result.settings.0,
                                                                           data: result.settings.1)
                    #if DEBUG
                        if endpoints != nil {
                            print("endpoints json from server:\n\(try! endpoints!.jsonString())")
                        }
                        
                        if settings != nil {
                            print("settings json from server:\n\(try! settings!.jsonString())")
                        }
                    #endif
                        
                        if endpoints?.isEndpointsEmpty() == true {
                            print("Warning: Recieved network endpoints is empty.")
                            endpoints = nil
                        }
                        
                        strongSelf.cleanupServerRequestsForNetwork(endpoints: endpoints, settings: settings, shouldUpdateConfigsIntoDatabase: updateConfigsInDatabase)
                        strongSelf.isFetchingServerAPIsFromNetwork = false
                    },
                    onError: { [weak self] (err) in
                        guard let strongSelf = self else { return }
                        strongSelf.cleanupServerRequestsForNetwork(endpoints: nil, settings: nil, shouldUpdateConfigsIntoDatabase: updateConfigsInDatabase)
                        strongSelf.isFetchingServerAPIsFromNetwork = false
                    }
                )
                .disposed(by: disposeBag)
            }
            
            else if includeSettings {
                
                let fetchSettings = getConfigRequest(isSettings: true, requestURLType: nil)
                
                print("fetching server configs from Network")
                print("request -> \(fetchSettings.url?.absoluteString ?? "")")
                
                URLSession.shared.rx
                    .response(request: fetchSettings)
                    .subscribe(onNext: { [weak self] (result) in
                        guard let strongSelf = self else { return }
                        
                        var settings: Settings? = strongSelf.serializeData(request: fetchSettings,
                                                                           response: result.0,
                                                                           data: result.1)
#if DEBUG
                        if settings != nil {
                            print("settings json from server:\n\(try! settings!.jsonString())")
                        }
#endif
                        
                        if settings?.isSettingsEmpty() == true {
                            settings = nil
                        }
                        
                        strongSelf.cleanupServerRequestsForNetwork(endpoints: nil, settings: settings, shouldUpdateConfigsIntoDatabase: updateConfigsInDatabase)
                        strongSelf.isFetchingServerAPIsFromNetwork = false
                        
                    }, onError: { [weak self] (err) in
                        guard let strongSelf = self else { return }
                        strongSelf.cleanupServerRequestsForNetwork(endpoints: nil, settings: nil, shouldUpdateConfigsIntoDatabase: updateConfigsInDatabase)
                        strongSelf.isFetchingServerAPIsFromNetwork = false
                    })
                    .disposed(by: disposeBag)
            }
            
            else if includeEndpoints {
                
                let fetchEndpoints = getConfigRequest(isSettings: false, requestURLType: endpointURLType)

                print("fetching server configs from Network")
                print("request -> \(fetchEndpoints.url?.absoluteString ?? "")")
                
                URLSession.shared.rx
                    .response(request: fetchEndpoints)
                    .subscribe(onNext: { [weak self] (result: (HTTPURLResponse, Data)) in
                        guard let strongSelf = self else { return }
                        
                        var endpoints: Endpoints? = strongSelf.serializeData(request: fetchEndpoints,
                                                                             response: result.0,
                                                                             data: result.1)
                        #if DEBUG
                        if endpoints != nil {
                            print("endpoints json from server:\n\(try! endpoints!.jsonString())")
                        }
                        #endif
                        
                        if endpoints?.isEndpointsEmpty() == true {
                            print("Warning: Recieved network endpoints is empty.")
                            endpoints = nil
                        }
                        
                        strongSelf.cleanupServerRequestsForNetwork(endpoints: endpoints, settings: nil, shouldUpdateConfigsIntoDatabase: updateConfigsInDatabase)
                        strongSelf.isFetchingServerAPIsFromNetwork = false
                    },
                    onError: { [weak self] (err) in
                        guard let strongSelf = self else { return }
                        strongSelf.cleanupServerRequestsForNetwork(endpoints: nil, settings: nil, shouldUpdateConfigsIntoDatabase: updateConfigsInDatabase)
                        strongSelf.isFetchingServerAPIsFromNetwork = false
                    }
                )
                .disposed(by: disposeBag)
                
            } else {
                cleanupServerRequestsForNetwork(endpoints: nil, settings: nil, shouldUpdateConfigsIntoDatabase: updateConfigsInDatabase)
                isFetchingServerAPIsFromNetwork = false
            }
        }
    }
    
    
    // MARK:- Utils
    
    private func cleanupServerRequestsForStorage(isSuccess: Bool) {
        //self.lock.lock() ; defer { self.lock.unlock() }
        // clean up all stored handlers
        for block in self.serverReqClosuresForStorage {
            block(isSuccess)
        }
        self.serverReqClosuresForStorage = []
    }
    
    private func cleanupServerRequestsForNetwork(endpoints: Endpoints?, settings: Settings?, shouldUpdateConfigsIntoDatabase: Bool = true) {
        // save the fetched data
        if shouldUpdateConfigsIntoDatabase {
            self.updateSettings(settings: settings)
            self.updateEndpoints(endpoints: endpoints)
        }

        // clean up all stored handlers
        for block in self.serverReqClosuresForNetwork {
            block(endpoints, settings)
        }
        self.serverReqClosuresForNetwork = []
    }
    
    private func getConfigRequest(isSettings: Bool, requestURLType: ConfigRequestURLType? = nil) -> URLRequest {
        var reqString = TrailingSlash(endpointURL) + (isSettings ? "settings" : "endpoints")
        print("request ---> \(reqString)")
        var authTypeValue = ""
        if let requestURLType = requestURLType {
            if let requestURL = requestURLType.url, !requestURL.isEmpty, let _ = URL(string: requestURL) {
                reqString = requestURL
            }
            if let authType = requestURLType.authTypeValue, !authType.isEmpty {
                authTypeValue = authType
            }
        }
        let url = URL(string: reqString)!
        var request = URLRequest(url: url)
        
        var headers: [String : String] = [:]
        headers["Accept"] = "application/x-protobuf"
        if let headerBuilder = NetworkManager.shared.headerBuilder as? HeaderBuilder {
            let authType = AuthType(rawValue: authTypeValue)
            headers = headerBuilder.applyAuthentication(to: url, authType: authType, additionalHeaders: headers)
        }
        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        return request
    }
    
    private func serializeData<T: ProtoBufDecodable>(request: URLRequest, response: HTTPURLResponse, data: Data, error: Error? = nil) -> T? {
        var model: T?
        let serializer = ProtobufDecodableParser<T>()
        let result = serializer.serializeResponse(request, response, data, error)
        
        switch result {
        case .success(let value):
            model = value
        case .failure(_):
            break
        }
        
        return model
    }
}
