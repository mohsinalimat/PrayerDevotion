// The MIT License (MIT)

// Copyright (c) 2014 Le Van Nghia

// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation
import UIKit

// MARK:
extension UIColor {
    convenience public init(hex: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hex & 0xFF00) >> 8) / 255.0
        let blue = CGFloat((hex & 0xFF)) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
}

////////// END LICENSE ///////////

////////// BEGIN COLOR SCHEME ////
// Created by Jonathan Hart, 07/24/2015

extension UINavigationBar {
    public func setThemeColor(color: UIColor, tintColor: UIColor) {
        self.barTintColor = color
        self.tintColor = tintColor
    }
}


struct Color {
    
    // Base Colors - 500s
    static let Red = UIColor(hex: 0xF44336, alpha: 1.0)
    static let Pink = UIColor(hex: 0xE91E63, alpha: 1.0)
    static let Purple = UIColor(hex: 0x9C27B0, alpha: 1.0)
    static let DeepPurple = UIColor(hex: 0x673AB7, alpha: 1.0)
    static let Indigo = UIColor(hex: 0x3F51B5, alpha: 1.0)
    static let Blue = UIColor(hex: 0x2196F3, alpha: 1.0)
    static let LightBlue = UIColor(hex: 0x03A9F4, alpha: 1.0)
    static let Cyan = UIColor(hex: 0x00BCD4, alpha: 1.0)
    static let Teal = UIColor(hex: 0x009688, alpha: 1.0)
    static let Green = UIColor(hex: 0x4CAF50, alpha: 1.0)
    static let LightGreen = UIColor(hex: 0x8BC34A, alpha: 1.0)
    static let Lime = UIColor(hex: 0xCDDC39, alpha: 1.0)
    static let Yellow = UIColor(hex: 0xFFEB3B, alpha: 1.0)
    static let Amber = UIColor(hex: 0xFFC107, alpha: 1.0)
    static let Orange = UIColor(hex: 0xFF9800, alpha: 1.0)
    static let DeepOrange = UIColor(hex: 0xFF5722, alpha: 1.0)
    static let Brown = UIColor(hex: 0x795548, alpha: 1.0)
    static let Grey = UIColor(hex: 0x9E9E9E, alpha: 1.0)
    static let BlueGrey = UIColor(hex: 0x607D8B, alpha: 1.0)
    static let White = UIColor(white: 0.93, alpha: 1.0)
    static let TrueWhite = UIColor(hex: 0xFFFFFF, alpha: 1.0)
    static let Black = UIColor(hex: 0x000000, alpha: 1.0)
    
    // Background Colors
    static let RedBack = UIColor(hex: 0xFFEBEE, alpha: 1.0)
    static let BrownBack = UIColor(hex: 0xEFEBE9, alpha: 1.0)
    
    // Converts a string to a color
    static func stringToColor(colorString: String) -> UIColor {
        switch colorString {
            case "Red": return Red
            case "Pink": return Pink
            case "Purple": return Purple
            case "Deep Purple": return DeepPurple
            case "Indigo": return Indigo
            case "Blue": return Blue
            case "Light Blue": return LightBlue
            case "Cyan": return Cyan
            case "Teal": return Teal
            case "Green": return Green
            case "Light Green": return LightGreen
            case "Lime": return Lime
            case "Yellow": return Yellow
            case "Amber": return Amber
            case "Orange": return Orange
            case "Deep Orange": return DeepOrange
            case "Brown": return Brown
            case "Grey": return Grey
            case "Blue Grey": return BlueGrey
            case "White": return White
            case "Black": return Black
            case "TrueWhite": return TrueWhite
            default: return UIColor(white: 1.0, alpha: 1.0)
        }
    }
    
    static func determineTextColor(backgroundColor: UIColor) -> String {
        switch backgroundColor {
        case White, TrueWhite, LightBlue, Cyan, LightGreen, Lime, Yellow, Amber, Orange:
            return "Black"
            
        default: return "TrueWhite"
        }
    }
}
