//
//  PrayerLocationsViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 8/18/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import PDKit
import GoogleMaps

class PrayerLocationsViewController: UIViewController, GMSMapViewDelegate {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var removeLocationButton: UIBarButtonItem!
    
    var allLocations = [PDLocation]()
    
    let locationManager = CLLocationManager()
    let placesClient = GMSPlacesClient.sharedClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Prayer Locations"
        
        navigationController!.toolbarHidden = true
        navigationController!.interactivePopGestureRecognizer!.enabled = false
        
        mapView.delegate = self
        mapView.camera = GMSCameraPosition.cameraWithLatitude(30.069094, longitude: -44.121094, zoom: 1)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        LocationStore.sharedInstance.fetchLocations()
        allLocations = LocationStore.sharedInstance.locations()
        
        refreshUI()
        
        mapView.clear()
        for location in allLocations {
            print("Location ID is \(location.locationID)")
            
            placesClient.lookUpPlaceID(location.locationID, callback: { place, error in
                if let fetchError = error {
                    print("An error occurred while fetching places: \(fetchError), \(fetchError.localizedDescription)")
                } else {
                    if let currentPlace = place {
                        print("Place name is \(currentPlace.name)")
                        let placeMarker = LocationMarker(place: currentPlace)
                        placeMarker.map = self.mapView
                    }
                }
            })
        }
    }
    
    func refreshUI() {
        if self.traitCollection.userInterfaceIdiom == .Phone {
            let categoriesItem = UIBarButtonItem(title: "Categories", style: .Plain, target: self, action: "unwindToCategories:")
            self.navigationItem.leftBarButtonItem = categoriesItem
        } else {
            let categoriesItem = UIBarButtonItem(title: "Hide Categories", style: .Plain, target: self, action: "showHideCategories:")
            self.navigationItem.leftBarButtonItem = categoriesItem
        }
    }
    
    func unwindToCategories(sender: AnyObject) {
        performSegueWithIdentifier(UnwindFromLocationsID, sender: self)
    }
    
    func showHideCategories(sender: UIBarButtonItem) {
        sender.title = sender.title == "Show Categories" ? "Hide Categories" : "Show Categories"
        self.splitViewController!.displayModeButtonItem().target!.performSelector(self.splitViewController!.displayModeButtonItem().action)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: GMSMapView Delegate Methods
    
    func mapView(mapView: GMSMapView!, willMove gesture: Bool) {
        if gesture {
            mapView.selectedMarker = nil
        }
    }
    
    func mapView(mapView: GMSMapView!, markerInfoContents marker: GMSMarker!) -> UIView! {
        let placeMarker = marker as! LocationMarker
        let placeID = placeMarker.place.placeID
        let location = LocationStore.sharedInstance.getLocationForID(placeID)
        
        if let infoView = NSBundle.mainBundle().loadNibNamed("LocationInfoView", owner: nil, options: nil).first as? LocationInfoView {
            infoView.locationNameLabel.text = placeMarker.place.name
            infoView.prayerCountLabel.text = String(format: "%d Prayer%@", location!.prayers.count, location!.prayers.count == 1 ? "" : "s")
            
            return infoView
        } else {
            return nil
        }
    }
    
    func mapView(mapView: GMSMapView!, didTapInfoWindowOfMarker marker: GMSMarker!) {
        let placeMarker = marker as! LocationMarker
        
        let placeID = placeMarker.place.placeID
        
        let locationPrayersVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SBLocationPrayersViewControllerID") as! LocationPrayersViewController
        locationPrayersVC.location = placeMarker.place
        locationPrayersVC.backViewController = self
        
        print("Address is \(placeMarker.place.formattedAddress)")
        
        navigationController!.pushViewController(locationPrayersVC, animated: true)
        
        print("Loading prayers for location with ID \(placeID)")
    }
}