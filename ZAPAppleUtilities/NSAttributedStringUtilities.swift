//
//  NSAttributedStringUtilities.swift
//  ZAPFoundationUIKitUtilities
//
//  Created by Stefan Pauwels on 06.12.18.
//  Copyright © 2018 Zozi Apps. All rights reserved.
//

import Foundation

extension NSAttributedString {
        
    @objc public func trailingNewlineChopped() -> NSAttributedString {
        
        if string.hasSuffix("\n") {
            return self.attributedSubstring(from: NSRange(location: 0, length: length - 1))
        } else {
            return self
        }
    }
}
