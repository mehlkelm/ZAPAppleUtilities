//
//  BuildCoordinator.swift
//
//  Created by Stefan Pauwels on 20.04.22.
//  Copyright © 2022 Zozi Apps. All rights reserved.
//

import Foundation

public class ZAPBuildCoordinator {
    
    public static var shared = ZAPBuildCoordinator()
    
    let lastLaunchedBuildKey = "lastLaunchedBuild"
    
    private(set) public var lastLaunchedBuild: Int
    
    private(set) public var currentBuild: Int
    
    init() {
        lastLaunchedBuild = UserDefaults.standard.integer(forKey: lastLaunchedBuildKey)

        if let currentBuildString = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String , let currentBuildNumber = Int(currentBuildString) {
            currentBuild = currentBuildNumber
            print("Launched build \(currentBuildString), last time was build \(lastLaunchedBuild)")
            UserDefaults.standard.set(currentBuild, forKey: lastLaunchedBuildKey)
        } else {
            print("Cannot parse build number!")
            currentBuild = 0
        }
    }
    
    public func migrate(lastAndCurrentBuildHandler :(Int, Int) -> Void) {
        
        lastAndCurrentBuildHandler(lastLaunchedBuild, currentBuild)
    }
}
