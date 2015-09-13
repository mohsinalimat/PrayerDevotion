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
    var changeCategoryButton: UIButton!
    
    var pickerView: UIPickerView!
    var newCategoryButton: UIButton!
    
    var isChangingCategory: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        prayerCategoryLabel = self.viewWithTag(1) as! UILabel
        changeCategoryButton = self.viewWithTag(2) as! UIButton
        
        pickerView = self.viewWithTag(3) as! UIPickerView
        newCategoryButton = self.viewWithTag(4) as! UIButton
    }
    
}
