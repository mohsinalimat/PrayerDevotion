//
//  TodayPrayersViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/19/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import PDKit

class TodayPrayersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    var todayPrayers = [PDPrayer]()
    var todayCount = 0
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noPrayersLabel: UILabel!
    @IBOutlet weak var todayLabel: UILabel!
    
    let dateFormatter = NSDateFormatter()
    let userPrefs = NSUserDefaults.standardUserDefaults()
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var selectedIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .NoStyle
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleURL:", name: "HandleURLNotification", object: nil)
        
        navigationController!.navigationBar.translucent = true
        
        PrayerStore.sharedInstance.checkIDs()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchTodayPrayers()
        tableView.reloadData()
        
        noPrayersLabel.hidden = !(todayCount == 0)
        
        view.backgroundColor = delegate.themeBackgroundColor
        
        todayLabel.textColor = delegate.themeTextColor
        noPrayersLabel.textColor = delegate.themeTextColor
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setPriorityText(priority: Int16, forCell cell: TodayPrayerCell) {
        switch priority {
        case 0: cell.priorityLabel.text = ""
        case 1: cell.priorityLabel.text = "!"
        case 2: cell.priorityLabel.text = "!!"
        case 3: cell.priorityLabel.text = "!!!"
        default: cell.priorityLabel.text = ""
        }
    }
    
    func fetchTodayPrayers() {
        todayPrayers = [PDPrayer]()
        todayPrayers += PrayerStore.sharedInstance.fetchTodayPrayers(.OnDate, forWidget: false)
        todayPrayers += PrayerStore.sharedInstance.fetchTodayPrayers(.Daily, forWidget: false)
        todayPrayers += PrayerStore.sharedInstance.fetchTodayPrayers(.Weekly, forWidget: false)
        
        todayCount = todayPrayers.count
    }
    
    // MARK: UITableView Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        else { return todayCount }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(CreatePrayerCellID, forIndexPath: indexPath) as! CreatePrayerCell
            
            cell.currentCategory = nil
            cell.prayerTextField.delegate = self
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(TodayCellID, forIndexPath: indexPath) as! TodayPrayerCell
            
            cell.nameLabel.text = todayPrayers[indexPath.row].name
            cell.prayerTypeLabel.text = todayPrayers[indexPath.row].prayerType
            setPriorityText(todayPrayers[indexPath.row].priority, forCell: cell)
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 { return 44 }
        else { return 55 }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section != 0
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete: break
        default: break
        }
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var deleteAction = UITableViewRowAction(style: .Normal, title: "Delete", handler: { rowAction, indexPath in
            PrayerStore.sharedInstance.deletePrayer(self.todayPrayers[indexPath.row], inCategory: CategoryStore.sharedInstance.categoryForString(self.todayPrayers[indexPath.row].category)!)
            
            self.todayPrayers.removeAtIndex(indexPath.row)
            self.todayCount = self.todayCount - 1
            
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            tableView.endUpdates()
            
            self.noPrayersLabel.hidden = !(self.todayCount == 0)
            (tableView.headerViewForSection(1))?.textLabel.text = self.tableView(tableView, titleForHeaderInSection: 1)
        })
        deleteAction.backgroundColor = UIColor.redColor()
        
        return [deleteAction]
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndex = indexPath.row
        
        performSegueWithIdentifier(PresentPrayerDetailsSegueID, sender: self)
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        var headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel.textColor = delegate.themeTextColor
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            let currentDate = NSDate()
            let dateString = dateFormatter.stringFromDate(currentDate)
            
            return todayCount == 0 ? "" : "Today, \(dateString)"
        }
        
        return ""
    }
    
    // MARK: Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == PresentPrayerDetailsSegueID {
            let prayerDetailsVC = (segue.destinationViewController as! UINavigationController).topViewController as! PrayerDetailsViewController
            prayerDetailsVC.currentPrayer = todayPrayers[selectedIndex]
            prayerDetailsVC.previousViewController = self
        }
    }
    
    // MARK: UITextField Delegate Methods
    
    func textFieldDidBeginEditing(textField: UITextField) {
        println("Beginning to add a prayer into the textField")
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        println("Ending textField editing...")
        
        let enteredString = textField.text
        let modifiedString = enteredString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if (modifiedString != "") {
            println("Entered string: \(enteredString)")
            println("Adding prayer to database...")
            
            var addedPrayer = PrayerStore.sharedInstance.addPrayerToDatabase(enteredString, details: "", category: CategoryStore.sharedInstance.categoryForString("Uncategorized")!, dateCreated: NSDate())
            
            CATransaction.begin()
            CATransaction.setCompletionBlock({
                self.tableView.reloadData()
                
                self.noPrayersLabel.hidden = !(self.todayCount == 0)
            })
            tableView.beginUpdates()
            
            fetchTodayPrayers()
            
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: find(todayPrayers, addedPrayer)!, inSection: 1)], withRowAnimation: .Right)
            
            tableView.endUpdates()
            
            CATransaction.commit()
        } else {
            println("String did not contain any characters at all. Not adding to prayer list...")
        }
        
        textField.text = ""
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
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
