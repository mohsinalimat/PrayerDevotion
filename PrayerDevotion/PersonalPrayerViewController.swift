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

class PersonalPrayerViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, NSFetchedResultsControllerDelegate {
    
    // Global variable that holds the current category
    var currentCategory: Category!
    var prayers: NSMutableArray!
    //var prayersCount: Int!
    
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
        prayers = PrayerStore.sharedInstance.fetchAllPrayersInCategory(currentCategory, sortDescriptors: [NSSortDescriptor(key: "creationDate", ascending: false)], batchSize: 50)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        println("PersonalPrayersVC: didRecieveMemoryWarning called")
    }
    
    // MARK: UITableView Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
            
        case 1:
            return PrayerStore.sharedInstance.prayerCountForCategory(currentCategory)
            
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
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(PrayerCellID, forIndexPath: indexPath) as! PrayerCell
        println("Index Path Row is = \(indexPath.row)")
        configureCell(cell, indexPath: indexPath)
            
        return cell
    }
    
    func configureCell(cell: PrayerCell, indexPath: NSIndexPath) {
        var editedIndexPath = NSIndexPath(forRow: indexPath.row, inSection: 0)
        let prayer = prayers[indexPath.row] as! Prayer
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .NoStyle
        
        cell.prayerNameLabel.text = prayer.name
        cell.dateCreatedLabel.text = dateFormatter.stringFromDate(prayer.creationDate)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 0 { return false }
        
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            PrayerStore.sharedInstance.deletePrayer(prayers[indexPath.row] as! Prayer, inCategory: currentCategory)
            prayers.removeObjectAtIndex(indexPath.row)
            
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
            tableView.endUpdates()
            
        default:
            break
        }
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
            
            PrayerStore.sharedInstance.addPrayerToDatabase(enteredString, details: "", category: currentCategory!, dateCreated: NSDate())
            prayers = PrayerStore.sharedInstance.fetchAllPrayersInCategory(currentCategory!, sortDescriptors: [NSSortDescriptor(key: "creationDate", ascending: false)], batchSize: 50)

            tableView.beginUpdates()
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 1)], withRowAnimation: .Right)
            tableView.endUpdates()
        } else {
            println("String did not contain any characters at all. Not adding to prayer list...")
        }
        
        textField.text = ""
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
}
