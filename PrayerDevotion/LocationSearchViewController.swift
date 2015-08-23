//
//  LocationSearchViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 8/6/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import AddressBookUI
import GoogleMaps

protocol LocationSearchViewControllerDelegate {
    func locationController(controller: LocationSearchViewController, didSelectLocation location: GMSPlace)
}

class LocationSearchViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    var searchItems = [GMSAutocompletePrediction]()
    var delegate: LocationSearchViewControllerDelegate?
    let placesClient = GMSPlacesClient.sharedClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: TableView Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchItems.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("LocationSearchCellID", forIndexPath: indexPath) as! UITableViewCell
        let nameLabel = cell.viewWithTag(1) as! UILabel
        
        formatSearchText(searchItems[indexPath.row], label: nameLabel)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedItem = searchItems[indexPath.row] as GMSAutocompletePrediction
        let placeID = selectedItem.placeID
        
        placesClient.lookUpPlaceID(placeID, callback: { place, error in
            if let fetchError = error {
                println("An error occurred while looking up place with ID \(placeID)")
                
                self.dismissViewControllerAnimated(true, completion: nil)
            } else {
                if let place = place {
                    self.delegate!.locationController(self, didSelectLocation: place)
                } else {
                    println("No place was selected")
                }
                
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        })
    }
    
    
    func formatSearchText(predication: GMSAutocompletePrediction, label: UILabel) {
        let regularFont = UIFont.systemFontOfSize(UIFont.labelFontSize())
        let boldFont = UIFont.systemFontOfSize(UIFont.labelFontSize())
        
        let bolded = predication.attributedFullText.mutableCopy() as! NSMutableAttributedString
        bolded.enumerateAttribute(kGMSAutocompleteMatchAttribute, inRange: NSMakeRange(0, bolded.length), options: nil) { (value, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            let font = (value == nil) ? regularFont : boldFont
            bolded.addAttribute(NSFontAttributeName, value: font, range: range)
        }
        
        label.attributedText = bolded
    }
}
