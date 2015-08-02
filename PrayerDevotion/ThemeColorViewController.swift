//
//  ThemeColorViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/25/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class ThemeColorViewController: UITableViewController, UITableViewDataSource, UITableViewDelegate {
    
    let colorArray = ["White", "Black", "Red", "Pink", "Purple", "Deep Purple", "Indigo", "Blue", "Light Blue", "Cyan", "Teal", "Green", "Light Green", "Lime", "Yellow", "Amber", "Orange", "Deep Orange", "Brown", "Grey", "Blue Grey"]
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Theme Color"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController!.navigationBar.tintColor = delegate.themeTintColor
        tableView.backgroundColor = delegate.themeBackgroundColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: TableView Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colorArray.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ThemeColorCellID", forIndexPath: indexPath) as! ThemeColorCell
        
        cell.setThemeColor(Color.stringToColor(colorArray[indexPath.row]), isWhite: indexPath.row == 0)
        cell.colorLabel.text = colorArray[indexPath.row]
        
        cell.colorView.layer.borderWidth = indexPath.row == 0 ? 1 : 0
        cell.colorView.layer.borderColor = indexPath.row == 0 ? UIColor.blackColor().CGColor : UIColor.clearColor().CGColor
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        (UIApplication.sharedApplication().delegate as! AppDelegate).window!.tintColor = indexPath.row == 0 ? Color.Brown : Color.stringToColor(colorArray[indexPath.row])
        
        navigationController!.navigationBar.tintColor = indexPath.row != 0 ? Color.stringToColor(colorArray[indexPath.row]) : Color.Brown
        tableView.backgroundColor = Color.stringToColor(colorArray[indexPath.row])
        
        var textColor = Color.determineTextColor(Color.stringToColor(colorArray[indexPath.row]))
        
        userDefaults.setObject(colorArray[indexPath.row], forKey: "themeBackgroundColor")
        userDefaults.setObject(colorArray[indexPath.row] != "White" ? colorArray[indexPath.row] : "Brown", forKey: "themeTintColor")
        userDefaults.setObject(textColor, forKey: "themeTextColor")
        
        delegate.themeBackgroundColor = Color.stringToColor(colorArray[indexPath.row])
        delegate.themeTintColor = Color.stringToColor(colorArray[indexPath.row] != "White" ? colorArray[indexPath.row] : "Brown")
        delegate.themeTextColor = Color.stringToColor(textColor)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
}
