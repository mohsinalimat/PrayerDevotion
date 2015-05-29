//
//  Prayer.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 4/18/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData

class Prayer: NSManagedObject {

    @NSManaged var category: String // This is the category that the prayer is currently in
    @NSManaged var creationDate: NSDate // The date that the prayer was created
    @NSManaged var details: String // The details of the prayer ("who", "what", "why", etc.)
    @NSManaged var addedDate: NSDate // This is the date that the prayer is due on (for now... TODO: Add ability for multiple due dates)
    @NSManaged var name: String // The "shortName" that is displayed on each cell in the tableView
    @NSManaged var answered: Bool // A boolean to determine whether or not the prayer has been answered
    @NSManaged var answeredNotes: String // These are the notes for the answered section of the prayer
}
