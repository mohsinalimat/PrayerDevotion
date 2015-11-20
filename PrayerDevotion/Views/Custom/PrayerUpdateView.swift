//
//  PrayerUpdateView.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 10/14/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import UIKit

protocol PrayerUpdateViewDelegate {
    func prayerUpdateView(updateView: PrayerUpdateView, didSaveUpdate update: String, isNewUpdate isNew: Bool, creationTime timestamp: NSDate)
    func prayerUpdateViewDidCancelUpdate(updateView: PrayerUpdateView)
}

class PrayerUpdateView: UIView {

    @IBOutlet weak var updateTitle: UILabel!
    @IBOutlet weak var updateTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!

    var view: UIView!
    var newUpdate: Bool = false
    var timestamp: NSDate = NSDate()
    
    var delegate: PrayerUpdateViewDelegate?
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }

    func xibSetup() {
        view = loadNIB()
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        view.layer.cornerRadius = 5
        view.clipsToBounds = true
        
        saveButton.addTarget(self, action: "saveUpdate:", forControlEvents: .TouchDown)
        cancelButton.addTarget(self, action: "cancelUpdate:", forControlEvents: .TouchDown)
        
        let doneToolbar = UIToolbar()
        doneToolbar.barStyle = .Default
        
        let doneAction = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: "textEndEditing:")
        doneAction.tintColor = UIColor.blackColor()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        doneToolbar.items = [flexSpace, doneAction]
        
        doneToolbar.sizeToFit()
        
        updateTextView.inputAccessoryView = doneToolbar
        addSubview(view)
    }
    
    func loadNIB() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "PrayerUpdateView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    // MARK: Custom Methods
    
    func saveUpdate(sender: UIButton) {
        let updateString = updateTextView.text
        
        delegate?.prayerUpdateView(self, didSaveUpdate: updateString, isNewUpdate: newUpdate, creationTime: timestamp)
    }
    
    func cancelUpdate(sender: UIButton) {
        delegate?.prayerUpdateViewDidCancelUpdate(self)
    }
    
    func textEndEditing(sender: UIButton) {
        updateTextView.endEditing(true)
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
