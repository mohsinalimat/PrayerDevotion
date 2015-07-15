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

let PrayerSearchCellID = "PrayerSearchCellID"

let PresentPrayerDetailsFromSearchSegueID = "PresentPrayerDetailsFromSearchSegueID"

class SearchViewController: UITableViewController, UITableViewDataSource, UISearchControllerDelegate, UISearchResultsUpdating {
    
    var searchController: CustomSearchController!
    var prayerSearchController: PrayerSearchViewController!
    var searchBar: CustomSearchBar!
    
    var selectedPrayer: PDPrayer?
    
    var filteredPrayers: NSMutableArray = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Because our SearchViewController is setup to display search results,
        // we simply need to pass "self" along as the searchResultsController
        searchController = CustomSearchController(searchResultsController: nil)
        searchBar = searchController.searchBar as! CustomSearchBar
        
        searchController.delegate = searchController // Set the searchController delegate to self
        searchController.searchResultsUpdater = self
        
        searchController.hidesNavigationBarDuringPresentation = false // Do not hid Nav Bar during presentation
        searchController.dimsBackgroundDuringPresentation = true // Dim the background while searching
        
        self.navigationItem.titleView = searchController.searchBar // Now set the naviation item's titleView to the searchBar
        
        definesPresentationContext = true
        
        tableView.tableFooterView = UIView(frame: CGRectZero)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFromEditingPrayer:", name: "ReloadSearchPrayers", object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didCancel(sender: AnyObject) {
        
        searchController.searchBar.endEditing(true)
        //dismissViewControllerAnimated(true, completion: nil)
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        var searchString = (searchController as! CustomSearchController).currentSearchText
        
        var prayers = PrayerStore.sharedInstance.filterPrayers(searchText: searchString, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], batchSize: 50)
        
        filteredPrayers = prayers
        tableView.reloadData()
    }
    
    func didPresentSearchController(searchController: UISearchController) {
        searchController.searchBar.becomeFirstResponder()
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
        
        let currentPrayer = filteredPrayers[indexPath.row] as! PDPrayer
        
        println("Prayer \(currentPrayer.name) is at indexPath \(indexPath) and is in category \(currentPrayer.category)")
        
        cell.prayerNameLabel.text = currentPrayer.name
        cell.categoryNameLabel.text = currentPrayer.category
        setPriorityText(currentPrayer.priority, forCell: cell)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedPrayer = filteredPrayers[indexPath.row] as? PDPrayer
        
        performSegueWithIdentifier(PresentPrayerDetailsFromSearchSegueID, sender: self)
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return filteredPrayers.count != 0 ? "Results" : ""
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        var headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel.textColor = UIColor.whiteColor()
    }
    
    // MARK: Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == PresentPrayerDetailsFromSearchSegueID {
            let destinationVC = (segue.destinationViewController as! UINavigationController).topViewController as! PrayerDetailsViewController_New
            destinationVC.currentPrayer = selectedPrayer!
            destinationVC.unwindToSearch = true
        }
    }
    
    func reloadFromEditingPrayer(notification: NSNotification) {
        println("Unwinding from Editing Prayer")
        BaseStore.baseInstance.saveDatabase()
        
        var searchString = searchController.currentSearchText
        
        var prayers = PrayerStore.sharedInstance.filterPrayers(searchText: searchString, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], batchSize: 50)
        
        filteredPrayers = prayers
        tableView.reloadData()
    }
 }

class CustomSearchBar: UISearchBar {
    
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
    }
    
    override func viewDidAppear(animated: Bool) {
        active = true
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
}

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
}
