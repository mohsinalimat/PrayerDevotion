//
//  TodayCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/11/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class TodayCell: UITableViewCell {
    
    var nameLabel: UILabel!
    var priorityLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        nameLabel = self.viewWithTag(1) as! UILabel
        priorityLabel = self.viewWithTag(2) as! UILabel
    }
    
}