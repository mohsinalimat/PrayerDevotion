//
//  PrayerPriorityCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/11/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class PrayerPriorityCell: UITableViewCell {
    
    var segmentedControl: UISegmentedControl!
    var currentPrayer: Prayer!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        segmentedControl = self.viewWithTag(1) as! UISegmentedControl
        segmentedControl.addTarget(self, action: "priorityChanged:", forControlEvents: .ValueChanged)
    }
    
    func priorityChanged(sender: AnyObject) {
        let segmentedControl = sender as! UISegmentedControl
        let selectedButton = segmentedControl.selectedSegmentIndex
        
        currentPrayer.priority = Int16(selectedButton)
        BaseStore.baseInstance.saveDatabase()
    }
}
