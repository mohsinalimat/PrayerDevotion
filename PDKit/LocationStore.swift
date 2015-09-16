//
//  LocationStore.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 8/5/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

public class LocationStore: BaseStore {
    
    private var allLocations: [PDLocation] = [PDLocation]()
    
    // MARK: Singleton Instance
    // This is the singleton variable for LocationStore that is
    // used to get an instance to the store
    // Used nested functions to return the instance
    public class var sharedInstance: LocationStore {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: LocationStore? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = LocationStore()
        }
        
        return Static.instance! // Returns an instance of the PrayerStore
    }
    
    // MARK: Locations
    // These methods create locations
    
    public func createLocation(latitude: Double, longitude: Double, name: String, locationID: String) -> PDLocation {
        let location = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: managedContext!) as! PDLocation
        
        location.locationName = name
        location.locationID = locationID
        location.longitude = longitude
        location.latitude = latitude
        
        location.prayers = NSSet()
        
        saveDatabase()
        
        return location
    }
    
    public func deleteLocation(location: PDLocation) {
        for prayer in location.prayers {
            let currentPrayer = prayer as! PDPrayer
            currentPrayer.location = nil
        }
        
        allLocations.removeObject(location)
        managedContext!.deleteObject(location)
        
        saveDatabase()
    }
    
    public func locations() -> [PDLocation] {
        return allLocations
    }
    
    public func fetchLocations() {
        let fetchRequest = NSFetchRequest(entityName: "Location")
        
        let error: NSError? = nil
        let fetchedResults = try! managedContext!.executeFetchRequest(fetchRequest) as? [PDLocation]
        
        if let fetchError = error {
            print("An error occurred while fetching all locations: \(fetchError), \(fetchError.localizedDescription)")
            return
        }
        
        allLocations = fetchedResults!
    }
    
    public func checkLocationCountForDeletion(location: PDLocation) {
        if location.prayers.count == 0 {
            print("Location Prayer Count has dropped to 0. Deleting location...")
            
            managedContext!.deleteObject(location)
            saveDatabase()
            
            fetchLocations()
        } else {
            print("Location Prayer Count is greater than 0. Keeping.")
        }
    }
    
    // MARK: Location-Return Methods
    
    public func locationExists(forID: String) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "Location")
        fetchRequest.resultType = .CountResultType
        fetchRequest.predicate = NSPredicate(format: "locationID == %@", forID)
        
        print("Looking up location with ID: \(forID)")
        
        let error: NSError? = nil
        var fetchResults = try! managedContext!.executeFetchRequest(fetchRequest) as? [NSNumber]
        
        if let fetchError = error {
            print("An error occurred while looking up location with ID \(forID): \(fetchError), \(fetchError.localizedDescription)")
            return false
        }
        
        print("Fetch results count == \(fetchResults![0].integerValue)")
        return fetchResults![0].integerValue > 0
    }
    
    public func getLocationForID(locationID: String) -> PDLocation? {
        let fetchRequest = NSFetchRequest(entityName: "Location")
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "locationID == %@", locationID)
        
        let error: NSError? = nil
        let fetchResults = try! managedContext!.executeFetchRequest(fetchRequest) as? [PDLocation]
        
        if let fetchError = error {
            print("An error occurred while fetching prayer for ID \(locationID): \(fetchError), \(fetchError.localizedDescription)")
        }
        
        if let results = fetchResults {
            return results.first
        }
        
        return nil
    }
    
    // MARK: Counting Methods
    
    public func locationCount() -> Int {
        let fetchRequest = NSFetchRequest(entityName: "Location")
        fetchRequest.resultType = .CountResultType
        
        let error: NSError? = nil
        var fetchResults = try! managedContext!.executeFetchRequest(fetchRequest) as? [NSNumber]
        
        if let fetchError = error {
            print("An error occurred while fetching location count: \(fetchError), \(fetchError.localizedDescription)")
            return 0
        }
        
        return fetchResults![0].integerValue
    }
    
    public func locationPrayersCount(forLocation: PDLocation) -> Int {
        return forLocation.prayers.count
    }
}