//
//  AppDelegate.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 5/11/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import UIKit
import CoreData
import PDKit
import GoogleMaps
import QuartzCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var themeBackgroundColor: UIColor = Color.Brown
    var themeTintColor: UIColor = Color.Brown
    var themeTextColor: UIColor = Color.TrueWhite
    
    var themeColorString: String = "Brown"
    
    var didBuyAdditionalFeatures = false
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        // Migrate the data from the first release of the application
        migrateData()
        migrateToDaily()
        
        GMSServices.provideAPIKey(googleiOSAPIKey) // Provide Google Maps with API Key
        
        // Ask for notifications
        let userNotifications = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(userNotifications)
        
        let userPrefs = NSUserDefaults.standardUserDefaults() // Get users prefs
        
        let installString: String? = userPrefs.objectForKey("didInstallApp_2.0") as? String
        
        if installString == nil || installString == "" {
            userPrefs.setBool(true, forKey: "firstInstallation")
            CategoryStore.sharedInstance.addCategoryToDatabase("Uncategorized", dateCreated: NSDate())
            
            print("User installed app for the first time. Make sure all local notifications are deleted")
            UIApplication.sharedApplication().cancelAllLocalNotifications()
            
            userPrefs.setObject("installed", forKey: "didInstallApp_2.0")
        }
        
        Color.setThemeColors(&themeBackgroundColor, tintColor: &themeTintColor, textColor: &themeTextColor, colorString: &themeColorString)
        let tintColor = userPrefs.stringForKey("themeBackgroundColor")!
        
        let autoOpenState = userPrefs.boolForKey("openPrayerDetailsAutoAdded")
        
        if autoOpenState == false {
            userPrefs.setBool(true, forKey: "openPrayerDetailsAuto")
            userPrefs.setBool(true, forKey: "openPrayerDetailsAutoAdded")
        }
        
        window!.tintColor = tintColor != "White" ? Color.stringToColor(tintColor) : Color.Brown
                
        // Check for pending alerts and notifications and update them
        Notifications.sharedNotifications.updateNotificationQueue()
        AlertStore.sharedInstance.deletePastAlerts()
                
        validatePurchase() // Validate In-App Purchase
        
        (self.window!.rootViewController as! UITabBarController).tabBar.layer.zPosition = 1
        
        return true
    }
    
    // This handles the application open scheme
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        print("URL was \(url.host)")
        
        if let host = url.host {
            if host == "open-today" {
                print("URL with scheme \(url.scheme) and host \(host) opened today view")
                
                let userInfo: [NSObject: AnyObject] = ["command": "open-today"]
                NSNotificationCenter.defaultCenter().postNotificationName("HandleURLNotification", object: nil, userInfo: userInfo)
            } else if host == "open-prayer" {
                print("URL with scheme \(url.scheme) and host \(host) passed query \(url.query!) to open prayer")
                
                let userInfo: [NSObject: AnyObject] = ["command": "open-prayer", "prayerID": "\(getURLPrayerID(url.query!)!)"]
                NSNotificationCenter.defaultCenter().postNotificationName("HandleURLNotification", object: nil, userInfo: userInfo)
            }
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        Notifications.sharedNotifications.updateNotificationQueue()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        Notifications.sharedNotifications.updateNotificationQueue()
        AlertStore.sharedInstance.deletePastAlerts()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        //self.saveContext()
        Notifications.sharedNotifications.updateNotificationQueue()
    }
    
    // MARK: Local Notifications
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        Notifications.sharedNotifications.updateNotificationQueue()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.shadowsystems.PrayerDevotion" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] 
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("PrayerDevotion", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("PrayerDevotion.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(error), \(error!.userInfo)")
                    abort()
                }
            }
        }
    }
    
    // MARK: Device Orientation
    
    /*func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .Portrait
        } else {
            return .All
        }
    }*/
    
    // MARK: Migration
    
    // Function for migration to later version of PrayerDevotion
    // CURRENT: Beta 2.0
    func migrateData() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.boolForKey("didMigratePrayerToBeta2.0") == false {
            let groupURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.shadowsystems.prayerdevotion")
            let oldStoreURL = applicationDocumentsDirectory.URLByAppendingPathComponent("PrayerDevotion.sqlite")
            let newStoreURL = groupURL!.URLByAppendingPathComponent("PrayerDevotion.sqlite")
        
            var sourceStore: NSPersistentStore? = nil
            var destinationStore: NSPersistentStore? = nil
        
            sourceStore = persistentStoreCoordinator!.persistentStoreForURL(oldStoreURL)
            //let newError: NSError? = nil
            if sourceStore != nil {
                do {
                    destinationStore = try persistentStoreCoordinator!.migratePersistentStore(sourceStore!, toURL: newStoreURL, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true], withType: NSSQLiteStoreType)
                } catch let error as NSError {
                    print("An error occurred during migration: \(error)")
                    destinationStore = nil
                }
                if destinationStore == nil {
                    print("Error migrating store")
                } else {
                    print("Migration successful!")
                
                    do {
                        try NSFileManager.defaultManager().removeItemAtPath(oldStoreURL.path!)
                    } catch {
                        print("Error migrating old store")
                    }
                    
                    migrateToPrayerID()
                    
                    userDefaults.setBool(true, forKey: "didMigratePrayerToBeta2.0")
                }
            }

        }
    }
    
    // Migrate each prayer to user a prayer ID that distinguishes each prayer from one another
    func migrateToPrayerID() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.boolForKey("didAddPrayerIDs") == false {
            print("Adding Prayer IDs to prayers")
            PrayerStore.sharedInstance.addPrayerIDDuringMigration()
        }
    }
    
    func migrateToDaily() {
        PrayerStore.sharedInstance.addDailyDateToPrayers()
    }
    
    // This takes a URL that I make and returns the prayer ID sent
    func getURLPrayerID(query: String) -> Int32? {
        // var dict = [String: Int32]()
        
        let comps: [String] = query.componentsSeparatedByString("=")
        
        if comps.count == 2 {
            return Int32(Int(comps[1])!)
        }
        
        return nil
    }
    
    // MARK: Custom Methods
    
    func switchTabBarToTab(tab: Int) {
        (window?.rootViewController as! UITabBarController).selectedIndex = tab
    }
    
    func validatePurchase() {
        let purchased = NSUserDefaults.standardUserDefaults().boolForKey(AdditionalFeaturesKey)
        
        if purchased {
            didBuyAdditionalFeatures = true
            print("Purchased In-App Additional Features")
        } else {
            print("User has not yet purchased the in app additional features")
        }
    }

}

