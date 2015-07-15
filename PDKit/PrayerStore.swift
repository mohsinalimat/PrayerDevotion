//
//  PrayerStore.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 6/1/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData

// An enum to identify the "Today" Fetch Type easily
public enum PrayerType: Int, Printable {
    case OnDate // This describes a prayer set to a specified date
    case Daily // This describes a daily prayer
    case Weekly // This describes a weekly prayer
    case None // This is used as a placeholder for the prayer type - It is not used in the today tab at all
    
    public var description: String {
        switch self {
        case .OnDate: return "On Date"
        case .Daily: return "Daily"
        case .Weekly: return "Weekly"
        case .None: return "None"
        }
    }
}

public class PrayerStore: BaseStore {
    
    // MARK: Singleton Instance
    // This is the singleton variable for PrayerStore that is
    // used to get an instance to the store
    // Used nested functions to return the instance
    public class var sharedInstance: PrayerStore {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: PrayerStore? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = PrayerStore()
        }
        
        return Static.instance! // Returns an instance of the PrayerStore
    }
    
    // MARK: Prayers
    // MARK: Fetching
    
    // This method will fetch all the prayers in a certain category.
    // It makes it easier than fetching all prayers into memory and then sorting them
    // manually
    public func fetchAllPrayersInCategory(category: PDCategory!, sortDescriptors: [NSSortDescriptor], batchSize: Int = 20) -> NSMutableArray! {
        var fetchRequest = NSFetchRequest(entityName: "Prayer")
        
        let categoryName = category.name
        let matchPredicate = NSPredicate(format: "category ==[c] %@", categoryName)
        fetchRequest.predicate = matchPredicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchBatchSize = batchSize
        
        var error: NSError?
        var fetchedArray: NSArray? = managedContext!.executeFetchRequest(fetchRequest, error: &error)
        
        if let errorMsg = error {
            println("ALERT! Error Occurred fetching prayer data by category! Error: \(errorMsg.localizedDescription)")
            return NSMutableArray()
        }
        
        return fetchedArray!.mutableCopy() as! NSMutableArray
    }
    
    // Returns a tuple of two NSMutableArrays
    public func fetchAndSortPrayersInCategory(category: PDCategory, sortDescriptors: [NSSortDescriptor], batchSize: Int = 20) -> (unanswered: NSMutableArray, answered: NSMutableArray) {
        var unansweredPrayers: NSMutableArray = NSMutableArray()
        var answeredPrayers: NSMutableArray = NSMutableArray()
        let categoryName = category.name
        
        var unansweredRequest = NSFetchRequest(entityName: "Prayer")
        var matchPredicate = NSPredicate(format: "category ==[c] %@ AND answered == %@", categoryName, false)
        unansweredRequest.predicate = matchPredicate
        unansweredRequest.sortDescriptors = sortDescriptors
        unansweredRequest.fetchBatchSize = batchSize
        
        var error: NSError?
        var unansweredFetched: NSArray? = managedContext!.executeFetchRequest(unansweredRequest, error: &error)
        
        if let fetched = unansweredFetched {
            unansweredPrayers = fetched.mutableCopy() as! NSMutableArray
        } else {
            println("ALERT! Error Occurred fetching answered prayer data by category! Error: \(error!.localizedDescription)")
        }
        
        var answeredRequest = NSFetchRequest(entityName: "Prayer")
        matchPredicate = NSPredicate(format: "category ==[c] %@ AND answered == %@", categoryName, true)
        answeredRequest.predicate = matchPredicate
        answeredRequest.sortDescriptors = [NSSortDescriptor(key: "answeredTimestamp", ascending: false)]
        
        var error2: NSError?
        var answeredFetched: NSArray? = managedContext!.executeFetchRequest(answeredRequest, error: &error2)
        
        if let fetched = answeredFetched {
            answeredPrayers = fetched.mutableCopy() as! NSMutableArray
        } else {
            println("ALERT! Error Occurred fetching answered prayer data by category! Error: \(error!.localizedDescription)")
        }
        
        return (unansweredPrayers, answeredPrayers)
    }
    
    // This method will filter prayers for searching through database
    public func filterPrayers(searchText text: String!, sortDescriptors sortDesc: [NSSortDescriptor], batchSize size: Int = 20) -> NSMutableArray! {
        var fetchRequest = NSFetchRequest(entityName: "Prayer")
        
        println("Searching for string \"\(text)\"")
        
        //let matchPredicate = NSPredicate(format: "category == [cd] %@ AND name CONTAINS[cd] %@", categoryName, text)
        let matchPredicate = NSPredicate(format: "name CONTAINS[cd] %@", text)
        fetchRequest.predicate = matchPredicate
        fetchRequest.sortDescriptors = sortDesc
        fetchRequest.fetchBatchSize = size
        
        var error: NSError?
        var fetchedArray: NSArray? = managedContext!.executeFetchRequest(fetchRequest, error: &error)
        
        if let errorMsg = error {
            println("ALERT! Error Occurred fetching prayer data by category (filtered)! Error: \(errorMsg.userInfo), \(errorMsg.localizedDescription)")
            return NSMutableArray()
        }
        
        return fetchedArray!.mutableCopy() as! NSMutableArray
    }
    
    // Fetches the "Today" Prayers from the database
    public func fetchTodayPrayers(todayFetchType: PrayerType) -> [PDPrayer]! {
        var fetchRequest = NSFetchRequest(entityName: "Prayer")
        let today = NSDate()
        let dateFormatter = NSDateFormatter()
        
        switch todayFetchType {
        case .OnDate:
            var dateComponents = NSCalendar.currentCalendar().components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: NSDate())
            var today = NSDateComponents()
            today.day = 1
            
            let lastMidnight: NSDate = NSCalendar.currentCalendar().dateFromComponents(dateComponents)!
            let thisMidnight = NSCalendar.currentCalendar().dateByAddingComponents(today, toDate: lastMidnight, options: nil)!
            
            fetchRequest.predicate = NSPredicate(format: "prayerType == %@ AND isDateAdded == %@ AND ((addedDate >= %@) AND (addedDate <= %@))", "On Date", true, lastMidnight, thisMidnight)
            
        case .Daily:
            fetchRequest.predicate = NSPredicate(format: "prayerType == %@ AND isDateAdded == %@", "Daily", true)
            
        case .Weekly:
            dateFormatter.dateFormat = "EEEE"
            fetchRequest.predicate = NSPredicate(format: "prayerType == %@ AND isDateAdded == %@ AND weekday == %@", "Weekly", true, dateFormatter.stringFromDate(NSDate()))
            
            break
            
        default:
            break
        }
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false), NSSortDescriptor(key: "name", ascending: true)]
        
        var error: NSError?
        var results = managedContext!.executeFetchRequest(fetchRequest, error: &error) as! [PDPrayer]?
        
        if let fetchError = error {
            println("An error occurred while fetching today prayers: \(fetchError), \(fetchError.userInfo)")
            return [PDPrayer]()
        }
        
        return results!
    }
    
    // Returns the prayer count for a specified category
    public func prayerCountForCategory(category: PDCategory!) -> Int {
        var fetchRequest = NSFetchRequest(entityName: "Prayer")
        fetchRequest.resultType = .CountResultType
        fetchRequest.predicate = NSPredicate(format: "category == %@", category.name)
        
        var error: NSError?
        let result = managedContext!.executeFetchRequest(fetchRequest, error: &error) as! [NSNumber]?
        
        if let countArray = result {
            return countArray[0].integerValue
        } else {
            println("Error occurred while fetching prayer count! \(error), \(error!.userInfo)")
            return 0
        }
    }
    
    // Delete a prayer from the database
    public func deletePrayer(prayer: PDPrayer!, inCategory category: PDCategory!) {
        println("Deleting prayer")
        
        for alert in prayer.alerts {
            let currentAlert = alert as! PDAlert
            Notifications.sharedNotifications.deleteLocalNotification(currentAlert.notificationID)
        }
        
        managedContext!.deleteObject(prayer)
        category.prayerCount -= 1
        
        // This is the method for an "order" - may use in the future
        /*if prayers.count > 0 {
        for oldPrayer in prayers {
        (oldPrayer as! Prayer).order - 1.0 != 0.0 ? (oldPrayer as! Prayer).order -= 1 : println("Can't make order 0.0 for prayer!")
        
        println("Prayer with name \((oldPrayer as! Prayer).shortName) changed order to new order \((oldPrayer as! Prayer).order)")
        }
        }*/
        
        saveDatabase()
    }
    
    // MARK: Adding Prayers
    
    // Add a prayer to the database
    public func addPrayerToDatabase(name: String!, details: String, category: PDCategory!, dateCreated: NSDate) {
        var prayer = NSEntityDescription.insertNewObjectForEntityForName("Prayer", inManagedObjectContext: managedContext!) as! PDPrayer
        
        // This is the method for an "order" - may use in the future
        /*var order = 1.0
        
        if prayers.count > 0 {
        for prayer in prayers {
        (prayer as! Prayer).order += 1.0
        
        println("Prayer with name \((prayer as! Prayer).shortName) changed order to new order \((prayer as! Prayer).order)")
        }
        
        order = 1.0
        }*/
        
        prayer.name = name
        prayer.details = details
        prayer.creationDate = dateCreated
        prayer.category = category.name
        prayer.answeredNotes = ""
        prayer.isDateAdded = false
        prayer.prayerType = "None"
        prayer.answeredTimestamp = NSDate()
        prayer.answered = false
        prayer.priority = 0
        
        prayer.alerts = NSOrderedSet()
        
        println("Category prayer count before update is: \(category.prayerCount)")
        category.prayerCount += 1
        println("Category prayer count after update is: \(category.prayerCount)")
        
        saveDatabase()
    }
    
    // MARK: Prayer Dates
    
    public func addDateToPrayer(prayer: PDPrayer!, prayerType: String, date: NSDate?, weekday: String?) {
        prayer.prayerType = prayerType
        
        if prayerType == "On Date" {
            if let prayerDate = date {
                prayer.addedDate = prayerDate
            } else {
                prayer.addedDate = NSDate()
            }
        } else {
            prayer.addedDate = nil
        }
        
        if prayerType == "Weekly" {
            if let prayerWeekday = weekday {
                prayer.weekday = weekday
            } else {
                prayer.weekday = "Sunday"
            }
        } else {
            prayer.weekday = nil
        }
        
        prayer.isDateAdded = true
        
        saveDatabase()
    }
    
    public func removeDateFromPrayer(prayer: PDPrayer!) {
        prayer.addedDate = nil
        prayer.prayerType = "None"
        prayer.weekday = nil
        prayer.isDateAdded = false
        
        saveDatabase()
    }
    
    public func prayerType(prayer: PDPrayer!) -> PrayerType {
        if prayer.prayerType == "On Date" { return .OnDate }
        if prayer.prayerType == "Daily" { return .Daily }
        if prayer.prayerType == "Weekly" { return .Weekly }
        
        return .None
    }
    
    public func stringToPrayerType(string: String) -> PrayerType {
        if string == "On Date" { return .OnDate }
        if string == "Daily" { return .Daily }
        if string == "Weekly" { return .Weekly }
        return .None
    }
    
    // MARK: Helper Methods
    
    // Returns the number of prayers that is in a specified Category
    public func numberOfPrayersInCategory(category: PDCategory!) -> Int {
        var count = 0;
        
        count = Int(category.prayerCount)
        
        return count
    }
    
}
