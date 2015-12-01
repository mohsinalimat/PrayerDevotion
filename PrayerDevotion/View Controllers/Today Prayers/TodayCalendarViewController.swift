//
//  TodayCalendarViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 11/26/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import FSCalendar

extension NSDate {
    func toLocalTime() -> NSDate {
        let timezone = NSTimeZone.defaultTimeZone()
        let seconds = Double(timezone.secondsFromGMTForDate(self))
        return NSDate(timeInterval: seconds, sinceDate: self)
    }
    
    func toGlobalTime() -> NSDate {
        let timezone = NSTimeZone.defaultTimeZone()
        let seconds = Double(-timezone.secondsFromGMTForDate(self))
        return NSDate(timeInterval: seconds, sinceDate: self)
    }
}

protocol TodayCalendarViewControllerDelegate {
    func didSelectNewDate(var date: NSDate)
}

class TodayCalendarViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource {
    
    @IBOutlet var calendarView: FSCalendar!
    @IBOutlet var nextMonthButton: UIButton!
    @IBOutlet var prevMonthButton: UIButton!
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var delegate: TodayCalendarViewControllerDelegate?
    
    var directionItem: UIBarButtonItem!
    var selectedDate = NSDate().toLocalTime()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        calendarView.scrollDirection = .Vertical
        calendarView.selectDate(NSDate().toLocalTime())
        calendarView.delegate = self
        
        calendarView.identifier = NSCalendarIdentifierGregorian
        
        directionItem = UIBarButtonItem(title: "Scroll Direction: \(calendarView.scrollDirection == .Horizontal ? "Horizontal" : "Vertical")", style: .Plain, target: self, action: "changeScrollDirection:")
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        self.toolbarItems = [flexSpace, directionItem, flexSpace]
        self.navigationController!.toolbarHidden = false
        
        prepareView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        prepareView()
    }
    
    func prepareView() {
        calendarView.selectionColor = appDelegate.themeTextColor
        calendarView.titleSelectionColor = appDelegate.themeTextColor == Color.TrueWhite ? Color.Black : Color.TrueWhite
        calendarView.titleDefaultColor = appDelegate.themeTextColor
        calendarView.headerTitleColor = appDelegate.themeTextColor
        calendarView.weekdayTextColor = appDelegate.themeTextColor
        calendarView.titleTodayColor = appDelegate.themeTextColor
        
        nextMonthButton.tintColor = appDelegate.themeTextColor
        prevMonthButton.tintColor = appDelegate.themeTextColor
        self.view.backgroundColor = appDelegate.themeBackgroundColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Custom Methods
    
    func changeScrollDirection(sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: "Change Scroll Direction", message: "Change calendar scrolling direction to horizonatal or vertical", preferredStyle: .ActionSheet)
        
        let horizontalAction = UIAlertAction(title: "Horizontal", style: .Default, handler: { alertAction in
            self.calendarView.scrollDirection = .Horizontal
            
            self.directionItem.title = "Scroll Direction: Horizontal"
        })
        
        let verticalAction = UIAlertAction(title: "Vertical", style: .Default, handler: { alertAction in
            self.calendarView.scrollDirection = .Vertical
            
            self.directionItem.title = "Scroll Direction: Vertical"
        })
        
        actionSheet.addAction(horizontalAction)
        actionSheet.addAction(verticalAction)
        
        actionSheet.popoverPresentationController?.barButtonItem = sender
        actionSheet.popoverPresentationController?.sourceView = self.view
        
        presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: IBActions
    
    @IBAction func prevMonth(sender: AnyObject) {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Year, .Month, .Day], fromDate: selectedDate)
        components.month -= 1
        components.day = 1
        let newDate = calendar.dateFromComponents(components)
        self.calendarView.selectDate(newDate, scrollToDate: true)
        selectedDate = newDate!
        
        delegate?.didSelectNewDate(newDate!)
    }
    
    @IBAction func nextMonth(sender: AnyObject) {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Year, .Month, .Day], fromDate: selectedDate)
        components.month += 1
        components.day = 1
        let newDate = calendar.dateFromComponents(components)
        //let newDate = calendar.dateByAddingComponents(components, toDate: selectedDate, options: NSCalendarOptions(rawValue: 0))
        self.calendarView.selectDate(newDate, scrollToDate: true)
        selectedDate = newDate!
        
        delegate?.didSelectNewDate(newDate!)
    }
        
    // MARK: FSCalendar Delegate and DataSource Methods
    
    func calendar(calendar: FSCalendar!, didSelectDate date: NSDate!) {
        print("New Date Selected: \(date.toGlobalTime())")
        delegate?.didSelectNewDate(date.toGlobalTime())
        selectedDate = date.toLocalTime()
    }
}