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
    
    @IBOutlet weak var prevDayButton: UIButton!
    @IBOutlet weak var nextDayButton: UIButton!
    
    var todayBarButton: UIBarButtonItem!
    
    let dateFormatter = NSDateFormatter()
    let userPrefs = NSUserDefaults.standardUserDefaults()
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var selectedPrayer: PDPrayer? = nil
    
    var date = NSDate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .NoStyle
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleURL:", name: "HandleURLNotification", object: nil)
        
        navigationController!.navigationBar.translucent = true
        
        todayBarButton = UIBarButtonItem(title: "Today", style: UIBarButtonItemStyle.Plain, target: self, action: "backToToday")
        
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
        prevDayButton.tintColor = delegate.themeTextColor
        nextDayButton.tintColor = delegate.themeTextColor
        
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
        
        print("Date is \(date)")
        
        todayPrayers += PrayerStore.sharedInstance.fetchPrayersOnDate(.OnDate, prayerDate: date);
        todayPrayers += PrayerStore.sharedInstance.fetchPrayersOnDate(.Daily, prayerDate: date);
        todayPrayers += PrayerStore.sharedInstance.fetchPrayersOnDate(.Weekly, prayerDate: date);
        
        todayCount = todayPrayers.count
    }
    
    // MARK: IBActions
    
    @IBAction func nextDay() {
        let currentDay = date
        let newDate = currentDay.dateByAddingTimeInterval(60*60*24*1)
        
        changeDate(newDate)
    }
    
    @IBAction func prevDay() {
        let currentDay = date
        let newDate = currentDay.dateByAddingTimeInterval(-60*60*24*1)
        
        changeDate(newDate)
    }
    
    // Change the current date of the today view
    func changeDate(newDate: NSDate) {
        date = newDate
        
        fetchTodayPrayers()
        tableView.reloadData()
        
        noPrayersLabel.hidden = !(todayCount == 0)
        
        let dateForm = NSDateFormatter()
        dateForm.dateStyle = .ShortStyle
        dateForm.timeStyle = .NoStyle
        
        let dateString = dateForm.stringFromDate(date)
        let todayString = dateForm.stringFromDate(NSDate())
        todayLabel.text = dateString == todayString ? "Today List" : "\(dateString) List"
        
        let tomorrowDateString = dateForm.stringFromDate(NSDate().dateByAddingTimeInterval(60*60*24))
        let yesterdayDateString = dateForm.stringFromDate(NSDate().dateByAddingTimeInterval(-60*60*24))
        
        if dateString == tomorrowDateString { todayLabel.text = "Tomorrow's List" }
        if dateString == yesterdayDateString { todayLabel.text = "Yesterday's List" }
        
        navigationItem.rightBarButtonItem = dateString == todayString ? nil : todayBarButton
    }
    
    func backToToday() {
        changeDate(NSDate())
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
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .Normal, title: "Delete", handler: { rowAction, indexPath in
            PrayerStore.sharedInstance.deletePrayer(self.todayPrayers[indexPath.row], inCategory: CategoryStore.sharedInstance.categoryForString(self.todayPrayers[indexPath.row].category)!)
            
            self.todayPrayers.removeAtIndex(indexPath.row)
            self.todayCount = self.todayCount - 1
            
            self.selectedPrayer = nil
            
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            tableView.endUpdates()
            
            self.noPrayersLabel.hidden = !(self.todayCount == 0)
            (tableView.headerViewForSection(1))?.textLabel!.text = self.tableView(tableView, titleForHeaderInSection: 1)
        })
        deleteAction.backgroundColor = UIColor.redColor()
        
        let answeredAction = UITableViewRowAction(style: .Normal, title: "Answered", handler: { rowAction, indexPath in
            let prayer = self.todayPrayers[indexPath.row]
            prayer.answered = true
            
            BaseStore.baseInstance.saveDatabase()
            
            self.fetchTodayPrayers()
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            tableView.endUpdates()
            
            self.noPrayersLabel.hidden = !(self.todayCount == 0)
            (tableView.headerViewForSection(1))?.textLabel!.text = self.tableView(tableView, titleForHeaderInSection: 1)
        })
        answeredAction.backgroundColor = UIColor.darkGrayColor()
        
        return [deleteAction, answeredAction]
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedPrayer = self.todayPrayers[indexPath.row]
        
        performSegueWithIdentifier(PresentPrayerDetailsSegueID, sender: self)
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel!.textColor = delegate.themeTextColor
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            //let currentDate = NSDate()
            let dateString = dateFormatter.stringFromDate(date)
            let thisDayString = dateFormatter.stringFromDate(NSDate())
            
            let tomorrowDateString = dateFormatter.stringFromDate(NSDate().dateByAddingTimeInterval(60*60*24))
            let yesterdayDateString = dateFormatter.stringFromDate(NSDate().dateByAddingTimeInterval(-60*60*24))
            
            var headerText = todayCount == 0 ? "" : (dateString == thisDayString ? "Today, \(dateString)" : "\(dateString)")
            
            if (dateString == tomorrowDateString && todayCount != 0) { headerText = "Tomorrow, \(dateString)" }
            if (dateString == yesterdayDateString && todayCount != 0) { headerText = "Yesterday, \(dateString)" }
            
            return headerText
        }
        
        return ""
    }
    
    // MARK: Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == PresentPrayerDetailsSegueID {
            let prayerDetailsVC = (segue.destinationViewController as! UINavigationController).topViewController as! PrayerDetailsViewController

            prayerDetailsVC.currentPrayer = selectedPrayer!
            prayerDetailsVC.previousViewController = self
            
        }
    }
    
    // MARK: UITextField Delegate Methods
    
    func textFieldDidBeginEditing(textField: UITextField) {
        print("Beginning to add a prayer into the textField")
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        print("Ending textField editing...")
        
        //var addedPrayerIndex: NSIndexPath? = nil
        let autoOpen = userPrefs.boolForKey("openPrayerDetailsAuto")
        
        let enteredString = textField.text!
        let modifiedString = enteredString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if (modifiedString != "") {
            print("Entered string: \(enteredString)")
            print("Adding prayer to database...")
            
            let addedPrayer = PrayerStore.sharedInstance.addPrayerToDatabase(enteredString, details: "", category: CategoryStore.sharedInstance.categoryForString("Uncategorized")!, dateCreated: NSDate())
            
            CATransaction.begin()
            CATransaction.setCompletionBlock({
                self.tableView.reloadData()
                
                self.noPrayersLabel.hidden = !(self.todayCount == 0)
            })
            tableView.beginUpdates()
            
            fetchTodayPrayers()
            
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: todayPrayers.indexOf(addedPrayer)!, inSection: 1)], withRowAnimation: .Right)
            selectedPrayer = addedPrayer
            
            tableView.endUpdates()
            
            CATransaction.commit()
        } else {
            print("String did not contain any characters at all. Not adding to prayer list...")
        }
        
        textField.text = ""
        
        if selectedPrayer != nil {
            if autoOpen == true {
                performSegueWithIdentifier(PresentPrayerDetailsSegueID, sender: self)
            }
        }
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
            let prayerID = Int32(Int((notificationInfo["prayerID"] as! String))!)
            
            let prayerNavController = storyboard.instantiateViewControllerWithIdentifier(SBPrayerDetailsNavControllerID) as! UINavigationController
            let prayerDetailsController = prayerNavController.topViewController as! PrayerDetailsViewController
            prayerDetailsController.currentPrayer = PrayerStore.sharedInstance.getPrayerForID(prayerID)!
            prayerDetailsController.previousViewController = self
            
            presentViewController(prayerNavController, animated: true, completion: nil)
        }
    }
    
}
