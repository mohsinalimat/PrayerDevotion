//
//  CategoryCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 5/13/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class CategoryCell: UITableViewCell {
    
    var categoryNameLabel: UILabel!
    var prayerCountLabel: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        categoryNameLabel = self.viewWithTag(1) as! UILabel
        prayerCountLabel = self.viewWithTag(2) as! UILabel
    }
    
}

class PrayerCell: UITableViewCell {
    
    var prayerNameLabel: UILabel!
    var dateCreatedLabel: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        prayerNameLabel = self.viewWithTag(1) as! UILabel
        dateCreatedLabel = self.viewWithTag(2) as! UILabel
    }
    
}

class CreatePrayerCell: UITableViewCell {
    
    var prayerTextField: UITextField!
    var currentCategory: Category?
        
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        prayerTextField = self.viewWithTag(1) as! UITextField
        
        assert(currentCategory == nil, "ERROR!!! CreatePrayerCell must have a non-nil category!!!!")
    }
}

