//
//  PrayerLocationViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 8/5/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import PDKit
import CoreLocation
import GoogleMaps

class PrayerLocationsViewController_old: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {
    
    var allLocations = [PDLocation]()
    var userLocationButton: UIBarButtonItem!
    var segmentedControl: UISegmentedControl!
    
    let locationManager = CLLocationManager()
    let placesClient = GMSPlacesClient.sharedClient()
    
    @IBOutlet var mapView: GMSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Prayer Locations"
        
        userLocationButton = UIBarButtonItem(image: UIImage(named: "CurrentLocation"), style: .Plain, target: self, action: "showUserLocation:")
        
        navigationItem.rightBarButtonItem = userLocationButton
        
        locationManager.delegate = self
        
        var segItems = ["Locations", "Alerts"]
        segmentedControl = UISegmentedControl(items: segItems)
        segmentedControl.frame = CGRectMake(0, 0, 200, 30)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: "segmentChanged:", forControlEvents: .ValueChanged)
        
        var segmentedItem = UIBarButtonItem(customView: segmentedControl)
        var flexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        toolbarItems = [flexSpace, segmentedItem, flexSpace]
        
        mapView.delegate = self
        mapView.mapType = kGMSTypeNormal
        
        userLocationButton.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        LocationStore.sharedInstance.fetchLocations()
        allLocations = LocationStore.sharedInstance.locations()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Custom Methods
    
    func presentUnauthorizedAlert() {
        var alert = UIAlertController(title: "Error", message: "In order to use the prayer locations feature of the application, you must allow this application to use your current location.", preferredStyle: .Alert)
        
        var okAction = UIAlertAction(title: "OK", style: .Cancel, handler: { alertAction in
            self.segmentedControl.selectedSegmentIndex = 0
        })
        alert.addAction(okAction)
        
        var settingsAction = UIAlertAction(title: "Open Settings", style: .Default, handler: { alertAction in
            self.segmentedControl.selectedSegmentIndex = 0
            
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        })
        alert.addAction(settingsAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: CLLocationManager Delegate methods
    
    // TODO: Will implement later
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        //mapView.showsUserLocation = (status == .AuthorizedAlways && segmentedControl.selectedSegmentIndex == 1)
        mapView.myLocationEnabled = (status == .AuthorizedAlways && segmentedControl.selectedSegmentIndex == 1)
        
        if (status == CLAuthorizationStatus.Denied || status == CLAuthorizationStatus.Restricted) && segmentedControl.selectedSegmentIndex == 1 {
            presentUnauthorizedAlert()
        }
    }
    
    // MARK: MapView Delegate
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let locationID = "location"
        let alertID = "alert"
        
        if segmentedControl.selectedSegmentIndex == 0 {
            if annotation is PDLocation {
                var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(locationID) as? MKPinAnnotationView
                if annotationView == nil {
                    annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: locationID)
                    annotationView?.canShowCallout = true
                    
                    var infoButton = UIButton.buttonWithType(.DetailDisclosure) as! UIButton
                    annotationView?.rightCalloutAccessoryView = infoButton
                } else {
                    annotationView?.annotation = annotation
                }
                
                return annotationView
            }
        }
        
        return nil
    }
    
}
