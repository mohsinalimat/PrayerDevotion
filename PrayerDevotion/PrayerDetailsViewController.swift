//
//  PrayerDetailsViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 5/31/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import PDKit

class PrayerDetailsViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    var currentPrayer: PDPrayer!
    var prayerAlerts: NSMutableOrderedSet!
    
    // This is the added date to the prayer
    var addedDate: NSDate?
        
    @IBOutlet var navItem: UINavigationItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(currentPrayer != nil, "Current Prayer is NIL!!!")
        
        navItem?.title = currentPrayer.name
        
        prayerAlerts = currentPrayer.alerts.mutableCopy() as! NSMutableOrderedSet
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: TableView Methods
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 || (indexPath.section == 3 && indexPath.row == 1) {
            return 130
        }
        
        return 44
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 || (indexPath.section == 3 && indexPath.row == 1) {
            return UITableViewAutomaticDimension
        } else if indexPath.section == 1 {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? AddPrayerDateCell
            
            if let dateCell = cell {
                if dateCell.isAddingDate {
                    if dateCell.selectedType == .None || dateCell.selectedType == .Daily {
                        return 84
                    } else {
                        return 309
                    }
                } else {
                    return 44
                }
            }
        } else if indexPath.section == 2 && indexPath.row != prayerAlerts.count {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? PrayerAlertCell
            
            if let alertCell = cell {
                return alertCell.isEditingAlert ? 260 : 44
            }
        } else if indexPath.section == 2 && indexPath.row == prayerAlerts.count {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? AddPrayerAlertCell
            
            if let addCell = cell {
                if addCell.isAddingAlert {
                    return 309
                }
            }
        }
        
        return 44
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        var headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel.textColor = UIColor.whiteColor()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // IndexPath sections: 0 = Prayer Details, 1 = Prayer Dates, 2 = Prayer Alerts, 3 = Prayer Answered
        // IndexPath rows: s0r0 = Prayer Details, s1r1 = Prayer Date, s2r? = Prayer Alerts, s2rLast = Add New Alert Cell, s3r0 = Answered Switch, s3r1 (sometimes hidden) = Answered notes
        if indexPath.section == 0 {
            var cell = tableView.dequeueReusableCellWithIdentifier(DetailsExtendedCellID, forIndexPath: indexPath) as! PrayerDetailsExtendedCell
        
            // Set the cell's prayer to the current prayer (for saving/fetching data)
            cell.currentPrayer = currentPrayer
            
            // If there is no text in the view, create placeholder-like text that is light gray to
            // show the user that they can enter additional prayer details
            if currentPrayer.details == "" {
                cell.detailsTextView.text = "Enter Additional Prayer Details..."
                cell.detailsTextView.textColor = UIColor.lightGrayColor()
            } else {
                cell.detailsTextView.textColor = UIColor.blackColor()
                cell.detailsTextView.text = currentPrayer.details
            }
            
            return cell
        } else if indexPath.section == 1 {
            var cell = tableView.dequeueReusableCellWithIdentifier(SetPrayerDateCellID, forIndexPath: indexPath) as! AddPrayerDateCell
            
            // Set the cell's prayer to the current prayer (for saving/fetching data)
            cell.currentPrayer = currentPrayer
            //cell.configureView()
            
            return cell
        } else if indexPath.section == 2 && indexPath.row == prayerAlerts.count {
            var cell = tableView.dequeueReusableCellWithIdentifier(AddNewAlertCellID, forIndexPath: indexPath) as! AddPrayerAlertCell
            
            cell.dateLabel.text = AlertStore.sharedInstance.convertDateToString(cell.datePicker.date)
            cell.datePicker.addTarget(self, action: "dateChanged:", forControlEvents: .ValueChanged)
            
            return cell
        } else if indexPath.section == 2 && indexPath.row < prayerAlerts.count {
            var cell = tableView.dequeueReusableCellWithIdentifier(PrayerAlertCellID, forIndexPath: indexPath) as! PrayerAlertCell
            
            let currentAlert = prayerAlerts[indexPath.row] as! PDAlert
            cell.alertLabel.text = AlertStore.sharedInstance.convertDateToString(currentAlert.alertDate)
            
            return cell
        } else {
            var cell = tableView.dequeueReusableCellWithIdentifier(AnsweredPrayerCellID, forIndexPath: indexPath) as! PrayerAnsweredCell
            
            cell.accessoryType = currentPrayer.answered ? .Checkmark : .None
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 || (indexPath.section == 3 && indexPath.row == 1) {
            return
        } else if indexPath.section == 2 && indexPath.row == prayerAlerts.count {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! AddPrayerAlertCell
            let dateCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as! AddPrayerDateCell
            
            if !cell.isAddingAlert {
                tableView.beginUpdates()
                
                dateCell.didCancelAddingDate(self)
            
                cell.isAddingAlert = true
            
                cell.saveButton.hidden = !cell.isAddingAlert
                cell.cancelButton.hidden = !cell.isAddingAlert
                cell.addNewAlertLabel.hidden = cell.isAddingAlert
                
                cell.saveButton.addTarget(self, action: "didSaveNewAlert:", forControlEvents: .TouchDown)
                cell.cancelButton.addTarget(self, action: "didCancelAddingAlert:", forControlEvents: .TouchDown)
            
                cell.alertCount = prayerAlerts.count
                
                addedDate = NSDate()
                tableView.endUpdates()
            
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
                
                cell.selectionStyle = .None
            } else {
                return
            }
        } else if indexPath.section == 1 {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! AddPrayerDateCell
            
            if cell.isAddingDate == false {
                cell.isAddingDate = true
                cell.selectionStyle = .None
            }
            //cell.configureView()
            
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
        } else if indexPath.section == 3 && indexPath.row == 0 {
            currentPrayer.answered = !currentPrayer.answered
            
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! PrayerAnsweredCell
            cell.accessoryType = currentPrayer.answered ? .Checkmark : .None
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        } else {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! PrayerAlertCell
            
            tableView.beginUpdates()
            if cell.isEditingAlert {
                cell.isEditingAlert = false
            } else {
                cell.isEditingAlert = true
            }
            tableView.endUpdates()
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 0 || indexPath.section == 1 || indexPath.section == 3 { return false }
        if indexPath.section == 2 && indexPath.row == prayerAlerts.count { return false }
        
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            AlertStore.sharedInstance.deleteAlert(prayerAlerts[indexPath.row] as! PDAlert, inPrayer: currentPrayer)
            prayerAlerts = currentPrayer.alerts.mutableCopy() as! NSMutableOrderedSet
            
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? PrayerAlertCell
            cell!.isEditingAlert = false
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            
        default:
            break
        }
    }
    
    override func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        var cell = tableView.cellForRowAtIndexPath(indexPath)
        
        cell!.contentView.clipsToBounds = true
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.contentView.clipsToBounds = true
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
            
        case 1:
            return 1
            
        case 2:
            return prayerAlerts.count + 1
            
        case 3:
            return 1
            
        default:
            return 0
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Details"
            
        case 1:
            return "Prayer Date"
            
        case 2:
            return "Alerts"
            
        case 3:
            return "Answered"
            
        default:
            return ""
        }
    }
    
    // MARK: Custom Functions
    
    func setState(sender: AnyObject) {
        let switchSender = sender as! UISwitch
        
        var state = switchSender.on
        currentPrayer.answered = state
        
        tableView.beginUpdates()
        if state {
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: 3)], withRowAnimation: .Top)
            //tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 3), atScrollPosition: .Bottom, animated: true)
        } else {
            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: 1, inSection: 3)], withRowAnimation: .Top)
            //tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 3), atScrollPosition: .Bottom, animated: true)
        }
        tableView.endUpdates()
    }
    
    func didSaveNewAlert(sender: AnyObject) {
        tableView.beginUpdates()
        
        var cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: prayerAlerts.count, inSection: 2)) as! AddPrayerAlertCell
        
        cell.isAddingAlert = false
        
        cell.saveButton.hidden = !cell.isAddingAlert
        cell.cancelButton.hidden = !cell.isAddingAlert
        cell.addNewAlertLabel.hidden = cell.isAddingAlert
        
        if let dateToAdd = addedDate {
            AlertStore.sharedInstance.createAlert(currentPrayer, inCategory: currentPrayer.category, withDate: dateToAdd)
            prayerAlerts = currentPrayer.alerts.mutableCopy() as! NSMutableOrderedSet
            
            cell.isAddingAlert = false
            cell.clipsToBounds = true
            
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: prayerAlerts.count - 1, inSection: 2)], withRowAnimation: .Right)
            
            //tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: prayerAlerts.count - 2, inSection: 2), atScrollPosition: .Bottom, animated: true)
        } else {
            println("ERROR! You must add a date!")
            
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: prayerAlerts.count, inSection: 2), atScrollPosition: .Bottom, animated: true)
            
            cell.selectionStyle = .Default
        }
        
        tableView.endUpdates()
        
        println("Prayer Alerts count = \(prayerAlerts.count)")
        cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: prayerAlerts.count, inSection: 2)) as! AddPrayerAlertCell
        cell.selectionStyle = .Default
    }
    
    func didCancelAddingAlert(sender: AnyObject) {
        tableView.beginUpdates()
        let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: prayerAlerts.count, inSection: 2)) as! AddPrayerAlertCell
        
        cell.isAddingAlert = false
        
        cell.saveButton.hidden = !cell.isAddingAlert
        cell.cancelButton.hidden = !cell.isAddingAlert
        cell.addNewAlertLabel.hidden = cell.isAddingAlert
        
        tableView.endUpdates()
        
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: prayerAlerts.count, inSection: 2), atScrollPosition: .Bottom, animated: true)
        
        cell.selectionStyle = .Default
    }
    
    func dateChanged(sender: AnyObject) {
        let datePicker = sender as! UIDatePicker
        
        let date = datePicker.date
        
        addedDate = date
        
        if let changeDate = addedDate {
            println("\(changeDate)")
        }
        
        let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: prayerAlerts.count, inSection: 2)) as! AddPrayerAlertCell
        cell.dateLabel.text = AlertStore.sharedInstance.convertDateToString(cell.datePicker.date)
    }
    
    // MARK: Views
    
    func setupBlurView(size: CGSize) -> UIView {
        let blurEffect = UIBlurEffect(style: .Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame.size = size
        
        let whiteView = UIView()
        whiteView.backgroundColor = UIColor.whiteColor()
        whiteView.alpha = 0.5
        whiteView.frame.size = size
        
        blurView.addSubview(whiteView)
        
        return blurView
    }
    
}