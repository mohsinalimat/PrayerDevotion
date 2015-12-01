//
//  TodaySplitViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 11/27/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class TodaySplitViewController: UISplitViewController, UISplitViewControllerDelegate, TodayCalendarViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        assignCalendarDelegate()
        
        self.presentsWithGesture = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func assignCalendarDelegate() {
        let calendarVC = (self.viewControllers.first as! UINavigationController).topViewController as! TodayCalendarViewController
        
        calendarVC.delegate = self
    }
    
    // MARK: Custom Methods
    
    func dateToLocalTime(date: NSDate) -> NSDate {
        let timezone = NSTimeZone.defaultTimeZone()
        let seconds = Double(timezone.secondsFromGMTForDate(date))
        return NSDate(timeInterval: seconds, sinceDate: date)
    }
    
    // UISplitViewController Delegate Methods
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {        
        return false
    }
    
    func splitViewController(splitViewController: UISplitViewController, separateSecondaryViewControllerFromPrimaryViewController primaryViewController: UIViewController) -> UIViewController? {
        if primaryViewController is UINavigationController {
            for controller in (primaryViewController as! UINavigationController).viewControllers {
                if controller is UINavigationController && (controller as! UINavigationController).visibleViewController is TodayPrayersViewController {
                    return controller
                }
            }
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navController = storyboard.instantiateViewControllerWithIdentifier(SBTodayCalendarNavID)
        
        return navController
    }
    
    // MARK: TodayCalendarViewController Delegate Methods
    
    func didSelectNewDate(date: NSDate) {
        let todayVC = (self.viewControllers.last as! UINavigationController).topViewController as! TodayPrayersViewController
        
        print("Bob is: \(date)")
        todayVC.changeDate(date)
    }
}