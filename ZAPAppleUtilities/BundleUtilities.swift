//
//  BundleUtilities.swift
//  ZAPFoundationUIKitUtilities
//
//  Created by Stefan Pauwels on 13.12.18.
//  Copyright © 2018 Zozi Apps. All rights reserved.
//

import Foundation

extension Bundle {
    
    public static var current: Bundle {
        
        // This stupid helper class seems to be the safest way to get the framework bundle
        class BundleDetector {}
        return Bundle(for: BundleDetector.self)
    }
    
    public var isExtension: Bool {
        
        return self.bundlePath.hasSuffix(".appex")
    }
}
