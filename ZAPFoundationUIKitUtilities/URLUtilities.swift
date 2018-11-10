//
//  WCHTTPURL.swift
//  ZAPFoundationUIKitUtilities
//
//  Created by Stefan Pauwels on 07.11.18.
//  Copyright © 2018 Zozi Apps. All rights reserved.
//

import Foundation

extension URL {
    
    public init?(HTTPURLWith string: String, relativeTo baseURL: URL?) {
        var correctedString = string
        let parts = string.components(separatedBy: "://")
        if parts[0] != "https" {
            correctedString = "http://\(parts.last!)"
        }
        self.init(string: correctedString, relativeTo: nil)
    }
    
    public init?(HTTPURLWith string: String) {
        self.init(HTTPURLWith: string, relativeTo: nil)
    }
}

