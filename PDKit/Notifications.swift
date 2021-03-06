//
//  Notifications.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 6/4/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import CoreData

public class Notifications {
    
    var updateTries = 0
    
    // The singleton method to access Notifications functions
    public class var sharedNotifications: Notifications {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: Notifications? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = Notifications()
        }
        
        return Static.instance!
    }
    
    // MARK: Updating Notification Queue
    
    public func updateNotificationQueue() {
        let application = UIApplication.sharedApplication()
        let notificationCount = application.scheduledLocalNotifications!.count
        
        if notificationCount < 64 {
            let countToAdd = 64 - notificationCount
            print("Scheduled Notification Count is less than 0. Scheduled Notification count is: \(notificationCount). Possibly adding up to \(countToAdd) notifications.")
            
            let fetchRequest = NSFetchRequest(entityName: "Alert")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "alertDate", ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "didSchedule == %@", NSNumber(bool: false))
            fetchRequest.fetchLimit = countToAdd
            
            var error: NSError?
            let context = CoreDataStore.sharedInstance.managedObjectContext!
            
            let results: [AnyObject]?
            do {
                results = try context.executeFetchRequest(fetchRequest)
            } catch let error1 as NSError {
                error = error1
                results = nil
            }
            
            if let fetchError = error {
                print("An error occurred while fetching the notifications: \(fetchError), \(fetchError.userInfo)")
                
                if updateTries == 3 {
                    print("Cannot seem to update local notifications. Alert User!")
                    return
                } else {
                    updateTries++
                    updateNotificationQueue()
                    return
                }
            }
            
            if let alerts = results {
                print("There are \(alerts.count) alerts waiting in the database to be scheduled")
                
                for fetchedAlert in alerts {
                    let alert = fetchedAlert as! PDAlert
                    let localNotification = createNotification(alert)
                    application.scheduleLocalNotification(localNotification)
                }
            }
        } else {
            print("Alerts are currently full. Try again later")
        }
        
        print("Completed Adding of notifications")
    }
    
    // MARK: Creating and Fetching Notifications
    
    // Create a notification from an Alert object
    public func createNotification(fromAlert: PDAlert!) -> UILocalNotification {
        let localNotification = UILocalNotification()
        localNotification.fireDate = fromAlert.alertDate
        localNotification.alertBody = fromAlert.prayer.name
        localNotification.soundName = UILocalNotificationDefaultSoundName
        
        var userDict = Dictionary<String, NSNumber>()
        userDict["notificationID"] = Int(fromAlert.notificationID)
        
        localNotification.userInfo = userDict
        
        fromAlert.didSchedule = true
        
        return localNotification
    }
    
    // Search the local notifications for a certain notification based on the Notification ID
    public func getLocalNotification(forNotificationID: UInt32) -> UILocalNotification? {
        let application = UIApplication.sharedApplication()
        
        for notification in application.scheduledLocalNotifications! {
            let localNotification = notification
            var userDict = notification.userInfo! as! [String: Int]
            let notificationID = UInt32(userDict["notificationID"]!)
            
            if notificationID == forNotificationID {
                return localNotification
            }
        }
        
        return nil
    }
    
    public func deleteLocalNotification(forNotificationID: UInt32) {
        let application = UIApplication.sharedApplication()
        
        let notificationToDelete = getLocalNotification(forNotificationID)
        
        if let notification = notificationToDelete {
            application.cancelLocalNotification(notification)
            print("Deleted scheduled notification")
        }
    }
    
}
