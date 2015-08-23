//
//  SPGooglePlacesAutocompletePlace.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 8/10/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

let kGoogleAPIKey = "AIzaSyBbxdJLV4JIJrjyhyh1eQYsSSMNQUB5xGA"
let kGoogleAPINSErrorCode = 42

extension Array {
    var onlyObject: T? {
        return self.count == 1 ? self[0] : nil
    }
}

enum SPGooglePlacesAutocompletePlaceType: Int {
    case Geocode = 0
    case Establishment = 1
}

class SPGooglePlacesAutocompleteUtilities {
    
    class func SPPlaceTypeFromDictionary(placeDictionary: NSDictionary) -> SPGooglePlacesAutocompletePlaceType {
        return placeDictionary.objectForKey("types")!.containsObject("establishment") ? .Establishment : .Geocode
    }
    
    class func SPBooleanStringForBool(boolean: Bool) -> String {
        return boolean ? "true" : "false"
    }
    
    class func SPPlaceTypeStringForPlaceType(type: SPGooglePlacesAutocompletePlaceType) -> String {
        return type == .Geocode ? "geocode" : "establishment"
    }
    
    class func SPEnsureGoogleAPIKey() -> Bool {
        var userHasProvidedAPIKey = true
        if kGoogleAPIKey == "YOUR_API_KEY" {
            userHasProvidedAPIKey = false
            var alert = UIAlertController(title: "API Key Needed", message: "Please replace kGoogleAPIKey with your Google API key.", preferredStyle: .Alert)
            
            var dismissAction = UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil)
            alert.addAction(dismissAction)
            
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        }
        
        return userHasProvidedAPIKey
    }
    
    class func SPPresentAlertWithErrorAndTitle(error: NSError, title: String) {
        var alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .Alert)
        
        var dismissAction = UIAlertAction(title: "Dismiss", style: .Cancel, handler: nil)
        alert.addAction(dismissAction)
        
        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }
    
    class func SPIsEmptyString(string: String?) -> Bool {
        return string == nil || count(string!) == 0
    }
}
