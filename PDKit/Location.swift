//
//  Locations.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 8/5/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(PDLocation)
public class PDLocation: NSManagedObject, MKAnnotation {
    
    @NSManaged public var locationID: String // This is a unique UUID of the location.
    @NSManaged public var locationName: String // This is the name of the location as it appears to the user
    @NSManaged public var latitude: Double // This is the latitude of the location
    @NSManaged public var longitude: Double // This is the longitude of the location
    
    @NSManaged public var prayers: NSSet // This is a set of the prayers that are contained under the location.
    
    public var title: String {
        if locationName.isEmpty {
            return "No Name"
        }
        
        return locationName
    }
    
    public var subtitle: String {
        return "0 Prayers"
    }
    
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
        
}
