//
//  Router.swift
//  AlamofireWrapper
//
//  Created by Mayur G on 09/06/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation
import Alamofire

public enum ImageRoute: String {
    case videoCat = "videoCat"
    case venueDetail = "venueDetail"
    case player = "player"
    case video = "video"
    case team = "team"
    case venue = "venue"
}

public enum ImageSizeType: String {
    case thumb = "thumb"
    case detail = "det"
    case gthumb = "gthumb"
}

public enum ImageSizeDimension: String {
    case extraLarge = "150x150"
    case large = "100x100"
    case medium = "80x80"
    case small = "48x48"
    case extraSmall = "32x32"
}

public enum ImageDensityType: String {
    case low = "low"
    case defaultDensity = "default"
    case none = "" // for actual image download pass none to density
}

/**
 * CBZRoute: It represents each url in CBZNetwork
 *
 * based on this enum value and CBZNetworkSettings, CBZURLBuilder will dynamically generate the url
 */
public enum NetworkRoute {
    
    // MARK: - APIs
    
    case endpoints
    
    case videos(categoryId: String?, playlistId: String?, lastVideoId: String?, isPremium: Bool, lastVideoPublishedTime: String?)
    case videosCategories
    case videoSuggestions(videoId: String)
    case videoCollections(lastCollectionOrderId: String?, categoryId: String?, collectionId: String?, lastVideoPublishedTime: String?, isPremiumCollection: Bool)
    case listOfMatchVideos(matchId: String)
    case videoDetail(videoId: String, userState: String?)
    case premiumHomePage
    
    /// user account
    case userSignIn
    case verifyOTP
    case verifyToken
    case verifyUserAccess
    case refreshToken
    case userSignout
    case smsCountryList
    
    // MARK: - Images
    
    /// construct image urls from the image module which is provided in endpoints
    case moduleImage(imageId: String, sizeType: ImageSizeType, density: ImageDensityType)
    /// construct image urls from the non-module node which is provided in the endpoints
    case nonModuleImage(route: ImageRoute, imageId: String, sizeType: ImageSizeType, density: ImageDensityType)
    
    // MARK: - Properties
    
    /// It returns URL path which is associated with API list in endpoint settings
    internal var nodeValue: String {
        switch self {
            case .endpoints:
                return "endpoints"
            case .videos, .videosCategories, .videoSuggestions, .videoCollections, .listOfMatchVideos, .videoDetail:
                return "videos"
            case .userSignIn, .verifyOTP, .verifyToken, .verifyUserAccess, .refreshToken, .userSignout:
                return "iam"
            case .smsCountryList:
                return "subscription"
            case .moduleImage:
                return "image"
            case .nonModuleImage:
                return "images"
            case .premiumHomePage:
                return "home"
        }
    }
    
}
