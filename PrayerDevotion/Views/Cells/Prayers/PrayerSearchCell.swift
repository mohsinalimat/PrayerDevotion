//
//  PrayerSearchCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 6/2/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class PrayerSearchCell: UITableViewCell {
    
    var prayerNameLabel: UILabel!
    var categoryNameLabel: UILabel!
    var priorityLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        prayerNameLabel = self.viewWithTag(1) as! UILabel
        categoryNameLabel = self.viewWithTag(2) as? UILabel
        priorityLabel = self.viewWithTag(3) as! UILabel
        
        let blurEffect = UIBlurEffect(style: .ExtraLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = frame
        
        backgroundView = blurView
    }
}