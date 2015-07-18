//
//  PrayerCategoryCEll.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/16/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class PrayerCategoryCell: UITableViewCell {
    
    var prayerCategoryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        prayerCategoryLabel = self.viewWithTag(1) as! UILabel
    }
    
}
