//
//  DataUtilities.swift
//  ZAPFoundationUIKitUtilities
//
//  Created by Stefan Pauwels on 28.10.20.
//  Copyright © 2020 Zozi Apps. All rights reserved.
//

import Foundation

extension Data {
    
    public func base64String(withImageDataPrefix: Bool = false) -> String {
        
        let base64 = self.base64EncodedString()
        let string = withImageDataPrefix ? "data:image/png;base64," : ""
        return string + base64
    }
}
