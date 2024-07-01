//
//  Settings+Extension.swift
//  CricbuzzMobile
//
//  Created by Mayur G on 04/09/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation

/**
 * Global constants
 */
public let kFeedRefreshRate: Int32 = 30    // seconds

public enum AnalyticsType: String {
    case colombia = "colombia"
    case crashlytics = "crashlytics"
    case google = "google"
    case inmobi = "inmobi"
    case dmp = "DMP"
    case comscore = "comscore"
    case apsalar = "apsalar"
    case aps = "aps"
}

public enum FeatureToggleType: String {
    case appreview = "appreview"
    case autoplayvideo_news = "autoplay_news"
    case userTime = "enable_analytics_user_time"
    case videoEvents = "enable_video_events"
    case eventAnalytics = "enable_event_analytics"
    case firebaseAnalytics = "enable_firebase_analytics"
    case fcm = "fcm"
    case fantasy = "fantasy"
    case mcenterMenuItem1 = "mcenter_menu_1"
    case mcenterMenuItem2 = "mcenter_menu_2"
    case games = "menu_games"
    case matchCarrouselAdLock = "match_carousel_ad_lock"
    case homeProfileIcon = "home_profile_icon"
    case ccpa = "ccpa"
    case myCoupons = "my_coupons"
    case adSurvey = "ads_survey"
    case fcm_match_notifications = "fcm_match_notifications"
    case mobileLogin = "mobile_login_enabled"
}

public enum RefreshRateType: String {
    case matchCenter = "mcenter"
    case liveblog = "liveblog"
    case commentary = "comm"
    case widget = "widget"
    case home = "home"
    case matches = "matches"
    case cdnStaleFeedTimeDiff = "cdn_stale_time_diff"
}

public enum InterstitialAdValueType: String {
    case interval = "interval"  // in seconds
    case maximum = "maximum"
    case lifespan = "lifespan"  // in hrs
}

public enum InterstitialAdType {
    case news
    case match
    case unknown
}

public enum ShoshAdType {
    case match
}

public enum ShoshAdValueType: String {
    case manualCounter = "manual_counter"  // in seconds
    case autoCounter = "auto_counter" // in seconds
    case threshold = "threshold"  // in minutes
}

public enum PremiumConfigKeys {
    case name
}

public extension Array where Element == FeatureToggle {
    
    func enabled(ofType: FeatureToggleType) -> Bool {
        var isEnabled = false
        
        if let toggleType = (self.filter{ $0.key == ofType.rawValue }).first {
            isEnabled = toggleType.value
        }
        
        return isEnabled
    }
}

public extension Array where Element == RefreshRate {
    
    func value(ofType: RefreshRateType) -> Int32? {
        var refreshRate: Int32 = kFeedRefreshRate
        
        if let refreshRateType = (self.filter{ $0.key == ofType.rawValue }).first {
            refreshRate = refreshRateType.value
        } else if ofType == .cdnStaleFeedTimeDiff {
            return nil
        }
        
        return refreshRate
    }
}

public extension Array where Element == AnalyticsData {

    func enabled(ofType: AnalyticsType) -> Bool {
        var isEnabled = false
        
        if let analytic = (self.filter{ $0.key == ofType.rawValue }).first {
            isEnabled = analytic.enabled
        }
        
        return isEnabled
    }
    
    func identifier(ofType: AnalyticsType) -> String? {
        if let analytic = (self.filter{ $0.key == ofType.rawValue }).first {
            return analytic.id
        }
        return nil
    }
    
    func secret(ofType: AnalyticsType) -> String? {
        if let analytic = (self.filter{ $0.key == ofType.rawValue }).first {
            return analytic.secret
        }
        return nil
    }
}

extension Settings {
    
    func isSettingsEmpty() -> Bool {
        return self.textFormatString().count == 0 || self.analytics.count == 0
    }
    
    public func carrouselOrderValue() -> Int {
        if let carrouselOrder = (self.videos.filter{$0.id == "carousel_order"}.first) {
            return Int(carrouselOrder.value) ?? 1
        }
        return 1
    }
    
    public var burstCachedId: String {
        return cache.burstCacheID
    }
        
    public var avatarImageIdentifiers: [String] {
        guard let avatarIdValue = cbPlus.filter({$0.id == "avatar_ids"}).first?.value else {
            return []
        }
        let avatarIdentifiers = avatarIdValue.components(separatedBy: ",")
        return avatarIdentifiers
    }
}

extension Settings {
    
    public func interstitialValue(of type: InterstitialAdValueType, for screenType: InterstitialAdType) -> Int32? {
        var values: [freq]?
        switch screenType {
            case .match: values = self.ads.interstial.match
            case .news: values = self.ads.interstial.news
            case .unknown: break
        }
        guard let result = values, result.isEmpty == false else {
            return nil
        }
        if let value = (result.filter{$0.key == type.rawValue}.first?.value), value > 0 {
            return value
        }
        return nil
    }
    
    public func shoshAdValue(of type: ShoshAdValueType, for screenType: ShoshAdType) -> Int32? {
        var values: [freq]?
        switch screenType {
            case .match: values = self.ads.shosh.match
        }
        guard let result = values, result.isEmpty == false else {
            return nil
        }
        if let value = (result.filter{$0.key == type.rawValue}.first?.value), value > 0 {
            return value
        }
        return nil
    }
    
    public func configurationNameForKey(_ key: PremiumConfigKeys) -> String {
        switch key {
            case .name: return premiumConfigs.name
        }
    }
}
