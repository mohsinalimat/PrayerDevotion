//
//  PrayerUpdateEditingViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 11/23/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import PDKit

class PrayerUpdateEditingViewController: UIViewController, UITextViewDelegate {
    
    let updateView = PrayerUpdateView()
    let dateFormatter = NSDateFormatter()
    
    var newCreationTime: NSDate = NSDate()
    
    var isAdding: Bool = false
    var update: PDUpdate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        // Used in testing ATM.... Need to figure out how to replace it
        assert(update != nil, "UPDATE IS NIL")
        
        prepareUpdateView(update)
    }
    
    func prepareUpdateView(update: PDUpdate) {
        updateView.updateTextView.delegate = self
        updateView.newUpdate = isAdding
        
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
        
        updateView.layer.cornerRadius = 10
        updateView.clipsToBounds = true
        
        self.newCreationTime = NSDate()
        if isAdding {
            self.updateView.updateTitle.text = "Update \(self.dateFormatter.stringFromDate(self.newCreationTime))"
            self.updateView.updateTextView.text = ""
            self.updateView.titleLabel.text = "Creating Update"
        } else {
            self.updateView.updateTitle.text = "Update \(self.dateFormatter.stringFromDate(update.timestamp))"
            self.updateView.updateTextView.text = update.update
            self.updateView.titleLabel.text = "Editing Update"
        }
        
        if (self.updateView.updateTextView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) == "" || self.updateView.updateTextView.text == "Add Prayer Update...") {
            update.update = ""
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
}