//
//  NetworkSettings.swift
//  CricbuzzMobile
//
//  Created by Sandeep GS on 17/08/20.
//  Copyright © 2020 Cricbuzz. All rights reserved.
//

import Foundation

public class APIHeaderSettings: NSObject {
    
    static let UserIDDefaultKey: String = "CBZTVUserID"
    
    public class var shortAppVersion: String {
        guard let infoDict = Bundle.main.infoDictionary,
              let shortVersion = infoDict["CFBundleShortVersionString"] as? String else {
            return ""
        }
        return shortVersion
    }
    
    class var appBundleVersion: String {
        guard let infoDict = Bundle.main.infoDictionary,
              let bundleVersion = infoDict["CFBundleVersion"] as? String else {
            return ""
        }
        return bundleVersion
    }
    
    class private var fetchUUIDFromDefaults: String {
        let userDefaults = UserDefaults.standard
        guard let uuid = userDefaults.value(forKey: APIHeaderSettings.UserIDDefaultKey) as? String else {
            let userid = UUID().uuidString
            userDefaults.setValue(userid, forKey: APIHeaderSettings.UserIDDefaultKey)
            userDefaults.synchronize()
            return userid
        }
        return uuid
    }

    private static var sCBZUserId: String? = nil
    public class var userId: String {
        if sCBZUserId == nil {
            sCBZUserId = APIHeaderSettings.fetchUUIDFromDefaults
        }
        return sCBZUserId ?? APIHeaderSettings.fetchUUIDFromDefaults
    }
    
    public class var timeZone: String {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        dateFormatter.dateFormat = "ZZZ"
        dateFormatter.timeZone = NSTimeZone.default as TimeZone

        let timezoneString = dateFormatter.string(from: currentDate)
        return timezoneString
    }
    
    public class var countryCode: String {
        let locale = NSLocale.current as NSLocale
        return locale.object(forKey: .countryCode) as? String ?? ""
    }
}
