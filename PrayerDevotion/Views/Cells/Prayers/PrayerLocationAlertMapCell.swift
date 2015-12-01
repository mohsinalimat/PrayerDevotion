//
//  PrayerLocationAlertMapCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 11/30/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import PDKit
import MapKit

class PrayerLocationAlertMapCell: UITableViewCell {
    
    var mapView: GMSMapView!
    
    var locationAlert: PDLocationAlert!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        mapView = self.viewWithTag(1) as! GMSMapView
    }
    
    func refreshCell() {
        GMSPlacesClient.sharedClient().lookUpPlaceID(locationAlert.locationID, callback: { place, error in
            if let error = error {
                print("An error occurred trying to fetch place: \(error), \(error.localizedDescription)")
            } else {
                if let place = place {
                    let locationMarker = LocationMarker(place: place)
                    locationMarker.map = self.mapView
                    
                    // Code adapted from http://stackoverflow.com/questions/26115047/change-camera-zoom-based-on-radius-google-maps-ios-sdk by @tounabun
                    let range = self.translateCoordinate(self.locationAlert.coordinate, metersLat: self.locationAlert.radius * 2, metersLong: self.locationAlert.radius * 2)
                    let bounds = GMSCoordinateBounds(coordinate: self.locationAlert.coordinate, coordinate: range)
                    let update = GMSCameraUpdate.fitBounds(bounds, withPadding: 5.0)
                    // End adapted code
                    
                    self.mapView.moveCamera(update)
                }
            }
        })
    }
    
    // Code taken from http://stackoverflow.com/questions/26115047/change-camera-zoom-based-on-radius-google-maps-ios-sdk by @tounabun
    func translateCoordinate(coordinate: CLLocationCoordinate2D, metersLat: Double, metersLong: Double) -> CLLocationCoordinate2D {
        var tempCoordinate = coordinate
        
        let tempRegion = MKCoordinateRegionMakeWithDistance(coordinate, metersLat, metersLong)
        let tempSpan = tempRegion.span
        
        tempCoordinate.latitude = coordinate.latitude + tempSpan.latitudeDelta
        tempCoordinate.longitude = coordinate.longitude + tempSpan.longitudeDelta
        
        return tempCoordinate
    }
    
}