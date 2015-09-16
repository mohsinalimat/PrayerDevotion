//
//  CategoriesStore.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 6/1/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import CoreData

public class CategoryStore: BaseStore {
    
    // I also only want this class to edit the categories directly
    // If you want to add or delete categories, use the provided functions
    // such as deleteCategory, addCategory, etc.
    private var categories: [PDCategory] = [PDCategory]()
    
    // MARK: Singleton Instance
    // This is the singleton variable for PrayerStore that is
    // used to get an instance to the store
    // Used nested functions to return the instance
    public class var sharedInstance: CategoryStore {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: CategoryStore? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = CategoryStore()
        }
        
        return Static.instance! // Returns an instance of the PrayerStore
    }
    
    // MARK: Categories /  All Data
    // MARK: Fetching
    
    // Fetch the categoreis only from the database
    public func fetchCategoriesData(predicate: NSPredicate?, sortKey: String = "creationDate", ascending: Bool = false) {
        let fetchReq = NSFetchRequest(entityName: "Category")
        
        print("fetchCategoriesData key is \(sortKey)")
        print("fetchCategoriesData ascending is \(ascending)")
        
        let sortDesc = [NSSortDescriptor(key: sortKey, ascending: ascending)]
        fetchReq.sortDescriptors = sortDesc
        
        if let fetchPredicate = predicate {
            fetchReq.predicate = fetchPredicate
        }
        
        let error: NSError? = nil
        let fetchedArray = try! managedContext!.executeFetchRequest(fetchReq) as? [PDCategory]
        
        if let array = fetchedArray {
            for var i = 0; i < array.count; i++ {
                print("--> Fetched Item at index \(i) is \(array[i].name)")
            }
            
            categories = array
        } else {
            print("An error occurred while fetching categories from the database: \(error!.localizedDescription)")
            categories = [PDCategory]()
        }
    }
    
    public func fetchCategoriesForMove(excludedCategory: String) -> [PDCategory] {
        let fetchRequest = NSFetchRequest(entityName: "Category")
        
        let predicate = NSPredicate(format: "name != %@", excludedCategory)
        fetchRequest.predicate = predicate
        
        let error: NSError? = nil
        let results = try! managedContext!.executeFetchRequest(fetchRequest) as? [PDCategory]
        
        if let fetchedCategories = results {
            return fetchedCategories
        } else {
            print("An error occurred while fetching categories for move: \(error), \(error!.userInfo)")
            return [PDCategory]()
        }
    }
    
    // Returns an NSArray of all prayers
    public func allCategories() -> [PDCategory] {
        return categories
    }
    
    // Delete a category from the database
    // Takes a "Category" argument
    public func deleteCategory(category: PDCategory) {
        print("Deleting category")
        
        let fetchRequest = NSFetchRequest(entityName: "Prayer")
        fetchRequest.includesPropertyValues = false
        
        let predicate = NSPredicate(format: "category == %@", category.name)
        fetchRequest.predicate = predicate
        
        let results = try! managedContext!.executeFetchRequest(fetchRequest) as? [PDPrayer]
        
        if let prayersToDelete = results {
            for prayer in prayersToDelete {
                PrayerStore.sharedInstance.deletePrayer(prayer, inCategory: category)
            }
        }
        
        // This is the method for an "order" - may use in the future
        /*if categories.count > 0 {
        for oldCategory in categories {
        (oldCategory as! Category).order - 1.0 != 0.0 ? (oldCategory as! Category).order -= 1 : println("Can't make order 0.0 for category!")
        println("Category with name \((oldCategory as! Category).shortName) changed order to new order \((oldCategory as! Category).order)")
        }
        }*/
        
        managedContext!.deleteObject(category)
        categories.removeObject(category)
        
        saveDatabase()
        fetchCategoriesData(nil)
    }
    
    // Changes a prayer's order with another prayer
    // TODO: Add method to change prayer position
    
    // MARK: Adding Categories
    
    // Add a category to the database
    // Takes a String argument and an NSDate argument
    public func addCategoryToDatabase(name: String, dateCreated: NSDate) {
        let category = NSEntityDescription.insertNewObjectForEntityForName("Category", inManagedObjectContext: managedContext!) as! PDCategory
        
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
        
        categories.insert(category, atIndex: 0)
        //categories.insertObject(categories, atIndex: 0)
        
        saveDatabase()
    }
    
    // MARK: Moving Prayers in Category
    
    // Moves all prayers in a specific category to another category
    public func movePrayers(inCategory: PDCategory, toCategory category: PDCategory) {
        var toCategoryCount = PrayerStore.sharedInstance.prayerCountForCategory(category)
        var fromCategoryCount = PrayerStore.sharedInstance.prayerCountForCategory(inCategory)
        
        toCategoryCount += fromCategoryCount
        fromCategoryCount = 0
        
        inCategory.prayerCount = Int32(fromCategoryCount)
        category.prayerCount = Int32(toCategoryCount)
        
        let batchRequest = NSBatchUpdateRequest(entityName: "Prayer")
        
        let predicate = NSPredicate(format: "category == %@", inCategory.name)
        batchRequest.predicate = predicate
        batchRequest.propertiesToUpdate = ["category" : category.name]
        batchRequest.resultType = .UpdatedObjectsCountResultType
        
        let batchResult = try! managedContext!.executeRequest(batchRequest) as? NSBatchUpdateResult
        
        if let result = batchResult {
            print("Updated \(result.result!) prayers")
        } else {
            print("An error occurred while updating records!")
        }
        
        saveDatabase()
        
    }
    
    // MARK: Helper methods
    
    // Returns the count of all categories
    public func allCategoriesCount() -> Int {
        return categories.count
    }
    
    // This method takes a string and returns the corresponding category with that string
    public func categoryForString(categoryName: String) -> PDCategory? {
        let fetchRequest = NSFetchRequest(entityName: "Category")
        fetchRequest.predicate = NSPredicate(format: "name == %@", categoryName)
        fetchRequest.fetchLimit = 1
        
        let category = try! managedContext!.executeFetchRequest(fetchRequest) as? [PDCategory]

        
        if let category = category {
            return category[0]
        }
        
        /*for category in categories {
            if category.name == categoryName {
                return category as? PDCategory
            }
        }*/
        
        return nil
    }
    
    // This checks to see if a category exists (Dunno what to use this for... yet)
    public func categoryExists(categoryName: String) -> Bool {
        let fetchReq = NSFetchRequest(entityName: "Category")
        fetchReq.predicate = NSPredicate(format: "name == %@", categoryName)
        fetchReq.fetchLimit = 1
        
        var error: NSError? = nil
        if (managedContext!.countForFetchRequest(fetchReq, error: &error) == 0) {
            print("Category \(categoryName) does not exist")
            
            return false
        }
        
        return true
    }
}