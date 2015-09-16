//
//  ThemeColorCustomViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 8/23/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit

class ThemeColorCustomViewController: UIViewController, RSColorPickerViewDelegate {
    
    var colorPicker: RSColorPickerView!
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var themeColorVC: ThemeColorViewController!
    var colorCell: ThemeColorCell?
    
    @IBOutlet weak var selectColorLabel: UILabel!
    @IBOutlet weak var brightnessLabel: UILabel!
    @IBOutlet weak var brightnessSlider: RSBrightnessSlider!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        colorPicker = RSColorPickerView(frame: CGRectMake(0, view.frame.size.height / 4, view.frame.size.width, view.frame.size.width))
        colorPicker.selectionColor = UIColor.whiteColor()
        colorPicker.showLoupe = false
        colorPicker.delegate = self
        
        view.addSubview(colorPicker)
        
        brightnessSlider.colorPicker = colorPicker
        
        colorPicker.selectionColor = delegate.themeBackgroundColor
        
        colorCell = themeColorVC.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as? ThemeColorCell
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: RSColorPicker Delegate Methods
    
    func colorPickerDidChangeSelection(cp: RSColorPickerView!) {
        print("Color Picker Changed Selection")
        
        let color = cp.selectionColor
        selectColorLabel.textColor = color.blackOrWhiteContrastingColor()
        
        userDefaults.setObject("Custom", forKey: "themeBackgroundColor")
        userDefaults.setObject("Custom", forKey: "themeTintColor")
        
        var red: CGFloat = 1.0
        var green: CGFloat = 1.0
        var blue: CGFloat = 1.0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        userDefaults.setFloat(Float(red), forKey: "customThemeColor_Red")
        userDefaults.setFloat(Float(green), forKey: "customThemeColor_Green")
        userDefaults.setFloat(Float(blue), forKey: "customThemeColor_Blue")
        
        userDefaults.synchronize()
        
        Color.setThemeColors(&delegate.themeBackgroundColor, tintColor: &delegate.themeTintColor, textColor: &delegate.themeTextColor, colorString: &delegate.themeColorString)
        
        (UIApplication.sharedApplication().delegate as! AppDelegate).window!.tintColor = delegate.themeTintColor
        self.view.backgroundColor = delegate.themeBackgroundColor
        self.navigationController!.navigationBar.tintColor = delegate.themeTintColor
        
        let brightness = colorPicker.brightness
        brightnessSlider.value = Float(brightness)
        
        print("Delegate Theme Color is \(delegate.themeBackgroundColor)")
    }
}
