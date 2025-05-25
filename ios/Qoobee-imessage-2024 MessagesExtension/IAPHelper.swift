
//
//  IAPHelper.swift
//  QooBee iMessage Stickers MessagesExtension
//
//  Created by lu peng on 21/11/19.
//  Copyright © 2019 www.QooBee.com. All rights reserved.
//

import StoreKit

// Define type aliases for product identifiers and completion handlers.
public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

// Protocol to handle purchasing alerts.
protocol PurchasingAlertDelegate {
    func showPurchasingAlert()
    func showCompleteAlert()
    func showRestoringAlert()
    func showBuyingAllAlert()
}

// Main class for handling In-App Purchases.
open class IAPHelper: NSObject {
    
    private let products = [SKProduct]()
    private let productIdentifiers: Set<ProductIdentifier>        // Set of product identifiers to request
    private var purchasedProductIdentifiers: Set<ProductIdentifier> = [] // Set of purchased products
    private var productsRequest: SKProductsRequest?               // Store ongoing SKProductsRequest
    private var productsRequestCompletionHandler: ProductsRequestCompletionHandler? // Completion handler for product request
    var total = 0
    
    // Delegate to handle alert actions
    var purchasingAlertDelegate: PurchasingAlertDelegate?

    // Delegate function shortcuts
    func showPurchasingAlert() { purchasingAlertDelegate?.showPurchasingAlert() }
    func showCompleteAlert() { purchasingAlertDelegate?.showCompleteAlert() }
    func showRestoringAlert() { purchasingAlertDelegate?.showRestoringAlert() }
    
    static let shared = IAPHelper(localProductIds: IAPHelper.loadProductIdentifiers(fromPlistNamed: "AllStickersData"))

    public init(localProductIds: Set<ProductIdentifier>) {
        productIdentifiers = localProductIds
        
        // Load previously purchased products from UserDefaults
        for productIdentifier in localProductIds {
            let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
            if purchased {
                purchasedProductIdentifiers.insert(productIdentifier)
                print("Previously purchased: \(productIdentifier)")
            } else {
                print("Not purchased: \(productIdentifier)")
            }
        }
        super.init()
        
        // Add self to SKPaymentQueue observers
        SKPaymentQueue.default().add(self)
        total = localProductIds.count
    }
    
    private static func loadProductIdentifiers(fromPlistNamed plistName: String) -> Set<ProductIdentifier> {
        guard let path = Bundle.main.path(forResource: plistName, ofType: "plist"),
              let data = NSDictionary(contentsOfFile: path),
              let rootArray = data["Root"] as? [[String: Any]] else {
            print("Failed to load product identifiers from plist")
            return []
        }
        
        var productIdentifiers: Set<ProductIdentifier> = []
        
        for item in rootArray {
            if let purchaseId = item["purchaseId"] as? String {
                productIdentifiers.insert(purchaseId)
            }
        }
        
        return productIdentifiers
    }
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {

    // Called when the payment queue updates its transactions.
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                complete(transaction: transaction)
            case .failed:
                fail(transaction: transaction)
            case .restored:
                restore(transaction: transaction)
            case .deferred:
                showCompleteAlert()
            case .purchasing:
                break
            default:
                fatalError("Unknown Purchase State Detected")
            }
        }
    }
    
    // Decides if a purchase should be automatically added to the queue.
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        guard productIdentifiers.contains(product.productIdentifier) else { return false }
        SKPaymentQueue.default().add(payment)
        return true
    }

    // MARK: - Transaction Handling Functions
    
    // Handle completed transaction
    private func complete(transaction: SKPaymentTransaction) {
        print("Transaction completed...")
        deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
        showCompleteAlert()
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    // Handle restored transaction
    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        print("Transaction restored: \(productIdentifier)")
        deliverPurchaseNotificationFor(identifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    // Handle failed transaction with enhanced error handling
    private func fail(transaction: SKPaymentTransaction) {
        print("Transaction failed...")
        showCompleteAlert()
        
        if let transactionError = transaction.error as NSError? {
            if transactionError.code == SKError.paymentCancelled.rawValue {
                print("User canceled the payment.")
            } else {
                print("Transaction Error: \(transactionError.localizedDescription)")
            }
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    

    // MARK: - Deliver Purchase Notification
    
    // Updates purchased products and saves to UserDefaults
    private func deliverPurchaseNotificationFor(identifier: String?) {
        guard let identifier = identifier else { return }
        
        // Special handling for bundle sales
        if identifier.contains("BUNDLESALE") {
            for bundleProductId in productIdentifiers {
                purchasedProductIdentifiers.insert(bundleProductId)
                UserDefaults.standard.set(true, forKey: bundleProductId)
            }
        } else {
            purchasedProductIdentifiers.insert(identifier)
            UserDefaults.standard.set(true, forKey: identifier)
        }
    }
}

// MARK: - Utility Functions

extension IAPHelper {
    
    // Initiates a product purchase
    public func buyProduct(_ productId: String) {
        showPurchasingAlert()
        print("Buying \(productId)...")
        let paymentRequest = SKMutablePayment()
        paymentRequest.productIdentifier = productId
        SKPaymentQueue.default().add(paymentRequest)
    }

    // Restores previously purchased products
    @objc public func restorePurchases() {
        showRestoringAlert()
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // Called when restore purchases complete
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        showCompleteAlert()
    }
    
    // Called if restore fails
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        showCompleteAlert()
    }

    // Check if the user has a lifetime membership.
    public func isLifeMemberShip() -> Bool {
        return purchasedProductIdentifiers.contains("com.qoobee.qoobeestickersanimated.MessageExtension.BUNDLESALE")
    }

    // Check if a specific product has been purchased.
    public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }

    // Check if the device can make payments
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
}

// MARK: - StoreKit API

extension IAPHelper {

    // Requests available products from iTunes Store
    public func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start() ?? completionHandler(false, nil)  // Handle case if request fails to start
    }
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {

    // Called when product data is received from the iTunes Store
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Loaded list of products...")
        let products = response.products
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()

        for p in products {
            print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }

    // Called if the request fails with an error
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        productsRequestCompletionHandler?(false, nil)
        clearRequestAndHandler()
    }

    // Clears the current product request and handler
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
}

// Extension for formatting SKProduct price in the local currency
extension SKProduct {
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceLocale
        return formatter.string(from: price) ?? "N/A"  // Return "N/A" if formatting fails
    }
}


