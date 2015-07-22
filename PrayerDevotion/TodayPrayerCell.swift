//
//  TodayPrayerCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/19/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class TodayPrayerCell: UITableViewCell {
    
    var nameLabel: UILabel!
    var priorityLabel: UILabel!
    var prayerTypeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        nameLabel = self.viewWithTag(1) as! UILabel
        prayerTypeLabel = self.viewWithTag(2) as! UILabel
        priorityLabel = self.viewWithTag(3) as! UILabel
    }
    
}
