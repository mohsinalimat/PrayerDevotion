//
//  PrayerNameCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/11/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class PrayerNameCell: UITableViewCell {
    
    var nameField: UITextField!
    var currentPrayer: Prayer!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        nameField = self.viewWithTag(1) as! UITextField
    }
    
}
