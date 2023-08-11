//
//  URLSessionUtilities.swift
//  ZAPFoundationUIKitUtilities
//
//  Created by Stefan Pauwels on 13.05.19.
//  Copyright © 2019 Zozi Apps. All rights reserved.
//

import Foundation

extension URLSession {
    
    public func execute<T>(request: URLRequest?, fail: @escaping (Error) -> Void, completion: @escaping (T, HTTPURLResponse) -> Void) {
        
        guard let request = request else {
            fail(NSError.couldNotCreateRequest)
            return
        }
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                guard let data = data else {
                    fail(ZAPError(message: "NO DATA FOR RESPONSE " + (response?.description ?? "–")))
                    return
                }
                guard let urlResponse = response as? HTTPURLResponse else {
                    fail(ZAPError(message: String(data: data, encoding: .utf8)))
                    return
                }
                if let error = error {
                    fail(error)
                    return
                }
//                if UIDevice.current.isSimulator, let content = String(data: data, encoding: .utf8) {
//                    print(content)
//                }
                guard urlResponse.statusCode < 500 else {
                    fail(NSError.serverError)
                    return
                }
                guard urlResponse.statusCode != 404 else {
                    fail(NSError.notFound)
                    return
                }
                guard urlResponse.statusCode < 400 else {
                    fail(NSError.accessDenied)
                    return
                }
                if T.self is Data.Type, let itsData = data as? T {
                    completion(itsData, urlResponse)
                    return
                } else if T.self is String.Type, let text = String(data: data, encoding: .utf8) as? T {
                    completion(text, urlResponse)
                }
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                    if let array = jsonObject as? T {
                        completion(array, urlResponse)
                    } else {
                        fail(ZAPError(message: "Unexpected response: " + (String(data: data, encoding: .utf8) ?? "NOT DECODED")))
                    }
                } catch {
                    fail(error)
                }
            }
        }.resume()
    }
}

extension NSError {
    
    public static let internalError = NSError(domain: "ZAPURLSession", code: 0, userInfo: [NSLocalizedDescriptionKey: "Internal account error!"])
    public static let couldNotCreateRequest = NSError(domain: "ZAPURLSession", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create request!"])
    public static let accessDenied = NSError(domain: "ZAPURLSession", code: 3, userInfo: [NSLocalizedDescriptionKey: "Access denied!"])
    public static let invalidResponse = NSError(domain: "ZAPURLSession", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server!"])
    public static let serverError = NSError(domain: "ZAPURLSession", code: 6, userInfo: [NSLocalizedDescriptionKey: "Server error!"])
    public static let notFound = NSError(domain: "ZAPURLSession", code: 7, userInfo: [NSLocalizedDescriptionKey: "Not found!"])
}
