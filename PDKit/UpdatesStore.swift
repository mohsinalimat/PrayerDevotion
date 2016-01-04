//
//  UpdatesStore.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 10/14/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

public class UpdatesStore: BaseStore {
    
    
    // MARK: Singleton Instance
    // This is the singleton variable for LocationStore that is
    // used to get an instance to the store
    // Used nested functions to return the instance
    public static var sharedInstance: UpdatesStore {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: UpdatesStore? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = UpdatesStore()
        }
        
        return Static.instance! // Returns an instance of the UpdatesStore
    }
    
    // MARK: Updates
    
    // Add Prayer Update to Core Data
    public func addUpdateToPrayer(update: String, toPrayer: PDPrayer, timestamp: NSDate = NSDate()) -> PDUpdate {
        let prayerUpdates = toPrayer.updates
        let mutableUpdates = prayerUpdates.mutableCopy() as! NSMutableOrderedSet
        
        let prayerUpdate = NSEntityDescription.insertNewObjectForEntityForName("Updates", inManagedObjectContext: managedContext!) as! PDUpdate
        prayerUpdate.update = update
        prayerUpdate.timestamp = timestamp
        
        prayerUpdate.prayer = toPrayer
        
        mutableUpdates.addObject(prayerUpdate)
        mutableUpdates.sortUsingDescriptors([NSSortDescriptor(key: "timestamp", ascending: true)])
        toPrayer.updates = mutableUpdates.copy() as! NSOrderedSet
        
        saveDatabase()
        
        return prayerUpdate
    }
    
    public func deleteUpdate(update: PDUpdate) {
        var prayerUpdates = update.prayer.updates
        let mutableUpdates = prayerUpdates.mutableCopy() as! NSMutableOrderedSet
        
        mutableUpdates.removeObject(update)
        mutableUpdates.sortUsingDescriptors([NSSortDescriptor(key: "timestamp", ascending: true)])
        prayerUpdates = mutableUpdates.copy() as! NSOrderedSet
        
        managedContext!.deleteObject(update)
        
        saveDatabase()
    }
    
    // Fetch all prayer updates
    public func fetchPrayerUpdatesForPrayerID(prayerID: Int32) -> NSOrderedSet {
        let fetchRequest = NSFetchRequest(entityName: "Prayer")
        fetchRequest.predicate = NSPredicate(format: "prayerID == %d", prayerID)
        fetchRequest.fetchLimit = 1
        
        do {
            let fetchedResults = try managedContext!.executeFetchRequest(fetchRequest) as! [PDPrayer]
            
            return fetchedResults[0].updates
        } catch let error as NSError {
            print("Error occurred while fetching prayer updates: \(error), \(error.localizedDescription)")
            
            return NSOrderedSet()
        }
    }
    
    public func fetchedPrayerUpdatesForPrayerID(prayerID: Int32) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: "Updates")
        fetchRequest.predicate = NSPredicate(format: "prayer.prayerID == %d", prayerID)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext!, sectionNameKeyPath: "day", cacheName: nil)
        
        return frc
    }
    
    public func getUpdateCountForPrayerID(prayerID: Int32) -> Int {
        let fetchRequest = NSFetchRequest(entityName: "Prayer")
        fetchRequest.predicate = NSPredicate(format: "prayerID == %d", prayerID)
        fetchRequest.fetchLimit = 1
        
        do {
            let fetchedResults = try managedContext!.executeFetchRequest(fetchRequest) as! [PDPrayer]
            
            return fetchedResults[0].updates.count
        } catch let error as NSError {
            print("An error occurred while fetching prayer updates count: \(error), \(error.localizedDescription)")
            
            return 0
        }
    }
    
    public func getAllUpdates() -> [PDUpdate] {
        let fetchRequest = NSFetchRequest(entityName: "Updates")
        
        do {
            let fetchedResults = try managedContext!.executeFetchRequest(fetchRequest) as! [PDUpdate]
            
            return fetchedResults
        } catch let error as NSError {
            print("An error occurred while fetching all updates: \(error), \(error.localizedDescription)")
            
            return [PDUpdate]()
        }
    }
}