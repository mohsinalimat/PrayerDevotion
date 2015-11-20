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
import CoreData

class PrayerUpdatesTableViewController : UITableViewController, UITextViewDelegate, PrayerUpdateViewDelegate, NSFetchedResultsControllerDelegate, UIViewControllerPreviewingDelegate {
    
    let dateFormatter = NSDateFormatter()
    
    var currentPrayer: PDPrayer!
    
    var updateView: PrayerUpdateView = PrayerUpdateView() // Optional PrayerUpdateView - may not always be on screen
    var newUpdateCreationTime = NSDate()
    var selectedPrayerUpdate: PDUpdate? = nil
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let frc = UpdatesStore.sharedInstance.fetchedPrayerUpdatesForPrayerID(self.currentPrayer.prayerID)
        frc.delegate = self
        return frc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // NSFetchedResultsController
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("An error occurred fetching updates")
        }
        
        navigationItem.title = "Prayer Updates"
        
        let addItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addNewUpdate:")
        navigationItem.rightBarButtonItem = addItem
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        if #available(iOS 9.0, *) {
            if self.traitCollection.forceTouchCapability == .Available {
                self.registerForPreviewingWithDelegate(self, sourceView: self.view)
            }
        }
        
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
        updateView.delegate = self
        updateView.newUpdate = isAdding
        
        
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
        
        self.newUpdateCreationTime = NSDate()
        if isAdding {
            self.updateView.updateTitle.text = "Update \(self.dateFormatter.stringFromDate(self.newUpdateCreationTime))"
            self.updateView.updateTextView.text = ""
            self.updateView.titleLabel.text = "Creating Update"
        } else {
            self.updateView.updateTitle.text = "Update \(self.dateFormatter.stringFromDate(update!.timestamp))"
            self.updateView.updateTextView.text = update!.update
            self.updateView.titleLabel.text = "Editing Update"
        }
        
        if (self.updateView.updateTextView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "" || self.updateView.updateTextView.text == "Add Prayer Update...") {
            update?.update = ""
            BaseStore.baseInstance.saveDatabase()
            self.updateView.updateTextView.text = "Add Prayer Update..."
            self.updateView.updateTextView.textColor = UIColor.lightGrayColor()
        } else {
            self.updateView.updateTextView.textColor = UIColor.blackColor()
        }
        
        self.updateView.saveButton.setTitle(self.updateView.updateTextView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "Add Prayer Update..." ? "Discard" : "Save", forState: .Normal)
        
        UIView.animateWithDuration(0.25, animations: {
            darkenView.alpha = 0.5
            self.updateView.alpha = 1.0
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
    
    // MARK: NSNotifications
    
    func keyboardWillShow(notification: NSNotification) {
        UIView.beginAnimations(nil, context: nil)
        
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
        let curve = UIViewAnimationCurve(rawValue: notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! Int)!
        
        UIView.setAnimationDuration(duration)
        UIView.setAnimationCurve(curve)
        UIView.setAnimationBeginsFromCurrentState(true)
        
        let updateSizeDifference = (self.view.frame.height * 0.92 - self.view.frame.height * 0.40) / 2
        updateView.frame = CGRectMake(0, 0, self.view.frame.width * 0.92, self.view.frame.height * 0.40)
        updateView.center = CGPointMake(self.view.center.x, self.view.center.y - updateSizeDifference + 10)
        
        UIView.commitAnimations()
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
        let curve = UIViewAnimationCurve(rawValue: notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! Int)!
        
        UIView.setAnimationDuration(duration)
        UIView.setAnimationCurve(curve)
        UIView.setAnimationBeginsFromCurrentState(true)
        
        updateView.frame = CGRectMake(0, 0, self.view.frame.width * 0.92, self.view.frame.height * 0.92)
        updateView.center = CGPointMake(self.view.center.x, self.view.center.y + 10)
        
        UIView.commitAnimations()
    }
    
    // MARK: UITableView Methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let currSection = fetchedResultsController.sections?[section] {
            return currSection.numberOfObjects
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(PrayerUpdateCellID, forIndexPath: indexPath) as! PrayerUpdateCell
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: PrayerUpdateCell, atIndexPath: NSIndexPath) {
        let update = fetchedResultsController.objectAtIndexPath(atIndexPath) as! PDUpdate
        
        
        cell.dateLabel.text = update.update
        /*dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .NoStyle
        
        cell.dateLabel.text = "Update \(dateFormatter.stringFromDate(update.timestamp))"*/
        
        dateFormatter.dateStyle = .NoStyle
        dateFormatter.timeStyle = .MediumStyle
        
        cell.timestampLabel.text = "\(dateFormatter.stringFromDate(update.timestamp))"
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        showPrayerUpdate(fetchedResultsController.objectAtIndexPath(indexPath) as! PDUpdate)
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            // Action is handled by NSFetchedResultsController
            UpdatesStore.sharedInstance.deleteUpdate(fetchedResultsController.objectAtIndexPath(indexPath) as! PDUpdate)
            
        default: break
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let currSection = fetchedResultsController.sections?[section] {
            return currSection.name
        }
        
        return nil
    }
    
    // MARK: NSFetchedResultsController Delegate Methods
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default: break
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Left)
            }
        case .Delete:
            if let indexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
            }
        case .Update:
            if let indexPath = indexPath, cell = tableView.cellForRowAtIndexPath(indexPath) as? PrayerUpdateCell {
                configureCell(cell, atIndexPath: indexPath)
            }
        case .Move:
            if let indexPath = indexPath, newIndexPath = newIndexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Left)
            }
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
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
    
    // MARK: PrayerUpdateView Delegate Methods
    
    func prayerUpdateView(updateView: PrayerUpdateView, didSaveUpdate update: String, isNewUpdate isNew: Bool, creationTime timestamp: NSDate) {
        if update != "Add Prayer Update..." && update.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != "" {
            if isNew {
                UpdatesStore.sharedInstance.addUpdateToPrayer(update, toPrayer: currentPrayer, timestamp: timestamp)
            } else {
                if let currentUpdate = selectedPrayerUpdate {
                    currentUpdate.update = update
                    BaseStore.baseInstance.saveDatabase()
                }
            }
            
            hidePrayerUpdate()
        } else {
            if !isNew {
                let alertView = UIAlertController(title: "Do you want to delete update?", message: "Updates cannot be blank. Would you like to continue editing this update or go ahead and delete it?", preferredStyle: .Alert)
                let yesAction = UIAlertAction(title: "Yes", style: .Destructive, handler: { alertAction in
                    if let currentUpdate = self.selectedPrayerUpdate {
                        UpdatesStore.sharedInstance.deleteUpdate(currentUpdate)
                    
                        self.hidePrayerUpdate()
                    }
                })
                
                let noAction = UIAlertAction(title: "No", style: .Default, handler: nil)
                
                alertView.addAction(noAction)
                alertView.addAction(yesAction)
                
                presentViewController(alertView, animated: true, completion: nil)
            } else {
                hidePrayerUpdate()
            }
        }
    }
    
    func prayerUpdateViewDidCancelUpdate(updateView: PrayerUpdateView) {
        print("Prayer Update Cancelled...")
        
        tableView.reloadData()
        hidePrayerUpdate()
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
    
    func textViewDidChange(textView: UITextView) {
        if (textView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())) == "" {
            updateView.saveButton.setTitle("Discard", forState: .Normal)
        } else {
            updateView.saveButton.setTitle("Save", forState: .Normal)
        }
    }
    
    // MARK: UIViewControllerPreviewing Delegate Methods
    
    @available(iOS 9.0, *)
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let indexPath = tableView.indexPathForRowAtPoint(location)
        
        if let indexPath = indexPath {
            let update = fetchedResultsController.objectAtIndexPath(indexPath) as! PDUpdate
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? PrayerUpdateCell
            
            if let cell = cell {
                previewingContext.sourceRect = cell.frame
                
                updateView = PrayerUpdateView()
                updateView.updateTextView.delegate = self
                updateView.delegate = self
                updateView.newUpdate = false
                
                dateFormatter.dateStyle = .ShortStyle
                dateFormatter.timeStyle = .MediumStyle
                
                updateView.tag = 1002
                updateView.alpha = 0.0
                updateView.backgroundColor = UIColor.whiteColor()
                
                self.navigationController!.view.addSubview(updateView)
                
                updateView.frame = CGRectMake(0, 0, self.view.frame.width * 0.92, self.view.frame.height * 0.92)
                updateView.center = CGPointMake(self.view.center.x, self.view.center.y + 10)
                
                updateView.layer.cornerRadius = 10
                updateView.clipsToBounds = true
                
                self.newUpdateCreationTime = NSDate()
                self.updateView.updateTitle.text = "Update \(self.dateFormatter.stringFromDate(update.timestamp))"
                self.updateView.updateTextView.text = update.update
                self.updateView.titleLabel.text = "Editing Update"
                
                if (self.updateView.updateTextView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "" || self.updateView.updateTextView.text == "Add Prayer Update...") {
                    update.update = ""
                    BaseStore.baseInstance.saveDatabase()
                    self.updateView.updateTextView.text = "Add Prayer Update..."
                    self.updateView.updateTextView.textColor = UIColor.lightGrayColor()
                } else {
                    self.updateView.updateTextView.textColor = UIColor.blackColor()
                }
                
                self.updateView.saveButton.setTitle(self.updateView.updateTextView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "Add Prayer Update..." ? "Discard" : "Save", forState: .Normal)
            }
        }
        
        return nil
    }
    
    @available(iOS 9.0, *)
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        var darkenView: UIView! = nil
        if self.view.viewWithTag(1001) == nil {
            darkenView = UIView(frame: self.view.frame)
            darkenView.backgroundColor = UIColor.blackColor()
            darkenView.tag = 1001
            darkenView.alpha = 0.0
            self.navigationController!.view.insertSubview(darkenView, aboveSubview: updateView)
        } else {
            darkenView = self.view.viewWithTag(1001)!
        }
        
        self.showDetailViewController(viewControllerToCommit, sender: self)
    }
}