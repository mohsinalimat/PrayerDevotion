//
//  PrayerAnsweredNotesCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/3/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class PrayerAnsweredNoteCell: UITableViewCell, UITextViewDelegate {
    
    var answeredNotesView: UITextView?
    var currentPrayer: Prayer!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        answeredNotesView = self.viewWithTag(1) as? UITextView
        answeredNotesView?.scrollEnabled = false
        answeredNotesView?.delegate = self
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            answeredNotesView?.becomeFirstResponder()
        } else {
            answeredNotesView?.resignFirstResponder()
        }
    }
    
    // MARK: TextView Methods
    
    func textViewDidBeginEditing(textView: UITextView) {
        if currentPrayer.details == "" {
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
            currentPrayer.answeredNotes == ""
            textView.textColor = UIColor.lightGrayColor()
            textView.text = "Enter Answered Prayer Notes..."
        } else {
            currentPrayer.answeredNotes = textView.text
        }
        
        return true
    }
}