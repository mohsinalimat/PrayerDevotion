//
//  CoreDataMaintainence.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 12/14/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import PDKit
import CoreData

extension NSArray {
    
    enum DistinctDataType: Int {
        case Prayer
        case Category
        case Alert
        case LocationAlert
        case Location
        case Update
    }
    
    func getDistinctArrayOfUpdates(forType type: DistinctDataType) -> NSArray {
        let tempArray = NSMutableArray()
        
        for item in self {
            switch type {
            case .Update:
                let updateItem = item as! PDUpdate
                var numOfObjectsInArray = 0
                for tempItem in tempArray {
                    if (tempItem as! PDUpdate).timestamp == updateItem.timestamp { numOfObjectsInArray += 1; continue }
                }
                
                if numOfObjectsInArray == 0 { tempArray.addObject(updateItem.timestamp) }
                
            default: break
            }
        }
        
        return tempArray.copy() as! NSArray
    }
    
    func getDistinctArrayOfInts(forType type: DistinctDataType) -> NSArray {
        let tempArray = NSMutableArray()
        
        for item in self {
            switch type {
            case .Prayer:
                let prayerItem = item as! PDPrayer
                var numOfObjectsInArray = 0
                for tempItem in tempArray {
                    let item = tempItem as! Int
                    if Int32(item) == prayerItem.prayerID { numOfObjectsInArray += 1; continue }
                }
                
                if numOfObjectsInArray == 0 { tempArray.addObject(Int(prayerItem.prayerID)) }
                
            case .Alert:
                let alertItem = item as! PDAlert
                var numOfObjectsInArray = 0
                for tempItem in tempArray {
                    let item = tempItem as! Int
                    if UInt32(item) == alertItem.notificationID { numOfObjectsInArray += 1; continue }
                }
                
                if numOfObjectsInArray == 0 { tempArray.addObject(Int(alertItem.notificationID)) }
                
            default: break
            }
        }
        
        return tempArray.copy() as! NSArray
    }
    
    func getDistinctArrayOfStrings(forType type: DistinctDataType) -> NSArray {
        let tempArray = NSMutableArray()
        
        for item in self {
            switch type {
            case .Category:
                let catItem = item as! PDCategory
                var numOfObjectsInArray = 0
                for tempItem in tempArray {
                    if (tempItem as! PDCategory).name == catItem.name { numOfObjectsInArray += 1; continue }
                }
                
                if numOfObjectsInArray == 0 { tempArray.addObject(catItem.name) }
                
            case .Location:
                let locItem = item as! PDLocation
                var numOfObjectsInArray = 0
                for tempItem in tempArray {
                    if (tempItem as! PDLocation).locationID == locItem.locationID { numOfObjectsInArray += 1; continue }
                }
                
                if numOfObjectsInArray == 0 { tempArray.addObject(locItem.locationID) }
                
            case .LocationAlert:
                let locAlertItem = item as! PDLocationAlert
                var numOfObjectsInArray = 0
                for tempItem in tempArray {
                    if (tempItem as! PDLocationAlert).identifier == locAlertItem.identifier { numOfObjectsInArray += 1; continue }
                }
                
                if numOfObjectsInArray == 0 { tempArray.addObject(locAlertItem) }
                
            default: break
            }
        }
        
        return tempArray.copy() as! NSArray
    }
}

class CoreDataMaintainance: NSObject {
    
    class func performDataDeduplication() {
        let startDate = NSDate()
        
        print("De-duplicating data...")
        
        let context = PrayerDevotionCloudStore.sharedInstance.managedObjectContext!
        context.performBlockAndWait {
            if context.undoManager != nil {
                context.undoManager!.disableUndoRegistration()
            }
            
            self.deduplicateObject("prayers", sortDescriptors: [NSSortDescriptor(key: "dateCreated", ascending: true)])
            self.deduplicateObject("categories", sortDescriptors: [NSSortDescriptor(key: "dateCreated", ascending: true)])
            self.deduplicateObject("alerts", sortDescriptors: [NSSortDescriptor(key: "alertDate", ascending: true)])
            self.deduplicateObject("location_alert", sortDescriptors: nil)
            self.deduplicateObject("location", sortDescriptors: nil)
            self.deduplicateObject("update", sortDescriptors: [NSSortDescriptor(key: "timestamp", ascending: true)])
            
            PrayerDevotionCloudStore.sharedInstance.saveContext()
            
            if context.undoManager != nil {
                context.undoManager!.enableUndoRegistration()
            }
        }
        
        let endDate = NSDate()
        print("Deduplication took \(endDate.timeIntervalSinceDate(startDate)) seconds")
    }
    
    private class func deduplicateObject(type: String, sortDescriptors sortDesc: [NSSortDescriptor]?) {
        let purgeArray = NSMutableArray()
        let allObjects: NSArray = getAllObjectsForType(type)
        
        var ids: NSArray!

        switch type {
            case "prayer", "prayers":
                ids = allObjects.getDistinctArrayOfInts(forType: .Prayer)
            case "category", "categories": ids = allObjects.getDistinctArrayOfStrings(forType: .Category)
            case "alert", "alerts": ids = allObjects.getDistinctArrayOfInts(forType: .Alert)
            case "alert_location", "location_alert", "locationalert": ids = allObjects.getDistinctArrayOfStrings(forType: .LocationAlert)
            case "location", "locations": ids = allObjects.getDistinctArrayOfStrings(forType: .Location)
            case "update", "updates": ids = allObjects.getDistinctArrayOfUpdates(forType: .Update)
            default: ids = NSArray()
        }
        
        print("\n\n")
        for object in allObjects {
            switch type {
            case "prayer", "prayers": print("Prayer Name: \((object as! PDPrayer).name)\nPrayer ID: \((object as! PDPrayer).prayerID)\n")
            case "category", "categories": print("Category Name: \((object as! PDCategory).name)\n")
            case "alert", "alerts": print("Alert ID: \((object as! PDAlert).notificationID)\n")
            case "alert_location", "location_alert", "locationalert": print("Alert Coordinate: \((object as! PDLocationAlert).coordinate)\nAlert Location ID: \((object as! PDLocationAlert).identifier)\n")
            case "location", "locations": print("Location Name: \((object as! PDLocation).locationName)\nLocation ID: \((object as! PDLocation).locationID)\n")
            case "update", "updates": print("Update Timestamp: \((object as! PDUpdate).timestamp)\n")
            default: break
            }
        }
        
        print("\n\n")
        for (index, element) in ids.enumerate() {
            print("ID #\(index): \(element)")
        }
        print("\n\n")
        
        if allObjects.count == ids.count { return } // Nothing to do here... no duplicates
        
        for id in ids {
            var predicate: NSPredicate!
            switch type {
                case "prayer", "prayers": predicate = NSPredicate(format: "prayerID = %d", (id as! Int))
                case "category", "categories": predicate = NSPredicate(format: "name = %@", (id as! String))
                case "alert", "alerts": predicate = NSPredicate(format: "notificationID = %d", (id as! Int))
                case "alert_location", "location_alert", "locationalert": predicate = NSPredicate(format: "identifier = %@", (id as! String))
                case "location", "locations": predicate = NSPredicate(format: "locationID = %@", (id as! String))
                case "update", "updates": predicate = NSPredicate(format: "timestamp = %@", (id as! NSDate))
                default: break
            }
            
            let filteredObjects = sortDesc != nil ? allObjects.filteredArrayUsingPredicate(predicate!) : allObjects
            let primeObject = filteredObjects.firstObject!
            
            for object in filteredObjects {
                let bool = checkAndRemapItems(type, withObject: object, toPrimeObj: primeObject)
                if bool {
                    purgeArray.addObject(object)
                }
            }
            
        }
        
        if purgeArray.count > 0 {
            for object in purgeArray {
                PrayerDevotionCloudStore.sharedInstance.managedObjectContext!.deleteObject(object as! NSManagedObject)
            }
        }
        
    }
    
    private class func getAllObjectsForType(type: String) -> NSArray {
        let newType = type.lowercaseString
        switch newType {
            case "prayer", "prayers": return NSArray(array: PrayerStore.sharedInstance.getAllPrayers())
            case "category", "categories": return NSArray(array: CategoryStore.sharedInstance.allCategories())
            case "alert", "alerts": return NSArray(array: AlertStore.sharedInstance.getAllAlerts())
            case "alert_location", "location_alert", "locationalert": return NSArray(array: LocationAlertStore.sharedInstance.getAllLocationAlerts())
            case "location", "locations": return NSArray(array: LocationStore.sharedInstance.getAllLocations())
            case "update", "updates": return NSArray(array: UpdatesStore.sharedInstance.getAllUpdates())
            default: return NSArray()
        }
    }
    
    private class func getUniqueKey(forType: String) -> String {
        let newType = forType.lowercaseString
        switch newType {
            case "prayer", "prayers": return "prayerID"
            case "category", "categories": return "name"
            case "alert", "alerts": return "notificationID"
            case "alert_location", "location_alert", "locationalert": return "identifier"
            case "location", "locations": return "locationID"
            case "update", "updates": return "timestamp"
            default: return ""
        }
    }
    
    private class func checkAndRemapItems(forType: String, withObject object: AnyObject, toPrimeObj primeObj: AnyObject) -> Bool {
        let newType = forType.lowercaseString
        switch newType {
        case "prayer", "prayers":
            if (object as! PDPrayer) == (primeObj as! PDPrayer) { return false }
            (object as! PDPrayer).remapUpdates(toPrayer: primeObj as! PDPrayer)
            (object as! PDPrayer).remapAlerts(toPrayer: primeObj as! PDPrayer)
            (object as! PDPrayer).remapLocationAlert(toPrayer: primeObj as! PDPrayer)
        case "category", "categories":
            if (object as! PDCategory) == (primeObj as! PDCategory) { return false }
        case "alert", "alerts":
            if (object as! PDAlert) == (primeObj as! PDAlert) { return false }
        case "alert_location", "location_alert", "locationalert":
            if (object as! PDLocationAlert) == (primeObj as! PDLocationAlert) { return false }
        case "location", "locations":
            if (object as! PDLocation) == (primeObj as! PDLocation) { return false }
            (object as! PDLocation).remapLocations(toLocation: primeObj as! PDLocation)
        case "update", "updates":
            if (object as! PDUpdate) == (primeObj as! PDUpdate) { return false }
        default: break
        }
        
        return true
    }
}
