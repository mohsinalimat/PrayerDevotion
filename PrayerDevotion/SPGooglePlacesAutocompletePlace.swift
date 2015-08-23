//
//  SPGooglePlacesAutocompletePlace.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 8/10/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreLocation

class SPGooglePlacesAutocompletePlace {
    
    let geocoder = CLGeocoder()
    
    var name: String!
    var type: SPGooglePlacesAutocompletePlaceType!
    
    private(set) var reference: String!
    private(set) var identifier: String!
    
    class func placeFromDictionary(placeDictionary: NSDictionary) -> SPGooglePlacesAutocompletePlace {
        let place = SPGooglePlacesAutocompletePlace()
        place.name = placeDictionary["description"] as! String
        place.reference = placeDictionary["reference"] as! String
        place.identifier = placeDictionary["id"] as! String
        place.type = SPPlaceTypeFromDictionary(placeDictionary)
        return place
    }
    
    func resolveToPlacemark(block: SPGooglePlacesPlacemarkResultBlock) {
        
    }
}
