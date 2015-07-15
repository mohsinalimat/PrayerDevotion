//
//  PrayerDetailsViewController_New.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/7/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import PDKit

let EnterPrayerNameCellID = "EnterPrayerNameCellID"
let DetailsExtendedCellID = "DetailsExtendedCellID"
let PrayerAlertCellID = "PrayerAlertCellID"
let AddNewAlertCellID = "AddNewAlertCellID"
let AnsweredPrayerCellID = "AnsweredPrayerCellID"
let AnsweredPrayerNotesCellID = "AnsweredPrayerNotesCellID"
let SetPrayerDateCellID = "SetPrayerDateCellID"
let PriorityCellID = "PriorityCellID"

class PrayerDetailsViewController_New: UITableViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    var currentPrayer: PDPrayer! // This is the prayer that the user is currently editing
    var prayerAlerts: NSMutableOrderedSet! // This is the mutable set of the prayer alerts that are included in the prayer
    var prayerAlertsCount: Int!
    var addedDate: NSDate? // This is the added date of the prayer... Dunno what it is used for actually
    
    var unwindToToday: Bool = false
    var unwindToSearch: Bool = false
    
    var cellForRowRefreshCount = 0
    
    @IBOutlet var navItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if currentPrayer == nil {
            NSException(name: "PrayerException", reason: "Current Prayer is nil! Unable to show prayer details!", userInfo: nil).raise()
        }
        
        navItem.title = currentPrayer.name // Sets the Nav Bar title to the current prayer name
        prayerAlerts = currentPrayer.alerts.mutableCopy() as! NSMutableOrderedSet // This passes the currentPrayer alerts to a copy called prayerAlerts
        prayerAlertsCount = prayerAlerts.count + 1
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: UITableView Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 6
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return 1
        case 3: return 1
        case 4: return 1
        case 5: return prayerAlertsCount
        default: return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        cellForRowRefreshCount += 1
        
        switch indexPath.section {
        case 0:
            var cell = tableView.dequeueReusableCellWithIdentifier(EnterPrayerNameCellID, forIndexPath: indexPath) as! PrayerNameCell
            cell.nameField.delegate = self
            cell.nameField.text = currentPrayer.name
            
            return cell
            
        case 1:
            var cell = tableView.dequeueReusableCellWithIdentifier(DetailsExtendedCellID, forIndexPath: indexPath) as! PrayerDetailsExtendedCell
            cell.currentPrayer = currentPrayer
            cell.refreshCell()
            
            return cell
            
        case 2:
            var cell = tableView.dequeueReusableCellWithIdentifier(PriorityCellID, forIndexPath: indexPath) as! PrayerPriorityCell
            cell.selectionStyle = .None
            cell.currentPrayer = currentPrayer
            cell.segmentedControl.selectedSegmentIndex = Int(currentPrayer.priority)
            
            return cell
            
        case 3:
            var cell = tableView.dequeueReusableCellWithIdentifier(AnsweredPrayerCellID, forIndexPath: indexPath) as! PrayerAnsweredCell
            cell.accessoryType = currentPrayer.answered == true ? .Checkmark : .None
            cell.answeredLabel.text = currentPrayer.answered == true ? "Prayer is Answered" : "Prayer is Unanswered"
            
            return cell
            
        case 4:
            var cell = tableView.dequeueReusableCellWithIdentifier(SetPrayerDateCellID, forIndexPath: indexPath) as! AddPrayerDateCell
            
            cell.currentPrayer = currentPrayer
            cell.refreshCell(false, selectedPrayer: cell.currentPrayer)
            
            return cell
            
        case 5:
            if indexPath.row == prayerAlerts.count {
                var cell = tableView.dequeueReusableCellWithIdentifier(AddNewAlertCellID, forIndexPath: indexPath) as! AddPrayerAlertCell
                cell.currentPrayer = currentPrayer
                cell.refreshCell(false, selectedPrayer: currentPrayer)
                cell.saveButton.addTarget(self, action: "didSaveNewAlert", forControlEvents: .TouchDown)
                
                return cell
            } else {
                var cell = tableView.dequeueReusableCellWithIdentifier(PrayerAlertCellID, forIndexPath: indexPath) as! PrayerAlertCell
                
                let currentAlert = prayerAlerts[indexPath.row] as! PDAlert
                cell.alertLabel.text = AlertStore.sharedInstance.convertDateToString(currentAlert.alertDate)
                
                return cell
            }
            
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 || indexPath.section == 2 || indexPath.section == 5 && indexPath.row < prayerAlerts.count { return }
        
        if indexPath.section == 0 {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! PrayerNameCell
            cell.nameField.becomeFirstResponder()
        }
        
        if indexPath.section == 3 {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! PrayerAnsweredCell
            currentPrayer.answered = !currentPrayer.answered
            cell.accessoryType = currentPrayer.answered == true ? .Checkmark : .None
            cell.answeredLabel.text = currentPrayer.answered == true ? "Prayer is Answered" : "Prayer is Unanswered"
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
            tableView.beginUpdates()
            var dateCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 4)) as! AddPrayerDateCell
            var alertCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: prayerAlerts.count, inSection: 5)) as? AddPrayerAlertCell // This must be optional because it may not have been created yet
            
            dateCell.refreshCell(false, selectedPrayer: currentPrayer)
            alertCell?.refreshCell(false, selectedPrayer: currentPrayer)
            tableView.endUpdates()
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
        
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 44
        case 1: return UITableViewAutomaticDimension
        case 2: return 30
        case 3: return 44
            
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
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 1: return 130
        default: return 44
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Prayer Name"
        case 1: return "Extended Details"
        case 2: return "Priority"
        case 3: return ""
        case 4: return "Prayer Date"
        case 5: return "Alerts"
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
        
        headerView.textLabel.textColor = UIColor.whiteColor()
    }
        
    // MARK: Scroll View Methods
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        let detailsCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as! PrayerDetailsExtendedCell
        
        detailsCell.detailsTextView.endEditing(true)
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
}
