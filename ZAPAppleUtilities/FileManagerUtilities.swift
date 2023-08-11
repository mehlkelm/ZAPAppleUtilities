//
//  FileManagerUtilities.swift
//  ZAPFoundationUIKitUtilities
//
//  Created by Stefan Pauwels on 23.11.21.
//  Copyright © 2021 Zozi Apps. All rights reserved.
//

import Foundation

extension FileManager {
    
    public var documentsDirectoryURL: URL {

        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = urls[0]
        return documentsDirectory
    }
}
