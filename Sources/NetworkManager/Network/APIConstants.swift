//
//  APIConstants.swift
//  CricbuzzMobile
//
//  Created by Sandeep GS on 17/08/20.
//  Copyright © 2020 Cricbuzz. All rights reserved.
//

import Foundation

public struct NetworkConstants {
    static let ignoredResponseEventThresholdValue: Int = 60
    
    public struct APIHeaderKeys {
        public static let acceptEncoding: String = "Accept-Encoding"
        public static let location: String = "cb-loc"
        public static let appVersion: String = "cb-appver"
        public static let timeZone: String = "cb-tz"
    }
    
    public struct APIHeaderValues {
        public static let acceptEncoding: String = "gzip"
    }
    
    struct FeedbackKeys {
        static let name: String = "name"
        static let email: String = "emailId"
        static let subject: String = "subject"
        static let feedback: String = "feedback"
        static let os: String = "osName"
        static let osVersion: String = "osVersion"
        static let appVersion: String = "appVersion"
        static let userId: String = "uid"
        static let deviceToken: String = "token"
        static let deviceModel: String = "deviceModel"
        static let idfa: String = "adId"
    }
    
    struct FCMTokenAPIKeys {
        static let udid: String = "udid"
        static let token: String = "token"
        static let appVersion: String = "app_version"
        static let OSVersion: String = "os_version"
        static let country: String = "country"
        static let model: String = "model"
        static let timeZone: String = "timezone"
        static let locale: String = "locale"
        static let topics: String = "topics"
    }
    
    public struct UserAccountKeys {
        public static let username: String = "username"
        public static let sessionToken: String = "Session"
        public static let accessToken: String = "AccessToken"
        public static let refreshToken: String = "RefreshToken"
        public static let otp: String = "otp"
        static let provider: String = "provider"
        static let cancelReason: String = "reason"
        public static let source: String = "source"
        public static let count: String = "count"
        public static let sourceId: String = "sourceId"
        public static let matchId: String = "matchId"
        public static let seriesId: String = "seriesId"
        
        static let user: String = "user"
        static let name: String = "name"
        static let email: String = "email"
        static let userImageId: String = "image_id"
        static let phoneNumber: String = "phone_number"
        static let userState: String = "userState"
        
        static let plan: String = "plan"
        static let id: String = "id"
        static let termId: String = "termId"
        static let isFree: String = "isFree"
        static let isRenewable: String = "isRenewable"
        
        static let txnId: String = "txnId"
        static let receipt: String = "receipt"
        static let isSandbox: String = "isSandbox"

        static let chat: String = "chat"
        static let chatTheme: String = "theme"
        static let channelId: String = "channelId"
        static let channelType: String = "channelType"
        static let channelInstanceKey: String = "instanceKey"
    }
}
