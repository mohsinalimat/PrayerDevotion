//
//  PrayerDetailCells.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 5/31/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class PrayerAlertCell: UITableViewCell {
    
    var alertLabel: UILabel!
    var datePicker: UIDatePicker!
    
    var isEditingAlert: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        alertLabel = self.viewWithTag(1) as! UILabel
        datePicker = self.viewWithTag(2) as! UIDatePicker
    }
}
