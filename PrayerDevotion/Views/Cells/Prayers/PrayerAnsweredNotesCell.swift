//
//  PrayerAnsweredNotesCell.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/3/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import PDKit

class PrayerAnsweredNoteCell: UITableViewCell, UITextViewDelegate {
    
    var answeredNotesView: UITextView!
    var currentPrayer: PDPrayer!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        answeredNotesView = self.viewWithTag(1) as! UITextView
        answeredNotesView.scrollEnabled = false
        answeredNotesView.delegate = self
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if selected {
            answeredNotesView.becomeFirstResponder()
        } else {
            answeredNotesView.resignFirstResponder()
        }
    }
    
    // MARK: Custom Methods
    
    func refreshCell() {
        // Check for answered details
        let answeredDetailsTrimmed = currentPrayer.answeredNotes.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if answeredDetailsTrimmed == "" {
            answeredNotesView.textColor = UIColor.lightGrayColor()
            answeredNotesView.text = "Enter Answered Prayer Notes..."
        } else {
            answeredNotesView.textColor = UIColor.blackColor()
            answeredNotesView.text = currentPrayer.answeredNotes
        }
    }
    
    // MARK: TextView Methods
    
    func textViewDidBeginEditing(textView: UITextView) {
        let answeredDetailsTrimmed = currentPrayer.answeredNotes.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if answeredDetailsTrimmed == "" {
            textView.textColor = UIColor.blackColor()
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
        }
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        let trimmedText = textView.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if trimmedText == "" {
            currentPrayer.answeredNotes == ""
            textView.textColor = UIColor.lightGrayColor()
            textView.text = "Enter Answered Prayer Notes..."
        } else {
            textView.textColor = UIColor.blackColor()
            currentPrayer.answeredNotes = textView.text
        }
        
        BaseStore.baseInstance.saveDatabase()
        
        return true
    }
}