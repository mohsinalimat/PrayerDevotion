//
//  PrayerUpdatesTableViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 10/11/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import PDKit

class PrayerUpdatesTableViewController : UITableViewController, UITextViewDelegate {
    
    var updatesSet = NSOrderedSet()
    let dateFormatter = NSDateFormatter()
    
    var currentPrayer: PDPrayer!
    
    var updateView: PrayerUpdateView = PrayerUpdateView() // Optional PrayerUpdateView - may not always be on screen
    var newUpdateCreationTime = NSDate()
    var selectedPrayerUpdate: PDUpdate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updatesSet = currentPrayer.updates
        
        navigationItem.title = "Prayer Updates"
        
        let addItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addNewUpdate:")
        navigationItem.rightBarButtonItem = addItem
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Custom Methods
    
    func addNewUpdate(sender: AnyObject) {
        print("Adding new prayer update...")
        
        prepareUpdateView(nil, isAdding: true)
    }
    
    func prepareUpdateView(update: PDUpdate?, isAdding: Bool = false) {
        updateView = PrayerUpdateView()
        updateView.updateTextView.delegate = self
        
        if let update = update {
            selectedPrayerUpdate = update
        }
        
        var darkenView: UIView! = nil
        if self.view.viewWithTag(1001) == nil {
            darkenView = UIView(frame: self.view.frame)
            darkenView.backgroundColor = UIColor.blackColor()
            darkenView.tag = 1001
            darkenView.alpha = 0.0
            self.navigationController!.view.addSubview(darkenView)
            
            let touchRec = UITapGestureRecognizer(target: self, action: "hidePrayerUpdate")
            darkenView.addGestureRecognizer(touchRec)
        } else {
            darkenView = self.view.viewWithTag(1001)!
        }
        
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .MediumStyle
        
        updateView.tag = 1002
        updateView.alpha = 0.0
        updateView.backgroundColor = UIColor.whiteColor()
        
        self.navigationController!.view.insertSubview(updateView, aboveSubview: darkenView)
        
        updateView.frame = CGRectMake(0, 0, self.view.frame.width * 0.92, self.view.frame.height * 0.92)
        updateView.center = CGPointMake(self.view.center.x, self.view.center.y + 10)
        
        updateView.layer.cornerRadius = 10
        updateView.clipsToBounds = true
        
        let saveActionString: Selector = isAdding == true ? "savePrayerUpdate:" : "updatePrayerUpdate:"
        print("saveActionString == \(saveActionString)")
        
        print("isAdding: \(isAdding)")
        updateView.saveButton.addTarget(self, action: saveActionString, forControlEvents: .TouchDown)
        updateView.cancelButton.addTarget(self, action: "cancelPrayerUpdate:", forControlEvents: .TouchDown)
        
        UIView.animateWithDuration(0.25, animations: {
            darkenView.alpha = 0.5
            self.updateView.alpha = 1.0
            
            self.newUpdateCreationTime = NSDate()
            if isAdding {
                self.updateView.updateTitle.text = "Update \(self.dateFormatter.stringFromDate(self.newUpdateCreationTime))"
                self.updateView.updateTextView.text = ""
                //self.updateView.titleLabel.text = "Adding Update"
            } else {
                self.updateView.updateTitle.text = "Update \(self.dateFormatter.stringFromDate(update!.timestamp))"
                self.updateView.updateTextView.text = update!.update
                ///self.updateView.titleLabel.text = ""
            }
            
            if (self.updateView.updateTextView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "" || self.updateView.updateTextView.text == "Add Prayer Update...") {
                update?.update = ""
                BaseStore.baseInstance.saveDatabase()
                self.updateView.updateTextView.text = "Add Prayer Update..."
                self.updateView.updateTextView.textColor = UIColor.lightGrayColor()
            } else {
                self.updateView.updateTextView.textColor = UIColor.blackColor()
            }
        })
    }
    
    func showPrayerUpdate(update: PDUpdate) {
        prepareUpdateView(update)
    }
    
    func hidePrayerUpdate() {
        if let darkenView = self.navigationController!.view.viewWithTag(1001) {
            UIView.animateWithDuration(0.25, animations: {
                darkenView.alpha = 0.0
                self.updateView.alpha = 0.0
            }, completion: { completed in
                darkenView.removeFromSuperview()
                self.updateView.removeFromSuperview()
                
                self.updateView.updateTextView.text = "Add Prayer Update..."
                self.updateView.updateTextView.textColor = UIColor.lightGrayColor()
            })
        }
    }
    
    func savePrayerUpdate(sender: AnyObject) {
        UpdatesStore.sharedInstance.addUpdateToPrayer(updateView.updateTextView.text, toPrayer: currentPrayer, timestamp: newUpdateCreationTime)
        updatesSet = currentPrayer.updates
        
        tableView.reloadData()
        hidePrayerUpdate()
    }
    
    func updatePrayerUpdate(sender: AnyObject) {
        if let update = selectedPrayerUpdate {
            update.update = updateView.updateTextView.text
            BaseStore.baseInstance.saveDatabase()
        }
        
        hidePrayerUpdate()
    }
    
    func cancelPrayerUpdate(sender: AnyObject) {
        hidePrayerUpdate()
    }
    
    // MARK: UITableView Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return updatesSet.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(PrayerUpdateCellID, forIndexPath: indexPath) as! PrayerUpdateCell
        
        let update = updatesSet[indexPath.row] as! PDUpdate
        
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .NoStyle
        
        cell.dateLabel.text = "Update \(dateFormatter.stringFromDate(update.timestamp))"
        
        dateFormatter.dateStyle = .NoStyle
        dateFormatter.timeStyle = .MediumStyle
        
        cell.timestampLabel.text = "\(dateFormatter.stringFromDate(update.timestamp))"
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        showPrayerUpdate(updatesSet[indexPath.row] as! PDUpdate)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            let update = updatesSet[indexPath.row] as! PDUpdate
            UpdatesStore.sharedInstance.deleteUpdate(update)
            updatesSet = currentPrayer.updates
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
            
        default: break
        }
    }
    
    // MARK: Touches
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let touch = touches.first! as UITouch
        
        if let darkenView = self.view.viewWithTag(1001) {
            if touch.view == darkenView {
                hidePrayerUpdate()
            }
        } else {
            print("Touch was not in darkenView")
        }
    }
    
    // MARK: UITextView Delegate Methods
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        if (textView.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "Add Prayer Update...") {
            textView.text = ""
        }
        
        textView.textColor = UIColor.blackColor()
        return true
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        if (textView.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "") {
            textView.textColor = UIColor.lightGrayColor()
            textView.text = "Add Prayer Update..."
        }
        
        return true
    }
}