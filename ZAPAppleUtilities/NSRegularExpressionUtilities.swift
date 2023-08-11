//
//  NSRegularExpressionUtilities.swift
//  ZAPFoundationUIKitUtilities
//
//  Created by Stefan Pauwels on 07.11.18.
//  Copyright © 2018 Zozi Apps. All rights reserved.
//

import Foundation

extension NSRegularExpression {
    
    public func firstMatch(in string: String?, options: NSRegularExpression.MatchingOptions = []) -> NSTextCheckingResult? {
        
        guard let string = string else {
            return nil
        }
        let nsRange = NSRange(location: 0, length: string.count)
        return firstMatch(in: string, options: options, range: nsRange)
    }
    
    public func matches(in string: String?, options: NSRegularExpression.MatchingOptions = []) -> [NSTextCheckingResult] {
        
        guard let string = string else {
            return [NSTextCheckingResult]()
        }
        let nsRange = NSRange(location: 0, length: string.count)
        return matches(in: string, options: options, range: nsRange)
    }
}

extension NSTextCheckingResult {
    
    public func range(at idx: Int, in string: String) -> Range<String.Index>? {
        
        let nsRange = range(at: idx)
        return Range<String.Index>(nsRange, in:string)
    }
    
    public func string(at idx: Int, in string: String?) -> String? {
        
        guard let string = string else {
            print("No string to extract from!")
            return nil
        }
        guard let range = self.range(at: idx, in: string) else {
            print("Could not extract string from text checking result!")
            return nil
        }
        return String(string[range])
    }
}
