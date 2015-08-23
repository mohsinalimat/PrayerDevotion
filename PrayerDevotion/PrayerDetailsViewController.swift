//
//  PrayerDetailsViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/7/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import PDKit
import MessageUI
import AddressBook
import AddressBookUI

class PrayerDetailsViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, MFMailComposeViewControllerDelegate, ABPeoplePickerNavigationControllerDelegate {
    
    @IBOutlet var navItem: UINavigationItem!
    
    var previousViewController: UIViewController? = nil
    
    var allCategories = [String]()
    
    var currentPrayer: PDPrayer! // This is the prayer that the user is currently editing
    var prayerAlerts: NSMutableOrderedSet! // This is the mutable set of the prayer alerts that are included in the prayer
    var prayerAlertsCount: Int!
    var addedDate: NSDate? // This is the added date of the prayer... Dunno what it is used for actually
    
    var unwindToToday: Bool = false
    var unwindToSearch: Bool = false
    
    var cellForRowRefreshCount = 0
    
    var isChangingCategory: Bool = false
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    // Contacts
    var addressBook: ABAddressBook? = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
    var categoryPickerView: UIPickerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //addressBook = ABAddressBookCreateWithOptions(nil, nil).takeRetainedValue()
        
        CategoryStore.sharedInstance.fetchCategoriesData(NSPredicate(format: "name != %@", "Uncategorized"), sortKey: "name", ascending: true)
        
        for item in CategoryStore.sharedInstance.allCategories() {
            allCategories.append(item.name)
        }
        
        if currentPrayer == nil {
            NSException(name: "PrayerException", reason: "Current Prayer is nil! Unable to show prayer details!", userInfo: nil).raise()
        }
        
        navItem.title = currentPrayer.name // Sets the Nav Bar title to the current prayer name
        prayerAlerts = currentPrayer.alerts.mutableCopy() as! NSMutableOrderedSet // This passes the currentPrayer alerts to a copy called prayerAlerts
        prayerAlertsCount = prayerAlerts.count + 1
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleURL:", name: "HandleURLNotification", object: nil)
        
        tableView.estimatedRowHeight = 44.0
        
        navigationController!.toolbarHidden = false
        
        let shareItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "openActionItems:")
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
        toolbarItems = [shareItem]
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController!.navigationBar.tintColor = delegate.themeTintColor
        tableView.backgroundColor = delegate.themeBackgroundColor
        tableView.separatorColor = delegate.themeBackgroundColor
        
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: UITableView Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return currentPrayer.answered == true ? 6 : 7
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return isChangingCategory == true ? 3 : 2
        case 1: return 1
        case 2: return 1
        case 3: return currentPrayer.answered == true ? 2 : 1
        case 4: return 1
        case 5: return prayerAlertsCount
        case 6: return 1
        default: return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        cellForRowRefreshCount += 1
        
        var doneToolbar = UIToolbar()
        doneToolbar.barStyle = .Default
        
        var doneAction = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: "textEndEditing:")
        doneAction.tintColor = UIColor.blackColor()
        var flexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        doneToolbar.items = [flexSpace, doneAction]
        
        doneToolbar.sizeToFit()
        
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                var cell = tableView.dequeueReusableCellWithIdentifier(EnterPrayerNameCellID, forIndexPath: indexPath) as! PrayerNameCell
                cell.nameField.delegate = self
                cell.nameField.text = currentPrayer.name
                cell.nameField.inputAccessoryView = doneToolbar
            
                return cell
            } else if indexPath.row == 1 {
                var cell = tableView.dequeueReusableCellWithIdentifier(PrayerCategoryCellID, forIndexPath: indexPath) as! PrayerCategoryCell
                cell.prayerCategoryLabel.text = "Prayer in Category \(currentPrayer.category)"
                cell.changeCategoryButton.addTarget(self, action: "changeCategory:", forControlEvents: .TouchDown)
                
                return cell
            } else {
                var cell = tableView.dequeueReusableCellWithIdentifier(ChangeCategoryCellID, forIndexPath: indexPath) as! UITableViewCell
                
                let pickerView = cell.viewWithTag(1) as! UIPickerView
                pickerView.delegate = self
                pickerView.dataSource = self
                pickerView.frame.size.height = 162
                self.categoryPickerView = pickerView
                
                let categoryIdx = currentPrayer.category == "Uncategorized" ? 0 : find(allCategories, currentPrayer.category)! + 1
                
                pickerView.selectRow(categoryIdx, inComponent: 0, animated: false)
                
                (cell.viewWithTag(2) as! UIButton).addTarget(self, action: "createCategory:", forControlEvents: .TouchDown)
                
                return cell
            }
            
        case 1:
            var cell = tableView.dequeueReusableCellWithIdentifier(DetailsExtendedCellID, forIndexPath: indexPath) as! PrayerDetailsExtendedCell
            cell.currentPrayer = currentPrayer
            cell.detailsTextView.inputAccessoryView = doneToolbar
            cell.refreshCell()
            
            return cell
            
        case 2:
            var cell = tableView.dequeueReusableCellWithIdentifier(PriorityCellID, forIndexPath: indexPath) as! PrayerPriorityCell
            cell.selectionStyle = .None
            cell.currentPrayer = currentPrayer
            cell.segmentedControl.selectedSegmentIndex = Int(currentPrayer.priority)
            
            return cell
            
        case 3:
            if indexPath.row == 0 {
                var cell = tableView.dequeueReusableCellWithIdentifier(AnsweredPrayerCellID, forIndexPath: indexPath) as! PrayerAnsweredCell
                cell.accessoryType = currentPrayer.answered == true ? .Checkmark : .None
                cell.answeredLabel.text = currentPrayer.answered == true ? "Prayer is Answered" : "Prayer is Unanswered"
                cell.color = delegate.themeTintColor
            
                return cell
            } else {
                var cell = tableView.dequeueReusableCellWithIdentifier(AnsweredPrayerNotesCellID, forIndexPath: indexPath) as! PrayerAnsweredNoteCell
                cell.currentPrayer = currentPrayer
                cell.answeredNotesView.inputAccessoryView = doneToolbar
                cell.refreshCell()
                
                return cell
            }
            
        case 4:
            var cell = tableView.dequeueReusableCellWithIdentifier(SetPrayerDateCellID, forIndexPath: indexPath) as! AddPrayerDateCell
            
            cell.currentPrayer = currentPrayer
            cell.addDateLabel.textColor = delegate.themeTintColor
            cell.refreshCell(false, selectedPrayer: cell.currentPrayer)
            
            return cell
            
        case 5:
            if currentPrayer.answered == false {
                if indexPath.row == prayerAlerts.count {
                    var cell = tableView.dequeueReusableCellWithIdentifier(AddNewAlertCellID, forIndexPath: indexPath) as! AddPrayerAlertCell
                
                    cell.currentPrayer = self.currentPrayer
                    cell.addNewAlertLabel.textColor = delegate.themeTintColor
                    cell.refreshCell(false, selectedPrayer: self.currentPrayer)
                    cell.saveButton.addTarget(self, action: "didSaveNewAlert", forControlEvents: .TouchDown)
                
                    return cell
                } else {
                    var cell = tableView.dequeueReusableCellWithIdentifier(PrayerAlertCellID, forIndexPath: indexPath) as! PrayerAlertCell
                
                    let currentAlert = self.prayerAlerts[indexPath.row] as! PDAlert
                    cell.alertLabel.text = AlertStore.sharedInstance.convertDateToString(currentAlert.alertDate)
                
                    return cell
                }
            } else {
                var cell = tableView.dequeueReusableCellWithIdentifier(PrayerLocationCellID, forIndexPath: indexPath) as! UITableViewCell
                
                var locationLabel = cell.viewWithTag(1) as! UILabel
                locationLabel.text = "Assign Location"
                
                return cell
            }
            
        case 6:
            var cell = tableView.dequeueReusableCellWithIdentifier(PrayerLocationCellID, forIndexPath: indexPath) as! UITableViewCell
            
            var locationLabel = cell.viewWithTag(1) as! UILabel
            
            if let previousVC = previousViewController {
                if previousVC is LocationPrayersViewController {
                    locationLabel.textColor = UIColor.lightGrayColor()
                    cell.selectionStyle = .None
                } else {
                    locationLabel.textColor = delegate.themeTintColor
                    cell.selectionStyle = .Default
                }
            }
            
            if let location = currentPrayer.location {
                locationLabel.text = "\(location.locationName)"
            } else {
                locationLabel.text = "Assign Location"
            }
            
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func textEndEditing(sender: AnyObject) {
        view.endEditing(true)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 || indexPath.section == 2 || (indexPath.section == 3 && indexPath.row == 1) || indexPath.section == 5 && indexPath.row < prayerAlerts.count { return }
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! PrayerNameCell
            cell.nameField.becomeFirstResponder()
        }
        
        if indexPath.section == 3 {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! PrayerAnsweredCell
            currentPrayer.answered = !currentPrayer.answered
            cell.accessoryType = currentPrayer.answered == true ? .Checkmark : .None
            cell.answeredLabel.text = currentPrayer.answered == true ? "Prayer is Answered" : "Prayer is Unanswered"
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
            CATransaction.begin()
            CATransaction.setCompletionBlock({
                tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.currentPrayer.answered == true ? 1 : 0, inSection: 3), atScrollPosition: .Bottom, animated: true)
            })
            tableView.beginUpdates()
            
            if currentPrayer.answered == true {
                currentPrayer.prayerType = "None"
                currentPrayer.isDateAdded = false
                tableView.deleteSections(NSIndexSet(index: 5), withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: 3)], withRowAnimation: .Fade)
                
                AlertStore.sharedInstance.deleteAllAlertsForPrayer(currentPrayer)
            } else {
                currentPrayer.prayerType = "Daily"
                currentPrayer.isDateAdded = true
                tableView.insertSections(NSIndexSet(index: 5), withRowAnimation: .Fade)
                tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: 3)], withRowAnimation: .Fade)
                currentPrayer.answeredNotes = ""
            }
            
            prayerAlerts = currentPrayer.alerts.mutableCopy() as! NSMutableOrderedSet
            prayerAlertsCount = prayerAlerts.count + 1
            
            var dateCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 4)) as? AddPrayerDateCell
            var alertCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: prayerAlerts.count, inSection: 5)) as? AddPrayerAlertCell // This must be optional because it may not have been created yet
            
            dateCell?.refreshCell(false, selectedPrayer: currentPrayer)
            alertCell?.refreshCell(false, selectedPrayer: currentPrayer)
                        tableView.endUpdates()
            
            tableView.estimatedRowHeight = 44.0
        }
        
        if indexPath.section == 4 {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! AddPrayerDateCell
            tableView.beginUpdates()
            cell.refreshCell(true, selectedPrayer: currentPrayer)
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            tableView.endUpdates()
        }
        
        if indexPath.section == 5 && indexPath.row == prayerAlerts.count {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! AddPrayerAlertCell
            tableView.beginUpdates()
            cell.refreshCell(true, selectedPrayer: currentPrayer)
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            tableView.endUpdates()
        }
        
        if indexPath.section == 6 {
            if let previousVC = previousViewController {
                if previousVC is LocationPrayersViewController {
                    println("Cannot change location while viewing from location")
                    return
                }
            }
            
            println("Assigning location - does not require auth to user location")
            
            let createLocationVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(SBCreateLocationViewControllerID) as! UINavigationController
            (createLocationVC.topViewController as! CreateLocationViewController).selectedPrayer = self.currentPrayer
            presentViewController(createLocationVC, animated: true, completion: nil)
        }
        
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                return 44
            } else if indexPath.row == 1 {
                return 30
            } else {
                return 207
            }
            
        case 1: return UITableViewAutomaticDimension
        case 2: return 30
        case 3: return indexPath.row == 0 ? 44 : UITableViewAutomaticDimension
            
        case 4:
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? AddPrayerDateCell
            
            if let thisCell = cell {
                let isAdding = thisCell.isAddingDate
            
                if isAdding {
                    if thisCell.selectedType == PrayerType.None || thisCell.selectedType == PrayerType.Daily {
                        return 89
                    } else {
                        return 309
                    }
                } else {
                    return 44
                }
            } else {
                return 44
            }
            
        case 5:
            if indexPath.row == prayerAlerts.count {
                let cell = tableView.cellForRowAtIndexPath(indexPath) as? AddPrayerAlertCell
                
                if let thisCell = cell {
                    let isAdding = thisCell.isAddingAlert
                
                    if isAdding { return 309 }; return 44
                } else {
                    return 44
                }
            } else {
                return 44
            }
            
        default: return 44
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Prayer Name"
        case 1: return "Extended Details"
        case 3: return ""
        case 5: return "Alerts"
        case 6: return "Location"
        default: return ""
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 5 && indexPath.row < prayerAlerts.count { return true }
        
        return false
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            AlertStore.sharedInstance.deleteAlert(prayerAlerts[indexPath.row] as! PDAlert, inPrayer: currentPrayer)
            prayerAlerts = currentPrayer.alerts.mutableCopy() as! NSMutableOrderedSet
            prayerAlertsCount = prayerAlertsCount - 1
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            
        default: break
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.contentView.clipsToBounds = true
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        var headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel.textColor = delegate.themeTextColor
    }
        
    // MARK: Scroll View Methods
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        let detailsCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as? PrayerDetailsExtendedCell
        let answeredDetailsCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 3)) as? PrayerAnsweredNoteCell
        
        detailsCell?.detailsTextView.endEditing(true)
        answeredDetailsCell?.answeredNotesView.endEditing(true)
    }
    
    // MARK: Cell Saving Methods
    
    func didSaveNewAlert() {
        let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: prayerAlerts.count, inSection: 5)) as! AddPrayerAlertCell
        
        let dateToAdd = cell.datePicker.date
        AlertStore.sharedInstance.createAlert(currentPrayer, inCategory: currentPrayer.category, withDate: dateToAdd)
        prayerAlerts = currentPrayer.alerts.mutableCopy() as! NSMutableOrderedSet
        prayerAlertsCount = prayerAlertsCount + 1
        
        tableView.beginUpdates()
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: currentPrayer.alerts.count - 1, inSection: 5)], withRowAnimation: .Right)
        cell.selectionStyle = .Default
        
        cell.refreshCell(false, selectedPrayer: currentPrayer)
        tableView.endUpdates()
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: prayerAlerts.count, inSection: 5), atScrollPosition: .Bottom, animated: true)
    }
    
    // MARK: Prayers
    
    @IBAction func savePrayer(sender: AnyObject) {
        if unwindToSearch == true {
            NSNotificationCenter.defaultCenter().postNotificationName("ReloadSearchPrayers", object: nil)
        } else if unwindToToday == true {
            NSNotificationCenter.defaultCenter().postNotificationName("ReloadTodayPrayers", object: nil)
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName("ReloadPrayers", object: nil)
        }
        
        if currentPrayer.isDateAdded == false {
            currentPrayer.prayerType = "None"
        }
        BaseStore.baseInstance.saveDatabase()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: UITextField Methods
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        let name = textField.text
        let trimmedName = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if trimmedName == "" {
            var alert = UIAlertController(title: "Error", message: "Prayer Name must have some text", preferredStyle: .Alert)
            
            var okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(okAction)
            
            presentViewController(alert, animated: true, completion: nil)
    
            textField.text = currentPrayer.name
        } else {
            currentPrayer.name = name
            navItem.title = name
        }
    }
    
    // MARK: Notifications
    
    func handleURL(notification: NSNotification) {
        if let viewController = previousViewController {
            let notificationInfo = notification.userInfo!
            let command = notificationInfo["command"] as! String
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if command == "open-today" {
                dismissViewControllerAnimated(true) {
                    (UIApplication.sharedApplication().delegate as! AppDelegate).switchTabBarToTab(0)
                }
            } else if command == "open-prayer" {
                let prayerID = Int32((notificationInfo["prayerID"] as! String).toInt()!)
                if self.currentPrayer.prayerID != prayerID {
                    dismissViewControllerAnimated(true) {
                        let prayerNavController = storyboard.instantiateViewControllerWithIdentifier(SBPrayerDetailsNavControllerID) as! UINavigationController
                        let prayerDetailsController = prayerNavController.topViewController as! PrayerDetailsViewController
                        prayerDetailsController.currentPrayer = PrayerStore.sharedInstance.getPrayerForID(prayerID)!
                        prayerDetailsController.previousViewController = viewController
                
                        viewController.presentViewController(prayerNavController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    // MARK: PickerView Methods
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return allCategories.count + 1
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        if row == 0 { return "Uncategorized" }
        else { return allCategories[row - 1] }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let rowTitle = self.pickerView(pickerView, titleForRow: row, forComponent: component)
        
        currentPrayer.category = rowTitle
        tableView.reloadData()
    }
    
    // MARK: MFMailViewController Methods
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        switch result.value {
        case MFMailComposeResultCancelled.value:
            println("Mail Compose Cancelled")
            
        case MFMailComposeResultFailed.value:
            println("Mail Compose Failed: \(error), \(error?.userInfo)")
            
        case MFMailComposeResultSaved.value:
            println("Mail Compose Saved")
            
        case MFMailComposeResultSent.value:
            println("Mail Successfully Sent!")
            
        default: break
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Contacts
    
    func promptForAddressBookRequestAccess(sender: AnyObject) {
        var error: Unmanaged<CFError>? = nil
        
        ABAddressBookRequestAccessWithCompletion(addressBook) {
            (granted: Bool, error: CFError!) in
            dispatch_async(dispatch_get_main_queue()) {
                if !granted {
                    println("Just denied")
                    self.displayUnableToAddContactAlert()
                } else {
                    println("Just authorized")
                }
            }
        }
    }
    
    func openSettings() {
        let settingsURL = NSURL(string: UIApplicationOpenSettingsURLString)
        UIApplication.sharedApplication().openURL(settingsURL!)
    }
    
    func displayUnableToAddContactAlert() {
        let alert = UIAlertController(title: "Cannot Assign Contact", message: "You must give the app permission to add the contact first", preferredStyle: .Alert)
        
        let action = UIAlertAction(title: "Open Settings", style: .Default, handler: { alertAction in
            self.openSettings()
        })
        alert.addAction(action)
        
        let cancelAction = UIAlertAction(title: "Close", style: .Cancel, handler: nil)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func handleContactPicker() {
        let allContacts = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue()
        
        let peoplePicker = ABPeoplePickerNavigationController()
        peoplePicker.peoplePickerDelegate = self
        peoplePicker.displayedProperties = [NSNumber(int: kABPersonEmailProperty)]
        
        if peoplePicker.respondsToSelector(Selector("predicateForEnablingPerson")) {
            peoplePicker.predicateForEnablingPerson = NSPredicate(format: "emailAddresses.@count > 0")
        }
        
        presentViewController(peoplePicker, animated: true, completion: nil)
    }
    
    // MARK: People Picker Methods
    
    func peoplePickerNavigationController(peoplePicker: ABPeoplePickerNavigationController!, didSelectPerson person: ABRecord!, property: ABPropertyID, identifier: ABMultiValueIdentifier) {
        let multiValue: ABMultiValueRef = ABRecordCopyValue(person, property).takeRetainedValue()
        let index = ABMultiValueGetIndexForIdentifier(multiValue, identifier)
        let email = ABMultiValueCopyValueAtIndex(multiValue, index).takeRetainedValue() as! String
        
        println("email = \(email)")
        
        currentPrayer.assignedEmail = email
        BaseStore.baseInstance.saveDatabase()
        
        peoplePicker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func peoplePickerNavigationControllerDidCancel(peoplePicker: ABPeoplePickerNavigationController!) {
        let p = peoplePicker.presentingViewController!
        p.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Custom Functions
    
    func changeCategory(sender: UIButton) {
        isChangingCategory = !isChangingCategory
        sender.setTitle(isChangingCategory == true ? "Done" : "Change", forState: .Normal)
        
        tableView.beginUpdates()
        if isChangingCategory {
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 2, inSection: 0)], withRowAnimation: .Top)
        } else {
            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: 2, inSection: 0)], withRowAnimation: .Top)
        }
        tableView.endUpdates()
        
        let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! PrayerCategoryCell
        cell.prayerCategoryLabel.text = "Prayer in Category \(currentPrayer.category)"
    }
    
    func createCategory(sender: UIButton) {
        var alertController = UIAlertController(title: "Create New Personal Category", message: "Enter a name below and press Create to create a new personal category", preferredStyle: .Alert)
        
        var cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        var createAction = UIAlertAction(title: "Create", style: .Default, handler: { alertAction in
            let textField = alertController.textFields![0] as! UITextField
            let categoryName = textField.text
            
            if CategoryStore.sharedInstance.categoryExists(categoryName) == false {
                CategoryStore.sharedInstance.addCategoryToDatabase(categoryName, dateCreated: NSDate())
                
                CategoryStore.sharedInstance.fetchCategoriesData(NSPredicate(format: "name != %@", "Uncategorized"), sortKey: "name", ascending: true)
                
                self.allCategories = [String]()
                for item in CategoryStore.sharedInstance.allCategories() {
                    self.allCategories.append(item.name)
                }
                
                let index = find(self.allCategories, categoryName)! + 1
                
                self.categoryPickerView!.reloadAllComponents()
                self.categoryPickerView!.selectRow(index, inComponent: 0, animated: true)
                
                self.currentPrayer.category = categoryName
                let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! PrayerCategoryCell
                cell.prayerCategoryLabel.text = "Prayer in Category \(self.currentPrayer.category)"
            } else {
                var errorAlert = UIAlertController(title: "Unable to Create Category", message: "There is already a category with the name \"\(categoryName)\". Do you want to select this category?", preferredStyle: .Alert)
                var yesAction = UIAlertAction(title: "Yes", style: .Default, handler: { alertAction in
                    let index = categoryName == "Uncategorized" ? 0 : find(self.allCategories, categoryName)! + 1
                    
                    self.categoryPickerView!.selectRow(index, inComponent: 0, animated: true)
                    self.currentPrayer.category = categoryName
                    
                    let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! PrayerCategoryCell
                    cell.prayerCategoryLabel.text = "Prayer in Category \(self.currentPrayer.category)"
                })
                var noAction = UIAlertAction(title: "No", style: .Cancel, handler: nil)
                errorAlert.addAction(noAction)
                errorAlert.addAction(yesAction)
                
                self.presentViewController(errorAlert, animated: true, completion: nil)
            }
        })
        createAction.enabled = false
        
        alertController.addTextFieldWithConfigurationHandler({ textField in
            textField.placeholder = "Enter Category Name..."
            textField.autocapitalizationType = .Words
            
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue(), usingBlock: { notification in
                createAction.enabled = textField.text != ""
            })
        })
        
        alertController.addAction(createAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func openActionItems(sender: AnyObject) {
        let actionSheet = UIAlertController(title: "Other Actions", message: currentPrayer.assignedEmail == nil ? nil : "Email: \(currentPrayer.assignedEmail!)", preferredStyle: .ActionSheet)
        
        let title = currentPrayer.assignedEmail == nil ? "Assign Contact Email" : "Remove Contact Email"
        
        let assignContactAction = UIAlertAction(title: title, style: .Default, handler: { alertAction in
            if self.currentPrayer.assignedEmail != nil {
                self.currentPrayer.assignedEmail = nil
            } else {
                let alert = UIAlertController(title: "Add Email Address", message: "Type in user email address or choose email from contact", preferredStyle: .Alert)
            
                let addAction = UIAlertAction(title: "Add Email", style: .Default, handler: { alertAction in
                    let textField = alert.textFields!.first as! UITextField
                
                    let email = textField.text
                    
                    self.currentPrayer.assignedEmail = email
                    BaseStore.baseInstance.saveDatabase()
                })
                
                alert.addAction(addAction)
                addAction.enabled = false
            
                alert.addTextFieldWithConfigurationHandler({ textField in
                    textField.placeholder = "Enter Email..."
                
                    NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue(), usingBlock: { (notification) in
                        addAction.enabled = self.checkEmail(textField.text) == true
                    })
                })
                
                let chooseContactAction = UIAlertAction(title: "Use Contact", style: .Default, handler: { alertAction in
                    let authorization = ABAddressBookGetAuthorizationStatus()
                    
                    switch authorization {
                    case .Denied, .Restricted:
                        println("User has denied or restricted access to contacts")
                        self.displayUnableToAddContactAlert()
                        
                    case .Authorized:
                        println("User has authorized access to contacts")
                        self.handleContactPicker()
                        
                    case .NotDetermined:
                        println("User has not chosen to authorize/not authorize access to contacts")
                        self.promptForAddressBookRequestAccess(alertAction)
                    }
                    
                })
                alert.addAction(chooseContactAction)
            
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                alert.addAction(cancelAction)
            
                self.presentViewController(alert, animated: true, completion: nil)
            }
        })
        actionSheet.addAction(assignContactAction)
        
        let encouragementAction = UIAlertAction(title: "Send Encouraging Note", style: .Default, handler: { alertAction in
            
            let toEmail = self.currentPrayer.assignedEmail == nil ? "" : self.currentPrayer.assignedEmail!
            
            let mailController = MFMailComposeViewController()
            mailController.mailComposeDelegate = self
            mailController.setToRecipients([toEmail])
            mailController.setSubject("")
            mailController.setMessageBody("", isHTML: false)
            
            self.presentViewController(mailController, animated: true, completion: nil)
        })
        actionSheet.addAction(encouragementAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    func checkEmail(email: String) -> Bool {
        let regExp = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        var emailTest = NSPredicate(format: "SELF MATCHES %@", regExp)
        var result = emailTest.evaluateWithObject(email)
        
        return result
    }
}
