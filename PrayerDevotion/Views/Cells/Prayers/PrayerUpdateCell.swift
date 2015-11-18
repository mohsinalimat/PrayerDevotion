//
//  PrayerUpdateCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 10/14/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class PrayerUpdateCell: UITableViewCell {
    
    var dateLabel: UILabel!
    var timestampLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        dateLabel = self.viewWithTag(1) as! UILabel
        timestampLabel = self.viewWithTag(2) as! UILabel
    }
    
}