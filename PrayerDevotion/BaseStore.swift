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
class BaseStore {
    
    // This is a reference to the app delegate (as AppDelegate for its methods
    // and variables)
    let managedContext: NSManagedObjectContext? = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    let userPrefs = NSUserDefaults.standardUserDefaults()
    
    // MARK: -----------
    // MARK: Saving / Deleting
    
    // MARK: Singleton Instance
    // This is the singleton variable for PrayerStore that is
    // used to get an instance to the store
    // Used nested functions to return the instance
    class var baseInstance: BaseStore {
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
    func saveDatabase() {
        var error: NSError?
        managedContext!.save(&error)
        
        if let saveError = error {
            println("An error occurred while saving the database: \(saveError.localizedDescription)")
        }
    }
    
    // MARK: -----------
    
}
