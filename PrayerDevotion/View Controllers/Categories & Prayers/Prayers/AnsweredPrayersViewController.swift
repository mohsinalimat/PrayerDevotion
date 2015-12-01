//
//  FAnsweredile.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/20/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import PDKit

class AnsweredPrayersViewController: UITableViewController, UIViewControllerPreviewingDelegate {
    
    var answeredPrayers = [PDPrayer]()
    var answeredCount = 0
    var selectedIndex = 0
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var categoriesItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //let categoriesItem = UIBarButtonItem(title: "Categories", style: .Plain, target: self, action: "unwindToCategories:")
        let searchItem = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: "openSearch:")
        
        navigationItem.rightBarButtonItem = searchItem
        navigationItem.title = "Answered"
        
        if #available(iOS 9.0, *) {
            if self.traitCollection.forceTouchCapability == .Available {
                self.registerForPreviewingWithDelegate(self, sourceView: self.tableView)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let sortDescriptors = [NSSortDescriptor(key: "answeredTimestamp", ascending: false)]
        answeredPrayers = PrayerStore.sharedInstance.fetchAllAnsweredPrayers(sortDescriptors)
        answeredCount = answeredPrayers.count
        tableView.reloadData()
                
        navigationController!.navigationBar.tintColor = delegate.themeTintColor
        tableView.backgroundColor = delegate.themeBackgroundColor
        
        refreshUI()
    }
    
    func refreshUI() {
        if self.traitCollection.userInterfaceIdiom == .Phone {
            categoriesItem = UIBarButtonItem(title: "Categories", style: .Plain, target: self, action: "unwindToCategories:")
            self.navigationItem.leftBarButtonItem = categoriesItem
        } else {
            categoriesItem = UIBarButtonItem(title: "Hide Categories", style: .Plain, target: self, action: "showHideCategories:")
            self.navigationItem.leftBarButtonItem = categoriesItem
        }
    }
    
    func showHideCategories(sender: UIBarButtonItem) {
        sender.title = sender.title == "Show Categories" ? "Hide Categories" : "Show Categories"
        self.splitViewController!.displayModeButtonItem().target!.performSelector(self.splitViewController!.displayModeButtonItem().action)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func unwindToCategories(sender: AnyObject) {
        performSegueWithIdentifier(UnwindFromAnsweredID, sender: self)
    }
    
    func openSearch(sender: AnyObject) {
        performSegueWithIdentifier(ShowSearchSegueID, sender: self)
    }
    
    func setPriorityText(priority: Int16, forCell cell: PrayerCell) {
        switch priority {
        case 0: cell.priorityLabel.text = ""
        case 1: cell.priorityLabel.text = "!"
        case 2: cell.priorityLabel.text = "!!"
        case 3: cell.priorityLabel.text = "!!!"
        default: cell.priorityLabel.text = ""
        }
    }
    
    // MARK: UITableView Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return answeredCount
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(PrayerCellID, forIndexPath: indexPath) as! PrayerCell
        
        configureCell(cell, prayer: answeredPrayers[indexPath.row], indexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: PrayerCell, prayer: PDPrayer?, indexPath: NSIndexPath) {
        //var editedIndexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .NoStyle
        
        if let selectedPrayer = prayer {
            cell.prayerNameLabel.text = selectedPrayer.name
            cell.dateCreatedLabel.text = dateFormatter.stringFromDate(selectedPrayer.creationDate)
            setPriorityText(selectedPrayer.priority, forCell: cell)
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 55
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndex = indexPath.row
        
        performSegueWithIdentifier(PresentPrayerDetailsSegueID, sender: self)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete: break
        default: break
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete", handler: { rowAction, indexPath in
            PrayerStore.sharedInstance.deletePrayer(self.answeredPrayers[indexPath.row], inCategory: CategoryStore.sharedInstance.categoryForString(self.answeredPrayers[indexPath.row].category)!)
            
            self.answeredPrayers.removeAtIndex(indexPath.row)
            self.answeredCount = self.answeredCount - 1
            
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            tableView.endUpdates()
        })
        deleteAction.backgroundColor = UIColor.redColor()
        
        return [deleteAction]
    }
    
    // MARK: Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == PresentPrayerDetailsSegueID {
            let destinationVC = (segue.destinationViewController as! UINavigationController).topViewController as! PrayerDetailsViewController
            destinationVC.currentPrayer = answeredPrayers[selectedIndex]
        }
    }
    
    // MARK: UIViewControllerPreviewing Delegate Methods
    
    @available(iOS 9.0, *)
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let indexPath = tableView.indexPathForRowAtPoint(location)
        
        if let indexPath = indexPath {
            let prayer = answeredPrayers[indexPath.row]
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            
            if let cell = cell {
                previewingContext.sourceRect = cell.frame
                
                let navController = self.storyboard!.instantiateViewControllerWithIdentifier(SBPrayerDetailsNavControllerID) as! UINavigationController
                let prayerDetailsVC = navController.topViewController as! PrayerDetailsViewController
                prayerDetailsVC.currentPrayer = prayer
                prayerDetailsVC.previousViewController = self
                
                return navController
            }
        }
        
        return nil
    }
    
    @available(iOS 9.0, *)
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        self.showDetailViewController(viewControllerToCommit, sender: self)
    }
}
