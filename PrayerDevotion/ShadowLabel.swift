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
        var myShadowOffset = CGSizeMake(0, 0)
        var myColorValues: [CGFloat] = [0, 0, 0, 0.5]
        
        var context: CGContextRef = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)
        
        var myColorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()
        var myColor: CGColorRef = CGColorCreate(myColorSpace, myColorValues)
        CGContextSetShadowWithColor(context, myShadowOffset, 1, myColor)
        
        super.drawTextInRect(rect)
        
        CGContextRestoreGState(context)
    }
    
}
