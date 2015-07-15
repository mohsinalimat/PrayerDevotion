//
//  PrayerDetailsExtendedCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/3/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import PDKit

class PrayerDetailsExtendedCell: UITableViewCell, UITextViewDelegate {
    
    var detailsTextView: UITextView!
    var currentPrayer: PDPrayer!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        detailsTextView = self.viewWithTag(1) as! UITextView
        detailsTextView.scrollEnabled = false
        detailsTextView.delegate = self
        
        if let prayer = currentPrayer {
            refreshCell()
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            detailsTextView.becomeFirstResponder()
        } else {
            detailsTextView.resignFirstResponder()
        }
    }
    
    // MARK: Custom Methods
    
    func refreshCell() {
        // Check for details
        let prayerDetailsTrimmed = currentPrayer.details.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if prayerDetailsTrimmed == "" {
            detailsTextView.textColor = UIColor.lightGrayColor()
            detailsTextView.text = "Enter Additional Prayer Details"
        } else {
            detailsTextView.textColor = UIColor.blackColor()
            detailsTextView.text = currentPrayer.details
        }
    }
    
    // MARK: TextView Methods
    
    func textViewDidBeginEditing(textView: UITextView) {
        let prayerDetailsTrimmed = currentPrayer.details.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if prayerDetailsTrimmed == "" {
            textView.textColor = UIColor.grayColor()
            textView.text = ""
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        let size = textView.bounds.size
        let newSize = textView.sizeThatFits(CGSize(width: size.width, height: CGFloat.max))
        
        if size.height != newSize.height {
            UIView.setAnimationsEnabled(false)
            tableView?.beginUpdates()
            tableView?.endUpdates()
            UIView.setAnimationsEnabled(true)
            
            if let thisIndexPath = tableView?.indexPathForCell(self) {
                tableView?.scrollToRowAtIndexPath(thisIndexPath, atScrollPosition: .Bottom, animated: false)
            }
        }
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        let trimmedText = textView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if trimmedText == "" {
            currentPrayer.details == ""
            textView.textColor = UIColor.lightGrayColor()
            textView.text = "Enter Addition Prayer Details..."
        } else {
            currentPrayer.details = textView.text
        }
        
        return true
    }
    
}