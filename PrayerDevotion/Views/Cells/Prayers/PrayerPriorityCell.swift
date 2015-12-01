//
//  PrayerPriorityCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/11/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import PDKit

class PrayerPriorityCell: UITableViewCell {
    
    var segmentedControl: UISegmentedControl!
    var priorityLabel: UILabel!
    var currentPrayer: PDPrayer!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        segmentedControl = self.viewWithTag(1) as! UISegmentedControl
        segmentedControl.addTarget(self, action: "priorityChanged:", forControlEvents: .ValueChanged)
        
        priorityLabel = self.viewWithTag(2) as! UILabel
    }
    
    func priorityChanged(sender: AnyObject) {
        let segmentedControl = sender as! UISegmentedControl
        let selectedButton = segmentedControl.selectedSegmentIndex
        
        print("New Priority: \(selectedButton)")
        
        currentPrayer.priority = Int16(selectedButton)
        BaseStore.baseInstance.saveDatabase()
    }
}
