//
//  URLRequestUtilities.swift
//  ZAPFoundationUIKitUtilities
//
//  Created by Stefan Pauwels on 13.11.18.
//  Copyright © 2018 Zozi Apps. All rights reserved.
//

import Foundation

public enum ContentType {
    
    case JSON
    case formURLEncoded
    case none
    
    var value: String? {
        switch self {
        case .JSON:
            return "application/json; charset=utf-8"
        case .formURLEncoded:
            return "application/x-www-form-urlencoded; charset=utf-8"
        default:
            return nil
        }
    }
}

extension URLRequest {
    
    public mutating func setContent(type: ContentType) {
        
        setValue(type.value, forHTTPHeaderField: "Content-Type")
    }
    
    public mutating func setJSONBody(object: Any) {
        
        do {
            self.httpBody = try JSONSerialization.data(withJSONObject: object, options: [])
            self.setContent(type: .JSON)
            self.httpMethod = "POST"
        } catch {
            NotificationCenter.default.postZAPError(object: self, title: "Could not set JSON Body!", error: error)
        }
    }
    
    public mutating func setURLEncodedFormString(string: String) {
        
        self.httpBody = string.data(using: .utf8)
        self.setContent(type: .formURLEncoded)
        self.httpMethod = "POST"
    }
}
