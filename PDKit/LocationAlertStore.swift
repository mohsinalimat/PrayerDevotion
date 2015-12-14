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
    
    private let locationManager = CLLocationManager()
    
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
        
        reloadAndMonitorAlerts()
        
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
    
    // MARK: Monitoring
    
    public func reloadAndMonitorAlerts() {
        let currentLocation = locationManager.location
        
        if currentLocation != nil {
            let fetchReqest = NSFetchRequest(entityName: "LocationAlert")
            
            /*let coord = currentLocation.coordinate
            let radius = 100.0
            let earthRadius = 6371009.0
            let meanLat = coord.latitude * M_PI / 180
            let deltaLat = radius / earthRadius * 180 / M_PI
            let deltaLong = radius / (earthRadius * cos(meanLat)) * 180 / M_PI
            let minLong = coord.latitude - deltaLong
            let maxLong = coord.latitude + deltaLong
            let minLat = coord.longitude - deltaLat
            let maxLat = coord.longitude + deltaLat
            
            fetchReqest.predicate = NSPredicate(format: "latitude >= %d AND latitude <= %d AND longitude >= %d AND longitude <= %d", minLat, maxLat, minLong, maxLong)*/
            fetchReqest.fetchLimit = 20
            
            stopMonitoringCurrentLocations()
            
            do {
                let regionsToMonitor = try managedContext!.executeFetchRequest(fetchReqest) as! [PDLocationAlert]
                
                let maxRadius: CLLocationDistance = 50
                let regions = regionsToMonitor.filter() {
                    //let coordinate = CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                    let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude), altitude: 1, horizontalAccuracy: 1, verticalAccuracy: -1, timestamp: NSDate())
                    //print("Current Location: Lat - \(currentLocation!.coordinate.latitude); Long - \(currentLocation!.coordinate.longitude)")
                    //print("Fetched Location: Lat - \($0.latitude); Long - \($0.longitude)")
                    //print("Convert Location: Lat - \(location.coordinate.latitude); Long - \(location.coordinate.longitude)")
                    let distance: CLLocationDistance = location.distanceFromLocation(currentLocation!)
                    //print("Distance: \(distance)")
                    return distance <= maxRadius
                }
                
                var i = 1
                for region in regions {
                    if i <= regionsToMonitor.count {
                        let monitorRegion = CLCircularRegion(center: region.coordinate, radius: region.radius, identifier: region.identifier)
                        monitorRegion.notifyOnEntry = region.onEnter
                        monitorRegion.notifyOnExit = !region.onEnter
                    
                        locationManager.startMonitoringForRegion(monitorRegion)
                        i++
                    } else {
                        break
                    }
                }
                //print("NumLocations: \(locationManager.monitoredRegions)")
            } catch let error as NSError {
                print("There was an error reloading location alerts: \(error), \(error.localizedDescription)")
            }
        }
    }
    
    //private func haversine
    
    private func stopMonitoringCurrentLocations() {
        let regions = locationManager.monitoredRegions
        
        for region in regions {
            locationManager.stopMonitoringForRegion(region)
        }
    }
}
