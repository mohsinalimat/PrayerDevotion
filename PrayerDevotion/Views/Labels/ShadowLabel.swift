//
//  ShadowLabel.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/26/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

class ShadowLabel: UILabel {
    
    override func drawTextInRect(rect: CGRect) {
        let myShadowOffset = CGSizeMake(0, 0)
        let myColorValues: [CGFloat] = [0, 0, 0, 0.5]
        
        let context = UIGraphicsGetCurrentContext() as CGContext!
        CGContextSaveGState(context)
        
        let myColorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB() as CGColorSpace!
        let myColor: CGColorRef = CGColorCreate(myColorSpace, myColorValues) as CGColor!
        CGContextSetShadowWithColor(context, myShadowOffset, 1, myColor)
        
        super.drawTextInRect(rect)
        
        CGContextRestoreGState(context)
    }
    
}
