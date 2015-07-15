//
//  Alerts.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 6/1/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData

@objc(PDAlert)
public class PDAlert: NSManagedObject {

    @NSManaged public var alertDate: NSDate // This is the alert date/time that has been set
    
    //The available types of alerts are:
    // "Daily", "Date", or "Weekly"
    @NSManaged public var didSchedule: Bool // This is a Bool value that tells whether or not the alert was scheduled.
    @NSManaged public var notificationID: UInt32 // This is a unique ID that is assigned to each notification
    
    @NSManaged public var prayer: PDPrayer // This is a reference back to the prayer that contains this alert

}
