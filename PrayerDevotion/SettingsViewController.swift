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
    
    @IBOutlet weak var todayOrderLabel: UILabel!
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        let todayType1 = PrayerType(rawValue: userDefaults.objectForKey("prayerTodayOrder_1") as! Int)!
        let todayType2 = PrayerType(rawValue: userDefaults.objectForKey("prayerTodayOrder_2") as! Int)!
        let todayType3 = PrayerType(rawValue: userDefaults.objectForKey("prayerTodayOrder_3") as! Int)!
        
        let todayOrderString = String(format: "%@, %@, %@", todayType1.description, todayType2.description, todayType3.description)
        
        todayOrderLabel.text = todayOrderString
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        var headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel.textColor = UIColor.whiteColor()
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0: break
        case 1:
            let todayOrderVC = mainStoryboard.instantiateViewControllerWithIdentifier("TodayOrderNavControllerID") as! UINavigationController
            presentViewController(todayOrderVC, animated: true, completion: nil)
            
        default: break
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let emailTypes = ["feedback", "bug_report", "feature_request"]
        
        switch indexPath.section {
        case 0: createEmailMessage(emailTypes[indexPath.row])
        case 1: break
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
    
}
