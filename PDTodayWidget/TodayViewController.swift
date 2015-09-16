//
//  TodayViewController.swift
//  PDTodayWidget
//
//  Created by Jonathan Hart on 7/15/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import UIKit
import NotificationCenter
import PDKit

let PrayerTodayCellID = "PrayerTodayCellID"
let AllTodayCellID = "AllTodayCellID"

class TodayViewController: UIViewController, NCWidgetProviding, UITableViewDataSource, UITableViewDelegate {
    
    var onDatePrayers = [PDPrayer]()
    var dailyPrayers = [PDPrayer]()
    var weeklyPrayers = [PDPrayer]()
    
    @IBOutlet var todayLabel: UILabel!
    @IBOutlet var noPrayersLabel: UILabel!
    
    let dateFormatter = NSDateFormatter()
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var tableViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.timeStyle = .NoStyle
        dateFormatter.dateStyle = .MediumStyle
        
        todayLabel.text = "Fetching Prayer Data..."
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, 20, 0)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        fetchTodayWidgetData()
        completionHandler(NCUpdateResult.NewData)
    }
    
    func fetchTodayWidgetData() -> Bool {
        onDatePrayers = PrayerStore.sharedInstance.fetchTodayPrayers(.OnDate, forWidget: true)
        dailyPrayers = PrayerStore.sharedInstance.fetchTodayPrayers(.Daily, forWidget: true)
        weeklyPrayers = PrayerStore.sharedInstance.fetchTodayPrayers(.Weekly, forWidget: true)
        
        tableView.reloadData()
        tableView.hidden = allPrayersCount() == 0 ? true : false
        todayLabel.hidden = allPrayersCount() == 0 ? true : false
        noPrayersLabel.hidden = allPrayersCount() == 0 ? false : true
        
        calculateTableViewHeight()
        
        todayLabel.text = "Today Prayers"
        
        return true
    }
    
    func setPriorityText(priority: Int16) -> String {
        switch priority {
        case 0: return ""
        case 1: return "!"
        case 2: return "!!"
        case 3: return "!!!"
        default: return ""
        }
    }
    
    func calculateTableViewHeight() {
        let contentSize = tableView.sizeThatFits(tableView.contentSize)
        
        tableViewHeight.constant = contentSize.height
    }
    
    // MARK: TableView Data Source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return onDatePrayers.count
        case 1: return dailyPrayers.count
        case 2: return weeklyPrayers.count
        case 3: return 1
        default: return 0
        }
    }
    
    func allPrayersCount() -> Int {
        return onDatePrayers.count + dailyPrayers.count + weeklyPrayers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(PrayerTodayCellID, forIndexPath: indexPath) as! PrayerTodayCell
            cell.prayerTitleLabel.text = onDatePrayers[indexPath.row].name
            cell.prayerTyleLabel.text = "Prayer Due on " + dateFormatter.stringFromDate(onDatePrayers[indexPath.row].addedDate!)
            cell.priorityLabel.text = setPriorityText(onDatePrayers[indexPath.row].priority)
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(PrayerTodayCellID, forIndexPath: indexPath) as! PrayerTodayCell
            cell.prayerTitleLabel.text = dailyPrayers[indexPath.row].name
            cell.prayerTyleLabel.text = "Prayer Due Daily"
            cell.priorityLabel.text = setPriorityText(dailyPrayers[indexPath.row].priority)
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier(PrayerTodayCellID, forIndexPath: indexPath) as! PrayerTodayCell
            cell.prayerTitleLabel.text = weeklyPrayers[indexPath.row].name
            cell.prayerTyleLabel.text = "Prayer Due on " + weeklyPrayers[indexPath.row].weekday! + "s"
            cell.priorityLabel.text = setPriorityText(weeklyPrayers[indexPath.row].priority)
            return cell
            
        case 3:
            let cell = tableView.dequeueReusableCellWithIdentifier(AllTodayCellID, forIndexPath: indexPath) 
            return cell
            
            
        default: return UITableViewCell()
        }
    }

    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        print("Selected row at indexPath \(indexPath)")
        
        var path: String = "prayerdevotion://"
        
        switch indexPath.section {
        case 0:
            path = "prayerdevotion://open-prayer?prayerID=\(onDatePrayers[indexPath.row].prayerID)"
            
        case 1:
            path = "prayerdevotion://open-prayer?prayerID=\(dailyPrayers[indexPath.row].prayerID)"
            
        case 2:
            path = "prayerdevotion://open-prayer?prayerID=\(weeklyPrayers[indexPath.row].prayerID)"
            
        case 3:
            path = "prayerdevotion://open-today"
            
        default: break
        }
        
        let url = NSURL(string: path)!
        extensionContext!.openURL(url, completionHandler: nil)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 3 { return 34 }
        
        return 56
    }
}
