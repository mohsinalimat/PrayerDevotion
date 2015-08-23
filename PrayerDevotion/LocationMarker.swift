//
//  LocationMarker.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 8/17/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import GoogleMaps

class LocationMarker: GMSMarker {
    
    let place: GMSPlace
    
    init(place: GMSPlace) {
        self.place = place
        super.init()
        
        position = place.coordinate
        icon = UIImage(named: "Pin")
        groundAnchor = CGPoint(x: 0.5, y: 0.5)
        appearAnimation = kGMSMarkerAnimationPop
    }
    
}