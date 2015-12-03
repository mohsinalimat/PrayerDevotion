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
    var circleOverlay: GMSCircle?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        mapView = self.viewWithTag(1) as! GMSMapView
        
        CLLocationManager().startUpdatingLocation()
        mapView.myLocationEnabled = CLLocationManager.authorizationStatus() == .AuthorizedAlways
        mapView.settings.myLocationButton = false
    }
    
    func refreshCell() {
        GMSPlacesClient.sharedClient().lookUpPlaceID(locationAlert.locationID, callback: { place, error in
            if let error = error {
                print("An error occurred trying to fetch place: \(error), \(error.localizedDescription)")
            } else {
                if let place = place {
                    self.addAndZoomToPlacemark(place)
                }
            }
        })
    }
    
    func addAndZoomToPlacemark(place: GMSPlace) {
        let placeMarker = LocationMarker(place: place)
        placeMarker.map = self.mapView
        
        let center = place.coordinate
        let region = MKCoordinateRegionMakeWithDistance(center, self.locationAlert.radius * 2, self.locationAlert.radius * 2)
        let northEast = CLLocationCoordinate2DMake(region.center.latitude - region.span.latitudeDelta / 2, region.center.longitude - region.span.longitudeDelta / 2)
        let southWest = CLLocationCoordinate2DMake(region.center.latitude + region.span.latitudeDelta / 2, region.center.longitude + region.span.longitudeDelta / 2)
        
        let bounds = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        let update = GMSCameraUpdate.fitBounds(bounds, withPadding: 30.0)
        
        self.mapView.moveCamera(update)
        
        removeOverlayFromMap()
        drawOverlayForLocation(place)
    }
    
    func drawOverlayForLocation(location: GMSPlace) {
        let coordinate = location.coordinate
        let radius = self.locationAlert.radius
        let circle = GMSCircle(position: coordinate, radius: radius)
        circle.fillColor = UIColor(white: 0.7, alpha: 0.5)
        circle.strokeWidth = 4
        circle.strokeColor = (UIApplication.sharedApplication().delegate as! AppDelegate).themeBackgroundColor
        circle.map = self.mapView
        
        circleOverlay = circle
    }
    
    func removeOverlayFromMap() {
        if let overlay = circleOverlay {
            overlay.map = nil
            circleOverlay = nil
        }
    }
}