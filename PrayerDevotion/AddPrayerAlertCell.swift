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
import PDKit

class AddPrayerAlertCell: UITableViewCell {
    var saveButton: UIButton!
    var cancelButton: UIButton!
    
    var addNewAlertLabel: UILabel!
    var dateLabel: UILabel!
    
    var datePicker: UIDatePicker!
    
    var isAddingAlert: Bool = false
    var alertCount = 0
    
    var currentPrayer: PDPrayer!
    
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
    
    func refreshCell(didSelect: Bool, selectedPrayer: PDPrayer!) {
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.selectionStyle = didSelect == true ? .None : .Default
            
            self.saveButton.hidden = !didSelect
            self.cancelButton.hidden = !didSelect
            self.addNewAlertLabel.hidden = didSelect
            
            self.isAddingAlert = didSelect
            
            self.dateLabel.text = AlertStore.sharedInstance.convertDateToString(self.datePicker.date)
            
            //println("AddPrayerAlertCell: Cell Refreshed")
            
            self.tableView?.scrollEnabled = !didSelect
        //})
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
