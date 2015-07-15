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

let UnwindFromMoveID = "UnwindFromMoveID"

class MovePrayersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var fromCategory: PDCategory!
    var deletingCategory: Bool = false
    
    private var fetchedCategories: NSArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println("View Did Load")
        
        fetchedCategories = CategoryStore.sharedInstance.fetchCategoriesForMove(fromCategory.name)
    }
    
    // MARK: TableView Methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedCategories.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("MoveCategoriesCellID", forIndexPath: indexPath) as! UITableViewCell
        
        cell.textLabel?.text = (fetchedCategories[indexPath.row] as! PDCategory).name
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let toCategory = fetchedCategories[indexPath.row] as! PDCategory
        
        if deletingCategory {
            var alert = UIAlertController(title: "Confirm Move and Delete", message: "Are you sure you want to move all prayers from the category \(fromCategory.name) to the category \(toCategory.name) then delete the original category?", preferredStyle: .Alert)
            
            var cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { alertAction in
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            })
            alert.addAction(cancelAction)
            
            var confirmAction = UIAlertAction(title: "Confirm", style: .Destructive, handler: { alertAction in
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
