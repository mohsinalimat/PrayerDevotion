//
//  ThemeColorCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/25/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

class ThemeColorCell: UITableViewCell {
    
    var colorLabel: UILabel!
    var colorView: UIView!
    var color = UIColor(white: 1.0, alpha: 1.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        colorLabel = self.viewWithTag(1) as! UILabel
        colorView = self.viewWithTag(2)
        colorView.clipsToBounds = true
        colorView.layer.cornerRadius = 5
    }
    
    func setThemeColor(color: UIColor, isWhite: Bool = false) {
        colorView.backgroundColor = color
        
        self.color = color != Color.White ? color : Color.TrueWhite
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setThemeColor(color)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        setThemeColor(color)
    }
    
}
