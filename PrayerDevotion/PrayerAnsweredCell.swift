//
//  PrayerAnsweredCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/3/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class PrayerAnsweredCell: UITableViewCell {
    
    var answeredLabel: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        answeredLabel = self.viewWithTag(1) as! UILabel
    }
}