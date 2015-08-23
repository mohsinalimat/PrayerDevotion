//
//  AddPrayerDateCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 6/6/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import PDKit

class AddPrayerDateCell: UITableViewCell, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var addDateLabel: UILabel!
    var dateLabel: UILabel!
    var datePicker: UIDatePicker!
    var weekdayPicker: UIPickerView!
    
    var onDateButton: UIButton!
    var dailyButton: UIButton!
    var weeklyButton: UIButton!
    
    var saveButton: UIButton!
    //var cancelButton: UIButton!
    
    var currentPrayer: PDPrayer!
    
    var selectedType: PrayerType?
    var isAddingDate: Bool = false
    var didAddDate: Bool = false
    var weekday: String?
    var dateToAdd: NSDate = NSDate()
    
    let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Connect the cell views to their corresponding variables via viewWithTag()
        addDateLabel = viewWithTag(1) as! UILabel
        datePicker = viewWithTag(2) as! UIDatePicker
        weekdayPicker = viewWithTag(3) as! UIPickerView
        
        onDateButton = viewWithTag(5) as! UIButton
        dailyButton = viewWithTag(6) as! UIButton
        weeklyButton = viewWithTag(7) as! UIButton
        
        saveButton = viewWithTag(8) as! UIButton
        //cancelButton = viewWithTag(9) as! UIButton
        
        // Add click actions to the buttons
        onDateButton.addTarget(self, action: "didClickButton:", forControlEvents: .TouchDown)
        dailyButton.addTarget(self, action: "didClickButton:", forControlEvents: .TouchDown)
        weeklyButton.addTarget(self, action: "didClickButton:", forControlEvents: .TouchDown)
        
        saveButton.addTarget(self, action: "didAddPrayerDate:", forControlEvents: .TouchDown)
        //cancelButton.addTarget(self, action: "didCancelAddingDate:", forControlEvents: .TouchDown)
        
        datePicker.addTarget(self, action: "dateChanged:", forControlEvents: .ValueChanged)
        
        // Set the weekday UIPickerView delegate to the current cell
        weekdayPicker.delegate = self
        
        if let prayer = currentPrayer {
            // Get the prayerType from the currentPrayer and convert it to a value of type
            // PrayerType
            var prayerType = PrayerStore.sharedInstance.stringToPrayerType(prayer.prayerType!)
            selectedType = prayerType // Now set the selectedType to this prayerType
        } else {
            selectedType = .None
        }
    }
    
    func refreshCell(didSelect: Bool, selectedPrayer: PDPrayer) {
        if selectedPrayer.answered == true {
            addDateLabel.text = "No Prayer Date"
            addDateLabel.textColor = UIColor.lightGrayColor()
            selectionStyle = .None
            saveButton.hidden = true
        } else {
            selectionStyle = didSelect == true ? .None : .Default
            addDateLabel.textColor = (UIApplication.sharedApplication().delegate as! AppDelegate).themeTintColor
        
            let type = selectedPrayer.prayerType!
        
            // Format prayer type
            var prayerType: PrayerType = PrayerStore.sharedInstance.stringToPrayerType(type)
            selectedType = prayerType
        
            if selectedType == nil {
                selectedType = .None
            }
        
            switch selectedType! {
            case .OnDate:
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateStyle = .LongStyle
                dateFormatter.timeStyle = .NoStyle
            
                datePicker.setDate(selectedPrayer.addedDate == nil ? NSDate() : selectedPrayer.addedDate!, animated: false)
                addDateLabel.text = "Prayer Due on \(dateFormatter.stringFromDate(datePicker.date))"
                didAddDate = selectedPrayer.isDateAdded
            
            case .Daily:
                addDateLabel.text = "Prayer Repeating Every Day"
                didAddDate = selectedPrayer.isDateAdded
            
            case .Weekly:
                let today = NSDate()
                let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
                let comps = calendar!.components(.CalendarUnitDay | .CalendarUnitWeekday, fromDate: today)
                let day = comps.weekday
            
                let row = selectedPrayer.weekday == nil ? day - 1 : find(weekdays, selectedPrayer.weekday!)!
            
                weekdayPicker.selectRow(row, inComponent: 0, animated: false)
                weekday = pickerView(weekdayPicker, titleForRow: row, forComponent: 0)
            
                if let selectedWeekday = selectedPrayer.weekday {
                    addDateLabel.text = "Prayer Repeating Every \(selectedWeekday)"
                }
                didAddDate = selectedPrayer.isDateAdded
            
            default:
                didAddDate = false
            }
        
            if didAddDate == false {
                addDateLabel.text = "Set Prayer Date"
            }
        
            isAddingDate = didSelect
        
            // Now hide/show buttons as selected
            weekdayPicker.hidden = !(selectedType == .Weekly)
            datePicker.hidden = !(selectedType == .OnDate)
        
            addDateLabel.hidden = didSelect
            saveButton.hidden = !didSelect
            /*if didSelect == true {
                cancelButton.hidden = false
                cancelButton.setTitle(didAddDate == true ? "Remove" : "Cancel", forState: .Normal)
                cancelButton.addTarget(self, action: didAddDate == true ? "didRemoveDate:" : "didCancelAddingDate:", forControlEvents: .TouchDown)
            } else {
                cancelButton.hidden = true
            }*/
        
            // Format buttons
            formatButton(onDateButton, didSelect: selectedType == .OnDate)
            formatButton(dailyButton, didSelect: selectedType == .Daily)
            formatButton(weeklyButton, didSelect: selectedType == .Weekly)
        
            tableView?.scrollEnabled = !didSelect
        }
    }
    
    func didClickButton(sender: AnyObject) {
        tableView?.beginUpdates()
        
        let button = sender as! UIButton
        let buttonTitle = button.titleLabel!.text
        
        selectedType = PrayerStore.sharedInstance.stringToPrayerType(buttonTitle!)
        currentPrayer.prayerType = selectedType!.description
        
        if selectedType == .OnDate {
            datePicker.minimumDate = NSDate()
        }
        
        //configureView()
        refreshCell(true, selectedPrayer: currentPrayer)
        
        tableView?.endUpdates()
        
        tableView?.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 4), atScrollPosition: .Bottom, animated: true)
    }
    
    func formatButton(button: UIButton, didSelect selected: Bool) {
        button.layer.borderColor = selected == true ? tintColor.CGColor : UIColor.clearColor().CGColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
    }
    
    // MARK: Custom Functions
    
    func didAddPrayerDate(sender: AnyObject) {
        if let type = selectedType {
            tableView?.beginUpdates()
            
            switch type {
            case .OnDate: PrayerStore.sharedInstance.addDateToPrayer(currentPrayer, prayerType: "On Date", date: dateToAdd, weekday: nil)
            case .Daily: PrayerStore.sharedInstance.addDateToPrayer(currentPrayer, prayerType: "Daily", date: nil, weekday: nil)
            case .Weekly: PrayerStore.sharedInstance.addDateToPrayer(currentPrayer, prayerType: "Weekly", date: nil, weekday: weekday)
            default: break
            }
            
            println("Current Prayer Type is: \(currentPrayer.prayerType)")
            println("Current Prayer Date is: \(currentPrayer.addedDate)")
            println("Current Prayer Weekday is \(currentPrayer.weekday)")
            
            selectionStyle = .Default
            
            refreshCell(false, selectedPrayer: currentPrayer)
            tableView?.endUpdates()
            
            tableView?.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 4), atScrollPosition: .Bottom, animated: true)
        } else {
            println("Error! Selected Type is nil!")
        }
    }
    
    func didRemoveDate(sender: AnyObject) {
        PrayerStore.sharedInstance.removeDateFromPrayer(currentPrayer)
        isAddingDate = false
        selectedType = .None
        addDateLabel.text = "Set Prayer Date"
        
        tableView?.beginUpdates()
        refreshCell(false, selectedPrayer: currentPrayer)
        tableView?.endUpdates()
    }
    
    func didCancelAddingDate(sender: AnyObject) {
        isAddingDate = false
        
        tableView?.beginUpdates()
        refreshCell(false, selectedPrayer: currentPrayer)
        tableView?.endUpdates()
    }
    
    // MARK: UIPickerView Functions
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return weekdays.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return weekdays[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        weekday = weekdays[row]
    }
    
    // MARK: Dates
    
    func dateChanged(sender: AnyObject) {
        println("Date Changed")
        
        let picker = sender as! UIDatePicker
        let date = picker.date
        
        dateToAdd = date
        
        println("Adding date: \(dateToAdd)")
    }
    
}
