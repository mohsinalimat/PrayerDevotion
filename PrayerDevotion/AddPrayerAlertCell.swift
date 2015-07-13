//
//  AddPrayerAlertCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 6/1/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

class AddPrayerAlertCell: UITableViewCell {
    var saveButton: UIButton!
    var cancelButton: UIButton!
    
    var addNewAlertLabel: UILabel!
    var dateLabel: UILabel!
    
    var datePicker: UIDatePicker!
    
    var isAddingAlert: Bool = false
    var alertCount = 0
    
    var currentPrayer: Prayer!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        saveButton = self.viewWithTag(1) as! UIButton
        cancelButton = self.viewWithTag(2) as! UIButton
        
        addNewAlertLabel = self.viewWithTag(3) as! UILabel
        dateLabel = self.viewWithTag(5) as! UILabel
        
        datePicker = self.viewWithTag(4) as! UIDatePicker
        datePicker.date = NSDate()
        
        datePicker.addTarget(self, action: "dateChanged", forControlEvents: .ValueChanged)
        cancelButton.addTarget(self, action: "didCancelNewAlert", forControlEvents: .TouchDown)
        
        clipsToBounds = true
    }
    
    func refreshCell(didSelect: Bool, selectedPrayer: Prayer!) {
        selectionStyle = didSelect == true ? .None : .Default
        
        saveButton.hidden = !didSelect
        cancelButton.hidden = !didSelect
        addNewAlertLabel.hidden = didSelect
        
        isAddingAlert = didSelect
        
        dateLabel.text = AlertStore.sharedInstance.convertDateToString(datePicker.date)
        
        //println("AddPrayerAlertCell: Cell Refreshed")
        
        tableView?.scrollEnabled = !didSelect
    }

    func didCancelNewAlert() {
        tableView?.beginUpdates()
        refreshCell(false, selectedPrayer: currentPrayer)
        tableView?.endUpdates()
        
        selectionStyle = .Default
    }
    
    func dateChanged() {
        let date = datePicker.date
        
        dateLabel.text = AlertStore.sharedInstance.convertDateToString(date)
    }
    
}
