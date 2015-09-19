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
            let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<String>)
            
            productRequest.delegate = self
            productRequest.start()
        } else {
            print("Unable to make In-App Purchases on this device")
        }
    }
    
    func restoreAdditionalFeatures() {
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    // MARK: Validation
    
    func validateReceipt() {
        //let response: NSURLResponse?
        //let error: NSError?
        
        let receiptURL = NSBundle.mainBundle().appStoreReceiptURL
        let receipt: NSData = try! NSData(contentsOfURL: receiptURL!, options: [])
        
        let receiptData: NSString = receipt.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        print("\(receiptData)")
        
        let request = NSMutableURLRequest(URL: NSURL(string: "http://localhost/PrayerDevotion/write.php")!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        request.HTTPBody = receiptData.dataUsingEncoding(NSASCIIStringEncoding)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error in
            let err: NSError? = nil
            let json = try! NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves) as? NSDictionary
            
            if err != nil {
                print("An error occurred while validating receipt: \(err), \(err!.localizedDescription)")
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Could not parse JSON: '\(jsonStr)'")
            } else {
                if let parseJSON = json {
                    print("Receipt \(parseJSON)")
                } else {
                    let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    print("Receipt error: \(jsonStr)")
                }
            }
        })
        
        task.resume() 
    }
    
    // MARK: Products Request Delegate Methods
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        if response.products.count != 0 {
            for product in response.products {
                productsArray.append(product )
            }
        } else {
            print("There are no products")
        }
        
        if response.invalidProductIdentifiers.count != 0 {
            print(response.invalidProductIdentifiers.description)
        }
    }
    
    // MARK: SKPaymentTransactionObserver
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case SKPaymentTransactionState.Purchased:
                print("Transaction completed successfully")
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                
                if transaction.payment.productIdentifier == "PD_AddFeatures_1_2015" {
                    (UIApplication.sharedApplication().delegate as! AppDelegate).didBuyAdditionalFeatures = true
                    delegate?.didPurchaseAdditionalFeatures()
                    transactionInProgress = false
                
                }
                completionMethod?(successful: transaction.payment.productIdentifier == "PD_AddFeatures_1_2015")
                
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: AdditionalFeaturesKey)
                
            case SKPaymentTransactionState.Failed:
                print("Transaction failed...")
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                transactionInProgress = false
                
                completionMethod?(successful: false)
                
            case SKPaymentTransactionState.Deferred:
                print("Transaction is deferred/pending...")
                
            case SKPaymentTransactionState.Purchasing:
                print("Purchase is in progress... Standby...")
                
            case SKPaymentTransactionState.Restored:
                print("Purchase has been successfully restored!")
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                completionMethod?(successful: transaction.payment.productIdentifier == "PD_AddFeatures_1_2015")
                transactionInProgress = false
                
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: AdditionalFeaturesKey)
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        for transaction in queue.transactions {
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