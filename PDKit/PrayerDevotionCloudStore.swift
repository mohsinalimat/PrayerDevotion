//
//  PrayerDevotionCloudStore.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 12/9/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData
import Reachability

// MARK: UIAlertController methods

extension UIAlertController {
    
    func present() {
        if let rootVC = UIApplication.sharedApplication().keyWindow?.rootViewController {
            presentFromController(rootVC)
        }
    }
    
    private func presentFromController(controller: UIViewController) {
        if let navVC = controller as? UINavigationController, let visibleVC = navVC.visibleViewController {
            presentFromController(visibleVC)
        } else {
            if let tabVC = controller as? UITabBarController, let selectedVC = tabVC.selectedViewController {
                presentFromController(selectedVC)
            } else {
                controller.presentViewController(self, animated: true, completion: nil)
            }
        }
    }
    
}

@objc public enum StoreState: Int {
    case Uninitialized = 0
    case ConvertingLegacyDataToCoreData = 1
    case ImportingMinimalDataSet = 2
    
    case CheckingForiCloudStore = 3
    case ValidatingUbiquityToken = 4
    case EnableiCloudPrompt = 5
    case ReadyToInitializeDataStore = 6
    
    case MigrateLocalDataToCloud = 7
    case MigrateCloudDataToLocal = 8
    case ReadyToLoadStore = 9
    
    case DataStoreOnline = 10
}

public let Setting_MinimalDataImportPerformed = "MinimalDataImportPerformed"
public let Setting_iCloudEnabled = "iCloud.Enabled"
public let Setting_IdentityToken = "iCloud.IdentityToken"

public let Setting_MigrationToCloudPerformedBase = "iCloud.%@.MigrationPerformedToCloud";
public let Setting_MigrationFromCloudPerformedBase = "iCloud.%@.MigrationPerformedFromCloud";

public let Setting_iCloudUUID = "iCloud.UUID";
public let iCloudDeviceListName = "ICLKnownDevices.plist";

@objc public protocol PrayerDevotionCloudStoreDelegate: NSObjectProtocol {
    func contextSaveNotification(notification: NSNotification)
    func storeDidImportUbiquitousContentChangesNotification(notification: NSNotification)
    func storeWillChangeNotification()
    func storeDidChangeNotification()
    
    optional func prepareForMigration(isLocalToCloud: Bool)
    optional func doesAppSupportiCloud() -> Bool
}

public class PrayerDevotionCloudStore: NSObject {
    
    public var delegate: PrayerDevotionCloudStoreDelegate?
    
    var storeURL: NSURL!
    var storeOptions: [String: AnyObject]!
    
    public var currentState: StoreState = .Uninitialized
    var canFinishLoadingDataSource: NSCondition?
    var requestFinishLoadingDataStoreRecieved: Bool = false
    
    var undoLevel: Int = 0
    
    var deviceList: DeviceList?
    var deviceListMetadataQuery: NSMetadataQuery?
    var knownDeviceUUIDs: [NSString]?
    
    var iCloudStoreExists: Bool = false
    var backgroundQueue: dispatch_queue_t!
    var accountChanged: Bool = false
    var firstTimeOnline: Bool = false
    
    public var migratingFromVersion1_0: Bool = false
    
    public class var sharedInstance: PrayerDevotionCloudStore {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: PrayerDevotionCloudStore? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = PrayerDevotionCloudStore().initInstance()
        }
        
        return Static.instance!
    }
    
    override init() {
        
    }
    
    private func initInstance() -> PrayerDevotionCloudStore {
        currentState = .Uninitialized
        undoLevel = 0
        accountChanged = false
        
        deviceList = nil
        iCloudStoreExists = false
        
        firstTimeOnline = true
        
        backgroundQueue = dispatch_queue_create("PrayerDevotionCloudStore.BackgroundQueue", nil)
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if userDefaults.objectForKey(Setting_iCloudUUID) == nil {
            userDefaults.setObject(NSUUID().UUIDString, forKey: Setting_iCloudUUID)
            userDefaults.synchronize()
        }
        
        return self
    }
    
    // MARK: Helper Methods
    
    func synced(lock: AnyObject, closure: (() -> ())) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    // MARK: Device List Handling
    
    func setupDeviceList() {
        if !self.iCloudAvailable() {
            return
        }
        
        knownDeviceUUIDs = nil
        
        deviceList = DeviceList(withURL: self.deviceListURL, queue: NSOperationQueue())
        
        NSFileCoordinator.addFilePresenter(deviceList!)
        
        deviceListMetadataQuery = NSMetadataQuery()
        deviceListMetadataQuery!.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        deviceListMetadataQuery!.predicate = NSPredicate(format: "%K like %@", NSMetadataItemFSNameKey, iCloudDeviceListName)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "deviceListChanged:", name: NSMetadataQueryDidUpdateNotification, object: deviceListMetadataQuery)
        
        dispatch_async(dispatch_get_main_queue(), {
            self.deviceListMetadataQuery!.startQuery()
        })
    }
    
    func teardownDeviceList() {
        if let deviceList = deviceList {
            NSFileCoordinator.removeFilePresenter(deviceList)
            self.deviceList = nil
            
            self.knownDeviceUUIDs = nil
            
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NSMetadataQueryDidUpdateNotification, object: deviceListMetadataQuery)

            dispatch_async(dispatch_get_main_queue(), {
                self.deviceListMetadataQuery!.stopQuery()
                self.deviceListMetadataQuery = nil
            })
        }
    }
    
    func deviceListChanged(notification: NSNotification) {
        dispatch_async(backgroundQueue, {
            self.synced(self.backgroundQueue) {
                self.deviceListMetadataQuery?.disableUpdates()
                
                self.refreshDeviceList(false, completionHandler: { deviceListExisted, currentDevicePresent in
                    self.deviceListMetadataQuery?.enableUpdates()
                })
            }
        })
    }
    
    func refreshDeviceList(canAddCurrentDevice: Bool, completionHandler: ((deviceListExisted: Bool, currentDevicePresent: Bool) -> Void)) {
        knownDeviceUUIDs = nil

        if !self.doesAppSupportiCloud() {
            return
        }
        
        let iCloudUUID: NSString? = NSUserDefaults.standardUserDefaults().stringForKey(Setting_iCloudUUID)
        
        let fileURL = self.deviceListURL
        fileURL.forceSyncFile(backgroundQueue, completionHandler: { syncCompleted in
            let coordinator = NSFileCoordinator(filePresenter: self.deviceList)
            
            var deviceListExisted = false
            var currentDevicePresent = false
            
            var error: NSError?
            coordinator.coordinateReadingItemAtURL(fileURL, options: NSFileCoordinatorReadingOptions(rawValue: 0), error: &error, byAccessor: { readURL in
                let deviceList = NSDictionary(contentsOfURL: readURL)
                
                if let deviceList = deviceList {
                    self.knownDeviceUUIDs = deviceList.objectForKey("DeviceUUIDs") as? [String]
                }
                
                deviceListExisted = self.knownDeviceUUIDs != nil && self.knownDeviceUUIDs!.count > 0
                currentDevicePresent = deviceListExisted && self.knownDeviceUUIDs!.contains(iCloudUUID!)
            })
            
            if !currentDevicePresent && canAddCurrentDevice {
                var newKnownDeviceUUIDs: [NSString] = self.knownDeviceUUIDs != nil ? self.knownDeviceUUIDs! : [NSString]()
                newKnownDeviceUUIDs.append(iCloudUUID!)
                
                let newDeviceList: NSDictionary = [("DeviceUUIDs" as NSString) : NSArray(array: newKnownDeviceUUIDs)]
                print("newDeviceList: \(newDeviceList)")
                
                let iCloudURLBase = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier("iCloud.com.shadowsystems.PrayerDevotion")
                var error: NSError?
                coordinator.coordinateReadingItemAtURL(iCloudURLBase!, options: NSFileCoordinatorReadingOptions(rawValue: 0), error: &error, byAccessor: { newURL in
                    
                    do {
                        try NSFileManager.defaultManager().createDirectoryAtURL(newURL, withIntermediateDirectories: true, attributes: nil)
                    } catch let error as NSError {
                        print("Error creating directories for file with code \(error.code): \(error), \(error.localizedDescription)")
                    }
                })
                
                var error2: NSError?
                coordinator.coordinateWritingItemAtURL(fileURL, options: NSFileCoordinatorWritingOptions.ForReplacing, error: &error2, byAccessor: { writeURL in
                    let ableToWrite = newDeviceList.writeToURL(writeURL, atomically: true)
                    //let ableToWrite = newDeviceList.writeToURL(writeURL, atomically: false)
                    if ableToWrite {
                        print("Wrote file with success!")
                    } else {
                        print("Did not write file... error: \(error2)")
                    }
                })
            }
            
            completionHandler(deviceListExisted: deviceListExisted, currentDevicePresent: currentDevicePresent)
        })
    }
    
    // MARK: Main Core Data Interface
    
    func performBlock(block: (() -> Void)) {
        if self.managedObjectContext!.concurrencyType == .MainQueueConcurrencyType && NSThread.currentThread().isMainThread {
            block()
        } else {
            self.managedObjectContext!.performBlock {
                block()
            }
        }
    }
    
    func performBlockAndWait(block: (() -> Void)) {
        if self.managedObjectContext!.concurrencyType == .MainQueueConcurrencyType && NSThread.currentThread().isMainThread {
            block()
        } else {
            self.managedObjectContext!.performBlockAndWait {
                block()
            }
        }
    }
    
    private var _persistentStoreCoordinator: NSPersistentStoreCoordinator? = nil
    
    public var persistentStoreCoordinator: NSPersistentStoreCoordinator? {
        get {
            /*if _persistentStoreCoordinator != nil {
                if self.currentState == .ReadyToLoadStore {
                    self.CoreData_RegisterForNotifications(_persistentStoreCoordinator!)
                }
                
                return _persistentStoreCoordinator
            }*/
            
            let coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
            
            if self.currentState == .ReadyToLoadStore {
                self.CoreData_RegisterForNotifications(coordinator!)
            }
            
            let workingOptions = self.storeOptions
            
            do {
                try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.storeURL, options: workingOptions)
            } catch let error as NSError {
                print("Unresolved Error with code \(error.code): \(error), \(error.localizedDescription)")
                abort()
            }
            
            _persistentStoreCoordinator = coordinator
            return coordinator
        }
        
        set(coordinator) {
            //self.persistentStoreCoordinator = coordinator
        }
    }
    
    private var _managedObjectContext: NSManagedObjectContext? = nil
    
    public var managedObjectContext: NSManagedObjectContext? {
        get {
            if _managedObjectContext != nil {
                return _managedObjectContext
            }
            
            var context: NSManagedObjectContext! = nil
            
            let coordinator = self.persistentStoreCoordinator
            if let coordinator = coordinator {
                if currentState.rawValue >= StoreState.ReadyToLoadStore.rawValue || migratingFromVersion1_0 {
                    context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
                    context.persistentStoreCoordinator = coordinator
                    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                    
                    context.undoManager = NSUndoManager()
                    
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextSaveNotification:", name: NSManagedObjectContextDidSaveNotification, object: context)
                } else {
                    context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
                    context.persistentStoreCoordinator = coordinator
                    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                }
            }
            
            _managedObjectContext = context
            return context
        }
        
        set(context) {
            //self.managedObjectContext = context
        }
    }
    
    public var managedObjectModel: NSManagedObjectModel {
        let bundle = NSBundle(identifier: "com.shadowsystems.PDKit")!
        let modelURL = bundle.URLForResource("PrayerDevotion", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }
    
    private func contextSaveNotification(notification: NSNotification) {
        // Must merge changes on main thread
        dispatch_async(dispatch_get_main_queue(), {
            self.delegate?.contextSaveNotification(notification)
        })
    }
    
    public func saveContext() {
        let managedObjectContext = self.managedObjectContext
        
        if let context = managedObjectContext {
            PrayerDevotionCloudStore.sharedInstance.performBlockAndWait {
                do {
                    if context.hasChanges {
                        try context.save()
                    }
                } catch let error as NSError {
                    print("Error saving prayer with code: \(error.code): \(error), \(error.localizedDescription)")
                }
            }
        }
    }
    
    public func resetCoreDataInterfaces() {
        if let context = managedObjectContext {
            PrayerDevotionCloudStore.sharedInstance.performBlockAndWait {
                do {
                    try context.save()
                } catch let error as NSError {
                    print("Error saving prayers with code: \(error.code): \(error), \(error.localizedDescription)")
                }
            }
            
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: self.managedObjectContext!)
        }
        
        if let coordinator = persistentStoreCoordinator {
            self.CoreData_UnregisterForNotifications(self.persistentStoreCoordinator!)
            
            for store in coordinator.persistentStores {
                do {
                    try coordinator.removePersistentStore(store)
                } catch {
                    print("Error reseting stores...")
                }
            }
        }
        
        persistentStoreCoordinator = nil
        managedObjectContext = nil
    }
    
    // MARK: Information Retrieval Methods
    
    public var storeNameLocal: String {
        return "PrayerDevotion"
    }
    
    public var storeNameiCloud: String {
        return "PrayerDevotion_iCloud"
    }
    
    public var storeURLLocal: NSURL {
        return self.applicationDocumentsDirectory.URLByAppendingPathComponent("PrayerDevotion").URLByAppendingPathExtension("sqlite")
    }
    
    public var storeURLiCloud: NSURL {
        return self.applicationDocumentsDirectory.URLByAppendingPathComponent(self.storeNameiCloud).URLByAppendingPathExtension("sqlite")
    }
    
    public var deviceListURL: NSURL {
        let iCloudURLBase = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier("iCloud.com.shadowsystems.PrayerDevotion")!
        let deviceListBase = (iCloudURLBase.path! as NSString).stringByAppendingPathComponent("Documents")
        let deviceList = (deviceListBase as NSString).stringByAppendingPathComponent(iCloudDeviceListName) as String
        return NSURL(fileURLWithPath: deviceList)
    }
    
    public var storeOptionsLocal: [String: AnyObject] {
        return [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
    }
    
    public var storeOptionsiCloud: [String: AnyObject] {
        let cloudDir = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier("iCloud.com.shadowsystems.PrayerDevotion")!.URLByAppendingPathComponent(self.storeNameiCloud)
        
        return [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true, NSPersistentStoreUbiquitousContentNameKey: self.storeNameiCloud, NSPersistentStoreUbiquitousContentURLKey: cloudDir]
    }
    
    public func doesAppSupportiCloud() -> Bool {
        if let delegate = self.delegate {
            if delegate.respondsToSelector("doesAppSupportiCloud") {
                return delegate.doesAppSupportiCloud!()
            }
        }
        
        return true
    }
    
    public func isDataStoreOnline() -> Bool {
        return self.currentState == .DataStoreOnline
    }
    
    public func iCloudAvailable() -> Bool {
        if !self.doesAppSupportiCloud() {
            return false
        }
        
        return self.ubiquityIdentifyToken != nil && NSFileManager.defaultManager().URLForUbiquityContainerIdentifier("iCloud.com.shadowsystems.PrayerDevotion") != nil
    }
    
    public func iCloudIsEnabled() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey(Setting_iCloudEnabled)
    }
    
    public func minimalDataImportWasPerformed() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setBool(true, forKey: Setting_MinimalDataImportPerformed)
        userDefaults.synchronize()
    }
    
    public var applicationDocumentsDirectory: NSURL {
        return NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.shadowsystems.prayerdevotion")!
    }
    
    public var ubiquityIdentifyToken: AnyObject? {
        if !self.doesAppSupportiCloud() {
            return false
        }
        
        if NSFileManager.defaultManager().URLForUbiquityContainerIdentifier("iCloud.com.shadowsystems.PrayerDevotion") != nil {
            return NSFileManager.defaultManager().ubiquityIdentityToken
        } else {
            return nil
        }
    }
    
    public func isLocalStorePresent() -> Bool {
        if self.storeURLLocal.path != nil {
            return NSFileManager.defaultManager().fileExistsAtPath(self.storeURLLocal.path!)
        }
        
        return false
    }
    
    public func isiCloudStorePresent() -> Bool {
        return iCloudStoreExists
    }
    
    // MARK: iCloud Enable / Disable
    
    public func toggleiCloud(iCloudEnabled_New: Bool) {
        let userDefault = NSUserDefaults.standardUserDefaults()
        
        userDefault.setBool(iCloudEnabled_New, forKey: Setting_iCloudEnabled)
        userDefault.synchronize()
        
        let identityToken: AnyObject? = self.ubiquityIdentifyToken
        let tokenString: String? = identityToken != nil ? NSKeyedArchiver.archivedDataWithRootObject(identityToken!).base64EncodedStringWithOptions(.Encoding64CharacterLineLength) : nil
        
        if userDefault.boolForKey(Setting_iCloudEnabled) {
            if let tokenString = tokenString {
                let Setting_MigrationToCloudPerformed = String(format: Setting_MigrationToCloudPerformedBase, tokenString)
                
                userDefault.removeObjectForKey(Setting_MigrationToCloudPerformed)
            } else {
                print("ERROR! TokenString is nil!")
            }
        } else {
            let Setting_MigrationFromCloudPerformed: String? = identityToken != nil ? String(format: Setting_MigrationFromCloudPerformedBase, tokenString!) : nil
            
            if let Setting_MigrationFromCloudPerformed = Setting_MigrationFromCloudPerformed {
                userDefault.removeObjectForKey(Setting_MigrationFromCloudPerformed)
            } else {
                print("ERROR! Setting_MigrationFromCloudPerformed!")
            }
        }
        
        userDefault.synchronize()
        
        self.delegate?.storeWillChangeNotification()
        self.currentState = .CheckingForiCloudStore
        
        self.requestLoadDataStore()
    }
    
    // MARK: iCloud Enable / Disable Internal
    
    public func switchStoreToiCloud() {
        if !(self.storeURL == self.storeURLiCloud) {
            self.storeURL = self.storeURLiCloud
            self.storeOptions = self.storeOptionsiCloud
            
            self.resetCoreDataInterfaces()
        }
    }
    
    public func switchStoreToLocal() {
        if !(self.storeURL == self.storeURLLocal) {
            self.storeURL = self.storeURLLocal
            self.storeOptions = self.storeOptionsLocal
            
            self.resetCoreDataInterfaces()
        }
    }
    
    // MARK: Finite State Machine Main Loop
    
    public func requestBeginLoadingDataStore() {
        // General Code
        assert(self.currentState == .Uninitialized)
            
        self.requestFinishLoadingDataStoreRecieved = false
        self.requestLoadDataStore()
    }
    
    public func requestFinishLoadingDataStore() {
        /*if !UIApplication.sharedApplication().isIgnoringInteractionEvents() {
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        }*/
        
        if !self.requestFinishLoadingDataStoreRecieved {
            self.canFinishLoadingDataSource?.signal()
            self.requestFinishLoadingDataStoreRecieved = true
        }
    }
    
    public func requestLoadDataStore() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.requestLoadDataStoreInternal()
        }
    }
    
    public func requestLoadDataStoreInternal() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        let networkReachability = Reachability.reachabilityForInternetConnection()
        var noConnectivity = networkReachability.currentReachabilityStatus() == .NotReachable
        
        // Initial Setup Stage
        if self.currentState == .Uninitialized {
            self.canFinishLoadingDataSource = self.requestFinishLoadingDataStoreRecieved ? nil : NSCondition()
            
            self.setupDeviceList()
            
            userDefaults.setBool(false, forKey: Setting_MinimalDataImportPerformed)
            userDefaults.synchronize()
            
            let isLocalStorePresent: Bool = self.isLocalStorePresent()
            
            // Always default to local store
            self.storeURL = self.storeURLLocal
            self.storeOptions = self.storeOptionsLocal
            
            // The local store should always be present. If it is not at this point then we
            // recreate it with minimal data
            if !isLocalStorePresent {
                userDefaults.setBool(true, forKey: Setting_MinimalDataImportPerformed)
                userDefaults.synchronize()
                
                self.currentState = .ImportingMinimalDataSet
                
                PrayerDevotionCloudStore.sharedInstance.performBlockAndWait {
                    self.saveContext()
                }
            }
            
            self.currentState = .CheckingForiCloudStore
        }
        
        let identityToken: AnyObject? = self.ubiquityIdentifyToken
        
        // We have not yet checked if the iCloud store is already present
        if self.currentState == .CheckingForiCloudStore {
            // Kick off an initial query to start the download in the background
            if identityToken != nil && !noConnectivity {
                dispatch_sync(backgroundQueue, {
                    self.refreshDeviceList(false, completionHandler: { deviceListExisted, currentDevicePresent in
                        self.iCloudStoreExists = deviceListExisted
                    })
                })
            }
            
            // We may have already been requested to proceed
            if !requestFinishLoadingDataStoreRecieved {
                canFinishLoadingDataSource?.lock()
                canFinishLoadingDataSource?.wait()
                canFinishLoadingDataSource?.unlock()
            }
            
            self.currentState = .ValidatingUbiquityToken
            
            // Refresh connectivity at this point
            noConnectivity = networkReachability.currentReachabilityStatus() == .NotReachable
        }
        
        /*if !UIApplication.sharedApplication().isIgnoringInteractionEvents() {
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        }*/
        
        // We have performed the initial setup so we know that the local data exists.
        // We now need to validate the ubiquity token and check if the user has made a choice
        // on enabling iCloud
        if currentState == .ValidatingUbiquityToken {
            // iCloud is supported for this user - check if the user has changed and warn accordingly
            if let token = identityToken {
                let previousTokenData = userDefaults.objectForKey(Setting_IdentityToken) as? NSData
                let previousIdentityToken: AnyObject? = previousTokenData != nil ? NSKeyedUnarchiver.unarchiveObjectWithData(previousTokenData!) : nil
                
                userDefaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(token), forKey: Setting_IdentityToken)
                userDefaults.synchronize()
                
                // The token has changed - warn the user so they know the data won't be present
                if previousIdentityToken != nil && !(token.isEqual(previousIdentityToken)) {
                    dispatch_async(dispatch_get_main_queue(), {
                        // let msgTitle = "iCloud Account Changed"
                        // let msgBody = "You have signed into a different iCloud account."
                        /*if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                            UIApplication.sharedApplication().endIgnoringInteractionEvents()
                        }*/
                        
                        let tokenString = NSKeyedArchiver.archivedDataWithRootObject(token).base64EncodedDataWithOptions(.Encoding64CharacterLineLength)
                        
                        let Setting_MigrationToCloudPerformed = String(format: Setting_MigrationToCloudPerformedBase, tokenString)
                        let Setting_MigrationFromCloudPerformed = String(format: Setting_MigrationFromCloudPerformedBase, tokenString)
                        
                        // Clear iCloud and migration related flags to force the user the make the choice again
                        userDefaults.removeObjectForKey(Setting_iCloudEnabled)
                        userDefaults.removeObjectForKey(Setting_MigrationToCloudPerformed)
                        userDefaults.removeObjectForKey(Setting_MigrationFromCloudPerformed)
                        userDefaults.synchronize()
                        
                        /*if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                            UIApplication.sharedApplication().endIgnoringInteractionEvents()
                        }*/
                    })
                    
                    return
                }
                
                let iCloudEnablePromptRequired = previousTokenData == nil || userDefaults.objectForKey(Setting_iCloudEnabled) == nil
                
                if iCloudEnablePromptRequired && noConnectivity {
                    // Nothing to do at this point...
                } else if iCloudEnablePromptRequired {
                    self.currentState = .EnableiCloudPrompt
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        let alertView = UIAlertController(title: "Data Storage Selection", message: "Select your preferred storage method", preferredStyle: .Alert)
                        let iCloudAction = UIAlertAction(title: "iCloud", style: .Default, handler: { alertAction in
                            
                            NSUserDefaults.standardUserDefaults().setBool(true, forKey: Setting_iCloudEnabled)
                            NSUserDefaults.standardUserDefaults().synchronize()
                            
                            self.currentState = .ReadyToInitializeDataStore
                            
                            self.requestLoadDataStore()
                        })
                        let localAction = UIAlertAction(title: "Local", style: .Default, handler: { alertAction in
                            NSUserDefaults.standardUserDefaults().setBool(false, forKey: Setting_iCloudEnabled)
                            NSUserDefaults.standardUserDefaults().synchronize()
                            
                            self.currentState = .ReadyToInitializeDataStore
                            
                            self.requestLoadDataStore()
                        })
                        
                        alertView.addAction(iCloudAction)
                        alertView.addAction(localAction)
                        
                        alertView.present()
                        
                        /*if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                            UIApplication.sharedApplication().endIgnoringInteractionEvents()
                        }*/
                    })
                    
                    // Must exit at this point - function is re-entered by the view
                    return
                }
                
                self.currentState = .ReadyToInitializeDataStore
            } else {
                self.forceLocalStoreAndDisableiCloud()
                
                self.currentState = .ReadyToInitializeDataStore
            }
        }
        
        // The user has made a choice if iCloud can be enabled or not
        if currentState == .ReadyToInitializeDataStore {
            let tokenString: String? = identityToken != nil ? NSKeyedArchiver.archivedDataWithRootObject(identityToken!).base64EncodedStringWithOptions(.Encoding64CharacterLineLength) : nil
            
            // User has elected to enable iCloud and it is supported
            if userDefaults.boolForKey(Setting_iCloudEnabled) {
                let Setting_MigrationToCloudPerformed = String(format: Setting_MigrationToCloudPerformedBase, tokenString!)
                
                // Migration cannot be performed if we have just done a minimal import
                // AND
                // Migration to the Cloud has not already been performed
                if (!userDefaults.boolForKey(Setting_MigrationToCloudPerformed) && !userDefaults.boolForKey(Setting_MinimalDataImportPerformed)) {
                    currentState = .MigrateLocalDataToCloud
                    
                    if isiCloudStorePresent() {
                        dispatch_async(dispatch_get_main_queue(), {
                            let alertView = UIAlertController(title: "Migrate Data To iCloud", message: "Would you like to merge you local data with iCloud or use only your iCloud data?", preferredStyle: .Alert)
                            let mergeAction = UIAlertAction(title: "Merge Local", style: .Default, handler: { alertAction in
                                
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                                    self.migrateLocalStoreToCloud()
                                })
                            })
                            let keepAction = UIAlertAction(title: "Use iCloud", style: .Default, handler: { alertAction in
                                self.switchStoreToiCloud()
                                
                                self.currentState = .ReadyToLoadStore
                                
                                let tokenString = NSKeyedArchiver.archivedDataWithRootObject(self.ubiquityIdentifyToken!).base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
                                let Setting_MigrationToCloudPerformed = String(format: Setting_MigrationToCloudPerformedBase, tokenString)
                                
                                NSUserDefaults.standardUserDefaults().setBool(true, forKey: Setting_MigrationToCloudPerformed)
                                NSUserDefaults.standardUserDefaults().synchronize()
                                
                                self.requestLoadDataStore()
                            })
                            
                            alertView.addAction(mergeAction)
                            alertView.addAction(keepAction)
                            
                            alertView.present()
                            
                            /*if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                            }*/
                        })
                    } else {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                            self.migrateLocalStoreToCloud()
                        })
                    }
                    
                    // Must exit at this point
                    return
                } else {
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: Setting_MigrationToCloudPerformed)
                    NSUserDefaults.standardUserDefaults().synchronize()
                    
                    if migratingFromVersion1_0 {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                            self.migrateLocalStoreToCloud()
                            
                            return
                        })
                    }
                    
                    self.switchStoreToiCloud()
                    
                    self.currentState = .ReadyToLoadStore
                }
            } else { // iCloud is not being used (or is not supported)
                let Setting_MigrationFromCloudPerformed: String? = identityToken != nil ? String(format: Setting_MigrationFromCloudPerformedBase, tokenString!) : nil
                
                // If we have a token
                //   AND there is data in the cloud
                //   AND migration has not been performed
                //   AND the network is reachable
                // then attempt to perform the migration
                if identityToken != nil && !userDefaults.boolForKey(Setting_MigrationFromCloudPerformed!) && self.isiCloudStorePresent() && !noConnectivity {
                    currentState = .MigrateCloudDataToLocal
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        let alertView = UIAlertController(title: "Migrate Data From iCloud", message: " You have data currently in your iCloud storage. Would you like to keep your iCloud data locally or start afresh (current iCloud data will not be overwritten)?", preferredStyle: .Alert)
                        let replaceAction = UIAlertAction(title: "Refresh", style: .Default, handler: { alertAction in
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                                self.migrateCloudStoreToLocal(true)
                            })
                        })
                        let keepAction = UIAlertAction(title: "Keep", style: .Default, handler: { alertAction in
                            self.switchStoreToLocal()
                            
                            self.currentState = .ReadyToLoadStore
                            
                            let tokenString = NSKeyedArchiver.archivedDataWithRootObject(self.ubiquityIdentifyToken!).base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
                            let Setting_MigrationFromCloudPerformed = String(format: Setting_MigrationFromCloudPerformedBase, tokenString)
                            
                            NSUserDefaults.standardUserDefaults().setBool(true, forKey: Setting_MigrationFromCloudPerformed)
                            NSUserDefaults.standardUserDefaults().synchronize()
                            
                            self.requestLoadDataStore()
                        })
                        
                        alertView.addAction(replaceAction)
                        alertView.addAction(keepAction)
                        
                        alertView.present()
                        
                        /*if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                            UIApplication.sharedApplication().endIgnoringInteractionEvents()
                        }*/
                    })
                    
                    return
                } else {
                    if identityToken != nil {
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: Setting_MigrationFromCloudPerformed!)
                        NSUserDefaults.standardUserDefaults().synchronize()
                    }
                    
                    self.switchStoreToLocal()
                    
                    currentState = .ReadyToLoadStore
                }
            }
        }
        
        // Any migration has been performed and the data store may be loaded
        if currentState == .ReadyToLoadStore {
            // Remove temporary flag
            userDefaults.removeObjectForKey(Setting_MinimalDataImportPerformed)
            userDefaults.synchronize()
            
            accountChanged = false
            
            /*if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
            }*/
            
            if self.storeURL == self.storeURLiCloud {
                iCloudStoreExists = true

                dispatch_async(backgroundQueue, {
                    self.refreshDeviceList(true, completionHandler: { deviceListExisted, currentDevicePresent in
                    })
                })
            }
            
            self.resetCoreDataInterfaces()
            
            NSNotificationCenter.defaultCenter().postNotificationName("StoreIsReady", object: nil, userInfo: nil)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.managedObjectContext
            })
        }
    }
    
    // MARK: Local Store Methods
    
    public func deleteLocalStore() {
        if !NSFileManager.defaultManager().fileExistsAtPath(self.storeURLLocal.path!) {
            return
        }
        
        do {
            try NSFileManager.defaultManager().removeItemAtPath(self.storeURLLocal.path!)
        } catch let error as NSError {
            print("Error deleting local store with code \(error.code): \(error), \(error.localizedDescription)")
        }
    }
    
    public func forceLocalStoreAndDisableiCloud() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setBool(false, forKey: Setting_iCloudEnabled)
        userDefaults.synchronize()
        
        self.switchStoreToLocal()
    }
    
    // MARK: Data Migration
    
    public func migrateLocalStoreToCloud() {
        /*if !UIApplication.sharedApplication().isIgnoringInteractionEvents() {
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        }*/
        
        self.switchStoreToLocal()
        
        PrayerDevotionCloudStore.sharedInstance.performBlockAndWait {
            self.delegate?.prepareForMigration?(true)
            
            let coordinator = self.persistentStoreCoordinator!
            let store = coordinator.persistentStores.first!
            let cloudStoreOptions = self.storeOptionsiCloud
            
            do {
                try coordinator.migratePersistentStore(store, toURL: self.storeURLiCloud, options: cloudStoreOptions, withType: NSSQLiteStoreType)
                
                self.switchStoreToiCloud()
                
                self.currentState = .ReadyToLoadStore
                
                let tokenString = NSKeyedArchiver.archivedDataWithRootObject(self.ubiquityIdentifyToken!).base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
                let Setting_MigrationToCloudPerformed = String(format: Setting_MigrationToCloudPerformedBase, tokenString)
                
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: Setting_MigrationToCloudPerformed)
                NSUserDefaults.standardUserDefaults().synchronize()
            } catch let error as NSError {
                print("Error migrating local store to iCloud with code \(error.code): \(error), \(error.localizedDescription)")
                
                self.forceLocalStoreAndDisableiCloud()
                
                self.currentState = .ReadyToLoadStore
                
                dispatch_async(dispatch_get_main_queue(), {
                    let alertView = UIAlertController(title: "iCloud Migration Failed", message: "Migration of the data to iCloud failed. iCloud will be disabled and the local data will be used. To attempt to switch back to iCloud go to PrayerDevotion Settings and flip the \"iCloud Enabled\" switch to the on position.", preferredStyle: .Alert)
                    let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                    alertView.addAction(okAction)
                    
                    alertView.present()
                    
                    /*if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                        UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    }*/
                })
            }
            
            self.requestLoadDataStore()
        }
    }
    
    public func migrateCloudStoreToLocal(overwrite: Bool) {
        /*if !UIApplication.sharedApplication().isIgnoringInteractionEvents() {
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        }*/
        
        self.switchStoreToiCloud()
        
        PrayerDevotionCloudStore.sharedInstance.performBlockAndWait {
            self.delegate?.prepareForMigration?(false)
            
            if overwrite {
                self.deleteLocalStore()
            }
            
            let coordinator = self.persistentStoreCoordinator!
            let store = coordinator.persistentStores.first!
            
            var localStoreOptions = self.storeOptionsLocal
            localStoreOptions[NSPersistentStoreRemoveUbiquitousMetadataOption] = true
            if overwrite {
                localStoreOptions[NSPersistentStoreRebuildFromUbiquitousContentOption] = true
            }
            
            do {
                try coordinator.migratePersistentStore(store, toURL: self.storeURLLocal, options: localStoreOptions, withType: NSSQLiteStoreType)
                
                let tokenString = NSKeyedArchiver.archivedDataWithRootObject(self.ubiquityIdentifyToken!).base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
                let Setting_MigrationFromCloudPerformed = String(format: Setting_MigrationFromCloudPerformedBase, tokenString)
                
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: Setting_MigrationFromCloudPerformed)
                NSUserDefaults.standardUserDefaults().synchronize()
            } catch let error as NSError {
                print("Error migrating iCloud store to local with code \(error.code): \(error), \(error.localizedDescription)")
                
                dispatch_async(dispatch_get_main_queue(), {
                    let alertView = UIAlertController(title: "iCloud Migration Failed", message: "Migration of the data to iCloud failed. Local data will be used instead", preferredStyle: .Alert)
                    let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                    alertView.addAction(okAction)
                    
                    alertView.present()
                    
                    /*if UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                        UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    }*/
                })
            }
            
            self.switchStoreToLocal()
            
            self.currentState = .ReadyToLoadStore
            
            self.requestLoadDataStore()
        }
    }
    
    // MARK: Notification Register
    
    public func CoreData_RegisterForNotifications(coordinator: NSPersistentStoreCoordinator) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        notificationCenter.addObserver(self, selector: "CoreData_StoresWillChange:", name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: coordinator)
        
        notificationCenter.addObserver(self, selector: "CoreData_StoresDidChange:", name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: coordinator)
        
        notificationCenter.addObserver(self, selector: "CoreData_StoreDidImportUbiquitousContentChanges:", name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: coordinator)
    }
    
    public func CoreData_UnregisterForNotifications(coordinator: NSPersistentStoreCoordinator) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        notificationCenter.removeObserver(self, name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: coordinator)
        
        notificationCenter.removeObserver(self, name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: coordinator)
        
        notificationCenter.removeObserver(self, name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: coordinator)
    }
    
    // MARK: Notification Handlers
    
    public func iCloudAccountChanged(notification: NSNotification) {
        if accountChanged {
            return
        }
        
        if !NSUserDefaults.standardUserDefaults().boolForKey(Setting_iCloudEnabled) {
            return
        }
        
        self.teardownDeviceList()
        self.setupDeviceList()
        
        let iCloudExistsNow = self.iCloudAvailable()
        
        if iCloudExistsNow {
            accountChanged = true
            
            self.CoreData_StoresWillChange(nil)
            
            /*if !UIApplication.sharedApplication().isIgnoringInteractionEvents() {
                UIApplication.sharedApplication().beginIgnoringInteractionEvents()
            }*/
            
            self.currentState = .Uninitialized
            self.requestFinishLoadingDataStoreRecieved = true
            
            self.requestLoadDataStore()
        }
    }
    
    public func CoreData_StoresWillChange(notification: NSNotification?) {
        if self.currentState == .MigrateCloudDataToLocal || self.currentState == .MigrateLocalDataToCloud {
            return
        }
        
        let context = self.managedObjectContext!
        
        PrayerDevotionCloudStore.sharedInstance.performBlockAndWait {
            self.abandonUndoGroups()
            
            do {
                if context.hasChanges {
                    try context.save()
                }
                
                context.reset()
            } catch let error as NSError {
                print("Error saving data on store change with code \(error.code): \(error), \(error.localizedDescription)")
            }
        }
        
        let willChangeBlock: (() -> Void) = {
            self.delegate?.storeWillChangeNotification()
            
            if !self.accountChanged {
                self.currentState = .ReadyToLoadStore
            }
        }
        
        if NSThread.currentThread().isMainThread {
            willChangeBlock()
        } else {
            dispatch_sync(dispatch_get_main_queue(), willChangeBlock)
        }
    }
    
    public func CoreData_StoresDidChange(notification: NSNotification) {
        if self.currentState == .MigrateCloudDataToLocal || self.currentState == .MigrateLocalDataToCloud {
            return
        }
        
        if !accountChanged {
            self.currentState = .DataStoreOnline
            
            let iCloudPreviouslyExisted = NSUserDefaults.standardUserDefaults().objectForKey(Setting_IdentityToken) != nil
            let iCloudExistsNow = self.iCloudAvailable()
            
            if iCloudPreviouslyExisted && !iCloudExistsNow {
                self.forceLocalStoreAndDisableiCloud()
                // self.managedObjectContext
            }
            
            let didChangeBlock: () -> Void = {
                () -> Void in
                    self.delegate?.storeDidChangeNotification()
            }
            
            if NSThread.currentThread().isMainThread {
                didChangeBlock()
            } else {
                dispatch_sync(dispatch_get_main_queue(), didChangeBlock)
            }
            
            if firstTimeOnline {
                firstTimeOnline = false
                
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "iCloudAccountChanged:", name: NSUbiquityIdentityDidChangeNotification, object: nil)
            }
        }
    }
    
    public func CoreData_StoreDidImportUbiquitousContentChanges(notification: NSNotification) {
        let context = self.managedObjectContext
        
        print("Importing Changes...")
        
        PrayerDevotionCloudStore.sharedInstance.performBlockAndWait {
            self.abandonUndoGroups()
            
            context!.mergeChangesFromContextDidSaveNotification(notification)
            
            let didImportBlock: (() -> Void) = {
                self.delegate?.storeDidImportUbiquitousContentChangesNotification(notification)
            }
            
            if NSThread.currentThread().isMainThread {
                didImportBlock()
            } else {
                dispatch_sync(dispatch_get_main_queue(), didImportBlock)
            }
        }
    }
    
    // MARK: Undo Handling
    
    public func beginUndoGroup() {
        synced(self) {
            self.undoLevel += 1
            self.managedObjectContext!.undoManager?.beginUndoGrouping()
        }
    }
    
    public func endUndoGroup(applyUndo: Bool) {
        synced(self) {
            self.undoLevel -= 1
            self.managedObjectContext!.undoManager?.endUndoGrouping()
            
            if applyUndo {
                self.managedObjectContext!.undoManager?.undoNestedGroup()
            }
        }
    }
    
    public func abandonUndoGroups() {
        synced(self) {
            while self.undoLevel > 0 {
                self.endUndoGroup(false)
            }
        }
    }
}
