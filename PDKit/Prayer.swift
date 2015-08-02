//
//  Prayer.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 4/18/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData

@objc(PDPrayer)
public class PDPrayer: NSManagedObject {

    @NSManaged public var category: String // This is the category that the prayer is currently in
    @NSManaged public var name: String // The "shortName" that is displayed on each cell in the tableView
    @NSManaged public var creationDate: NSDate // The date that the prayer was created
    @NSManaged public var details: String // The details of the prayer ("who", "what", "why", etc.)
    @NSManaged public var addedDate: NSDate? // This is the date that the prayer is due on (for now... TODO: Add ability for multiple due dates)
    @NSManaged public var weekday: String? // This is the string representation of the weekly weekday to repeat the prayer on
    @NSManaged public var answered: Bool // A boolean to determine whether or not the prayer has been answered
    @NSManaged public var answeredNotes: String // These are the notes for the answered section of the prayer
    @NSManaged public var prayerType: String? // This is the type of the prayer (On_Date, Daily, or Weekly) that the user may have set
    @NSManaged public var isDateAdded: Bool // This is the boolean that determines whether or not a date was added to the prayer
    @NSManaged public var answeredTimestamp: NSDate // This is the date of the time when the prayer was answered
    @NSManaged public var priority: Int16 // This is the priority of the prayer (0 - None, 1, 2, and 3)
    @NSManaged public var assignedEmail: String? // This is an optional email assigned to the prayer
    
    @NSManaged public var prayerID: Int32 // This is a unique prayer ID that will distinguish the prayer from all other prayers
    
    @NSManaged public var alerts: NSOrderedSet // This is the ordered set of the alerts for the selected prayer
}
