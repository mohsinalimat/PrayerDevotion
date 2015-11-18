//
//  PrayerUpdateView.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 10/14/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import UIKit

class PrayerUpdateView: UIView {

    @IBOutlet weak var updateTitle: UILabel!
    @IBOutlet weak var updateTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!

    var view: UIView!
    
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
        
        addSubview(view)
    }
    
    func loadNIB() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "PrayerUpdateView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
