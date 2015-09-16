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
    var categoryImageView: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        categoryNameLabel = self.viewWithTag(1) as! UILabel
        prayerCountLabel = self.viewWithTag(2) as! UILabel
        categoryImageView = self.viewWithTag(3) as! UIImageView
    }
    
}

