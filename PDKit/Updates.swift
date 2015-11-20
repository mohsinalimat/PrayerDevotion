//
//  Updates.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 10/11/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData

@objc(PDUpdate)
public class PDUpdate : NSManagedObject {
    
    @NSManaged public var update: String // This is the actual update text itself
    @NSManaged public var timestamp: NSDate // This is the timestamp of when the update was created
    
    @NSManaged public var prayer: PDPrayer // This is the parent prayer of the update
    
    public var day: NSString {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .NoStyle
        
        return dateFormatter.stringFromDate(self.timestamp)
    }
    
}