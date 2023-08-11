//
//  NetworkCheck.swift
//  ZAPFoundationUIKitUtilities
//
//  Created by Stefan Pauwels on 11.04.22.
//  Copyright © 2022 Zozi Apps. All rights reserved.
//

import Foundation
import Network

protocol NetworkCheckObserver: AnyObject {
    
    func statusDidChange(status: NWPath.Status)
}

public class NetworkCheck {

    struct NetworkChangeObservation {
        
        weak var observer: NetworkCheckObserver?
    }

    private var monitor = NWPathMonitor()
    
    public static let shared = NetworkCheck()
    
    private var observations = [ObjectIdentifier: NetworkChangeObservation]()
    
    public var currentStatus: NWPath.Status {
        get {
            return monitor.currentPath.status
        }
    }

    init() {
        
        monitor.pathUpdateHandler = { [unowned self] path in
            for (id, observations) in self.observations {

                //If any observer is nil, remove it from the list of observers
                guard let observer = observations.observer else {
                    self.observations.removeValue(forKey: id)
                    continue
                }

                DispatchQueue.main.async(execute: {
                    observer.statusDidChange(status: path.status)
                })
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }

    func addObserver(observer: NetworkCheckObserver) {
        
        let id = ObjectIdentifier(observer)
        observations[id] = NetworkChangeObservation(observer: observer)
    }

    func removeObserver(observer: NetworkCheckObserver) {
        
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
    }

}
