//
//  LocationAlert.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 11/29/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(PDLocationAlert)
public class PDLocationAlert: NSManagedObject, MKAnnotation {
    
    @NSManaged public var locationID: String // This is the unique UUID of the location
    @NSManaged public var locationName: String // This is the name of the location as it appears to the user
    @NSManaged public var latitude: Double // This is the latitude of the location alert
    @NSManaged public var longitude: Double // This is the longitude of the location alert
    @NSManaged public var onEnter: Bool // This is a bool to determine whether to alert on enter or exit - true = alert on enter. false = alert on exit
    @NSManaged public var radius: Double // This is the radius of the geofence
    @NSManaged public var identifier: String // This is a unique UUID that is used to distinguish between multiple location alerts that share the same locationID
    
    @NSManaged public var prayer: PDPrayer // This is the prayer that the location is attached to
    
    public var title: String? {
        if locationName.isEmpty {
            return "No Name"
        }
        
        return locationName
    }
    
    public var subtitle: String? {
        return ""
    }
    
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
