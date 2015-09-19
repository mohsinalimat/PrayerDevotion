//
//  LocationPrayersViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 8/22/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import PDKit
import MapKit
import CoreLocation
import GoogleMaps

class LocationPrayersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var locationPrayers = [PDPrayer]()
    var selectedIndex = 0
    
    var location: GMSPlace!
    
    var shouldExitScreen: Bool = true
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let dateFormatter = NSDateFormatter()
    let userPrefs = NSUserDefaults.standardUserDefaults()
    
    var backViewController: PrayerLocationsViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .NoStyle
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        tableView.backgroundView = blurView
        tableView.backgroundColor = UIColor.clearColor()
        
        locationLabel.layer.shadowColor = UIColor.blackColor().CGColor
        locationLabel.layer.shadowRadius = 5
        locationLabel.layer.shadowOpacity = 0.5
        locationLabel.layer.shadowOffset = CGSizeMake(0, -0.5)
        
        tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        shouldExitScreen = true
        
        locationPrayers = PrayerStore.sharedInstance.fetchPrayersForLocationID(location.placeID)
        
        locationLabel.text = location.name
        locationLabel.textColor = delegate.themeTextColor
        locationLabel.backgroundColor = delegate.themeBackgroundColor
        view.backgroundColor = delegate.themeBackgroundColor
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        if shouldExitScreen { navigationController?.popToViewController(backViewController, animated: true) }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: TableView Data Source and Delegate Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locationPrayers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(PrayerCellID, forIndexPath: indexPath) as! PrayerCell
        
        configureCell(cell, prayer: locationPrayers[indexPath.row], indexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: PrayerCell, prayer: PDPrayer?, indexPath: NSIndexPath) {
        if let selectedPrayer = prayer {
            cell.prayerNameLabel.text = selectedPrayer.name
            cell.dateCreatedLabel.text = dateFormatter.stringFromDate(selectedPrayer.creationDate)
            
            cell.setPriorityText(selectedPrayer.priority)
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndex = indexPath.row
        
        performSegueWithIdentifier(PresentPrayerDetailsSegueID, sender: self)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == PresentPrayerDetailsSegueID {
            let prayerDetailsVC = (segue.destinationViewController as! UINavigationController).topViewController as! PrayerDetailsViewController
            prayerDetailsVC.currentPrayer = locationPrayers[selectedIndex]
            prayerDetailsVC.previousViewController = self
            shouldExitScreen = false
        }
    }
    
}
