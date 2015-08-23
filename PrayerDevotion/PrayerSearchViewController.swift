//
//  PrayerSearchViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 5/29/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import PDKit

class SearchViewController: UITableViewController, UITableViewDataSource, UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    var previousViewController: UIViewController? = nil
    
    var newSearchBar: UISearchBar!
    var newSearchController: UISearchController!
    
    var selectedPrayer: PDPrayer?
    
    var filteredPrayers = [PDPrayer]()
    var searchText: String = ""
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFromEditingPrayer:", name: "ReloadSearchPrayers", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleURL:", name: "HandleURLNotification", object: nil)
        
        newSearchController = UISearchController(searchResultsController: nil)
        newSearchController.searchResultsUpdater = self
        newSearchController.dimsBackgroundDuringPresentation = false
        newSearchController.hidesNavigationBarDuringPresentation = false
        newSearchController.searchBar.delegate = self
        newSearchController.searchBar.sizeToFit()
        newSearchController.searchBar.placeholder = "Search Prayers"
        
        definesPresentationContext = true
        
        navigationItem.titleView = newSearchController.searchBar
        navigationItem.backBarButtonItem?.title = ""
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController!.navigationBar.tintColor = delegate.themeTintColor
        tableView.backgroundColor = delegate.themeBackgroundColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        var searchString = searchController.searchBar.text
        searchText = searchString
        
        var prayers = PrayerStore.sharedInstance.filterPrayers(searchText: searchText, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], batchSize: 50)
        
        filteredPrayers = prayers
        tableView.reloadData()
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        navigationController!.navigationBar.endEditing(true)
    }
    
    func setPriorityText(priority: Int16, forCell cell: PrayerSearchCell) {
        switch priority {
        case 0: cell.priorityLabel.text = ""
        case 1: cell.priorityLabel.text = "!"
        case 2: cell.priorityLabel.text = "!!"
        case 3: cell.priorityLabel.text = "!!!"
        default: cell.priorityLabel.text = ""
        }
    }
    
    // MARK: UITableView Delegate & DataSource methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        println("Filtered Prayers Count = \(filteredPrayers.count)")
        return filteredPrayers.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 58
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(PrayerSearchCellID, forIndexPath: indexPath) as! PrayerSearchCell
        
        let currentPrayer = filteredPrayers[indexPath.row]
        
        println("Prayer \(currentPrayer.name) is at indexPath \(indexPath) and is in category \(currentPrayer.category)")
        
        cell.prayerNameLabel.text = currentPrayer.name
        cell.categoryNameLabel.text = currentPrayer.category
        setPriorityText(currentPrayer.priority, forCell: cell)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedPrayer = filteredPrayers[indexPath.row]
        
        performSegueWithIdentifier(PresentPrayerDetailsSegueID, sender: self)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return filteredPrayers.count != 0 ? "Results" : ""
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        var headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel.textColor = delegate.themeTextColor
    }
    
    // MARK: Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == PresentPrayerDetailsSegueID {
            let destinationVC = (segue.destinationViewController as! UINavigationController).topViewController as! PrayerDetailsViewController
            destinationVC.currentPrayer = selectedPrayer!
            destinationVC.unwindToSearch = true
        }
    }
    
    func reloadFromEditingPrayer(notification: NSNotification) {
        println("Unwinding from Editing Prayer")
        BaseStore.baseInstance.saveDatabase()
        
        var searchString = newSearchController.searchBar.text
        
        var prayers = PrayerStore.sharedInstance.filterPrayers(searchText: searchString, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], batchSize: 50)
        
        filteredPrayers = prayers
        tableView.reloadData()
    }
    
    // MARK: Notifications
    
    func handleURL(notification: NSNotification) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let notificationInfo = notification.userInfo!
        let command = notificationInfo["command"] as! String
        
        if command == "open-today" {
            (UIApplication.sharedApplication().delegate as! AppDelegate).switchTabBarToTab(0)
        } else if command == "open-prayer" {
            let prayerID = Int32((notificationInfo["prayerID"] as! String).toInt()!)
            
            let prayerNavController = storyboard.instantiateViewControllerWithIdentifier(SBPrayerDetailsNavControllerID) as! UINavigationController
            let prayerDetailsController = prayerNavController.topViewController as! PrayerDetailsViewController
            prayerDetailsController.currentPrayer = PrayerStore.sharedInstance.getPrayerForID(prayerID)!
            prayerDetailsController.previousViewController = self
            
            presentViewController(prayerNavController, animated: true, completion: nil)
        }
    }
 }

/*class CustomSearchBar: UISearchBar {
    
    override func setShowsCancelButton(showsCancelButton: Bool, animated: Bool) {
        
    }
    
    func startSearching() {
        becomeFirstResponder()
    }
}

class CustomSearchController: UISearchController, UISearchBarDelegate, UISearchControllerDelegate {
    
    var currentSearchText: String! = ""
    var searchTableView: UITableView?
    
    override var searchBar: UISearchBar {
        get {
            let searchBar = CustomSearchBar()
            searchBar.placeholder = "Search for Prayer..."
            searchBar.delegate = self
            return searchBar
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //navigationController!.navigationItem.titleView = searchBar
        //navigationItem.titleView = searchBar
    }
    
    override func viewDidAppear(animated: Bool) {
        active = true
        searchBar.becomeFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        let length = count(searchBar.text)
        println("Search Text: \(searchText)")
        currentSearchText = searchText
        
        active = true
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func endEditing() {
        searchBar.resignFirstResponder()
    }
    
    func didPresentSearchController(searchController: UISearchController) {
        searchController.searchBar.becomeFirstResponder()
    }
}*/

class PrayerSearchViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    var filteredPrayers = NSMutableArray()
    var searchInCurrentCategory = false
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        println("Filtered Prayers Count = \(filteredPrayers.count)")
        return filteredPrayers.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return searchInCurrentCategory ? 44 : 58
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier(PrayerSearchCellID, forIndexPath: indexPath) as! PrayerSearchCell
        
        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: PrayerSearchCell, indexPath: NSIndexPath) {
        var editedIndexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
        
        var prayer = filteredPrayers[indexPath.row] as! PDPrayer
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .NoStyle
        
        cell.prayerNameLabel.text = prayer.name
        
        if let categoryLabel = cell.categoryNameLabel {
            categoryLabel.text = searchInCurrentCategory ? "" : "Category: \(prayer.category)"
        }
    }
    
    // MARK: Notifications
    
    func handleURL(notification: NSNotification) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let notificationInfo = notification.userInfo!
        let command = notificationInfo["command"] as! String
        
        if command == "open-today" {
            (UIApplication.sharedApplication().delegate as! AppDelegate).switchTabBarToTab(0)
        } else if command == "open-prayer" {
            let prayerID = Int32((notificationInfo["prayerID"] as! String).toInt()!)
            
            let prayerNavController = storyboard.instantiateViewControllerWithIdentifier(SBPrayerDetailsNavControllerID) as! UINavigationController
            let prayerDetailsController = prayerNavController.topViewController as! PrayerDetailsViewController
            prayerDetailsController.currentPrayer = PrayerStore.sharedInstance.getPrayerForID(prayerID)!
            prayerDetailsController.previousViewController = self
            
            presentViewController(prayerNavController, animated: true, completion: nil)
        }
    }
}
