//
//  PrayerDevotionStore.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 8/28/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import StoreKit

protocol PrayerDevotionStoreDelegate {
    func didPurchaseAdditionalFeatures()
}

class PrayerDevotionStore: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate {
    
    private var productIDs = [AdditionalFeaturesKey]
    var productsArray = [SKProduct]()

    var transactionInProgress = false
    
    var delegate: PrayerDevotionStoreDelegate?
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var completionMethod: ((successful: Bool) -> Void)?
    
    override init() {
        super.init()
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
    
    func requestProductInfo() {
        if SKPaymentQueue.canMakePayments() {
            let productIdentifiers = NSSet(array: productIDs)
            let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<NSObject>)
            
            productRequest.delegate = self
            productRequest.start()
        } else {
            println("Unable to make In-App Purchases on this device")
        }
    }
    
    func restoreAdditionalFeatures() {
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    // MARK: Validation
    
    func validateReceipt() {
        var response: NSURLResponse?
        var error: NSError?
        
        var receiptURL = NSBundle.mainBundle().appStoreReceiptURL
        var receipt: NSData = NSData(contentsOfURL: receiptURL!, options: nil, error: nil)!
        
        var receiptData: NSString = receipt.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(0))
        println("\(receiptData)")
        
        var request = NSMutableURLRequest(URL: NSURL(string: "http://localhost/PrayerDevotion/write.php")!)
        var session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        request.HTTPBody = receiptData.dataUsingEncoding(NSASCIIStringEncoding)
        
        var task = session.dataTaskWithRequest(request, completionHandler: { data, response, error in
            var err: NSError?
            var json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &err) as? NSDictionary
            
            if err != nil {
                println("An error occurred while validating receipt: \(err), \(err!.localizedDescription)")
                let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                println("Could not parse JSON: '\(jsonStr)'")
            } else {
                if let parseJSON = json {
                    println("Receipt \(parseJSON)")
                } else {
                    let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                    println("Receipt error: \(jsonStr)")
                }
            }
        })
        
        task.resume() 
    }
    
    // MARK: Products Request Delegate Methods
    
    func productsRequest(request: SKProductsRequest!, didReceiveResponse response: SKProductsResponse!) {
        if response.products.count != 0 {
            for product in response.products {
                productsArray.append(product as! SKProduct)
            }
        } else {
            println("There are no products")
        }
        
        if response.invalidProductIdentifiers.count != 0 {
            println(response.invalidProductIdentifiers.description)
        }
    }
    
    // MARK: SKPaymentTransactionObserver
    
    func paymentQueue(queue: SKPaymentQueue!, updatedTransactions transactions: [AnyObject]!) {
        for transaction in transactions as! [SKPaymentTransaction] {
            switch transaction.transactionState {
            case SKPaymentTransactionState.Purchased:
                println("Transaction completed successfully")
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                
                if transaction.payment.productIdentifier == "PD_AddFeatures_1_2015" {
                    (UIApplication.sharedApplication().delegate as! AppDelegate).didBuyAdditionalFeatures = true
                    delegate?.didPurchaseAdditionalFeatures()
                    transactionInProgress = false
                
                }
                completionMethod?(successful: transaction.payment.productIdentifier == "PD_AddFeatures_1_2015")
                
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: AdditionalFeaturesKey)
                
            case SKPaymentTransactionState.Failed:
                println("Transaction failed...")
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                transactionInProgress = false
                
                completionMethod?(successful: false)
                
            case SKPaymentTransactionState.Deferred:
                println("Transaction is deferred/pending...")
                
            case SKPaymentTransactionState.Purchasing:
                println("Purchase is in progress... Standby...")
                
            case SKPaymentTransactionState.Restored:
                println("Purchase has been successfully restored!")
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                completionMethod?(successful: transaction.payment.productIdentifier == "PD_AddFeatures_1_2015")
                transactionInProgress = false
                
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: AdditionalFeaturesKey)
                
            default:
                println(transaction.transactionState.rawValue)
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue!) {
        for transaction in queue.transactions as! [SKPaymentTransaction] {
            let productID = transaction.payment.productIdentifier
            
            if productID == "PD_AddFeatures_1_2015" {
                (UIApplication.sharedApplication().delegate as! AppDelegate).didBuyAdditionalFeatures = true
                delegate?.didPurchaseAdditionalFeatures()
            }
        }
        
        let alert = UIAlertController(title: "Purchases successfully restored!", message: "Any purchases you made with this account have been restored.", preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alert.addAction(okAction)
        
        appDelegate.window!.rootViewController!.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: Custom Methods
    
    func askForAdditionalFeatures(fromCategories: Bool, completion: ((successful: Bool) -> Void)?) {
        if transactionInProgress {
            return
        }
        
        let normalString = "PrayerDevotion is a free application, but there are additional features available that are not necessary to use the core features of the application. These features only cost $0.99 USD as a one-time payment. Would you like to purchase them?"
        let fromCategoriesString = "PrayerDevotion is a free application, but there are additional features available that are not necessary to use the core features of the application. Included is the ability to create more than 5 categories at once. These features only cost $0.99 USD as a one-time payment. Would you like to purchase them?"
        
        let alert = UIAlertController(title: "PrayerDevotion", message: fromCategories == true ? fromCategoriesString : normalString, preferredStyle: .Alert)
        
        let notNowAction = UIAlertAction(title: "Not Now", style: .Cancel, handler: nil)
        alert.addAction(notNowAction)
        
        let sureAction = UIAlertAction(title: "Sure", style: .Default, handler: { alertAction in
            let payment = SKPayment(product: self.productsArray[0])
            SKPaymentQueue.defaultQueue().addPayment(payment)
            self.transactionInProgress = true
        })
        alert.addAction(sureAction)
        
        appDelegate.window!.rootViewController!.presentViewController(alert, animated: true, completion: nil)
        
        completionMethod = completion
    }
}