import Foundation
import StoreKit

public enum StoreError: Error {

    case failedVerification
	case noSuchProduct
	
	var localizedDescription: String {
		
		switch self {
			case .failedVerification:
				return "Transaction verification failed"
			case .noSuchProduct:
				return "Product unavailable"
		}
	}
}

@available(iOS 15.0, macOS 12.0, *)
open class ZAPStore2Coordinator: ObservableObject {
		
	typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
	
	typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

        
    @Published private(set) public var nonconsumables: [Product]
    
    @Published private(set) public var consumables: [Product]
    
    @Published private(set) public var autoRenewableSubs: [Product]
    
    @Published private(set) public var nonRenewingSubs: [Product]
    
    @Published private(set) public var productIdentifiers = [String]()
    
    @Published private(set) public var purchasedIdentifiers = Set<String>()

    var updateListenerTask: Task<Void, Error>? = nil
        
	public init(productIdentifiers: [String]) {
        
        self.productIdentifiers = productIdentifiers

        //Initialize empty products then do a product request asynchronously to fill them in.
        nonconsumables = []
        consumables = []
        autoRenewableSubs = []
        nonRenewingSubs = []
        
        startListeningForTransactions()

        Task {
            //Initialize the store by starting a product request.
            await requestProducts()
        }
    }
    
    public func startListeningForTransactions() {
        
        //Start a transaction listener as close to app launch as possible so you don't miss any transactions.
        if updateListenerTask == nil {
            updateListenerTask = listenForTransactions()
        }
    }
    
    deinit {
        
        updateListenerTask?.cancel()
        updateListenerTask = nil
    }

    func listenForTransactions() -> Task<Void, Error> {
        
        return Task.detached {
            //Iterate through any transactions which didn't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    //Deliver content to the user.
                    await self.updatePurchasedIdentifiers(transaction)

                    //Always finish a transaction.
                    await transaction.finish()
                } catch {
                    //StoreKit has a receipt it can read but it failed verification. Don't deliver content to the user.
                    print("Transaction failed verification")
                }
            }
        }
    }

    @MainActor
    func requestProducts() async {
        
        do {
            //Request products from the App Store using the identifiers defined in the Products.plist file.
            let storeProducts = try await Product.products(for: productIdentifiers)

            var newNonconsumables: [Product] = []
            var newConsumables: [Product] = []
            var newAutoRenewableSubs: [Product] = []
            var newNonRenewingSubs: [Product] = []

            //Filter the products into different categories based on their type.
            for product in storeProducts {
                switch product.type {
                case .consumable:
                    newConsumables.append(product)
                case .nonConsumable:
                    newNonconsumables.append(product)
                case .autoRenewable:
                    newAutoRenewableSubs.append(product)
                case .nonRenewable:
                    newNonRenewingSubs.append(product)
                default:
                    //Ignore this product.
                    print("Unknown product")
                }
            }

            //Sort each product category by price, lowest to highest, to update the store.
            nonconsumables = sortByPrice(newNonconsumables)
            consumables = sortByPrice(newConsumables)
            autoRenewableSubs = sortByPrice(newAutoRenewableSubs)
            nonRenewingSubs = sortByPrice(newNonRenewingSubs)
        } catch {
            print("Failed product request: \(error)")
        }
    }
    
    public func purchase(productID: String) async throws -> Transaction? {
        
        if let product = product(for: productID) {
            return try await purchase(product)
        }
		throw StoreError.noSuchProduct
    }
    
    public func product(for identifier: String) -> Product? {
        
        for group in [nonconsumables, consumables, autoRenewableSubs, nonRenewingSubs] {
            if let product = group.first(where: { $0.id == identifier }) {
                return product
            }
        }
        print("Product ID \(identifier) not found!")
        return nil
    }

    public func purchase(_ product: Product) async throws -> Transaction? {
        
        //Begin a purchase.
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            //Deliver content to the user.
            await updatePurchasedIdentifiers(transaction)

            //Always finish a transaction.
            await transaction.finish()

            return transaction
        case .pending:
            return nil
        case .userCancelled:
            return nil
        default:
            return nil
        }
    }

    public func purchaseTransactionForProduct(_ productIdentifier: String) async -> Result<Transaction, Error> {
        
        guard let result = await Transaction.latest(for: productIdentifier) else {
            return .failure(ZAPError(message: "Product has not been purchased."))
        }

        do {
            let transaction = try checkVerified(result)
            let purchasedSince = Date().timeIntervalSince(transaction.purchaseDate)
            
            if transaction.productType == .nonRenewable {
				#if DEBUG
				if purchasedSince > TimeInterval.minute {
					return .failure(ZAPError(message: "Non renewable sandbox subscription has expired."))
				}
				#endif
                if productIdentifier.hasSuffix(".year") && purchasedSince > TimeInterval.year {
                    return .failure(ZAPError(message: "Non renewable yearly subscription has expired."))
                }
                if productIdentifier.hasSuffix(".month") && purchasedSince > TimeInterval.month {
                    return .failure(ZAPError(message: "Non renewable monthly subscription has expired."))
                }
            }
            
            //Ignore revoked transactions, they're no longer purchased.
            if transaction.revocationDate != nil {
                return .failure(ZAPError(message: "Subscription has been revoked."))
            }
            return .success(transaction)
            
        } catch {
            return .failure(error)
        }
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        
        //Check if the transaction passes StoreKit verification.
        switch result {
        case .unverified:
            //StoreKit has parsed the JWS but failed verification. Don't deliver content to the user.
            throw StoreError.failedVerification
        case .verified(let safe):
            //If the transaction is verified, unwrap and return it.
            return safe
        }
    }

    @MainActor
    open func updatePurchasedIdentifiers(_ transaction: Transaction) async {
        
        if transaction.revocationDate == nil {
            //If the App Store has not revoked the transaction, add it to the list of `purchasedIdentifiers`.
            purchasedIdentifiers.insert(transaction.productID)
        } else {
            //If the App Store has revoked this transaction, remove it from the list of `purchasedIdentifiers`.
            purchasedIdentifiers.remove(transaction.productID)
        }
		
		NotificationCenter.default.post(name: .ProductAccessDidChange, object: self)
    }

    func sortByPrice(_ products: [Product]) -> [Product] {
        
        products.sorted(by: { return $0.price < $1.price })
    }
	
	open func sync() async {
		
		do {
			try await AppStore.sync()
		} catch {
			print(error)
		}
	}
}
