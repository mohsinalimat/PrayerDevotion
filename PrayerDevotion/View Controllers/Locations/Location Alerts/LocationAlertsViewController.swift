//
//  LocationAlertsViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 11/29/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import PDKit
import GoogleMaps
import MapKit
import CoreLocation

protocol LocationAlertsViewControllerDelegate {
    func didFinishPickingLocationAlert()
}

class LocationAlertsViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate, GMSMapViewDelegate, LocationSearchViewControllerDelegate, CLLocationManagerDelegate {
    
    // IBOutlets / UI
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var removeButton: UIBarButtonItem!
    @IBOutlet weak var selectedLocationLabel: UILabel!
    @IBOutlet weak var radiusTextField: UITextField!
    @IBOutlet weak var onEnterSwitch: UISwitch!
    
    var saveButton: UIBarButtonItem!
    
    // View Controllers
    var searchController: UISearchController!
    var locationSearchVC: LocationSearchViewController!
    
    // Searching
    var searchResults = [CLPlacemark]()
    var selectedMarker: LocationMarker?
    var searchTimer: NSTimer!
    
    // Models
    var selectedPrayer: PDPrayer!
    var previousSelectedAlert: PDLocationAlert?
    var selectedPlace: GMSPlace?
    
    // Locations
    let geocoder = CLGeocoder()
    let placesClient = GMSPlacesClient.sharedClient()
    
    // Delegates
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var delegate: LocationAlertsViewControllerDelegate?
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        previousSelectedAlert = selectedPrayer.locationAlert
        
        navigationController?.navigationBar.tintColor = appDelegate.themeTintColor
        
        locationSearchVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SBLocationSearchViewControllerID") as! LocationSearchViewController
        locationSearchVC.delegate = self
        
        searchController = UISearchController(searchResultsController: locationSearchVC)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.sizeToFit()
        
        navigationItem.titleView = searchController.searchBar
        definesPresentationContext = true
        
        navigationItem.title = "Add Location Alert"
        
        saveButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "saveLocationAlert:")
        navigationItem.rightBarButtonItem = saveButton
        
        mapView.delegate = self
        mapView.mapType = kGMSTypeNormal
        mapView.camera = GMSCameraPosition.cameraWithLatitude(30.069094, longitude: -44.121094, zoom: 1)
        
        if let locationAlert = selectedPrayer.locationAlert {
            selectedLocationLabel.hidden = false
            selectedLocationLabel.text = "Selected \(locationAlert.locationName)"
        } else {
            selectedLocationLabel.hidden = true
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func saveLocationAlert(sender: AnyObject) {
        if let place = selectedPlace {
            print("Saving location alert with ID: \(place.placeID)")
            
            let radius = radiusTextField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let onEnter = onEnterSwitch.on
            
            let locationAlert = LocationAlertStore.sharedInstance.createLocation(place.coordinate.latitude, longitude: place.coordinate.longitude, radius: radius == "" ? 25 : Double(radius)!, name: place.formattedAddress, locationID: place.placeID, onEnter: onEnter)
            
            selectedPrayer.locationAlert = locationAlert
            
            BaseStore.baseInstance.saveDatabase()
        } else {
            print("Unable to create location")
        }
        
        delegate?.didFinishPickingLocationAlert()
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func removeLocationAlert(sender: AnyObject) {
        if let locationAlert = selectedPrayer.locationAlert {
            selectedPrayer.locationAlert = nil
            LocationAlertStore.sharedInstance.deleteLocationAlert(locationAlert)
            
            selectedMarker?.map = nil
        }
        
        selectedLocationLabel.hidden = true
        removeButton.enabled = false
        
        mapView.animateToZoom(1)
    }
    
    // MARK: Custom Methods
    
    func regionForLocationAlert(locationAlert: PDLocationAlert) -> CLCircularRegion {
        let region = CLCircularRegion(center: locationAlert.coordinate, radius: locationAlert.radius, identifier: locationAlert.identifier)
        region.notifyOnEntry = locationAlert.onEnter
        region.notifyOnExit = !locationAlert.onEnter
        
        return region
    }
    
    func startMonitoringLocationAlert(locationAlert: PDLocationAlert) {
        // TODO: Make Sure PrayerDetailsViewController checks to make sure that CLLocationManager
        // can monitor CLCircularRegions
        // Example: if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) { ... }
        
        let region = regionForLocationAlert(locationAlert)
        // TODO: Add Function to LocationAlertStore that reloads all locations and finds 20 nearest and monitors them.
        // TODO: Make sure to use didUpdateLocation: to reload region monitoring as well
    }
    
    // MARK: GMSMapView Delegate Methods
    
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        self.selectedPlace = (marker as! LocationMarker).place
        
        return false
    }
    
    func mapView(mapView: GMSMapView!, markerInfoContents marker: GMSMarker!) -> UIView! {
        let placeMarker = marker as! LocationMarker
            
        if let infoView = NSBundle.mainBundle().loadNibNamed("LocationInfoView", owner: nil, options: nil).first as? LocationInfoView {
            infoView.locationNameLabel.text = placeMarker.place.name
            infoView.prayerCountLabel.text = String(format: "Radius: %@", (radiusTextField.text == "" ? "25" : radiusTextField.text)!)
                
            return infoView
        } else {
            return nil
        }
    }
    
    // MARK: UISearchController Methods
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        print("Updating search results...")
        
        performSearch(searchController.searchBar.text!)
    }
    
    func performSearch(searchText: String) {
        let addressString = searchText
        
        if let timer = searchTimer { timer.invalidate() }
        searchTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "queryPlaces", userInfo: addressString, repeats: false)
    }
    
    func addPlacemarkToSearchResults(placemark: CLPlacemark, searchCount: Int) {
        print("Search Result Count = \(searchCount)")
        print("Appending search result")
        searchResults.append(placemark)
        
        if searchResults.count == searchCount {
            print("refreshing location alert tableview")
            locationSearchVC.tableView.reloadData()
        }
    }
    
    func queryPlaces() {
        let query = searchTimer!.userInfo as! String
        let filter = GMSAutocompleteFilter()
        filter.type = .Geocode
        
        placesClient.autocompleteQuery(query, bounds: nil, filter: filter, callback: { (results, error: NSError?) in
            if let error = error {
                print("An error occurred while search: \(error), \(error.localizedDescription)")
            } else {
                self.locationSearchVC.searchItems = [GMSAutocompletePrediction]()
                for result in results! {
                    if let result = result as? GMSAutocompletePrediction {
                        print("Result \(result.attributedFullText) with place ID \(result.placeID)")
                        self.locationSearchVC.searchItems.append(result)
                    }
                }
                self.locationSearchVC.tableView.reloadData()
            }
        })
    }
    
    // MARK: LocationSearchViewController Delegate Methods
    
    func locationController(controller: LocationSearchViewController, didSelectLocation location: GMSPlace) {
        print("Place with name \(location.name) and ID \(location.placeID) selected")
        selectedPlace = location
        selectedLocationLabel.hidden = false
        selectedLocationLabel.text = "Selected: \(selectedPlace!.formattedAddress)"
        
        let placeMarker = LocationMarker(place: selectedPlace!)
        placeMarker.map = self.mapView
        
        var radius: Double {
            if self.radiusTextField.text == "" {
                return 25
            } else {
                return Double(self.radiusTextField.text!)!
            }
        }
        
        //let range = self.translateCoordinate(location.coordinate, metersLat: radius * 2, metersLong: radius * 2)
        //let bounds = GMSCoordinateBounds(coordinate: location.coordinate, coordinate: range)
        //let update = GMSCameraUpdate.fitBounds(bounds, withPadding: 10.0)
        
        let center = location.coordinate
        let region = MKCoordinateRegionMakeWithDistance(center, radius * 2, radius * 2)
        let northEast = CLLocationCoordinate2DMake(region.center.latitude - region.span.latitudeDelta / 2, region.center.longitude - region.span.longitudeDelta / 2)
        let southWest = CLLocationCoordinate2DMake(region.center.latitude + region.span.latitudeDelta / 2, region.center.longitude + region.span.longitudeDelta / 2)
        
        let bounds = GMSCoordinateBounds(coordinate: northEast, coordinate: southWest)
        let update = GMSCameraUpdate.fitBounds(bounds, withPadding: 5.0)
        
        self.mapView.moveCamera(update)
        
        navigationItem.rightBarButtonItem = saveButton
    }
    
    // MARK: Search Bar Delegate Methods
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        navigationItem.rightBarButtonItem = nil
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        navigationItem.rightBarButtonItem = saveButton
    }
    
    // MARK: CLLocationManager Delegate Methods
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            locationManager.startUpdatingLocation()
            mapView.myLocationEnabled = true
            mapView.settings.myLocationButton = false
        case .Denied, .NotDetermined, .Restricted:
            let alertController = UIAlertController(title: "Error", message: "You must allow PrayerDevotion to use location services in order to use the location alerts feature. Please go to Settings -> PrayerDevotion to change your location settings", preferredStyle: .Alert)
            
            let closeAction = UIAlertAction(title: "Close", style: .Default, handler: nil)
            let settingsAction = UIAlertAction(title: "Settings", style: .Default, handler: { alertAction in
                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            })
            
            alertController.addAction(closeAction)
            alertController.addAction(settingsAction)
            
            dismissViewControllerAnimated(true) {
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
}
