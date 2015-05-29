//
//  PrayerStore.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 3/4/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class PrayerStore: NSObject, NSFetchedResultsControllerDelegate {
    
    // MARK: -----------------------------------------------------------------------------
    // TODO: THE PRAYERS ARRAY IS CURRENTLY UNUSED DUE TO NSFETCHEDRESULTSCONTROLLER
    // I only want this class to edit the prayers directly
    // If you want to add prayers or delete them, use the functions
    // provided (such as deletePrayer() or addPrayer())
    private var prayers: NSMutableArray = NSMutableArray()
    
    
    // This variable is also private. I don't want other classes editing the
    // dates on a prayer without the store knowing that it is updating it.
    // NOTE: THIS SHOULD NOT BE USED YET
    private var prayerDates: NSMutableArray = NSMutableArray()
    
    // MARK: -----------------------------------------------------------------------------
    
    // MARK: Beginning of PrayerStore
    
    // I also only want this class to edit the categories directly
    // If you want to add or delete categories, use the provided functions
    // such as deleteCategory, addCategory, etc.
    private var categories: NSMutableArray = NSMutableArray()
    
    // This is a reference to the app delegate (as AppDelegate for its methods
    // and variables)
    let managedContext: NSManagedObjectContext? = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    let userPrefs = NSUserDefaults.standardUserDefaults()
    
    // MARK: Singleton Instance
    // This is the singleton variable for PrayerStore that is
    // used to get an instance to the store
    // Used nested functions to return the instance
    class var sharedInstance: PrayerStore {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: PrayerStore? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = PrayerStore()
        }
        
        return Static.instance! // Returns an instance of the PrayerStore
    }
    
    // MARK: Categories /  All Data
    // MARK: Fetching
    
    // Fetch the categoreis only from the database
    func fetchCategoriesData(predicate: NSPredicate?, sortKey: String = "creationDate", ascending: Bool = false) {
        var fetchReq = NSFetchRequest(entityName: "Category")
        
        println("fetchCategoriesData key is \(sortKey)")
        println("fetchCategoriesData ascending is \(ascending)")
        
        let sortDesc = [NSSortDescriptor(key: sortKey, ascending: ascending)]
        fetchReq.sortDescriptors = sortDesc
        
        if let fetchPredicate = predicate {
            fetchReq.predicate = fetchPredicate
        }
        
        var error: NSError?
        var fetchedArray: NSArray? = managedContext!.executeFetchRequest(fetchReq, error: &error)
        
        if let array = fetchedArray {
            for var i = 0; i < array.count; i++ {
                println("--> Fetched Item at index \(i) is \((array[i] as! Category).name)")
            }
            
            categories = NSMutableArray(array: array)
        } else {
            println("An error occurred while fetching categories from the database: \(error!.localizedDescription)")
            categories = NSMutableArray()
        }
    }
    
    // Returns an NSArray of all prayers
    func allCategories() -> NSArray {
        return categories
    }
    
    // Delete a category from the database
    // Takes a "Category" argument
    func deleteCategory(category: Category!) {
        println("Deleting category")
        
        managedContext!.deleteObject(category)
        categories.removeObjectIdenticalTo(category)
        
        // This is the method for an "order" - may use in the future
        /*if categories.count > 0 {
            for oldCategory in categories {
                (oldCategory as! Category).order - 1.0 != 0.0 ? (oldCategory as! Category).order -= 1 : println("Can't make order 0.0 for category!")
                println("Category with name \((oldCategory as! Category).shortName) changed order to new order \((oldCategory as! Category).order)")
            }
        }*/
        
        saveDatabase()
        fetchCategoriesData(nil)
    }
    
    // Changes a prayer's order with another prayer
    // TODO: Add method to change prayer position
    
    // MARK: Adding Categories
    
    // Add a category to the database
    // Takes a String argument and an NSDate argument
    func addCategoryToDatabase(name: String, dateCreated: NSDate) {
        var category = NSEntityDescription.insertNewObjectForEntityForName("Category", inManagedObjectContext: managedContext!) as! Category
        
        // This is the method for an "order" - may use in the future
        /*var order = 1.0
        
        if categories.count > 0 {
            for category in categories {
                (category as! Category).order += 1.0
                
                println("Category with name \((category as! Category).shortName) changed order to new order \((category as! Category).order)")
            }
        }*/
        
        category.name = name
        category.creationDate = NSDate()
        category.prayerCount = 0
        
        categories.insertObject(categories, atIndex: 0)
        
        saveDatabase()
    }
    
    // MARK: Category Helper methods
    
    // Returns the count of all categories
    func allCategoriesCount() -> Int {
        return categories.count
    }
    
    // This method takes a string and returns the corresponding category with that string
    func categoryForString(categoryName: String!) -> Category? {
        for category in categories {
            if category.name == categoryName {
                return category as? Category
            }
        }
        
        return nil
    }
    
    func categoryExists(categoryName: String!) -> Bool {
        var fetchReq = NSFetchRequest(entityName: "Category")
        fetchReq.predicate = NSPredicate(format: "name == %@", categoryName)
        fetchReq.fetchLimit = 1
        
        var error: NSError? = nil
        if (managedContext!.countForFetchRequest(fetchReq, error: &error) == 0) {
            println("Category \(categoryName) does not exist")
            
            return false
        }
        
        return true
    }
    
    
    
    
    // MARK: Prayers
    // MARK: Fetching
    
    // NSFetchedResultsController instance
    var fetchedResultsController: NSFetchedResultsController?
    
    func initFRC(sortDescriptors: [NSSortDescriptor], category: Category!, batchSize: Int = 20, delegate: NSFetchedResultsControllerDelegate?) {
        let fetchRequest = NSFetchRequest(entityName: "Prayer")
        
        //let sortDesc = NSSortDescriptor(key: sortKey, ascending: ascending)
        fetchRequest.sortDescriptors = sortDescriptors
        
        let predicate = NSPredicate(format: "category == %@", category.name)
        fetchRequest.predicate = predicate
        
        fetchRequest.fetchBatchSize = batchSize
        
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext!, sectionNameKeyPath: nil, cacheName: "prayersCache")
        
        fetchedResultsController = frc
        fetchedResultsController!.delegate = delegate
    }
    
    func fetchPrayerData() {
        var error: NSError?
        if !fetchedResultsController!.performFetch(&error) {
            println("Error fetching prayer data")
        }
    }
    
    func deletePrayerCache() {
        NSFetchedResultsController.deleteCacheWithName("prayersCache")
    }
    
    // MARK: Older methods (deprecated)
    
    // Fetch the prayers only from the database
    func fetchPrayerDataOld(predicate: NSPredicate?) {
        var fetchReq = NSFetchRequest(entityName: "Prayer")
        
        let sortDesc = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fetchReq.sortDescriptors = sortDesc
        
        if let fetchPredicate = predicate {
            fetchReq.predicate = fetchPredicate
        }
        
        var error: NSError?
        var fetchedArray: NSArray? = managedContext!.executeFetchRequest(fetchReq, error: &error)
        
        if let array = fetchedArray {
            prayers = NSMutableArray(array: array)
        } else {
            println("An error occurred while fetching prayers from the database: \(error!.localizedDescription)")
            prayers = NSMutableArray()
        }
    }
    
    // This method will fetch all the prayers in a certain category.
    // It makes it easier than fetching all prayers into memory and then sorting them
    // manually
    func fetchAllPrayersInCategory(category: Category!, sortDescriptors: [NSSortDescriptor], batchSize: Int = 20) -> NSMutableArray! {
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
    
    // Returns an NSArray of all prayers
    func allPrayers() -> NSArray {
        return prayers
    }
    
    func prayerCountForCategory(category: Category!) -> Int {
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
    // Takes a "Prayer" argument
    func deletePrayer(prayer: Prayer!, inCategory category: Category!) {
        println("Deleting prayer")
        
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
    // Takes two String arguments and an NSDate argument
    func addPrayerToDatabase(name: String!, details: String, category: Category!, dateCreated: NSDate) {
        var prayer = NSEntityDescription.insertNewObjectForEntityForName("Prayer", inManagedObjectContext: managedContext!) as! Prayer
        
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
        
        println("Category prayer count before update is: \(category.prayerCount)")
        category.prayerCount += 1
        println("Category prayer count after update is: \(category.prayerCount)")
        
        prayers.insertObject(prayer, atIndex: 0)
        
        saveDatabase()
    }
    
    // MARK: Helper Methods
    
    // Returns the count of all prayers
    func allPrayersCount() -> Int {
        return prayers.count
    }
    
    // Returns the number of prayers that is in a specified Category
    func numberOfPrayersInCategory(category: Category!) -> Int {
        var count = 0;
        
        count = Int(category.prayerCount)
        
        return count
    }
    
    
    
    // MARK: -----------
    // MARK: Saving / Deleting
    
    // Save the database
    func saveDatabase() {
        var error: NSError?
        managedContext!.save(&error)
        
        if let saveError = error {
            println("An error occurred while saving the database: \(saveError.localizedDescription)")
        }
    }
    
    
    
    
    // MARK: -----------
    // MARK: Unused
    // MARK: Prayer Dates
    
    // This function will search the database for all dates that are related to 
    // the specified prayer
    func allDates(forPrayer: Prayer) -> NSArray! {
        var fetchReq = NSFetchRequest(entityName: "Dates")
        fetchReq.predicate = NSPredicate(format: "prayer == %@", forPrayer)
        fetchReq.sortDescriptors = nil
        
        var error: NSError?
        let fetchedDates: NSArray? = managedContext!.executeFetchRequest(fetchReq, error: &error)
        
        if let fetchError = error {
            println("An error occurred while fetching data for prayer \(forPrayer)")
            return NSArray()
        }
        
        return fetchedDates
    }
    
    // This function will insert a data for a specific prayer into the database
    // NOTE: DO NOT USE THIS METHOD!!!!! It uses the value "dates" which I have removed for now - a one-many relationship
    // in the database (may use it later)
    func insertDate(forPrayer: Prayer, date: NSDate) {
        var addedDate: NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("Dates", inManagedObjectContext: managedContext!) as! NSManagedObject
        addedDate.setValue(date, forKey: "date")
        
        addedDate.setValue(forPrayer, forKey: "prayer")
        forPrayer.setValue(addedDate, forKey: "dates")
        
        saveDatabase()
    }
    
}
