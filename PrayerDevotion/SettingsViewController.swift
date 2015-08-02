//
//  SettingsViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 6/5/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import MessageUI
import PDKit

class SettingsViewController: UITableViewController, UITableViewDataSource, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var colorView: UIView!
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var themeString: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleURL:", name: "HandleURLNotification", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        themeString = NSUserDefaults.standardUserDefaults().stringForKey("themeBackgroundColor")!
        
        navigationController!.navigationBar.tintColor = delegate.themeTintColor
        tableView.backgroundColor = delegate.themeBackgroundColor
        let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as! ThemeColorCell
        cell.color = delegate.themeBackgroundColor
        
        colorLabel.text = "Theme Color: \(themeString)"
        colorView.backgroundColor = themeString == "White" ? Color.TrueWhite : delegate.themeBackgroundColor
        colorView.layer.borderColor = themeString == "White" ? UIColor.blackColor().CGColor : UIColor.clearColor().CGColor
        colorView.layer.borderWidth = themeString == "White" ? 1 : 0
        
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        var headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel.textColor = delegate.themeTextColor
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0: break
        default: break
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let emailTypes = ["feedback", "bug_report", "feature_request"]
        
        switch indexPath.section {
        case 0: createEmailMessage(emailTypes[indexPath.row])
        case 1: tableView.deselectRowAtIndexPath(indexPath, animated: true)
        default: break
        }
    }
    
    // MARK: Custom Functions
    func createEmailMessage(type: String) {
        var emailTitle = ""
        if type == "feedback" { emailTitle = "PrayerDevotion User Feedback" }
        else if type == "bug_report" { emailTitle = "PrayerDevotion User Bug Report" }
        else { emailTitle = "PrayerDevotion User Feature Request" }
        
        let toEmail = ["jonathanhart3000@gmail.com"]
        
        var mailController = MFMailComposeViewController()
        mailController.mailComposeDelegate = self
        mailController.setSubject(emailTitle)
        mailController.setToRecipients(toEmail)
        mailController.setMessageBody("", isHTML: false)
        
        presentViewController(mailController, animated: true, completion: nil)
    }
    
    // MARK: MailController Delegate Methods
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        switch result.value {
        case MFMailComposeResultCancelled.value:
            println("Mail Compose Cancelled")
            
        case MFMailComposeResultFailed.value:
            println("Mail Compose Failed: \(error), \(error?.userInfo)")
            
        case MFMailComposeResultSaved.value:
            println("Mail Compose Saved")
            
        case MFMailComposeResultSent.value:
            println("Mail Successfully Sent!")
            
        default:
            break
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Notifications
    
    func handleURL(notification: NSNotification) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let notificationInfo = notification.userInfo!
        let command = notificationInfo["command"] as! String
        
        if command == "open-today" {
            (UIApplication.sharedApplication().delegate as! AppDelegate).switchTabBarToTab(0)
        } else if command == "open-prayer" {
            let prayerID = Int32((notificationInfo["prayerID"] as! String).toInt()!)
            
            let prayerNavController = storyboard.instantiateViewControllerWithIdentifier(SBPrayerDetailsNavControllerID) as! UINavigationController
            let prayerDetailsController = prayerNavController.topViewController as! PrayerDetailsViewController
            prayerDetailsController.currentPrayer = PrayerStore.sharedInstance.getPrayerForID(prayerID)!
            prayerDetailsController.previousViewController = self
            
            presentViewController(prayerNavController, animated: true, completion: nil)
        }
    }
    
}
