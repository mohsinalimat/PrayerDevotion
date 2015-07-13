//
//  TodayViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 6/6/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData
import UIKit

let TodayPrayerCellID = "TodayPrayerCellID"

let PresentPrayerDetailsFromTodaySegueID = "PresentPrayerDetailsFromTodaySegueID"

enum TodaySectionType: Int, Printable {
    case OnDate
    case Daily
    case Weekly
    
    var description: String {
        switch self {
        case .OnDate: return "On Date"
        case .Daily: return "Daily"
        case .Weekly: return "Weekly"
        }
    }
}

class TodayViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var userPrefs = NSUserDefaults.standardUserDefaults()
    
    // Arrays
    var onDatePrayers = PrayerStore.sharedInstance.fetchTodayPrayers(.OnDate)
    var dailyPrayers = PrayerStore.sharedInstance.fetchTodayPrayers(.Daily)
    var weeklyPrayers = PrayerStore.sharedInstance.fetchTodayPrayers(.Weekly)
    
    var todayOrder: [PrayerType] = [.OnDate, .Daily, .Weekly] // 1 - On Date, 2 - Daily, 3 - Weekly
    var section1: String?
    var section2: String?
    var section3: String?
    
    var selectedPrayer: Prayer?
    
    // IBOutlets
    @IBOutlet var noPrayersLabel: UILabel!
    @IBOutlet var todayLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var tableViewHidden = onDatePrayers.count == 0 && dailyPrayers.count == 0 && weeklyPrayers.count == 0
        
        tableView.hidden = tableViewHidden
        todayLabel.hidden = tableViewHidden
        noPrayersLabel.hidden = !tableViewHidden
        
        // Figures out where the location of the numerical value of the specified type is
        // And delete it from the array
        var onDateLocation = find(todayOrder, .OnDate)!
        if onDatePrayers.count <= 0 { todayOrder.removeAtIndex(onDateLocation) }

        var dailyLocation = find(todayOrder, .Daily)!
        if dailyPrayers.count <= 0 { todayOrder.removeAtIndex(dailyLocation) }

        var weeklyLocation = find(todayOrder, .Weekly)!
        if weeklyPrayers.count <= 0 { todayOrder.removeAtIndex(weeklyLocation) }
        
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadFromEditingPrayer:", name: "ReloadTodayPrayers", object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: TableView Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return todayOrder.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return countOfPrayers(todayOrder[0])
        } else if section == 1 {
            return countOfPrayers(todayOrder[1])
        } else if section == 2 {
            return countOfPrayers(todayOrder[2])
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TodayPrayerCellID) as! TodayCell
        
        switch indexPath.section {
        case 0:
            configureCell(cell, forIndexPath: indexPath, withTodayType: todayOrder[0])
                
        case 1:
            configureCell(cell, forIndexPath: indexPath, withTodayType: todayOrder[1])
            
        case 2:
            configureCell(cell, forIndexPath: indexPath, withTodayType: todayOrder[2])

        default:
            break
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            if todayOrder[0].description == "On Date" { return "Today Prayers" }
            return todayOrder[0].description + " Prayers"
        
        case 1:
            if todayOrder[1].description == "On Date" { return "Today Prayers" }
            return todayOrder[1].description + " Prayers"
        
        case 2:
            if todayOrder[2].description == "On Date" { return "Today Prayers" }
            return todayOrder[2].description + " Prayers"

        default:
            return ""
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            selectPrayerAtIndexPath(indexPath, withType: todayOrder[0])
            
        case 1:
            selectPrayerAtIndexPath(indexPath, withType: todayOrder[1])
            
        case 2:
            selectPrayerAtIndexPath(indexPath, withType: todayOrder[2])
            
        default:
            break
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        performSegueWithIdentifier(PresentPrayerDetailsFromTodaySegueID, sender: self)
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        var headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel.textColor = UIColor.whiteColor()
    }
    
    // MARK: Custom Methods
    
    func configureCell(cell: TodayCell, forIndexPath indexPath: NSIndexPath, withTodayType type: PrayerType) {
        switch type {
        case .OnDate:
            cell.nameLabel.text = onDatePrayers[indexPath.row].name
            setPriorityText(onDatePrayers[indexPath.row].priority, forCell: cell)
            
        case .Daily:
            cell.nameLabel.text = dailyPrayers[indexPath.row].name
            setPriorityText(dailyPrayers[indexPath.row].priority, forCell: cell)
            
        case .Weekly:
            cell.nameLabel.text = weeklyPrayers[indexPath.row].name
            setPriorityText(weeklyPrayers[indexPath.row].priority, forCell: cell)
            
        default:
            println("Type \(type) does not exist")
        }
        
        var blurEffect = UIBlurEffect(style: .ExtraLight)
        var blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = cell.frame
        
        cell.backgroundView = blurView
    }
    
    func selectPrayerAtIndexPath(indexPath: NSIndexPath, withType type: PrayerType) {
        switch type {
        case .OnDate:
            selectedPrayer = onDatePrayers[indexPath.row]
            
        case .Daily:
            selectedPrayer = dailyPrayers[indexPath.row]
            
        case .Weekly:
            selectedPrayer = weeklyPrayers[indexPath.row]
            
        default:
            break
        }
        
        performSegueWithIdentifier(PresentPrayerDetailsFromTodaySegueID, sender: self)
    }
    
    func countOfPrayers(inType: PrayerType) -> Int {
        switch inType {
        case .OnDate:
            return onDatePrayers.count
            
        case .Daily:
            return dailyPrayers.count
            
        case .Weekly:
            return weeklyPrayers.count
            
        default:
            return 0
        }
    }

    
    // MARK: Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == PresentPrayerDetailsFromTodaySegueID {
            var destinationVC = (segue.destinationViewController as! UINavigationController).topViewController as! PrayerDetailsViewController_New
            destinationVC.currentPrayer = selectedPrayer!
            destinationVC.unwindToToday = true
        }
    }
    
    // MARK: Custom Methods
    
    func setPriorityText(priority: Int16, forCell cell: TodayCell) {
        switch priority {
        case 0: cell.priorityLabel.text = ""
        case 1: cell.priorityLabel.text = "!"
        case 2: cell.priorityLabel.text = "!!"
        case 3: cell.priorityLabel.text = "!!!"
        default: cell.priorityLabel.text = ""
        }
    }
    
    func reloadFromEditingPrayer(notification: NSNotification) {
        println("Unwinding from Editing Prayer")
        BaseStore.baseInstance.saveDatabase()
        
        onDatePrayers = PrayerStore.sharedInstance.fetchTodayPrayers(.OnDate)
        dailyPrayers = PrayerStore.sharedInstance.fetchTodayPrayers(.Daily)
        weeklyPrayers = PrayerStore.sharedInstance.fetchTodayPrayers(.Weekly)
        
        var tableViewHidden = onDatePrayers.count == 0 && dailyPrayers.count == 0 && weeklyPrayers.count == 0
        
        tableView.hidden = tableViewHidden
        todayLabel.hidden = tableViewHidden
        noPrayersLabel.hidden = !tableViewHidden
        
        todayOrder = [.OnDate, .Daily, .Weekly]
        
        // Figures out where the location of the numerical value of the specified type is
        // And delete it from the array
        var onDateLocation = find(todayOrder, .OnDate)!
        if onDatePrayers.count <= 0 { todayOrder.removeAtIndex(onDateLocation) }
        
        var dailyLocation = find(todayOrder, .Daily)!
        if dailyPrayers.count <= 0 { todayOrder.removeAtIndex(dailyLocation) }
        
        var weeklyLocation = find(todayOrder, .Weekly)!
        if weeklyPrayers.count <= 0 { todayOrder.removeAtIndex(weeklyLocation) }
        
        tableView.reloadData()
    }
}
