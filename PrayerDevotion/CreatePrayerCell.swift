//
//  CreatePrayerCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/3/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import PDKit

class CreatePrayerCell: UITableViewCell {
    
    var prayerTextField: UITextField!
    var currentCategory: PDCategory?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        prayerTextField = self.viewWithTag(1) as! UITextField
        
        assert(currentCategory == nil, "ERROR!!! CreatePrayerCell must have a non-nil category!!!!")
    }
}