//
//  ZAPStoreCoordinator.swift
//  ZAPFoundationUIKitUtilities
//
//  Created by Stefan Pauwels on 14.06.21.
//  Copyright © 2021 Zozi Apps. All rights reserved.
//

import Foundation
import StoreKit

extension Notification.Name {
    
    public static let ProductAccessDidChange = Notification.Name("ProductAccessDidChange")
}

@available(iOS, deprecated: 15.0, message: "Use ZAPStore2Coordinator which uses StoreKit2 APIs.")
open class ZAPStoreCoordinator: NSObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {
    
    let keychain = Keychain()
    
    let productIDs = [String]()
    
    public private(set) var errors = [Error]()
        
    private var productRequest: SKProductsRequest?
    
    public private(set) var products = [SKProduct]()
    
    public func productWith(ID: String) -> SKProduct? {
        
        return products.first(where: { $0.productIdentifier == ID })
    }

    /// Keeps track of all purchases.
    var purchased = [SKPaymentTransaction]()
    
    /// Keeps track of all restored purchases.
    var restored = [SKPaymentTransaction]()
    
    /// Indicates whether there are restorable purchases.
    fileprivate var hasRestorablePurchases = false

    var completionHandler: ((Result<SKPaymentTransaction?, Error>) -> Void)?

    public init(productIDs: [String], keychain: Keychain = Keychain()) {
        
        lastLaunchedBuild = UserDefaults.standard.integer(forKey: lastLaunchedBuildKey)

        if let currentBuildString = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String , let currentBuildNumber = Int(currentBuildString) {
            currentBuild = currentBuildNumber
            print("Launched build \(currentBuildString), last time was build \(lastLaunchedBuild)")
            UserDefaults.standard.set(currentBuild, forKey: lastLaunchedBuildKey)
        } else {
            print("Cannot parse build number!")
            currentBuild = 0
        }

        super.init()
        
        // If app was deleted, also clear purchases from keychain (for testing purposes)
        if lastLaunchedBuild == 0 {
            productIDs.forEach {
                do {
                    try keychain.remove($0)
                } catch {
                    errors.append(error)
                    print(error)
                }
            }
        }
        
        validate(productIdentifiers: productIDs)
    }

    func validate(productIdentifiers: [String]) {
        
        let productIdentifiers = Set(productIdentifiers)
        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest?.delegate = self
        productRequest?.start()
    }
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        if !response.products.isEmpty {
           products = response.products
           // Custom method.
           // displayStore(products)
        }

        for invalidIdentifier in response.invalidProductIdentifiers {
           // Handle any invalid product identifiers as appropriate.
            errors.append(ZAPError(message: "Invalid product ID!"))
            print("Invalid product identifier: \(invalidIdentifier)")
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        
        errors.append(error)
        print(error)
    }
    
    // MARK: - Submit Payment Request
    
    /// Create and add a payment request to the payment queue.
    public func buy(product: SKProduct, completion: ((Result<SKPaymentTransaction?, Error>) -> Void)?) {
        
        self.completionHandler = completion
        let payment = SKMutablePayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    public func buy(productID: String, completion: ((Result<SKPaymentTransaction?, Error>) -> Void)?) {
        
        guard let product = products.first(where: { $0.productIdentifier == productID }) else {
            completion?(.failure(ZAPError(message: "Product ID not found!")))
            return
        }
        buy(product: product, completion: completion)
   }
    
    // MARK: - Restore All Restorable Purchases
    
    /// Restores all previously completed purchases.
    public func restore(completion: ((Result<SKPaymentTransaction?, Error>) -> Void)?) {
        
        self.completionHandler = completion
        if !restored.isEmpty {
            restored.removeAll()
        }
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - SKPaymentTransactionObserver
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                break
            // Do not block the UI. Allow the user to continue using the app.
            case .deferred:
                print("Purchase pending")
            // The purchase was successful.
            case .purchased:
                handlePurchased(transaction)
            // The transaction failed.
            case .failed:
                handleFailed(transaction)
            // There're restored products.
            case .restored:
                handleRestored(transaction)
            @unknown default: fatalError("INTERNAL ERROR!")
            }
        }
    }
    
    /// Logs all transactions that have been removed from the payment queue.
    public func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            print("\(transaction.payment.productIdentifier) processed.")
        }
    }
    
    /// Called when an error occur while restoring purchases. Notify the user about the error.
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        
        errors.append(error)
        if let error = error as? SKError, error.code != .paymentCancelled {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(error))
                self.completionHandler = nil
            }
        }
    }
    
    /// Called when all restorable transactions have been processed by the payment queue.
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        
        print("All restorable transactions have been processed by the payment queue.")
        
        DispatchQueue.main.async {
            self.completionHandler?(.success(nil))
            self.completionHandler = nil
        }
    }

    // MARK: - Handle Payment Transactions
    
    /// Handles successful purchase transactions.
    fileprivate func handlePurchased(_ transaction: SKPaymentTransaction) {
        
        let id = transaction.payment.productIdentifier
        keychain[id] = String(id.simpleHash)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .ProductAccessDidChange, object: self)
            self.completionHandler?(.success(transaction))
            self.completionHandler = nil
        }

        // Finish the successful transaction.
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    /// Handles failed purchase transactions.
    fileprivate func handleFailed(_ transaction: SKPaymentTransaction) {
        
        // Do not send any notifications when the user cancels the purchase.
        if let error = transaction.error {
            errors.append(error)
        }
        if (transaction.error as? SKError)?.code != .paymentCancelled {
            DispatchQueue.main.async {
                self.completionHandler?(.failure(transaction.error ?? ZAPError(message: "Transaction failed!")))
                self.completionHandler = nil
            }
        }
        // Finish the failed transaction.
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    /// Handles restored purchase transactions.
    fileprivate func handleRestored(_ transaction: SKPaymentTransaction) {
        
        print("Restore content for \(transaction.payment.productIdentifier).")
        hasRestorablePurchases = true
        handlePurchased(transaction)
    }

    public func hasPersonAccessToProduct(with ID: String) -> Bool {
        
        let entry = keychain[ID]
        let check = entry == String(ID.simpleHash)
        return check
    }
    
    let lastLaunchedBuildKey = "lastLaunchedBuild"
    
    private(set) public var lastLaunchedBuild: Int
    
    private(set) public var currentBuild: Int?
}
