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

class SettingsViewController: UITableViewController, UITableViewDataSource, MFMailComposeViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        var headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel.textColor = UIColor.whiteColor()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            createEmailMessage(indexPath.row == 0 ? "feedback" : "bug_report")
        }
    }
    
    // MARK: Custom Functions
    func createEmailMessage(type: String) {
        let emailTitle = type == "feedback" ? "PrayerDevotion User Feedback" : "PrayerDevotion User Bug Report"
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
