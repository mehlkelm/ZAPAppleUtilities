//
//  NotificationCenterUtilities.swift
//  ZAPFoundationUIKitUtilities
//
//  Created by Stefan Pauwels on 13.11.18.
//  Copyright © 2018 Zozi Apps. All rights reserved.
//

import Foundation

extension Notification.Name {
    
    public static let ZAPError: NSNotification.Name = Notification.Name("ZAPError")
}

extension NotificationCenter {
    
    public func postZAPError(object: Any?, title: String?, description: String) {
        
        var info = [AnyHashable: Any]()
        info["description"] = description
        info["title"] = title
        let notification = Notification(name: .ZAPError, object: object, userInfo: info)
        print(notification)
        
        DispatchQueue.main.async {
            self.post(notification)
        }
    }
    
    public func postZAPError(object: Any?, title: String?, error: Error) {
        
        postZAPError(object: object, title: title, description: error.localizedDescription)
    }
}

