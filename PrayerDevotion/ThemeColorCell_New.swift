//
//  ThemeColorCell_New.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 8/26/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class ThemeColorCell_New: UITableViewCell {
    
    var colorLabel: UILabel!
    var colorView: UIView!
    
    // This is the theme color of the cell - it is private
    private var themeColor = UIColor(white: 1.0, alpha: 1.0)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        colorLabel = self.viewWithTag(1) as! UILabel
        colorView = self.viewWithTag(2)
        
        colorView.clipsToBounds = true
        colorView.layer.cornerRadius = 5
        
        setThemeColor(themeColor)
    }
    
    func setThemeColor(color: UIColor) {
        themeColor = color
        colorView.backgroundColor = themeColor
        
        var white: CGFloat = 0.0
        color.getWhite(&white, alpha: nil)
        
        colorView.layer.borderWidth = white > 0.9 ? 1 : 0
        colorView.layer.borderColor = Color.Black.CGColor
    }
    
    func getColor() -> UIColor {
        return themeColor
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        colorView.backgroundColor = themeColor
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        colorView.backgroundColor = themeColor
    }
    
}
