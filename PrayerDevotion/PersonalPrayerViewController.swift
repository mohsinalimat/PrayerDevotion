//
//  PersonalPrayerViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 5/13/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import CoreData

let CreatePrayerCellID = "CreatePrayerCellID"
let PrayerCellID = "PrayerCellID"

let PrayerSearchViewControllerID = "PrayerSearchViewControllerID"
let PresentPrayerDetailsSegueID = "PresentPrayerDetailsSegueID"
let SearchSegueID = "SearchSegueID"

class PersonalPrayerViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UISearchBarDelegate {
    
    // Global variable that holds the current category
    var currentCategory: Category!
    var prayers: NSMutableArray!
    var answeredPrayers: NSMutableArray!
    
    var unansweredCount: Int!
    var answeredCount: Int!
    //var prayersCount: Int!
    
    private var selectedPrayer: Prayer?

    @IBOutlet var navItem: UINavigationItem?
    
    required init!(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // viewDidLoad function
        
        assert(currentCategory != nil, "ERROR! CATEGORY IS NIL!")
        
        navItem?.title = currentCategory.name
        println("Changing Nav Title to name \(currentCategory.name)")
        
        // Fetch Prayers for category
        var sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false), NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchAndUpdatePrayers(sortDescriptors)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFromEditingPrayer:", name: "ReloadPrayers", object: nil)
        
        refreshControl!.addTarget(self, action: "refreshView", forControlEvents: .ValueChanged)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        println("PersonalPrayersVC: didRecieveMemoryWarning called")
    }
    
    // MARK: UITableView Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
            
        case 1:
            return unansweredCount
            //return PrayerStore.sharedInstance.prayerCountForCategory(currentCategory)
            
        case 2:
            return answeredCount
        
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(CreatePrayerCellID, forIndexPath: indexPath) as! CreatePrayerCell
            cell.currentCategory = currentCategory
            cell.prayerTextField.delegate = self
            
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier(PrayerCellID, forIndexPath: indexPath) as! PrayerCell
            println("Index Path Row is = \(indexPath.row)")
        
            configureCell(cell, prayer: prayers[indexPath.row] as? Prayer, indexPath: indexPath)
            cell.prayerNameLabel.textColor = UIColor.blackColor()
            setPriorityText((prayers[indexPath.row] as! Prayer).priority, forCell: cell)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(PrayerCellID, forIndexPath: indexPath) as! PrayerCell
            println("Index Path Row is = \(indexPath.row)")
            
            configureCell(cell, prayer: answeredPrayers[indexPath.row] as? Prayer, indexPath: indexPath)
            cell.prayerNameLabel.textColor = UIColor.darkGrayColor()
            setPriorityText((answeredPrayers[indexPath.row] as! Prayer).priority, forCell: cell)
            
            return cell
        }
    }
    
    func configureCell(cell: PrayerCell, prayer: Prayer?, indexPath: NSIndexPath) {
        var editedIndexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
        
        //let prayer = prayers[indexPath.row] as! Prayer

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .NoStyle
        
        if let selectedPrayer = prayer {
            cell.prayerNameLabel.text = selectedPrayer.name
            cell.dateCreatedLabel.text = dateFormatter.stringFromDate(selectedPrayer.creationDate)
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 0 { return false }
        
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            PrayerStore.sharedInstance.deletePrayer(indexPath.section == 1 ? prayers[indexPath.row] as! Prayer : answeredPrayers[indexPath.row] as! Prayer, inCategory: currentCategory)
            
            if indexPath.section == 1 {
                prayers.removeObjectAtIndex(indexPath.row)
            } else {
                answeredPrayers.removeObjectAtIndex(indexPath.row)
            }
            
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            tableView.endUpdates()
            
            (tableView.headerViewForSection(2))?.textLabel.text = self.tableView(tableView, titleForHeaderInSection: 2)
            
        default:
            break
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            return
        }
        
        selectedPrayer = indexPath.section == 1 ? prayers[indexPath.row] as! Prayer : answeredPrayers[indexPath.row] as! Prayer
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! PrayerCell
        
        performSegueWithIdentifier(PresentPrayerDetailsSegueID, sender: cell)
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        var headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel.textColor = UIColor.whiteColor()
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 2 && answeredPrayers.count > 0 { return "ANSWERED" }
        if section == 1 && prayers.count > 0 { return "ACTIVE" }
        
        return ""
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var deleteAction = UITableViewRowAction(style: .Normal, title: "Delete", handler: { rowAction, indexPath in
            PrayerStore.sharedInstance.deletePrayer(indexPath.section == 1 ? self.prayers[indexPath.row] as! Prayer : self.answeredPrayers[indexPath.row] as! Prayer, inCategory: self.currentCategory)
            
            if indexPath.section == 1 {
                self.prayers.removeObjectAtIndex(indexPath.row)
                self.unansweredCount = self.unansweredCount - 1
            } else {
                self.answeredPrayers.removeObjectAtIndex(indexPath.row)
                self.answeredCount = self.answeredCount - 1
            }
            
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            tableView.endUpdates()
            
            (tableView.headerViewForSection(1))?.textLabel.text = self.tableView(tableView, titleForHeaderInSection: 1)
            (tableView.headerViewForSection(2))?.textLabel.text = self.tableView(tableView, titleForHeaderInSection: 2)
        })
        deleteAction.backgroundColor = UIColor.redColor()
        
        let prayer = indexPath.section == 1 ? self.prayers[indexPath.row] as! Prayer : self.answeredPrayers[indexPath.row] as! Prayer
        var answeredAction = UITableViewRowAction(style: .Normal, title: prayer.answered == true ? "Answered" : "Unanswered", handler: { rowAction, indexPath in
            self.tableView.editing = false
            
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! PrayerCell
            cell.prayerNameLabel.textColor = prayer.answered == true ? UIColor.blackColor() : UIColor.darkGrayColor()
            
            self.tableView.beginUpdates()
            self.tableView.moveRowAtIndexPath(indexPath, toIndexPath: NSIndexPath(forRow: 0, inSection: prayer.answered == true ? 1 : 2))
            prayer.answered = !prayer.answered
            BaseStore.baseInstance.saveDatabase()
            
            var sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false), NSSortDescriptor(key: "creationDate", ascending: false)]
            self.fetchAndUpdatePrayers(sortDescriptors)
            
            (tableView.headerViewForSection(1))?.textLabel.text = self.tableView(tableView, titleForHeaderInSection: 1)
            (tableView.headerViewForSection(2))?.textLabel.text = self.tableView(tableView, titleForHeaderInSection: 2)
            
            self.tableView.endUpdates()
            
            self.sortUnansweredPrayers(sortDescriptors)
        })
        answeredAction.backgroundColor = prayer.answered == true ? UIColor.greenColor() : UIColor.darkGrayColor()
        
        return [deleteAction, answeredAction]
    }
    
    // MARK: Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == PresentPrayerDetailsSegueID {
            let destinationVC = (segue.destinationViewController as! UINavigationController).topViewController as! PrayerDetailsViewController_New
            destinationVC.currentPrayer = selectedPrayer!
        }
    }
    
    @IBAction func prepareForUnwindFromEditingPrayer(segue: UIStoryboardSegue) {
        println("Unwinding from Editing Prayer")
        BaseStore.baseInstance.saveDatabase()
        
        var sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false), NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchAndUpdatePrayers(sortDescriptors)
        
        tableView.reloadData()
    }
    
    @IBAction func prepareForUnwindFromSearch(segue: UIStoryboardSegue) {
        println("Unwinding from Searching")
        BaseStore.baseInstance.saveDatabase()
        
        var sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false), NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchAndUpdatePrayers(sortDescriptors)
        
        tableView.reloadData()
    }
    
    func reloadFromEditingPrayer(notification: NSNotification) {
        println("Unwinding from Editing Prayer")
        BaseStore.baseInstance.saveDatabase()
        
        var sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false), NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchAndUpdatePrayers(sortDescriptors)
        
        tableView.reloadData()
    }
    
    // MARK: TextField Delegate
    
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
            
            PrayerStore.sharedInstance.addPrayerToDatabase(enteredString, details: "", category: currentCategory, dateCreated: NSDate())
            var sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false), NSSortDescriptor(key: "creationDate", ascending: false)]

            CATransaction.begin()
            CATransaction.setCompletionBlock({
                self.tableView.reloadData()
                self.sortUnansweredPrayers(sortDescriptors)
            })
            tableView.beginUpdates()
            
            fetchAndUpdatePrayers([NSSortDescriptor(key: "creationDate", ascending: false)])
            
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 1)], withRowAnimation: .Right)
            
            (tableView.headerViewForSection(1))?.textLabel.text = self.tableView(tableView, titleForHeaderInSection: 1)
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
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 15
        }
        
        return UITableViewAutomaticDimension
    }
    
    // MARK: Custom Methods
    
    func setPriorityText(priority: Int16, forCell cell: PrayerCell) {
        switch priority {
        case 0: cell.priorityLabel.text = ""
        case 1: cell.priorityLabel.text = "!"
        case 2: cell.priorityLabel.text = "!!"
        case 3: cell.priorityLabel.text = "!!!"
        default: cell.priorityLabel.text = ""
        }
    }
    
    func sortUnansweredPrayers(sortDescriptors: [NSSortDescriptor]) {
        let objectsBeforeSorting = prayers
        
        fetchAndUpdatePrayers(sortDescriptors)
        
        tableView.beginUpdates()
        for var i = 0; i < prayers.count; i++ {
            var newRow = prayers.indexOfObject(objectsBeforeSorting[i])
            tableView.moveRowAtIndexPath(NSIndexPath(forRow: i, inSection: 1), toIndexPath: NSIndexPath(forRow: newRow, inSection: 1))
        }
        tableView.endUpdates()
    }
    
    func fetchAndUpdatePrayers(sortDescriptors: [NSSortDescriptor]) {
        var fetchedPrayers = PrayerStore.sharedInstance.fetchAndSortPrayersInCategory(currentCategory, sortDescriptors: sortDescriptors, batchSize: 50)
        prayers = fetchedPrayers.unanswered
        answeredPrayers = fetchedPrayers.answered
        
        unansweredCount = prayers.count
        answeredCount  = answeredPrayers.count
    }
    
    func refreshView() {
        fetchAndUpdatePrayers([NSSortDescriptor(key: "priority", ascending: false), NSSortDescriptor(key: "creationDate", ascending: false)])
        tableView.reloadData()
        
        refreshControl!.endRefreshing()
    }
}
