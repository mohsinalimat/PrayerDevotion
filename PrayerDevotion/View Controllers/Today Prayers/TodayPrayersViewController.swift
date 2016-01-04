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
import CoreData

class TodayPrayersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIViewControllerPreviewingDelegate, CoreDataStoreDelegate {
    
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
    
    var persistentStoreCoordinatorChangesObserver: NSNotificationCenter? {
        didSet {
            oldValue?.removeObserver(self, name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: CoreDataStore.sharedInstance.persistentStoreCoordinator!)
            persistentStoreCoordinatorChangesObserver?.addObserver(self, selector: "persistentStoreCoordinatorDidChangeStores:", name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: CoreDataStore.sharedInstance.persistentStoreCoordinator!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationItem.backBarButtonItem = nil
        self.navigationController?.navigationItem.hidesBackButton = true
        
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .NoStyle
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleURL:", name: "HandleURLNotification", object: nil)
        
        navigationController!.navigationBar.translucent = true
        
        todayBarButton = UIBarButtonItem(title: "Today", style: UIBarButtonItemStyle.Plain, target: self, action: "backToToday")
        
        //PrayerStore.sharedInstance.checkIDs()
        
        // Peek and Pop
        if #available(iOS 9.0, *) {
            if self.traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
                self.registerForPreviewingWithDelegate(self, sourceView: self.tableView)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setupData()
        
        if !userPrefs.boolForKey("migratedToVersion2_0") {
            fetchTodayPrayers()
            tableView.reloadData()
            
            noPrayersLabel.hidden = !(todayCount == 0)
            
            userPrefs.setBool(true, forKey: "migratedToVersion2_0")
        }
        /*fetchTodayPrayers()
        tableView.reloadData()
        
        noPrayersLabel.hidden = !(todayCount == 0)*/
        
        view.backgroundColor = delegate.themeBackgroundColor
        
        todayLabel.textColor = delegate.themeTextColor
        noPrayersLabel.textColor = delegate.themeTextColor
        prevDayButton.tintColor = delegate.themeTextColor
        nextDayButton.tintColor = delegate.themeTextColor
        
        let currentState = PrayerDevotionCloudStore.sharedInstance.currentState
        if currentState == .DataStoreOnline {
            fetchTodayPrayers()
            tableView.reloadData()
            
            noPrayersLabel.hidden = !(todayCount == 0)
        }
        
        /*CoreDataStore.sharedInstance.updateContextWithUbiquitousContentUpdates = true
        CoreDataStore.sharedInstance.delegate = self
        persistentStoreCoordinatorChangesObserver = NSNotificationCenter.defaultCenter()*/
    }
    
    func setupData() {
        NSNotificationCenter.defaultCenter().postNotificationName("LoadedNewViewController", object: nil, userInfo: ["viewController": self])
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didImportChanges:", name: DidImportChangesNotificationID, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willChangeStore:", name: WillChangeStoreNotificationID, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didChangeStore:", name: DidChangeStoreNotificationID, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let showiCloudMigrateAlert = userPrefs.boolForKey("showiCloudMigrateAlert")
        if showiCloudMigrateAlert {
            let migrateAlert = UIAlertController(title: "Migrate Data to iCloud?", message: "iCloud Support is finally here! Do you want to go ahead and migrate your data to iCloud (you must be logged in to do this)?", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "Migrate", style: .Default, handler: { alertAction in
                CoreDataStore.sharedInstance.migrateLocalStoreToiCloud()
                self.userPrefs.setBool(false, forKey: "showiCloudMigrateAlert")
            })
            let notNowAction = UIAlertAction(title: "Not Now", style: .Default, handler: nil)
            let doNotShowAgainAction = UIAlertAction(title: "Do Not Show Again", style: .Destructive, handler: { alertAction in
                self.userPrefs.setBool(false, forKey: "showiCloudMigrateAlert")
            })
            
            migrateAlert.addAction(okAction)
            migrateAlert.addAction(notNowAction)
            migrateAlert.addAction(doNotShowAgainAction)
            
            self.presentViewController(migrateAlert, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
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
        
        let fetchDate = date.toLocalTime()
        
        print("Date is \(fetchDate)")
        
        todayPrayers += PrayerStore.sharedInstance.fetchPrayersOnDate(.OnDate, prayerDate: fetchDate);
        todayPrayers += PrayerStore.sharedInstance.fetchPrayersOnDate(.Daily, prayerDate: fetchDate);
        todayPrayers += PrayerStore.sharedInstance.fetchPrayersOnDate(.Weekly, prayerDate: fetchDate);
        
        for prayer in todayPrayers {
            print("Prayer:\n\(prayer)")
            for alert in prayer.alerts {
                print("Alert:\n\(alert)")
            }
        }
        
        todayCount = todayPrayers.count
        var i = 0;
    }
    
    // MARK: IBActions
    
    @IBAction func nextDay() {
        let currentDay = date
        let newDate = currentDay.dateByAddingTimeInterval(60*60*24*1)
        
        ((self.splitViewController!.viewControllers.first as? UINavigationController)?.topViewController as? TodayCalendarViewController)?.calendarView.selectDate(newDate.toLocalTime(), scrollToDate: true)
        
        changeDate(newDate)
    }
    
    @IBAction func prevDay() {
        let currentDay = date
        let newDate = currentDay.dateByAddingTimeInterval(-60*60*24*1)
        
        ((self.splitViewController!.viewControllers.first as? UINavigationController)?.topViewController as? TodayCalendarViewController)?.calendarView.selectDate(newDate.toLocalTime(), scrollToDate: true)
        
        changeDate(newDate)
    }
    
    // Change the current date of the today view
    func changeDate(newDate: NSDate) {
        date = newDate
        
        fetchTodayPrayers()
        tableView.reloadData()
        
        noPrayersLabel.hidden = !(todayCount == 0)
        
        let currentDate = NSDate()
        
        let dateForm = NSDateFormatter()
        dateForm.dateStyle = .ShortStyle
        dateForm.timeStyle = .NoStyle
        
        let dateString = dateForm.stringFromDate(newDate)
        let todayString = dateForm.stringFromDate(currentDate)
        todayLabel.text = dateString == todayString ? "Today List" : "\(dateString) List"
        
        let tomorrowDateString = dateForm.stringFromDate(currentDate.dateByAddingTimeInterval(60*60*24))
        let yesterdayDateString = dateForm.stringFromDate(currentDate.dateByAddingTimeInterval(-60*60*24))
        
        print("Today String: \(dateString)")
        print("Tomorrow String: \(tomorrowDateString)")
        print("Yesterday String:\(yesterdayDateString)")
        
        if dateString == tomorrowDateString { todayLabel.text = "Tomorrow's List" }
        if dateString == yesterdayDateString { todayLabel.text = "Yesterday's List" }
        
        navigationItem.rightBarButtonItem = dateString == todayString ? nil : todayBarButton
    }
    
    func backToToday() {
        changeDate(NSDate())
        
        ((self.splitViewController!.viewControllers.first as? UINavigationController)?.topViewController as? TodayCalendarViewController)?.calendarView.selectDate(NSDate().toLocalTime(), scrollToDate: true)
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
        print("Index Path Row: \(indexPath.row)")
        
        for prayer in todayPrayers {
            print("today: \(prayer)")
        }
        
        selectedPrayer = self.todayPrayers[indexPath.row]
        print("Selected Prayer: \(selectedPrayer)")
        
        performSegueWithIdentifier(PresentPrayerDetailsSegueID, sender: self)
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel!.textColor = delegate.themeTextColor
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            //let currentDate = NSDate()
            let currentDate = NSDate()
            let dateString = dateFormatter.stringFromDate(date)
            let thisDayString = dateFormatter.stringFromDate(currentDate)
            
            let tomorrowDateString = dateFormatter.stringFromDate(currentDate.dateByAddingTimeInterval(60*60*24))
            let yesterdayDateString = dateFormatter.stringFromDate(currentDate.dateByAddingTimeInterval(-60*60*24))
            
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
    
    // MARK: UIViewControllerPreviewing Delegate Methods
    
    @available(iOS 9.0, *)
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let indexPath = tableView.indexPathForRowAtPoint(location)
        
        if let indexPath = indexPath {
            let prayer = todayPrayers[indexPath.row]
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? TodayPrayerCell
            
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
    
    // MARK: TodayCalendarViewController Delegate Methods
    
    /*func didSelectNewDate(date: NSDate) {
        changeDate(date)
    }*/
    
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
    
    // MARK: iCloud
    
    func persistentStoreCoordinatorDidChangeStores(notification: NSNotification) {
        print("Coordinator Did Change Store")
        fetchTodayPrayers()
        self.tableView.reloadData()
    }
    
    func didMergeUbiquitousChanges() {
        print("New Changes Merged")
        fetchTodayPrayers()
        self.tableView.reloadData()
        
        noPrayersLabel.hidden = !(todayCount == 0)
        
        view.backgroundColor = delegate.themeBackgroundColor
        
        todayLabel.textColor = delegate.themeTextColor
        noPrayersLabel.textColor = delegate.themeTextColor
        prevDayButton.tintColor = delegate.themeTextColor
        nextDayButton.tintColor = delegate.themeTextColor
    }
    
    // MARK: CoreDataManager Store Notifications
        
    func didImportChanges(notification: NSNotification) {
        print("TodayPrayerViewController DidImportChanges: called")
        
        self.fetchTodayPrayers()
        self.tableView.reloadData()
    }
    
    func willChangeStore(notification: NSNotification) {
        print("TodayPrayersViewController WillChangeStore: called")
    }
    
    func didChangeStore(notification: NSNotification) {
        //dispatch_async(dispatch_get_main_queue(), {
            print("TodayPrayersViewController DidChangeStore: called")
        
            self.fetchTodayPrayers()
            self.tableView.reloadData()
        
            for prayer in todayPrayers {
                print("Today Prayer: \(prayer)")
            }
            
            self.noPrayersLabel.hidden = !(self.todayCount == 0)
            
            self.view.backgroundColor = self.delegate.themeBackgroundColor
            
            self.todayLabel.textColor = self.delegate.themeTextColor
            self.noPrayersLabel.textColor = self.delegate.themeTextColor
            self.prevDayButton.tintColor = self.delegate.themeTextColor
            self.nextDayButton.tintColor = self.delegate.themeTextColor
            print("Finished Syncing")
        //3})
    }
}
