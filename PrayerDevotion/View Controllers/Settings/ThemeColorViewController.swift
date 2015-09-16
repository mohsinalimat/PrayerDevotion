//
//  ThemeColorViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/25/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class ThemeColorViewController: UITableViewController, PrayerDevotionStoreDelegate {
    
    let colorArray = ["White", "Black", "Red", "Pink", "Purple", "Deep Purple", "Indigo", "Blue", "Light Blue", "Cyan", "Teal", "Green", "Light Green", "Lime", "Yellow", "Amber", "Orange", "Deep Orange", "Brown", "Grey", "Blue Grey"]
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let prayerStore = PrayerDevotionStore()

    var selectedCell: ThemeColorCell_New?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Theme Color"
        
        // TODO: Add Recents Item
        //let recentsItem = UIBarButtonItem(barButtonSystemItem: .Bookmarks, target: self, action: "openRecents:")
        //navigationItem.rightBarButtonItem = recentsItem
        
        prayerStore.delegate = self
        prayerStore.requestProductInfo()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController!.navigationBar.tintColor = delegate.themeTintColor
        tableView.backgroundColor = delegate.themeBackgroundColor
        
        tableView.beginUpdates()
        tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 1)], withRowAnimation: .None)
        tableView.endUpdates()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: TableView Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return colorArray.count }
        else { return 1 }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ThemeColorCellID", forIndexPath: indexPath) as! ThemeColorCell_New
        
        if indexPath.section == 0 {
            cell.setThemeColor(Color.stringToColor(colorArray[indexPath.row]))
            cell.colorLabel.text = colorArray[indexPath.row]
            
            if delegate.themeColorString != "Custom" && Color.stringToColor(delegate.themeColorString) == Color.stringToColor(colorArray[indexPath.row]) {
                cell.accessoryType = .Checkmark
                selectedCell = cell
            } else {
                cell.accessoryType = .None
            }
        } else {
            cell.setThemeColor(Color.stringToColor("Custom"))
            cell.colorLabel.text = "Custom"
            
            cell.colorView.layer.borderWidth = 1
            cell.colorView.layer.borderColor = UIColor.blackColor().CGColor
            
            if delegate.themeColorString == "Custom" {
                cell.accessoryType = .Checkmark
                selectedCell = cell
            } else {
                cell.accessoryType = .None
            }
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            (UIApplication.sharedApplication().delegate as! AppDelegate).window!.tintColor = indexPath.row == 0 ? Color.Brown : Color.stringToColor(colorArray[indexPath.row])
            
            navigationController!.navigationBar.tintColor = indexPath.row != 0 ? Color.stringToColor(colorArray[indexPath.row]) : Color.Brown
            tableView.backgroundColor = Color.stringToColor(colorArray[indexPath.row])
            
            let textColor = Color.determineTextColor(Color.stringToColor(colorArray[indexPath.row]))
            
            userDefaults.setObject(colorArray[indexPath.row], forKey: "themeBackgroundColor")
            userDefaults.setObject(colorArray[indexPath.row] != "White" ? colorArray[indexPath.row] : "Brown", forKey: "themeTintColor")
            userDefaults.setObject(textColor, forKey: "themeTextColor")
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
            Color.setThemeColors(&delegate.themeBackgroundColor, tintColor: &delegate.themeTintColor, textColor: &delegate.themeTextColor, colorString: &delegate.themeColorString)
            
            delegate.themeColorString = userDefaults.stringForKey("themeBackgroundColor")!
            
            selectedCell?.accessoryType = .None
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! ThemeColorCell_New
            cell.accessoryType = .Checkmark
            selectedCell = cell
        } else {
            determinePurchasedStatus()
        }
    }
    
    func determinePurchasedStatus() {
        let purchased = delegate.didBuyAdditionalFeatures
        
        if purchased {
            let themeColorCustomVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SBThemeColorCustomViewControllerID") as! ThemeColorCustomViewController
            navigationController!.pushViewController(themeColorCustomVC, animated: true)
            themeColorCustomVC.themeColorVC = self
            
            delegate.themeColorString = userDefaults.stringForKey("themeBackgroundColor")!
            
            selectedCell?.accessoryType = .None
            let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as! ThemeColorCell_New
            cell.accessoryType = .Checkmark
            selectedCell = cell
        } else {
            tableView.deselectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1), animated: true)
            prayerStore.askForAdditionalFeatures(false, completion: nil)
        }
    }
    
    // MARK: PrayerDevotionStore Delegate Methods
    
    func didPurchaseAdditionalFeatures() {
        let themeColorCustomVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SBThemeColorCustomViewControllerID") as! ThemeColorCustomViewController
        navigationController!.pushViewController(themeColorCustomVC, animated: true)
        themeColorCustomVC.themeColorVC = self
        
        delegate.themeColorString = userDefaults.stringForKey("themeBackgroundColor")!
        
        selectedCell?.accessoryType = .None
        let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as! ThemeColorCell_New
        cell.accessoryType = .Checkmark
        selectedCell = cell
    }
    
}
