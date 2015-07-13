//
//  Category.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 3/7/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData

class Category: NSManagedObject {

    @NSManaged var creationDate: NSDate // This is the date on which the category was created. Just usually a good idea to store this for later on
    @NSManaged var name: String // This is the category's name
    @NSManaged var prayerCount: Int32 // This is the number of prayers in the specified category
        
}
