//
//  AddPrayerDateCell_New.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 9/11/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import PDKit

protocol AddPrayerDateCellDelegate_New {
    func didAddPrayerDate(cell: AddPrayerDateCell_New)
    func didCancelAddingPrayerDate(cell: AddPrayerDateCell_New)
}

class AddPrayerDateCell_New: UITableViewCell, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var delegate: AddPrayerDateCellDelegate_New?
    var appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var addDateButton: UIButton!
    var dateLable: UILabel!
    var datePicker: UIDatePicker!
    var weekdayPicker: UIPickerView!
    
    var onDateButton: UIButton!
    var dailyButton: UIButton!
    var weeklyButton: UIButton!
    
    // NOTE: No longer in use!
    // var saveButton: UIButton!
    
    var currentPrayer: PDPrayer? // Current Prayer can be nil
    
    var selectedType: PrayerType = .None
    var isAddingDate: Bool = false
    var didAddDate: Bool {
        return selectedType != .None
    }
    var weekday: String?
    var dateToAdd = NSDate()
    
    let dateFormatter = NSDateFormatter()
    let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Connect the cell views to their corresponding variables via viewWithTag()
        addDateButton = viewWithTag(1) as! UIButton
        datePicker = viewWithTag(2) as! UIDatePicker
        weekdayPicker = viewWithTag(3) as! UIPickerView
        
        onDateButton = viewWithTag(5) as! UIButton
        dailyButton = viewWithTag(6) as! UIButton
        weeklyButton = viewWithTag(7) as! UIButton
        
        // Add click actions to the buttons
        onDateButton.addTarget(self, action: "didChangeDateType:", forControlEvents: .TouchDown)
        dailyButton.addTarget(self, action: "didChangeDateType:", forControlEvents: .TouchDown)
        weeklyButton.addTarget(self, action: "didChangeDateType:", forControlEvents: .TouchDown)
        
        datePicker.addTarget(self, action: "dateChanged:", forControlEvents: .ValueChanged)
        
        addDateButton.addTarget(self, action: "buttonClicked:", forControlEvents: .TouchDown)
        
        // Set the weekday UIPickerView delegate to the current cell
        weekdayPicker.delegate = self
        
        // Set Date Formatter Styles
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .NoStyle
    }
    
    func getSelectedType() -> PrayerType {
        if let prayer = currentPrayer {
            let type = PrayerStore.sharedInstance.stringToPrayerType(prayer.prayerType!)
            return type
        }
        
        return .None
    }
    
    func refreshCell(didSelect: Bool) {
        print("Did Select: \(didSelect)")
        
        if let prayer = currentPrayer {
            if prayer.answered == true {
                addDateButton.setTitle("No Prayer Date", forState: .Normal)//; addDateButton.tintColor = UIColor.lightGrayColor()
                addDateButton.enabled = false
                
                selectionStyle = .None
            } else {
                selectionStyle = .None
                isAddingDate = didSelect
                
                selectedType = getSelectedType()
                
                //addDateButton.textColor = appDelegate.themeTintColor
                
                switch selectedType {
                case .OnDate:
                    datePicker.setDate(prayer.addedDate == nil ? NSDate() : prayer.addedDate!, animated: false)
                    addDateButton.setTitle("Prayer Due on \(dateFormatter.stringFromDate(datePicker.date))", forState: .Normal)
                    
                case .Daily:
                    addDateButton.setTitle("Prayer Repeating Every Day", forState: .Normal)
                    
                case .Weekly:
                    let today = NSDate()
                    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
                    let comps = calendar!.components([.Day, .Weekday], fromDate: today)
                    let day = comps.weekday
                    
                    // Get pickerView row
                    let row = prayer.weekday == nil ? day - 1 : weekdays.indexOf((prayer.weekday!))!
                    
                    // Set pickerView row
                    weekdayPicker.selectRow(row, inComponent: 0, animated: false)
                    weekday = pickerView(weekdayPicker, titleForRow: row, forComponent: 0)
                    
                    addDateButton.setTitle("Prayer Repeating Every \(weekday!)", forState: .Normal)
                    
                default:
                    addDateButton.setTitle("Set Prayer Date", forState: .Normal)
                }
                
                weekdayPicker.hidden = !(selectedType == .Weekly)
                datePicker.hidden = !(selectedType == .OnDate)
                
                // Format Buttons
                formatButton(onDateButton, didSelect: selectedType == .OnDate)
                formatButton(dailyButton, didSelect: selectedType == .Daily)
                formatButton(weeklyButton, didSelect: selectedType == .Weekly)
            }
        } else {
            print("Current Prayer Not Set")
        }
    }
    
    func didChangeDateType(sender: AnyObject) {
        tableView?.beginUpdates()
        let button = sender as! UIButton
        let buttonTitle = button.titleLabel!.text!
        
        let newType = PrayerStore.sharedInstance.stringToPrayerType(buttonTitle)
        
        print("\(selectedType.description)")
        if let currentPrayer = currentPrayer {
            currentPrayer.prayerType = newType.description
        }
        BaseStore.baseInstance.saveDatabase()
        
        selectedType = getSelectedType()
        
        if selectedType == .OnDate {
            datePicker.minimumDate = NSDate()
            dateToAdd = datePicker.date
        }
        
        tableView?.endUpdates()
        
        tableView?.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2), atScrollPosition: .Bottom, animated: true)
        
        print("\(selectedType.description)")
        refreshCell(true)
    }
    
    func formatButton(button: UIButton, didSelect selected: Bool) {
        button.layer.borderColor = selected == true ? tintColor.CGColor : UIColor.clearColor().CGColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
    }
    
    func savePrayerDate() {
        switch selectedType {
        case .OnDate: PrayerStore.sharedInstance.addDateToPrayer(currentPrayer!, prayerType: "On Date", date: dateToAdd, weekday: nil)
        case .Daily: PrayerStore.sharedInstance.addDateToPrayer(currentPrayer!, prayerType: "Daily", date: nil, weekday: nil)
        case .Weekly: PrayerStore.sharedInstance.addDateToPrayer(currentPrayer!, prayerType: "Weekly", date: nil, weekday: weekday!)
        default: break
        }
        
        print("Current Prayer Type is: \(currentPrayer!.prayerType)")
        print("Current Prayer Date is: \(currentPrayer!.addedDate)")
        print("Current Prayer Weekday is \(currentPrayer!.weekday)")
        
        refreshCell(isAddingDate)
        
        delegate?.didAddPrayerDate(self)
    }
    
    func didRemoveDate(sender: AnyObject) {
        PrayerStore.sharedInstance.removeDateFromPrayer(currentPrayer!)
        isAddingDate = false
        selectedType = .None
        addDateButton.setTitle("Set Prayer Date", forState: .Normal)
        
        refreshCell(false)
        delegate?.didCancelAddingPrayerDate(self)
    }
    
    // MARK: UIPickerView Functions
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return weekdays.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return weekdays[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        weekday = weekdays[row]
        savePrayerDate()
    }
    
    // MARK: Dates
    
    func dateChanged(sender: AnyObject) {
        print("Date Changed")
        
        let picker = sender as! UIDatePicker
        let date = picker.date
        
        dateToAdd = date
        
        print("Adding date: \(dateToAdd)")
        
        savePrayerDate()
    }
    
    func buttonClicked(sender: UIButton) {
        tableView?.beginUpdates()
        refreshCell(!isAddingDate)        
        tableView?.endUpdates()
    }
}
