//
//  CoreDataStore.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/14/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData

@objc public protocol CoreDataStoreDelegate {
    func didMergeUbiquitousChanges()
}

public let iCloudEnabledKey = "iCloudEnabled" // Checks to see if iCloud is enabled
public let allowLocalBackupKey = "AllowLocalBackup" // Checks to see if a local backup is allowed
public let askForMergeKey = "AskForMerge" // If true, ask the user for a merge

public let iCloudContainerID = "iCloud.com.shadowsystems.PrayerDevotion" // This is the container ID of the iCloud storage

public class CoreDataStore {
    
    var options: [String : AnyObject] = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
    
    public var delegate: CoreDataStoreDelegate?
    
    
    // MARK: Variables
    public var iCloudEnabled: Bool = false {
        willSet {
            if newValue {
                options.removeValueForKey(NSPersistentStoreRemoveUbiquitousMetadataOption)
                options[NSPersistentStoreUbiquitousContentNameKey] = "PrayerDevotion"
            } else {
                options.removeValueForKey(NSPersistentStoreUbiquitousContentNameKey)
                options[NSPersistentStoreRemoveUbiquitousMetadataOption] = true
            }
        }
    }
    
    var deviceListURL: NSURL {
        let iCloudURLBase = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier("iCloud.com.shadowsystems.PrayerDevotion")
        let deviceListBase = (iCloudURLBase!.path! as NSString).stringByAppendingPathComponent("Documents")
        let deviceList = (deviceListBase as NSString).stringByAppendingPathComponent("ICLKnownDevices.plist")
        return NSURL(fileURLWithPath: deviceList)
    }
    
    // MARK: Singleton Method
    public class var sharedInstance: CoreDataStore {
        struct Static {
            static var onceToken: dispatch_once_t =  0
            static var instance: CoreDataStore? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = CoreDataStore()
        }
        
        return Static.instance!
    }
    
    // Custom Functions
    
    // MARK: - Core Data stack
    
    public lazy var applicationDocumentsDirectory: NSURL = {
        return NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.shadowsystems.prayerdevotion")!
    }()
    
    public lazy var managedObjectModel: NSManagedObjectModel = {
        let bundle = NSBundle(identifier: "com.shadowsystems.PDKit")!
        let modelURL = bundle.URLForResource("PrayerDevotion", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    public lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("PrayerDevotion.sqlite")
        
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: self.options)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "CoreDataStore", code: 9999, userInfo: dict)
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
        }()
    
    public class func context() -> NSManagedObjectContext {
        return self.sharedInstance.managedObjectContext!
    }
    
    public lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    public func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                    NSLog("Unresolved error \(error), \(error!.userInfo)")
                    abort()
                }
            }
        }
    }
    
    // MARK: iCloud
    
    public func migrateiCloudStoreToLocal() {
        let store = persistentStoreCoordinator!.persistentStores.first!
        self.iCloudEnabled = false
        
        let storeURL = applicationDocumentsDirectory.URLByAppendingPathComponent("PrayerDevotion.sqlite")
        
        do {
            let newStore = try persistentStoreCoordinator!.migratePersistentStore(store, toURL: storeURL, options: options, withType: NSSQLiteStoreType)
            
            self.reloadStore(newStore)
        } catch let error as NSError {
            print("Error migrating iCloud Data to local store with error code \(error.code): \(error), \(error.localizedDescription)")
        }
    }
    
    public func migrateLocalStoreToiCloud() {
        let store = persistentStoreCoordinator!.persistentStores.first!
        self.iCloudEnabled = true
        
        let storeURL = applicationDocumentsDirectory.URLByAppendingPathComponent("PrayerDevotion.sqlite")
        
        do {
            let newStore = try persistentStoreCoordinator!.migratePersistentStore(store, toURL: storeURL, options: options, withType: NSSQLiteStoreType)
            
            self.reloadStore(newStore)
        } catch let error as NSError {
            print("Error migrating Local Data to iCloud store with error code \(error.code): \(error), \(error.localizedDescription)")
        }
    }
    
    public func reloadStore(store: NSPersistentStore?) {
        if let store = store {
            do {
                try persistentStoreCoordinator!.removePersistentStore(store)
            } catch let error as NSError {
                print("Error reloading store with error code \(error.code): \(error), \(error.localizedDescription)")
            }
        }
        
        let storeURL = applicationDocumentsDirectory.URLByAppendingPathComponent("PrayerDevotion.sqlite")
        
        do {
            try persistentStoreCoordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: self.options)
        } catch let error as NSError {
            print("Error adding new persistent store with error code \(error.code): \(error), \(error.localizedDescription)")
        }
    }
    
    public class func migrateToICloud() {
        let documentsDir = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.shadowsystems.prayerdevotion")!
        let storeURL = documentsDir.URLByAppendingPathComponent("PrayerDevotion.sqlite")
        
        let coord = NSPersistentStoreCoordinator(managedObjectModel: CoreDataStore.sharedInstance.managedObjectModel)
        
        let options = [NSPersistentStoreUbiquitousContentNameKey: "PrayerDevotion", NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        
        do {
            try coord.migratePersistentStore(CoreDataStore.sharedInstance.persistentStoreCoordinator!.persistentStores.first!, toURL: storeURL, options: options, withType: NSSQLiteStoreType)
            
            let userPrefs = NSUserDefaults.standardUserDefaults()
            userPrefs.setBool(true, forKey: "iCloudMigrateComplete")
        } catch let error as NSError {
            print("Error migrating to icloud: \(error), \(error.localizedDescription)")
        }
    }
    
    // MARK: iCloud Notifications
    
    public var updateContextWithUbiquitousContentUpdates: Bool = false {
        willSet {
            ubiquitousChangesObserver = newValue ? NSNotificationCenter.defaultCenter() : nil
        }
    }
    
    private var ubiquitousChangesObserver: NSNotificationCenter? {
        didSet {
            oldValue?.removeObserver(self, name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: self.persistentStoreCoordinator!)
            ubiquitousChangesObserver?.addObserver(self, selector: "persistentStoreDidImportUbiquitousContentChanges:", name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: self.persistentStoreCoordinator)
            ubiquitousChangesObserver?.addObserver(self, selector: "persistentStoreCoordinatorWillChangeStores:", name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.persistentStoreCoordinator!)
        }
    }
    
    @objc private func persistentStoreDidImportUbiquitousContentChanges(notification: NSNotification) {
        managedObjectContext!.performBlock({
            dispatch_async(dispatch_get_main_queue(), {
                print("Merging Changes...")
                self.managedObjectContext!.mergeChangesFromContextDidSaveNotification(notification)
                
                self.delegate?.didMergeUbiquitousChanges()
            })
        })
    }
    
    @objc func persistentStoreCoordinatorWillChangeStores(notification: NSNotification) {
        if managedObjectContext!.hasChanges {
            do {
                print("Coordinator Will Change Store")
                try managedObjectContext!.save()
            } catch let error as NSError {
                print("Error saving \(error)")
            }
        }
        
        let ubiquityURL = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier("iCloud.com.shadowsystems.PrayerDevotion")
        let keepLocalPrayerBackup = NSUserDefaults.standardUserDefaults().boolForKey(allowLocalBackupKey)
        if ubiquityURL != nil {
            // First check to see if we should keep a local backup
            if keepLocalPrayerBackup {
                CoreDataStore.sharedInstance.migrateiCloudStoreToLocal()
                return
            }
        }
        
        // If not, reset the entire managedObjectContext
        managedObjectContext!.reset()
    }
    
}
