//
//  DateUtilities.swift
//  ZAPFoundationUIKitUtilities
//
//  Created by Stefan Pauwels on 11.11.18.
//  Copyright © 2018 Zozi Apps. All rights reserved.
//

import Foundation

public extension Date {
    
    static func daysAgo(_ days: Double) -> Date {
        
        return Date(timeIntervalSinceNow: -days * TimeInterval.day)
    }
    
    static func daysAgo(_ days: Int) -> Date {
        
        return daysAgo(Double(days))
    }
}

public extension TimeInterval {
    
	static var minute: TimeInterval = 60
    static var day: TimeInterval = 24 * 60 * 60
    static var week: TimeInterval = day * 7
    static var month: TimeInterval = day * 30
    static var year: TimeInterval = day * 365
}
