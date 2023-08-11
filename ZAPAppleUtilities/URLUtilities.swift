//
//  WCHTTPURL.swift
//  ZAPFoundationUIKitUtilities
//
//  Created by Stefan Pauwels on 07.11.18.
//  Copyright © 2018 Zozi Apps. All rights reserved.
//

import Foundation

extension URL {
    
    static let adServerDomains: [String] = {
        // The list is from http://pgl.yoyo.org/as/
        guard let filePath = Bundle.current.path(forResource: "ad_server_domains", ofType: "txt") else {
            print("Could not read ad server domains!")
            return [String]()
        }
        
        guard let string: String = try? String(contentsOfFile: filePath) else {
            print("Could not read ad server domains!")
            return [String]()
        }
        
        var items = string.components(separatedBy: "\n")
        items.append(contentsOf: ["feeds.wordpress.com", "feeds.feedburner.com", "feedads.doubleclick.net", "feedsportal.com", "syndicateads.net", "images-na.ssl-images-amazon.com"])
        
        return items;
    }()
    
    public var hasAdDomain: Bool {
        guard let letHost = host else {
            return false
        }
        return URL.adServerDomains.contains(letHost)
    }
    
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
    
    public func queryValue(forKey key: String) -> String? {
        
        let components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        for item in components?.queryItems ?? [URLQueryItem]() {
            if item.name == key {
                return item.value
            }
        }
        return nil
    }
}

