//
//  CoreDataManager.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 12/11/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import PDKit
import CoreData

let WillChangeStoreNotificationID = "PDWillChangeStoreNotification"
let DidChangeStoreNotificationID = "PDDidChangeStoreNotification"
let DidImportChangesNotificationID = "PDDidImportChangesNotification"

@objc class CoreDataManager: NSObject, PrayerDevotionCloudStoreDelegate {
    
    //private var storeChangedDelegates: [AnyObject]? = nil
    
    private var currentViewController: UIViewController? = nil

    class var sharedInstance: CoreDataManager {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: CoreDataManager? = nil
        }
        
        dispatch_once(&Static.onceToken, {
            Static.instance = CoreDataManager()
        })
        
        return Static.instance!
    }
    
    func applicationInitialized() {
        PrayerDevotionCloudStore.sharedInstance.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadedNewVC:", name: "LoadedNewViewController", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "storeIsReady:", name: "StoreIsReady", object: nil)
        
        PrayerDevotionCloudStore.sharedInstance.requestBeginLoadingDataStore()
        
        // Put all CoreData related initialization here...
    }
    
    func loadedNewVC(notification: NSNotification) {
        if notification.userInfo!["viewController"] != nil {
            if currentViewController == nil {
                PrayerDevotionCloudStore.sharedInstance.requestFinishLoadingDataStore()
            }
            
            currentViewController = notification.userInfo!["viewController"] as? UIViewController
        }
    }
    
    // MARK: Custom Methods
    
    func storeIsReady(notification: NSNotification) {
        let userPrefs = NSUserDefaults.standardUserDefaults()
        
        // This install string is for every user that has used version 2.0 and up
        let installString: String? = userPrefs.objectForKey("didInstallApp_2.0") as? String
        
        let iCloudUpdateInstalled = userPrefs.boolForKey("iCloudUpdateInstalled")
        if iCloudUpdateInstalled == false && installString == "didInstallApp_2.0" {
            userPrefs.setBool(true, forKey: "showiCloudMigrateAlert")
            userPrefs.setBool(true, forKey: "iCloudUpdateInstalled")
            userPrefs.setBool(false, forKey: "iCloudEnabled")
            userPrefs.setBool(false, forKey: "keepLocalPrayerBackup")
        } else if iCloudUpdateInstalled == false {
            let ubiquityURL = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier("iCloud.com.shadowsystems.PrayerDevotion")
            userPrefs.setBool(ubiquityURL != nil, forKey: "iCloudEnabled")
            userPrefs.setBool(ubiquityURL != nil, forKey: "keepLocalPrayerBackup")
        }
        
        //let isiCloudEnabled = userPrefs.boolForKey("iCloudEnabled")
        //print("iCloud Enabled: \(isiCloudEnabled)")
        //CoreDataStore.sharedInstance.iCloudEnabled = isiCloudEnabled
        
        if installString == nil || installString == "" {
            userPrefs.setBool(true, forKey: "firstInstallation")
            CategoryStore.sharedInstance.addCategoryToDatabase("Uncategorized", dateCreated: NSDate())
        
            print("User installed app for the first time. Make sure all local notifications are deleted")
            UIApplication.sharedApplication().cancelAllLocalNotifications()
        
            userPrefs.setObject("installed", forKey: "didInstallApp_2.0")
        }
        
        // Check for pending alerts and notifications and update them
        Notifications.sharedNotifications.updateNotificationQueue()
        AlertStore.sharedInstance.deletePastAlerts()
    }
    
    // MARK: PrayerDevotionCloudStore Delegate
    
    func contextSaveNotification(notification: NSNotification) {
        print("Store Context Saved")
    }
    
    func storeDidImportUbiquitousContentChangesNotification(notification: NSNotification) {
        PrayerDevotionCloudStore.sharedInstance.saveContext()
        
        NSNotificationCenter.defaultCenter().postNotificationName(DidImportChangesNotificationID, object: nil)
    }
    
    func storeWillChangeNotification() {
        /*if !UIApplication.sharedApplication().isIgnoringInteractionEvents() {
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        }*/
        
        NSNotificationCenter.defaultCenter().postNotificationName(WillChangeStoreNotificationID, object: nil)
    }
    
    func storeDidChangeNotification() {
        /*if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
        }*/
        
        NSNotificationCenter.defaultCenter().postNotificationName(DidChangeStoreNotificationID, object: nil)
    }
}