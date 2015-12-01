//
//  LocationAlertStore.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 11/29/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

public class LocationAlertStore: BaseStore {
    
    
    // MARK: Singleton Instance
    // This is the singleton variable for LocationAlertStore that is
    // used to get an instance to the store
    // Used nested functions to return the instance
    public class var sharedInstance: LocationAlertStore {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: LocationAlertStore? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = LocationAlertStore()
        }
        
        return Static.instance! // Returns an instance of the LocationAlertStore
    }
    
    // MARK: Location Alerts
    // These methods create location alerts
    
    public func createLocation(latitude: Double, longitude: Double, radius: Double, name: String, locationID: String, onEnter: Bool) -> PDLocationAlert {
        let locationAlert = NSEntityDescription.insertNewObjectForEntityForName("LocationAlert", inManagedObjectContext: managedContext!) as! PDLocationAlert
        
        locationAlert.locationName = name
        locationAlert.locationID = locationID
        locationAlert.longitude = longitude
        locationAlert.latitude = latitude
        locationAlert.radius = radius
        locationAlert.onEnter = onEnter
        
        saveDatabase()
        
        return locationAlert
    }
    
    // Default radius = 25
    public func createLocationWithDefaultRadius(latitude: Double, longitude: Double, name: String, locationID: String, onEnter: Bool) -> PDLocationAlert {
        let locationAlert = NSEntityDescription.insertNewObjectForEntityForName("LocationAlert", inManagedObjectContext: managedContext!) as! PDLocationAlert
        
        locationAlert.locationName = name
        locationAlert.locationID = locationID
        locationAlert.longitude = longitude
        locationAlert.latitude = latitude
        locationAlert.radius = 25
        locationAlert.onEnter = onEnter
    
        locationAlert.identifier = NSUUID().UUIDString
        while true {
            if fetchLocationAlertForIdentifier(locationAlert.identifier) != nil {
                locationAlert.identifier = NSUUID().UUIDString
                continue
            } else {
                break
            }
        }
        
        saveDatabase()
        
        return locationAlert
    }
    
    public func deleteLocationAlert(locationAlert: PDLocationAlert) {
        locationAlert.prayer.locationAlert = nil
        
        managedContext!.deleteObject(locationAlert)
        
        saveDatabase()
    }
    
    public func fetchLocationAlertForID(locationID: String) -> PDLocationAlert? {
        let fetchRequest = NSFetchRequest(entityName: "LocationAlert")
        fetchRequest.predicate = NSPredicate(format: "locationID == %@", locationID)
        fetchRequest.fetchLimit = 1
        
        do {
            let fetchedResults = try managedContext!.executeFetchRequest(fetchRequest) as! [PDLocationAlert]
            return fetchedResults.first
        } catch let error as NSError {
            print("An error occurred while fetching location for ID \(locationID): \(error), \(error.localizedDescription)")
            return nil
        }
    }
    
    public func fetchLocationAlertForIdentifier(identifier: String) -> PDLocationAlert? {
        let fetchRequest = NSFetchRequest(entityName: "LocationAlert")
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
        fetchRequest.fetchLimit = 1
        
        do {
            let fetchedResults = try managedContext!.executeFetchRequest(fetchRequest) as! [PDLocationAlert]
            return fetchedResults.first
        } catch let error as NSError {
            print("An error occurred while fetching location for identifier \(identifier): \(error), \(error.localizedDescription)")
            return nil
        }
    }
}
