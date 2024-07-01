//
//  CBZWatchURLBuilder.swift
//  WatchApp Extension
//
//  Created by Sandeep GS on 12/10/20.
//  Copyright © 2020 Cricbuzz. All rights reserved.
//

import Foundation

protocol URLBuildableBase: URLBuildable {
    /**
     Construct URL with given CBZRouter
     
     - parameter route: CBZRouter value
     
     - returns constructed URL
     */
    func url(forRoute route: NetworkRoute) -> URL
    
    /**
     Construct URL with given CBZRouter and make sure server endpoints are fetched
     
     - parameter route: CBZRouter value
     
     - parameter completion: block will call after fetching endpoints
     */
    func asyncUrl(forRoute route: NetworkRoute, _ completion: @escaping (URL)->Void) -> Void
}

/**
 * `CBZURLBuilder` instance have all the logic in order to generate full url
 */
open class URLBuilder : BaseURLBuilder {
    
    internal let serverConfigManager: ServerConfigManager
    
    public init(serverConfigs: ServerConfigManager = ServerConfigManager.shared) {
        self.serverConfigManager = serverConfigs
        super.init(baseURL: "")
    }
}

extension URLBuilder: URLBuildableBase {
    
    public func urlString(_ forRoute: NetworkRoute) -> String {
        
        switch forRoute {
            // apis
            case .endpoints:
                return TrailingSlash(endpointURL) + "endpoints"
            
            // tv
            case .videosCategories:
                return TrailingSlash(baseURL(forRoute)) + "cat"
            
            case .videoSuggestions(let videoId):
                return TrailingSlash(baseURL(forRoute)) + TrailingSlash("sugg") + videoId
            
            case .listOfMatchVideos(let matchId):
                return TrailingSlash(baseURL(forRoute)) + "matchStream/\(matchId)"
            
            case .videoDetail(let videoId, let userState):
                let url = TrailingSlash(baseURL(forRoute)) + TrailingSlash("plain-detail") + videoId
                var params: [String: String] = [:]
                userState.map { params["userState"] = $0 }

                return url + params.queryString
            
            case .videos(let categoryId, let playlistId, let lastVideoId, let isPremium, let lastVideoPublishedTime):
                var url = TrailingSlash(baseURL(forRoute))
                var useLastVideoID: Bool = true
                
                if let catId = categoryId {
                    url += "cat/\(catId)"
                } else if let pId = playlistId {
                    if pId == "5" {
                        url += "featured"
                    } else {
                        url += "playlist/\(pId)"
                    }
                } else {
                    url += isPremium ? "premiumIndex" : "index"
                    useLastVideoID = false
                }
                
                var params: [String: String] = [:]
                
                /// in case of video index, we need to pass published time for next page and video id for categories/playlists
                if useLastVideoID {
                    lastVideoId.map { params["lastId"] = $0 }
                } else {
                    lastVideoPublishedTime.map { params["pt"] = $0 }
                }
                
                return url + params.queryString

            case .videoCollections(let lastCollectionOrderId, let categoryId, let collectionId, let lastVideoPublishedTime, let isPremiumCollection):
                var url = TrailingSlash(baseURL(forRoute))
                if let catId = categoryId {
                    url += "collection/cat/\(catId)"
                } else if let cId = collectionId {
                    url += "collection/detail/\(cId)"
                } else {
                    url += isPremiumCollection ? "collection/premiumIndex" : "collection/videoIndex"
                }
                var params: [String: String] = [:]
                // if there is published time, then send the same instead of order id
                if let _ = lastVideoPublishedTime {
                    lastVideoPublishedTime.map { params["pt"] = $0 }
                } else {
                    lastCollectionOrderId.map { params["order"] = $0 }
                }
                return url + params.queryString
            
            // user api's
            case .userSignIn:
                return TrailingSlash(baseURL(forRoute)) + "user/sign-in"
                
            case .verifyOTP:
                return TrailingSlash(baseURL(forRoute)) + "user/verify-otp"

            case .verifyToken:
                return TrailingSlash(baseURL(forRoute)) + "user/verify-token"

            case .verifyUserAccess:
                return TrailingSlash(baseURL(forRoute)) + "user/verify-access"
            
            case .refreshToken:
                return TrailingSlash(baseURL(forRoute)) + "user/refresh-token"
            
            case .userSignout:
                return TrailingSlash(baseURL(forRoute)) + "user/sign-out"
            
            case .smsCountryList:
                return TrailingSlash(baseURL(forRoute)) + "country/sms"
            
            case .premiumHomePage:
                return TrailingSlash(baseURL(forRoute)) + "premiumIndex"
            
            // images
            case .moduleImage(let imageId, let sizeType, let densityType):
                var params: [String : String] = ["p": sizeType.rawValue]
                if !densityType.densityValue.isEmpty {
                    params["d"] = densityType.densityValue
                }
                let moduleImageURL: String = TrailingSlash(baseURL(forRoute)) + "i1/c\(imageId)/i.jpg" + params.queryString
                var imageURL = moduleImageURL
                #if STAGING
                    imageURL = imageURL.replacingOccurrences(of: "cricbuzz.stg", with: "cricbuzz.com")
                    imageURL = imageURL.replacingOccurrences(of: "http", with: "https")
                    print("for staging")
                #endif
                print("module image url: \(imageURL)")
                return imageURL
                
            case .nonModuleImage(let imageRoute, let imageId, let sizeType, _):
                var params: [String : String] = ["p": sizeType.rawValue]
                params["d"] = "high"
                let url = baseImageURL(imageRoute) ?? ""
                let nonModuleImageURL: String = TrailingSlash(url) + "\(imageId)\(params.queryString)"
                var imageURL = nonModuleImageURL
                #if STAGING
                    imageURL = imageURL.replacingOccurrences(of: "cricbuzz.stg", with: "cricbuzz.com")
                    imageURL = imageURL.replacingOccurrences(of: "http", with: "https")
                    print("for staging")
                #endif
                print("nonmodule image url: \(imageURL)")
                return imageURL
        }
    }
    
    public func url(forRoute route: NetworkRoute) -> URL {
        return URL(string: urlString(route)) ?? URL(string:"1")!
    }
    
    public func asyncUrl(forRoute route: NetworkRoute, _ completion: @escaping (URL)->Void) -> Void {
        if serverConfigManager.serverEndpoints == nil {
            NetworkManager.shared.serverConfigManager.fetchServerConfigFromStorage { _ in
                completion(self.url(forRoute: route))
            }
        } else {
            completion(self.url(forRoute: route))
        }
    }
    
    /// indicates path = uri + version
    public func path(forRoute route: NetworkRoute) -> String {
        let fallbacks = serverConfigManager.cachedEndpoints
        let module = fallbacks?.getModuleFor(path: route.nodeValue)
        if let module = module {
            let finalPath = TrailingSlash(module.uri) + module.version
            return finalPath
        } else {
            return ""
        }
    }
    
    private func baseURL(_ forRoute: NetworkRoute) -> String? {
        let expandedURL = serverConfigManager.cachedEndpoints?.getURLFor(path: forRoute.nodeValue)
        return expandedURL
    }
    
    private func baseImageURL(_ forRoute: ImageRoute) -> String? {
        let expandedURL = serverConfigManager.cachedEndpoints?.getImageURLFor(path: forRoute.rawValue)
        return expandedURL
    }
}
