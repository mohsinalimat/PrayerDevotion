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
    var color: UIColor {
        get {
            return answeredLabel.textColor
        }
        
        set(color) {
            answeredLabel.textColor = color
            answeredLabel.highlightedTextColor = color
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        answeredLabel = self.viewWithTag(1) as! UILabel
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        answeredLabel.textColor = color
        super.setSelected(selected, animated: animated)
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        answeredLabel.textColor = color
        super.setSelected(selected, animated: animated)
    }
}