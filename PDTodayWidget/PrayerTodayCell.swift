//
//  PrayerTodayCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/15/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class PrayerTodayCell: UITableViewCell {
    
    var prayerTitleLabel: UILabel!
    var prayerTyleLabel: UILabel!
    var priorityLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        prayerTitleLabel = self.viewWithTag(1) as! UILabel
        prayerTyleLabel = self.viewWithTag(2) as! UILabel
        priorityLabel = self.viewWithTag(3) as! UILabel
    }
    
}
