//
//  URLResponseUtilities.swift
//  ZAPFoundationUIKitUtilities
//
//  Created by Stefan Pauwels on 02.05.19.
//  Copyright © 2019 Zozi Apps. All rights reserved.
//

import Foundation

extension URLResponse {
    
    public var textEncoding: String.Encoding {
        
        var encoding = String.Encoding.utf8
        if let encodingName = self.textEncodingName {
            let CFEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
            encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFEncoding))
        }
        return encoding
    }
}
