//
//  BaseStore.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 6/1/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData
import UIKit

// This is the basic store that will be used by the CategoryStore, PrayerStore, and AlertStore
public class BaseStore {
    
    // This is a reference to the app delegate (as AppDelegate for its methods
    // and variables)
    let managedContext: NSManagedObjectContext? = CoreDataStore.sharedInstance.managedObjectContext
    let userPrefs = NSUserDefaults.standardUserDefaults()
    
    // MARK: -----------
    // MARK: Saving / Deleting
    
    // MARK: Singleton Instance
    // This is the singleton variable for PrayerStore that is
    // used to get an instance to the store
    // Used nested functions to return the instance
    public class var baseInstance: BaseStore {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: BaseStore? = nil
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = BaseStore()
        }
        
        return Static.instance! // Returns an instance of the PrayerStore
    }
    
    // Save the database
    public func saveDatabase() {
        var error: NSError?
        do {
            try managedContext!.save()
        } catch let error1 as NSError {
            error = error1
        }
        
        if let saveError = error {
            print("An error occurred while saving the database: \(saveError.localizedDescription)")
        }
    }
    
    // MARK: -----------
    
}
