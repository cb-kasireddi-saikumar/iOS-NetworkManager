//
//  String+Extension.swift
//  CBZNetwork
//
//  Created by Mayur G on 03/05/17.
//  Copyright © 2017 Cricbuzz. All rights reserved.
//

import Foundation
//import CommonCrypto
import CryptoSwift
//import SwiftyRSA

fileprivate let ivForAnalytics: String = "oH3JFQoglYHddoJx"

extension String {
    
    internal func hmac(key: String?) -> String? {
        return CBZEncryptor.hashHMAC(algorithm: .sha2(.sha256), value: self, key: key, needBase64: true)
    }
    
    public func encrypt() -> String? {
        return CBZEncryptor.encryptAES(value: self, keyMode: .padded, iv: ivForAnalytics, padding: .pkcs5)
    }
    
    public func decrypt() -> String? {
        return CBZEncryptor.decryptAES(value: self, keyMode: .padded, iv: ivForAnalytics, padding: .pkcs5)
    }

    public func decryptForAnalytics() -> String? {
        return CBZEncryptor.decryptAES(value: self, keyMode: .sha, iv: ivForAnalytics, padding: .pkcs5)
    }
}

/**
 * A helper class for encryption and decryption
 */
public final class CBZEncryptor {
    
    public enum KeyMode {
        case padded
        case sha
    }
    
    internal static let authSecret = "1JD8EE9H4l52ii2LCKVhbjmsFvQ2rycUGiwcqBW31e4="
    
    private static let privateKey = "PXZk64YVlSM1Pnt7EbXv5YWrfXCcOnQcLrk802pBJd3v5Fm8TFF"
    private static let keyData = CBZEncryptor.privateKey.data(using: .utf8, allowLossyConversion: false)!.bytes
    private static let paddedKey = Array(keyData[0...15]) // 16 padded keydata
    
    internal static let akamaiSecret = "8kNJAFQ5nFXxbGzudYR/D4FD15BVb0znrc52vTNnVf26HoRKXy+D5PCVCgWhLbcWm2ESMVgTSiD7HJvC7vKTetYeoFb7xYSSFRPpdmHE3lY="
    
    internal static let awscKeyPairId = "gE0qaWC+4gc4wZzyuxXfyXK5v8U4jCAl3RntxD6IroA="
    internal static let awscPemKey = "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"
    
    public static func hashHMAC(algorithm: HMAC.Variant = .sha2(.sha256), value: String, key: String?, needBase64: Bool = true) -> String? {
        
        do {
            guard let key = key else { return nil }
            let hash = try HMAC(key: Array(key.utf8), variant: algorithm).authenticate(Array(value.utf8))
            return needBase64 ? hash.toBase64() : hash.toHexString()
        } catch {
            return nil
        }
    }
    
    public static func encryptAES(value: String,
                                  keyMode: KeyMode = .padded,
                                  iv: String,
                                  padding: CryptoSwift.Padding = .pkcs5) -> String? {
        
        do {
            var privateKey: [UInt8]
            
            switch keyMode {
                case .padded: privateKey = paddedKey
                case .sha:
                    let shaData = keyData.sha1()
                    privateKey = Array(shaData[0...15])
            }
            
            if let ivBytes = iv.data(using: .utf8)?.bytes {
                let cbcmode = CBC(iv: ivBytes)
                let cipher = try AES.init(key: privateKey, blockMode: cbcmode, padding: padding)
                
                let encryptedData = try cipher.encrypt(Array(value.utf8))
                return encryptedData.toBase64()
            } else {
                return nil
            }
        } catch {
            return nil
        }
        
    }
    
    public static func decryptAES(value: String,
                                  keyMode: KeyMode = .padded,
                                  iv: String,
                                  padding: CryptoSwift.Padding = .pkcs5) -> String?
    {
        var privateKey: [UInt8]
        
        switch keyMode {
            case .padded:
                privateKey = paddedKey
            case .sha:
                let shaData = keyData.sha1()
                privateKey = Array(shaData[0...15])
        }
        
        do {
            if let ivBytes = iv.data(using: .utf8)?.bytes {
                let cbcmode = CBC(iv: ivBytes)
                let cipher = try AES.init(key: privateKey, blockMode: cbcmode, padding: padding)
                
                let base64decoded = Array(base64: value)
                let decryptedData = try cipher.decrypt(base64decoded)
                return String(bytes: decryptedData, encoding: .utf8)
            } else {
                return nil
            }
        } catch {
            return nil
        }        
    }
    
    
    /**
     Sign given message.
     
     - parameter message: A string which needs to be encrypted
     
     - parameter pemString: PEM-encoded key string.
     
     - parameter digestType: Digest.
     
     - returns: A Base64Encoded formatted string.
     */
//    public static func sign(message: String,
//                            using pemString: String,
//                            digestType: DigestType) -> String? {
//
//        guard let privateKey = try? PrivateKey(pemEncoded: pemString) else { return nil }
//        guard let clearMessage = try? ClearMessage.init(string: message, using: .utf8) else { return nil }
//        guard let signature = try? clearMessage.signed(with: privateKey, digestType: digestType.toSwiftRSADigest) else { return nil }
//
//        return signature.base64String
//    }
        
//    public enum DigestType {
//        case sha1
//        case sha224
//        case sha256
//        case sha384
//        case sha512
//        
//        fileprivate var toSwiftRSADigest: Signature.DigestType {
//            switch self {
//            case .sha1: return .sha1
//            case .sha224: return .sha224
//            case .sha256: return .sha256
//            case .sha384: return .sha384
//            case .sha512: return .sha512
//            }
//        }
//    }
    
}
