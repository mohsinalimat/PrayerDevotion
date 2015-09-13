//
//  PrayerStore.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 6/1/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData
import Swift

// An enum to identify the "Today" Fetch Type easily
public enum PrayerType: Int, Printable {
    case OnDate = 0// This describes a prayer set to a specified date
    case Daily = 1// This describes a daily prayer
    case Weekly = 2 // This describes a weekly prayer
    case None = 3// This is used as a placeholder for the prayer type - It is not used in the today tab at all
    
    public var description: String {
        switch self {
        case .OnDate: return "On Date"
        case .Daily: return "Daily"
        case .Weekly: return "Weekly"
        case .None: return "None"
        }
    }
}

// An extension to the Swift class "Array" that adds NSArray.removeObject-like functionality
extension Array {
    mutating func removeObject<T: Equatable>(object: T) -> Bool {
        for (idx, objectToCompare) in enumerate(self) {
            if let to = objectToCompare as? T {
                if object == to {
                    self.removeAtIndex(idx)
                    return true
                }
            }
        }
        
        return false
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

    // MARK: Prayer Database Fetching
    
    // This method will fetch all the prayers in a certain category.
    // TODO: Delete this method
    @availability(iOS, introduced=8.0, deprecated=8.4, message="Use fetchAndSortPrayersInCategory() instead")
    public func fetchAllPrayersInCategory(category: PDCategory, sortDescriptors: [NSSortDescriptor]) -> [PDPrayer] {
        var fetchRequest = NSFetchRequest(entityName: "Prayer")
        
        let categoryName = category.name
        let matchPredicate = NSPredicate(format: "category ==[c] %@", categoryName)
        fetchRequest.predicate = matchPredicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchBatchSize = 50
        
        var error: NSError?
        var fetchedArray = managedContext!.executeFetchRequest(fetchRequest, error: &error) as? [PDPrayer]
        
        if let errorMsg = error {
            println("ALERT! Error Occurred fetching prayer data by category! Error: \(errorMsg.localizedDescription)")
            return [PDPrayer]()
        }
        
        return fetchedArray!
    }
    
    // This method fetches all answered prayers in all categories
    @availability(iOS, introduced=8.0)
    public func fetchAllAnsweredPrayers(sortDescriptors: [NSSortDescriptor]) -> [PDPrayer] {
        var fetchRequest = NSFetchRequest(entityName: "Prayer")
        fetchRequest.predicate = NSPredicate(format: "answered == %@", true)
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchBatchSize = 50
        
        var error: NSError? = nil
        var fetchedArray = managedContext!.executeFetchRequest(fetchRequest, error: &error) as? [PDPrayer]
        
        if let errorMsg = error {
            println("ALERT! Error Occurred fetching answered prayer data! Error: \(errorMsg.localizedDescription)")
            return [PDPrayer]()
        }
        
        return fetchedArray!
    }
    
    // Returns a tuple of two NSMutableArrays
    // Used when loading both unanswered and answered prayers
    @availability(iOS, introduced=8.0)
    public func fetchAndSortPrayersInCategory(category: PDCategory?, sortDescriptors: [NSSortDescriptor], batchSize: Int = 20, isAllPrayers: Bool) -> (unanswered: [PDPrayer], answered: [PDPrayer]) {
        var unansweredPrayers = [PDPrayer]()
        var answeredPrayers = [PDPrayer]()
        let categoryName = category?.name
        
        var unansweredRequest = NSFetchRequest(entityName: "Prayer")
        var matchPredicate = isAllPrayers == true ? NSPredicate(format: "answered == %@", false) : NSPredicate(format: "category ==[c] %@ AND answered == %@", categoryName!, false)
        unansweredRequest.predicate = matchPredicate
        unansweredRequest.sortDescriptors = sortDescriptors
        unansweredRequest.fetchBatchSize = batchSize
        
        var error: NSError?
        var unansweredFetched = managedContext!.executeFetchRequest(unansweredRequest, error: &error) as? [PDPrayer]
        
        if let fetched = unansweredFetched {
            unansweredPrayers = fetched
        } else {
            println("ALERT! Error Occurred fetching answered prayer data by category! Error: \(error!.localizedDescription)")
        }
        
        var answeredRequest = NSFetchRequest(entityName: "Prayer")
        matchPredicate = isAllPrayers == true ? NSPredicate(format: "answered == %@", true) : NSPredicate(format: "category ==[c] %@ AND answered == %@", categoryName!, true)
        answeredRequest.predicate = matchPredicate
        answeredRequest.sortDescriptors = [NSSortDescriptor(key: "answeredTimestamp", ascending: false)]
        
        var error2: NSError?
        var answeredFetched = managedContext!.executeFetchRequest(answeredRequest, error: &error2) as? [PDPrayer]
        
        if let fetched = answeredFetched {
            answeredPrayers = fetched
        } else {
            println("ALERT! Error Occurred fetching answered prayer data by category! Error: \(error!.localizedDescription)")
        }
        
        return (unansweredPrayers, answeredPrayers)
    }
    
    // Get all prayers for a certain location ID
    @availability(iOS, introduced=8.4)
    public func fetchPrayersForLocationID(locationID: String) -> [PDPrayer] {
        var fetchRequest = NSFetchRequest(entityName: "Prayer")
        fetchRequest.predicate = NSPredicate(format: "location.locationID == %@", locationID)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fetchRequest.fetchBatchSize = 50
        
        var error: NSError? = nil
        var fetchResults = managedContext!.executeFetchRequest(fetchRequest, error: &error) as? [PDPrayer]
        
        if let fetchError = error {
            println("An error occurred while fetching prayers for location with ID \(locationID): \(fetchError), \(fetchError.localizedDescription)")
            return [PDPrayer]()
        }
        
        return fetchResults!
    }
    
    // This fetchs all prayers on a certain date for the specified PrayerType
    @availability(iOS, introduced=8.0)
    public func fetchPrayersOnDate(todayFetchType: PrayerType, prayerDate: NSDate) -> [PDPrayer] {
        var fetchRequest = NSFetchRequest(entityName: "Prayer")
        let dateFormatter = NSDateFormatter()
        
        switch todayFetchType {
        case .OnDate:
            var dateComponents = NSCalendar.currentCalendar().components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: prayerDate)
            var thisDay = NSDateComponents()
            thisDay.day = 1
            
            let prevMidnight: NSDate = NSCalendar.currentCalendar().dateFromComponents(dateComponents)!
            let nextMidnight: NSDate = NSCalendar.currentCalendar().dateByAddingComponents(thisDay, toDate: prevMidnight, options: nil)!
            
            fetchRequest.predicate = NSPredicate(format: "prayerType == %@ AND isDateAdded == %@ AND answered == %@ AND ((addedDate >= %@) AND (addedDate <= %@))", "On Date", true, false, prevMidnight, nextMidnight)
            
        case .Daily:
            fetchRequest.predicate = NSPredicate(format: "prayerType == %@ AND isDateAdded == %@ AND answered == %@", "Daily", true, false)
            
        case .Weekly:
            dateFormatter.dateFormat = "EEEE"
            fetchRequest.predicate = NSPredicate(format: "prayerType == %@ AND isDateAdded == %@ AND answered == %@ AND weekday == %@", "Weekly", true, false, dateFormatter.stringFromDate(prayerDate))
            
        default: break
        }
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false), NSSortDescriptor(key: "creationDate", ascending: false)]
        
        var error: NSError? = nil
        var results = managedContext!.executeFetchRequest(fetchRequest, error: &error) as? [PDPrayer]
        
        if let fetchError = error {
            println("An error occured while fetching today prayers: \(fetchError), \(fetchError.userInfo)")
            return [PDPrayer]()
        }
        
        return results!
    }
    
    // Fetches the "Today" Prayers from the database
    // TODO: Delete this method in the future and move functionality to fetchPrayersOnDate()
    // @availability(iOS, introduced=8.0, deprecated=8.4, message="Use fetchPrayersOnDate() instead")
    public func fetchTodayPrayers(todayFetchType: PrayerType, forWidget: Bool) -> [PDPrayer] {
        var fetchRequest = NSFetchRequest(entityName: "Prayer")
        if forWidget { fetchRequest.fetchLimit = 2 }
        
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
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false), NSSortDescriptor(key: "creationDate", ascending: false)]
        
        var error: NSError?
        var results = managedContext!.executeFetchRequest(fetchRequest, error: &error) as! [PDPrayer]?
        
        if let fetchError = error {
            println("An error occurred while fetching today prayers: \(fetchError), \(fetchError.userInfo)")
            return [PDPrayer]()
        }
        
        return results!
    }
    
    // MARK: Prayer Searching
    
    // This method will filter prayers for searching through database
    @availability(iOS, introduced=8.0)
    public func filterPrayers(searchText text: String, sortDescriptors sortDesc: [NSSortDescriptor], batchSize size: Int = 20) -> [PDPrayer] {
        var fetchRequest = NSFetchRequest(entityName: "Prayer")
        
        println("Searching for string \"\(text)\"")
        
        //let matchPredicate = NSPredicate(format: "category == [cd] %@ AND name CONTAINS[cd] %@", categoryName, text)
        let matchPredicate = NSPredicate(format: "name CONTAINS[cd] %@", text)
        fetchRequest.predicate = matchPredicate
        fetchRequest.sortDescriptors = sortDesc
        fetchRequest.fetchBatchSize = size
        
        var error: NSError?
        var fetchedArray = managedContext!.executeFetchRequest(fetchRequest, error: &error) as? [PDPrayer]
        
        if let errorMsg = error {
            println("ALERT! Error Occurred fetching prayer data by category (filtered)! Error: \(errorMsg.userInfo), \(errorMsg.localizedDescription)")
            return [PDPrayer]()
        }
        
        return fetchedArray!
    }
    
    // MARK: Prayer Counts
    
    // Returns the prayer count for a specified category
    @availability(iOS, introduced=8.0)
    public func prayerCountForCategory(category: PDCategory) -> Int {
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
    
    // Returns the count of all answered prayers
    @availability(iOS, introduced=8.0)
    public func answeredPrayerCount() -> Int {
        var fetchRequest = NSFetchRequest(entityName: "Prayer")
        fetchRequest.resultType = .CountResultType
        fetchRequest.predicate = NSPredicate(format: "answered == %@", true)
        
        var error: NSError? = nil
        let result = managedContext!.executeFetchRequest(fetchRequest, error: &error) as? [NSNumber]
        
        if let countArray = result {
            return countArray[0].integerValue
        } else {
            println("Error occurred while fetching answered prayers count! \(error), \(error!.userInfo)")
            return 0
        }
    }
    
    // Returns the count of all prayers that have been added
    @availability(iOS, introduced=8.0)
    public func allPrayersCount() -> Int {
        var fetchRequest = NSFetchRequest(entityName: "Prayer")
        fetchRequest.resultType = .CountResultType
        
        var error: NSError? = nil
        let result = managedContext!.executeFetchRequest(fetchRequest, error: &error) as! [NSNumber]?
        
        if let countArray = result {
            return countArray[0].integerValue
        } else {
            println("Error occurred while fetching all prayers count! \(error), \(error!.userInfo)")
            return 0
        }
    }
    
    // MARK: Deleting Prayers
    
    // Delete a prayer from the database
    @availability(iOS, introduced=8.0)
    public func deletePrayer(prayer: PDPrayer, inCategory category: PDCategory?) {
        println("Deleting prayer")
        
        for alert in prayer.alerts {
            let currentAlert = alert as! PDAlert
            Notifications.sharedNotifications.deleteLocalNotification(currentAlert.notificationID)
        }
        
        if let prayerLocation = prayer.location {
            var mutablePrayers = prayerLocation.prayers.mutableCopy() as! NSMutableSet
            mutablePrayers.removeObject(prayer)
            
            prayerLocation.prayers = mutablePrayers.copy() as! NSSet
            
            BaseStore.baseInstance.saveDatabase()
            LocationStore.sharedInstance.checkLocationCountForDeletion(prayerLocation)
        }
        
        managedContext!.deleteObject(prayer)
        if let currentCategory = category { currentCategory.prayerCount -= 1 }
        
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
    @availability(iOS, introduced=8.0)
    public func addPrayerToDatabase(name: String!, details: String, category: PDCategory, dateCreated: NSDate) -> PDPrayer {
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
        prayer.isDateAdded = true
        prayer.prayerType = "Daily"
        prayer.answeredTimestamp = NSDate()
        prayer.answered = false
        prayer.priority = 0
        
        while true {
            let generatedID = generateID()
            
            let fetchRequest = NSFetchRequest(entityName: "Prayer")
            fetchRequest.predicate = NSPredicate(format: "prayerID == %d", generatedID)
            fetchRequest.fetchLimit = 1
            
            var error: NSError? = nil
            var fetchedResults = managedContext!.executeFetchRequest(fetchRequest, error: &error) as? [PDPrayer]
            
            if let fetchError = error {
                println("An error occurred checking the ID of prayer during creation: \(fetchError), \(fetchError.localizedDescription)")
                continue
            } else {
                if fetchedResults?.count > 0 { continue }
                else {
                    prayer.prayerID = generatedID
                    break
                }
            }
        }
        
        prayer.alerts = NSOrderedSet()
        
        saveDatabase()
        
        return prayer
    }
    
    // MARK: Prayer Dates
    
    // This method adds a date to a prayer
    @availability(iOS, introduced=8.0)
    public func addDateToPrayer(prayer: PDPrayer, prayerType: String, date: NSDate?, weekday: String?) {
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
    
    // This method removes a date from a prayer (used in answered prayers)
    @availability(iOS, introduced=8.0)
    public func removeDateFromPrayer(prayer: PDPrayer) {
        prayer.addedDate = nil
        prayer.prayerType = "None"
        prayer.weekday = nil
        prayer.isDateAdded = false
        
        saveDatabase()
    }
    
    // MARK: Prayer Types
    
    // This method returns the PrayerType of a certain prayer
    @availability(iOS, introduced=8.0)
    public func prayerType(prayer: PDPrayer) -> PrayerType {
        if prayer.prayerType == "On Date" { return .OnDate }
        if prayer.prayerType == "Daily" { return .Daily }
        if prayer.prayerType == "Weekly" { return .Weekly }
        
        return .None
    }
    
    // This method converts a String to PrayerType
    @availability(iOS, introduced=8.0)
    public func stringToPrayerType(string: String) -> PrayerType {
        if string == "On Date" { return .OnDate }
        if string == "Daily" { return .Daily }
        if string == "Weekly" { return .Weekly }
        return .None
    }
    
    // MARK: Prayer Migration Methods

    // This migration method adds Prayer IDs to all prayers when upgrading to PrayerDevotion 2.0
    @availability(iOS, introduced=8.0)
    public func addPrayerIDDuringMigration() -> Bool {
        var fetchReqest = NSFetchRequest(entityName: "Prayer")
        
        var error: NSError? = nil
        let fetchedPrayers = managedContext!.executeFetchRequest(fetchReqest, error: &error) as? [PDPrayer]
        
        if let fetchError = error {
            println("An error occurred fetching prayers for migration")
            return false
        }
        
        for prayer in fetchedPrayers! {
            var id: Int32 = 0
            
            while true {
                let generatedID = generateID()
            
                let newFetchRequest = NSFetchRequest(entityName: "Prayer")
                newFetchRequest.fetchLimit = 1
                newFetchRequest.predicate = NSPredicate(format: "prayerID == %d", generatedID)
            
                let fetchedPrayer = managedContext!.executeFetchRequest(newFetchRequest, error: &error)
            
                if let fetchedError = error {
                    println("Error checking database for prayer with ID \(generatedID)")
                } else if fetchedPrayer!.count > 0 {
                    continue
                } else {
                    id = generatedID
                    prayer.prayerID = generatedID
                    break
                }
            }
            
            println("Prayer ID for prayer \(prayer.name) before save is \(prayer.prayerID)")
            saveDatabase()
            println("Prayer ID for prayer \(prayer.name) after save is \(prayer.prayerID)")
        }
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setBool(true, forKey: "didAddPrayerIDs")
        
        return true
    }
    
    // This migration method adds Daily dates to prayers when upgrading to PrayerDevotion 2.0
    @availability(iOS, introduced=8.0)
    public func addDailyDateToPrayers() -> Bool {
        var fetchRequest = NSFetchRequest(entityName: "Prayer")
        fetchRequest.predicate = NSPredicate(format: "isDateAdded == false")
        
        var error: NSError? = nil
        let fetchedPrayers = managedContext!.executeFetchRequest(fetchRequest, error: &error) as? [PDPrayer]
        
        if let fetchError = error {
            println("An error occurred fetching prayers to add prayer date")
            return false
        }
        
        for prayer in fetchedPrayers! {
            prayer.prayerType = "Daily"
            prayer.isDateAdded = true
        }
        
        saveDatabase()
        
        return true
    }
    
    // MARK: Helper Methods
    
    // Returns the number of prayers that is in a specified Category
    public func numberOfPrayersInCategory(category: PDCategory) -> Int {
        var count = 0;
        
        count = Int(category.prayerCount)
        
        return count
    }
    
    // This method gets a prayer for a certain prayer ID
    @availability(iOS, introduced=8.0)
    public func getPrayerForID(id: Int32) -> PDPrayer? {
        var fetchRequest = NSFetchRequest(entityName: "Prayer")
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "prayerID == %d", id)
        
        var error: NSError? = nil
        let fetchedPrayer = managedContext!.executeFetchRequest(fetchRequest, error: &error) as? [PDPrayer]
        
        if fetchedPrayer?.count == 0 {
            println("Could not find prayer for ID \(id)")
            return nil
        } else if error != nil {
            println("An error occurred while fetching prayer for ID \(id)")
            return nil
        }
        
        return fetchedPrayer![0]
    }
    
    // This method generates a unique identifier for each prayer
    @availability(iOS, introduced=8.0)
    func generateID() -> Int32 {
        var id: UInt32 = arc4random_uniform(UInt32(Int32.max))
        return Int32(id)
    }
    
    // This method loops through all prayers in the database and prints their IDs
    @availability(iOS, introduced=8.0)
    public func checkIDs() {
        var fetchReqest = NSFetchRequest(entityName: "Prayer")
        
        var error: NSError? = nil
        let fetchedPrayers = managedContext!.executeFetchRequest(fetchReqest, error: &error) as? [PDPrayer]
        
        if let fetchError = error {
            println("An error occurred fetching prayers for check")
        }
        
        for prayer in fetchedPrayers! {
            println("Prayer ID for prayer \(prayer.name) is \(prayer.prayerID)")
        }
    }
}
