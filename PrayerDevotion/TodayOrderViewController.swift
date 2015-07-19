//
//  TodayOrderViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/18/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import PDKit

class TodayOrderViewController: UITableViewController, UITableViewDataSource {
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var todayOrder1: PrayerType!
    var todayOrder2: PrayerType!
    var todayOrder3: PrayerType!
    
    var prayerOrder: [PrayerType]!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        todayOrder1 = PrayerType(rawValue: userDefaults.objectForKey("prayerTodayOrder_1") as! Int)!
        todayOrder2 = PrayerType(rawValue: userDefaults.objectForKey("prayerTodayOrder_2") as! Int)!
        todayOrder3 = PrayerType(rawValue: userDefaults.objectForKey("prayerTodayOrder_3") as! Int)!
        
        prayerOrder = [todayOrder1, todayOrder2, todayOrder3]
        
        tableView.editing = true
        tableView.allowsSelectionDuringEditing = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func savePrayerOrder() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func saveOrder() {
        userDefaults.setObject(prayerOrder[0].rawValue, forKey: "prayerTodayOrder_1")
        userDefaults.setObject(prayerOrder[1].rawValue, forKey: "prayerTodayOrder_2")
        userDefaults.setObject(prayerOrder[2].rawValue, forKey: "prayerTodayOrder_3")
    }

    // MARK: UITableView Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 3 : 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("TodayOrderCellID", forIndexPath: indexPath) as! UITableViewCell
        
            cell.textLabel!.text = prayerOrder[indexPath.row].description
        
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("ResetTodayOrderCellID", forIndexPath: indexPath) as! UITableViewCell
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 { return }
        else {
            tableView.beginUpdates()
            let resetOrder: [PrayerType] = [.OnDate, .Daily, .Weekly]
            
            for (indexPath, item) in enumerate(prayerOrder) {
                let newPosition = find(resetOrder, item)!
                tableView.moveRowAtIndexPath(NSIndexPath(forRow: indexPath, inSection: 0), toIndexPath: NSIndexPath(forRow: newPosition, inSection: 0))
            }
            
            prayerOrder = resetOrder
            tableView.endUpdates()
            
            saveOrder()
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let firstObject = prayerOrder[sourceIndexPath.row]
        let secondObject = prayerOrder[destinationIndexPath.row]
        
        prayerOrder[sourceIndexPath.row] = secondObject
        prayerOrder[destinationIndexPath.row] = firstObject
        
        saveOrder()
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        var headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel.textColor = UIColor.whiteColor()
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .None
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    override func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundView?.backgroundColor = UIColor.whiteColor()
    }

}
