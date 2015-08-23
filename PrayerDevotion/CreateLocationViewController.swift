//
//  CreateLocationViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 8/6/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import PDKit
import CoreLocation
import AddressBook
import GoogleMaps

class CreateLocationViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate, LocationSearchViewControllerDelegate, GMSMapViewDelegate {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var removeButton: UIBarButtonItem!
    @IBOutlet weak var selectedLocationLabel: UILabel!
    
    var saveButton: UIBarButtonItem!
    var searchController: UISearchController!
    var locationSearchVC: LocationSearchViewController!
    var selectedPrayer: PDPrayer!
    
    var searchResults = [CLPlacemark]()
    var selectedPlace: GMSPlace?
    var existingLocations = [LocationMarker]()
    
    var selectedMarker: LocationMarker?
    var searchTimer: NSTimer!
    
    let geocoder = CLGeocoder()
    let placesClient = GMSPlacesClient.sharedClient()
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LocationStore.sharedInstance.fetchLocations()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.tintColor = delegate.themeTintColor
        
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
        
        navigationItem.title = "Add Location"
        
        saveButton = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "saveLocation:")
        navigationItem.rightBarButtonItem = saveButton
        
        mapView.delegate = self
        mapView.mapType = kGMSTypeNormal
        mapView.camera = GMSCameraPosition.cameraWithLatitude(30.069094, longitude: -44.121094, zoom: 1)
        
        if selectedPrayer.location != nil {
            selectedLocationLabel.hidden = false
            selectedLocationLabel.text = "Selected: \(selectedPrayer.location!.locationName)"
        } else {
            selectedLocationLabel.hidden = true
        }
        
        //removeButton.enabled = selectedPrayer.location != nil
        
        loadExistingMarkers()
        
        for location in LocationStore.sharedInstance.locations() {
            placesClient.lookUpPlaceID(location.locationID, callback: { place, error in
                if let fetchError = error {
                    println("An error occurred while fetching place: \(fetchError), \(fetchError.localizedDescription)")
                } else {
                    if let currentPlace = place {
                        println("Appending marker to existingLocations")
                        let placeMarker = LocationMarker(place: currentPlace)
                        self.existingLocations.append(placeMarker)
                        placeMarker.map = self.mapView
                        
                        if placeMarker.place.placeID == self.selectedPrayer.location?.locationID {
                            self.mapView.selectedMarker = placeMarker
                            
                            let place = placeMarker.place
                            self.mapView.camera = GMSCameraPosition.cameraWithLatitude(place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 6)
                            self.removeButton.enabled = true
                            self.selectedMarker = placeMarker
                        }
                    }
                }
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: IBActions
    
    @IBAction func saveLocation(sender: AnyObject) {
        if let place = selectedPlace {
            println("Saving location with ID: \(place.placeID)")
            
            if LocationStore.sharedInstance.locationExists(place.placeID) == false {
                let location = LocationStore.sharedInstance.createLocation(place.coordinate.latitude, longitude: place.coordinate.longitude, name: place.formattedAddress, locationID: place.placeID)
                
                selectedPrayer.location = location
                
                let mutablePrayers = location.prayers.mutableCopy() as! NSMutableSet
                mutablePrayers.addObject(selectedPrayer)
                
                location.prayers = mutablePrayers.copy() as! NSSet
                
                BaseStore.baseInstance.saveDatabase()
            } else {
                println("Location already exists... Adding prayer to that location")
                
                let location = LocationStore.sharedInstance.getLocationForID(place.placeID)
                
                if let location = location {
                    selectedPrayer.location = location
                    
                    let mutablePrayers = location.prayers.mutableCopy() as! NSMutableSet
                    mutablePrayers.addObject(selectedPrayer)
                    
                    location.prayers = mutablePrayers.copy() as! NSSet
                    
                    BaseStore.baseInstance.saveDatabase()
                } else {
                    println("For some reason location exists but can't be fetched....")
                }
            }
        } else {
            println("Unable to create location")
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func removeLocation(sender: AnyObject) {
        if let prayerLocation = selectedPrayer.location {
            let prayerCount = prayerLocation.prayers.count
            
            let mutablePrayers = prayerLocation.prayers.mutableCopy() as! NSMutableSet
            mutablePrayers.removeObject(selectedPrayer)
                
            prayerLocation.prayers = mutablePrayers.copy() as! NSSet
            selectedPrayer.location = nil
            
            BaseStore.baseInstance.saveDatabase()
            LocationStore.sharedInstance.checkLocationCountForDeletion(prayerLocation)
            
            selectedMarker?.map = nil
        }
        
        selectedLocationLabel.hidden = true
        
        removeButton.enabled = false
        
        mapView.animateToZoom(1)
    }
    
    // MARK: Custom Methods
    
    func loadExistingMarkers() {
        for marker in existingLocations {
            marker.map = self.mapView
        }
    }
    
    // MARK: GMSMapView Delegate Methods
    
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        self.selectedPlace = (marker as! LocationMarker).place
        
        return false
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
    
    // MARK: UISearchController Methods
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        println("Updating search results...")
        
        performSearch(searchController.searchBar.text)
    }
    
    func performSearch(searchText: String) {
        let addressString = searchText
        
        if let timer = searchTimer { timer.invalidate() }
        searchTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "queryPlaces", userInfo: addressString, repeats: false)
    }
    
    func addPlacemarkToSearchResults(placemark: CLPlacemark, searchCount: Int) {
        println("Search Result Count = \(searchCount)")
        println("Appending search result")
        searchResults.append(placemark)
        
        if searchResults.count == searchCount {
            println("refreshing location tableview")
            locationSearchVC.tableView.reloadData()
        }
    }
    
    func queryPlaces() {
        var query: String = searchTimer!.userInfo as! String
        
        let placesClient = GMSPlacesClient.sharedClient()
        
        let filter = GMSAutocompleteFilter()
        filter.type = GMSPlacesAutocompleteTypeFilter.Geocode
        
        placesClient.autocompleteQuery(query, bounds: nil, filter: filter, callback: { (results, error: NSError?) in
            if let error = error {
                println("An error occurred while searching: \(error), \(error.localizedDescription)")
            } else {
                self.locationSearchVC.searchItems = [GMSAutocompletePrediction]()
                for result in results! {
                    if let result = result as? GMSAutocompletePrediction {
                        println("Result \(result.attributedFullText) with place ID \(result.placeID)")
                        self.locationSearchVC.searchItems.append(result)
                    }
                }
                self.locationSearchVC.tableView.reloadData()
                
            }
        })
    }
    
    
    // MARK: LocationSearchViewController Delegate methods
    
    func locationController(controller: LocationSearchViewController, didSelectLocation location: GMSPlace) {
        println("Place with name \(location.name) and ID \(location.placeID) selected")
        selectedPlace = location
        selectedLocationLabel.hidden = false
        selectedLocationLabel.text = "Selected: \(selectedPlace!.formattedAddress)"
        
        loadExistingMarkers()
        
        if LocationStore.sharedInstance.locationExists(location.placeID) {
            for marker in existingLocations {
                if marker.place.placeID == location.placeID {
                    mapView.selectedMarker = marker
                    break
                }
            }
        } else {
            let placeMarker = LocationMarker(place: selectedPlace!)
            placeMarker.map = self.mapView
        }
        
        var locationCam = GMSCameraPosition(target: selectedPlace!.coordinate, zoom: 9, bearing: 0, viewingAngle: 0)
        mapView.camera = locationCam
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
}