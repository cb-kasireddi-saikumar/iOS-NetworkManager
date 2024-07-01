//
//  CBZWatchCachedEndpoints.swift
//  WatchApp Extension
//
//  Created by Sandeep GS on 12/10/20.
//  Copyright © 2020 Cricbuzz. All rights reserved.
//

import Foundation
//import SwiftProtobuf

struct CachedEndpoints {
    /// Array of Hosts
    var hostURLList: [String]?
    /// modules map with path i.e. "uri" -> Module
    var modules: [String: Module]?
    // Array of image urls for differnt modules
    var images: [FormatMap]?
    /// A mutex for accessing modules
    let modulesLock = NSLock()
    /// Initial value of maxFails
    var maxFails: [String: Int32]?
    
    ///
    var didChangedModule:((Module) -> Void)?
    
    internal init(urls: [String]?, modules: [Module]?, images: [FormatMap]?) {
        self.hostURLList = urls
        self.images = images
        
        var moduleMaps: [String: Module] = [:]
        var maxFailMap: [String : Int32] = [:]
        modules?.forEach({ (module) in
            let key = module.name
            moduleMaps[key] = module
            maxFailMap[key] = (module.maxFails == 0) ? 2 : module.maxFails
        })
        
        self.modules = moduleMaps
        self.maxFails = maxFailMap
        
    }
    
    /// Get module info for given path name
    /// - parameter path: name
    /// - returns: A module info
    internal func getModuleFor(path: String) -> Module? {
        var module: Module?
        if let modules = self.modules {
            let moduleList = Array(modules.values)
            module = moduleList.filter{ $0.name == path }.first
        }
        return module
    }
    
    /// Get expanded URL for given path name
    /// - parameter path: = name
    /// - returns: The expanded URL = host + uri + version
    internal func getURLFor(path: String) -> String? {
        var expandedURL: String?
        if let module = getModuleFor(path: path) {
            var host = self.hostURLList?[Int(module.inUse)]
            host = host?.replacingOccurrences(of: "{0}", with: httpScheme)
            expandedURL = TrailingSlash(host) + TrailingSlash(module.uri) + module.version
        }
        return expandedURL
    }
    
    internal func getImageURLFor(path: String) -> String {
        if let imageMap = (self.images?.filter{ $0.id == path }.first) {
            let urlWithoutScheme = imageMap.value
            let expandedURL = urlWithoutScheme.replacingOccurrences(of: "{0}", with: httpScheme)
            return expandedURL
        } else {
            return ""
        }
    }
    
    /// Switch host for given path if needed
    ///
    /// condition-1: previous host and current host must be same
    ///
    /// condition-2: number of total failing cycles across all domains should not be reached to zero
    /// - returns: A boolean indicates weather request should be retry or not
    mutating internal func switchDomainIfNeededFor(path: String, previousHost: String) -> Bool {
        if let module = self.modules?[path] {
            
            // condition-2
            if module.maxFails == 0 {
                if let m = (NetworkManager.shared.serverConfigManager.serverEndpoints!.modules.first(where: { $0.name == module.name })) {
                    var aModule = m
                    if aModule.maxFails == 0 {
                        aModule.maxFails = self.maxFails?[module.name] ?? 2
                    }
                    self.modules![path] = aModule
                    didChangedModule?(aModule)
                }
                return false
            }
            
            // condition-1
            if let currentHost = self.hostURLList?[Int(module.inUse)], currentHost.contains(previousHost) {
                modulesLock.lock(); defer{ modulesLock.unlock() }
                let changedModule = switchDomain(module: module)
                self.modules?[path] = changedModule
                didChangedModule?(changedModule)
            }
            
            return true
            
        } else {
            return false
        }
    }
    
    private func switchDomain(module: Module) -> Module {
        var moduleObj = module
        
        moduleObj.inUse += 1
        let totalHostCount = self.hostURLList?.count ?? 0
        
        // restart the cycle if it exceeds the appUrl count
        if Int(moduleObj.inUse) >= totalHostCount {
            moduleObj.inUse = 0
            
            // update only if cycle completes
            let maxFails = moduleObj.maxFails - 1
            moduleObj.maxFails = maxFails < 0 ? 0 : maxFails
        }
        
        return moduleObj
    }
    
}

