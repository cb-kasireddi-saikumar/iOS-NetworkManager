//
//  CBZRoute+Additions.swift
//  CBZNetwork
//
//  Created by Sandeep GS on 12/10/20.
//  Copyright © 2020 Cricbuzz. All rights reserved.
//

import Foundation

extension ImageDensityType {
    
    var densityValue: String {
        switch self {
            case .low: return self.rawValue
            case .defaultDensity: return "high"
            case .none: return self.rawValue
        }
    }
}
