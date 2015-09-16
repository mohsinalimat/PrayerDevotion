//
//  PrayerCells.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 6/1/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

// Used for getting the tableView the cell is contained in
extension UITableViewCell {
    var tableView: UITableView? {
        get {
            var table: UIView? = superview
            while !(table is UITableView) && table != nil {
                table = table?.superview
            }
            
            return table as? UITableView
        }
    }
}

class PrayerCell: UITableViewCell {
    
    var prayerNameLabel: UILabel!
    var dateCreatedLabel: UILabel!
    var priorityLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        prayerNameLabel = self.viewWithTag(1) as! UILabel
        dateCreatedLabel = self.viewWithTag(2) as! UILabel
        priorityLabel = self.viewWithTag(3) as! UILabel
    }
    
    func setPriorityText(priority: Int16) {
        switch priority {
        case 0: priorityLabel.text = ""
        case 1: priorityLabel.text = "!"
        case 2: priorityLabel.text = "!!"
        case 3: priorityLabel.text = "!!!"
        default: priorityLabel.text = ""
        }
    }
    
}