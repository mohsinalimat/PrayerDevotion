//
//  MovePrayersViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 6/1/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import PDKit

class MovePrayersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var fromCategory: PDCategory!
    var deletingCategory: Bool = false
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var moveLabel: UILabel!
    
    private var fetchedCategories: NSArray!
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("View Did Load")
        
        fetchedCategories = CategoryStore.sharedInstance.fetchCategoriesForMove(fromCategory.name)
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
        tableView.backgroundView = blurView
        tableView.backgroundColor = UIColor.clearColor()
        
        moveLabel.layer.shadowColor = UIColor.blackColor().CGColor
        moveLabel.layer.shadowRadius = 5
        moveLabel.layer.shadowOpacity = 0.5
        moveLabel.layer.shadowOffset = CGSizeMake(0, -0.5)
        
        tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController!.navigationBar.tintColor = delegate.themeTintColor
        view.backgroundColor = delegate.themeBackgroundColor
        moveLabel.backgroundColor = delegate.themeBackgroundColor
        moveLabel.textColor = delegate.themeTextColor
    }
    
    // MARK: TableView Methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedCategories.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MoveCategoriesCellID, forIndexPath: indexPath)
        
        cell.textLabel?.text = (fetchedCategories[indexPath.row] as! PDCategory).name
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let toCategory = fetchedCategories[indexPath.row] as! PDCategory
        
        if deletingCategory {
            let alert = UIAlertController(title: "Confirm Move and Delete", message: "Are you sure you want to move all prayers from the category \(fromCategory.name) to the category \(toCategory.name) then delete the original category?", preferredStyle: .Alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { alertAction in
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            })
            alert.addAction(cancelAction)
            
            let confirmAction = UIAlertAction(title: "Confirm", style: .Destructive, handler: { alertAction in
                CategoryStore.sharedInstance.movePrayers(self.fromCategory, toCategory: toCategory)
                
                CategoryStore.sharedInstance.deleteCategory(self.fromCategory)
                CategoryStore.sharedInstance.fetchCategoriesData(nil)
                
                self.performSegueWithIdentifier(UnwindFromMoveID, sender: self)
            })
            alert.addAction(confirmAction)
            
            presentViewController(alert, animated: true, completion: nil)
        } else {
            CategoryStore.sharedInstance.movePrayers(fromCategory, toCategory: toCategory)
        
            performSegueWithIdentifier(UnwindFromMoveID, sender: self)
        }
    }
}
