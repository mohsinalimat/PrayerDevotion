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
import StoreKit

class SettingsViewController: UITableViewController, MFMailComposeViewControllerDelegate, PrayerDevotionStoreDelegate {
    
    @IBOutlet weak var colorLabel: UILabel!
    @IBOutlet weak var purchaseButton: UIButton!
    
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var verseView: UITextView!
    
    @IBOutlet weak var prayerDetailsAutoSwitch: UISwitch!
    
    @IBOutlet weak var cell: ThemeColorCell_New!
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let prayerStore = PrayerDevotionStore()
    
    var themeString: String!
    
    // MARK: StoreKit Variables
    var transactionInProgress = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 44.0
        tableView.estimatedRowHeight = 44.0
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleURL:", name: "HandleURLNotification", object: nil)
        prayerStore.requestProductInfo()
        prayerStore.delegate = self
        
        purchaseButton.enabled = !delegate.didBuyAdditionalFeatures
        //let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 3))
        
        if delegate.didBuyAdditionalFeatures {
            tableView.beginUpdates()
            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: 2, inSection: 3)], withRowAnimation: .None)
            tableView.endUpdates()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController!.navigationBar.tintColor = delegate.themeTintColor
        tableView.backgroundColor = delegate.themeBackgroundColor
        tableView.separatorColor = delegate.themeBackgroundColor
        
        colorLabel.text = "Theme Color: \(delegate.themeColorString)"
        
        // Because TableView is static, not much memory should be used by retaining one cell in memory
        cell.setThemeColor(delegate.themeBackgroundColor)
        
        verseView.textColor = delegate.themeTextColor
        
        tableView.reloadData()

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        cell.setThemeColor(delegate.themeBackgroundColor)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel!.textColor = delegate.themeTextColor
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
        case 1:
            if indexPath.row == 0 { UIApplication.sharedApplication().openURL(NSURL(string: "https://jonhartdevelopments.wordpress.com/prayerdevotion/prayerdevotion-support/")!) }
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            
        case 2: tableView.deselectRowAtIndexPath(indexPath, animated: true)
        default: break
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if delegate.didBuyAdditionalFeatures && indexPath.section == 3 && indexPath.row == 2 {
            return 0
        }
        
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    // MARK: Custom Functions
    func createEmailMessage(type: String) {
        var emailTitle = ""
        if type == "feedback" { emailTitle = "PrayerDevotion User Feedback" }
        else if type == "bug_report" { emailTitle = "PrayerDevotion User Bug Report" }
        else { emailTitle = "PrayerDevotion User Feature Request" }
        
        let toEmail = ["jonathanhart3000@gmail.com"]
        
        let mailController = MFMailComposeViewController()
        mailController.mailComposeDelegate = self
        mailController.setSubject(emailTitle)
        mailController.setToRecipients(toEmail)
        mailController.setMessageBody("", isHTML: false)
        
        presentViewController(mailController, animated: true, completion: nil)
    }
    
    // MARK: IBActions
    
    @IBAction func changeOpenDetailsAuto(sender: UISwitch) {
        let switchState = sender.on
        
        userDefaults.setBool(switchState, forKey: "openPrayerDetailsAuto")
    }
    
    @IBAction func purchaseAdditionalFeatures(sender: AnyObject) {
        prayerStore.askForAdditionalFeatures(false, completion: nil)
    }
    
    @IBAction func restoreAdditionalFeatures(sender: AnyObject) {
        prayerStore.restoreAdditionalFeatures()
    }
    
    // MARK: MailController Delegate Methods
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        switch result.rawValue {
        case MFMailComposeResultCancelled.rawValue:
            print("Mail Compose Cancelled")
            
        case MFMailComposeResultFailed.rawValue:
            print("Mail Compose Failed: \(error), \(error?.userInfo)")
            
        case MFMailComposeResultSaved.rawValue:
            print("Mail Compose Saved")
            
        case MFMailComposeResultSent.rawValue:
            print("Mail Successfully Sent!")
            
        default:
            break
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: PrayerDevotionStoreDelegate Methods
    
    func didPurchaseAdditionalFeatures() {
        tableView.beginUpdates()
        purchaseButton.enabled = !delegate.didBuyAdditionalFeatures
        
        tableView.endUpdates()
    }
    
    // MARK: Notifications
    
    func handleURL(notification: NSNotification) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let notificationInfo = notification.userInfo!
        let command = notificationInfo["command"] as! String
        
        if command == "open-today" {
            (UIApplication.sharedApplication().delegate as! AppDelegate).switchTabBarToTab(0)
        } else if command == "open-prayer" {
            let prayerID = Int32(Int((notificationInfo["prayerID"] as! String))!)
            
            let prayerNavController = storyboard.instantiateViewControllerWithIdentifier(SBPrayerDetailsNavControllerID) as! UINavigationController
            let prayerDetailsController = prayerNavController.topViewController as! PrayerDetailsViewController
            prayerDetailsController.currentPrayer = PrayerStore.sharedInstance.getPrayerForID(prayerID)!
            prayerDetailsController.previousViewController = self
            
            presentViewController(prayerNavController, animated: true, completion: nil)
        }
    }
    
}
