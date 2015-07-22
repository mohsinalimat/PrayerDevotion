//
//  AlertStore.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 6/1/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData

public class AlertStore: BaseStore {
    
    let dateFormatter = NSDateFormatter()
    
    // MARK: Singleton Instance
    // This is the singleton variable for AlertStore that is
    // used to get an instance to the store
    // Used nested functions to return the instance
    public class var sharedInstance: AlertStore {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: AlertStore? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = AlertStore()
        }
        
        return Static.instance! // Returns an instance of the PrayerStore
    }
    
    // MARK: Alerts
    // This methods creates an alert for a specific prayer and stores it in the database
    // The Category is included for now, although it does nothing (yet)
    public func createAlert(prayer: PDPrayer, inCategory category: String, withDate date: NSDate) {
        var alert = NSEntityDescription.insertNewObjectForEntityForName("Alert", inManagedObjectContext: managedContext!) as! PDAlert
        
        alert.alertDate = date
        
        var generatedID: Int = 0
        
        while true {
            generatedID = Int(UInt32(arc4random()) % UInt32(1000))
            
            var fetchRequest = NSFetchRequest(entityName: "Alert")
            fetchRequest.predicate = NSPredicate(format: "notificationID == %d", generatedID)
            fetchRequest.fetchLimit = 1
            
            var error: NSError?
            let result = managedContext!.executeFetchRequest(fetchRequest, error: &error)
            
            if let fetchError = error {
                println("Error: \(fetchError)")
            } else {
                if result!.count > 0 {
                    continue
                } else {
                    break
                }
            }
        }
        
        alert.notificationID = UInt32(generatedID)
        alert.didSchedule = false
        
        var alerts = prayer.alerts.mutableCopy() as! NSMutableOrderedSet
        alerts.addObject(alert)
        
        prayer.alerts = alerts.copy() as! NSOrderedSet
        
        saveDatabase()
    }
    
    public func deleteAlert(alert: PDAlert, inPrayer prayer: PDPrayer) {
        var prayerAlerts = prayer.alerts.mutableCopy() as! NSMutableOrderedSet
        
        Notifications.sharedNotifications.deleteLocalNotification(alert.notificationID)
        
        prayerAlerts.removeObject(alert)
        managedContext!.deleteObject(alert)
        
        prayer.alerts = prayerAlerts.copy() as! NSOrderedSet
        
        saveDatabase()
    }
    
    public func deleteAllAlertsForPrayer(prayer: PDPrayer) {
        var alerts = prayer.alerts.mutableCopy() as! NSMutableOrderedSet
        
        for alert in alerts {
            Notifications.sharedNotifications.deleteLocalNotification(alert.notificationID)
            
            alerts.removeObject(alert)
            managedContext!.deleteObject(alert as! NSManagedObject)
        }
        
        prayer.alerts = NSOrderedSet()
        
        saveDatabase()
    }
    
    // Delete all past alerts
    
    public func deletePastAlerts() {
        var fetchRequest = NSFetchRequest(entityName: "Alert")
        
        var error: NSError?
        var results = managedContext!.executeFetchRequest(fetchRequest, error: &error)
        
        if let fetchedAlerts = results {
            for fetchedAlert in fetchedAlerts {
                let alert = fetchedAlert as! PDAlert
                
                let now = NSDate()
                let alertDate = alert.alertDate
                
                if now.compare(alertDate) == .OrderedDescending && alert.didSchedule {
                    deleteAlert(alert, inPrayer: alert.prayer)
                } else {
                    println("Alert is either in the future or has not been scheduled yet.")
                }
            }
        } else {
            println("Error deleting all past alerts: \(error), \(error!.userInfo)")
        }
    }
    
    // MARK: Helper Methods
    
    // Converts an NSDate to a string with format "September 17, 2003 at 3:00 PM"
    public func convertDateToString(date: NSDate) -> String {
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .NoStyle
        
        let dayString = dateFormatter.stringFromDate(date)
        
        dateFormatter.dateStyle = .NoStyle
        dateFormatter.timeStyle = .ShortStyle
        
        let timeString = dateFormatter.stringFromDate(date)
        
        let dateString = "\(dayString) at \(timeString)"
        return dateString
        
    }
    
    
    // MARK: Unused
    // MARK: Prayer Dates
    
    // This function will search the database for all dates that are related to
    // the specified prayer
    public func allDates(forPrayer: PDPrayer) -> [PDAlert] {
        var fetchReq = NSFetchRequest(entityName: "Dates")
        fetchReq.predicate = NSPredicate(format: "prayer == %@", forPrayer)
        fetchReq.sortDescriptors = nil
        
        var error: NSError?
        let fetchedDates = managedContext!.executeFetchRequest(fetchReq, error: &error) as? [PDAlert]
        
        if let fetchError = error {
            println("An error occurred while fetching data for prayer \(forPrayer)")
            return [PDAlert]()
        }
        
        return fetchedDates!
    }
    
    // This function will insert a data for a specific prayer into the database
    // NOTE: DO NOT USE THIS METHOD!!!!! It uses the value "dates" which I have removed for now - a one-many relationship
    // in the database (may use it later)
    public func insertDate(forPrayer: PDPrayer, date: NSDate) {
        var addedDate: NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("Dates", inManagedObjectContext: managedContext!) as! NSManagedObject
        addedDate.setValue(date, forKey: "date")
        
        addedDate.setValue(forPrayer, forKey: "prayer")
        forPrayer.setValue(addedDate, forKey: "dates")
        
        saveDatabase()
    }
    
}