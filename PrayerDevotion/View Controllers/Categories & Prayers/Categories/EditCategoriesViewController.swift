//
//  EditCategoriesViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 5/17/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import PDKit

class EditCategoriesViewController: UITableViewController {
    
    var currentCategory: PDCategory!
    
    @IBOutlet var categoryNameField: UITextField!
    @IBOutlet var dateCreatedLabel: UILabel!
    @IBOutlet var doneButtonItem: UIBarButtonItem!
    
    var oldCategoryName: String?
    var isEditingName: Bool = false
    
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(currentCategory != nil, "ERROR!!! CURRENT CATEGORY IS NIL!!!")
        
        categoryNameField.text = currentCategory.name
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        
        let creationDate = dateFormatter.stringFromDate(currentCategory.creationDate)
        
        dateCreatedLabel.text = "Created On \(creationDate)"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController!.navigationBar.tintColor = delegate.themeTintColor
        tableView.backgroundColor = delegate.themeBackgroundColor
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: TableView Data Source
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel!.textColor = delegate.themeTextColor
    }
    
    // MARK: IBActions
    
    @IBAction func deleteCategory(sender: AnyObject) {
        let alertController = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete category \"\(currentCategory.name)\"? All prayers under this category will be deleted along with it, and this action is irreversable.", preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { alertAction in
            
        })
        alertController.addAction(cancelAction)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .Destructive, handler: { alertAction in
            let userDefaults = NSUserDefaults.standardUserDefaults()
            
            let sortKey: String! = userDefaults.stringForKey("categoriesSortKey")
            let ascending = userDefaults.boolForKey("categoriesAscending")
            
            CategoryStore.sharedInstance.deleteCategory(self.currentCategory!)
            CategoryStore.sharedInstance.fetchCategoriesData(nil, sortKey: sortKey, ascending: ascending)
            
            self.performSegueWithIdentifier(UnwindFromEditID, sender: self)
        })
        alertController.addAction(confirmAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func donePressed(sender: AnyObject) {
        if (isEditingName == false) {
            performSegueWithIdentifier(UnwindFromEditID, sender: sender)
        } else {
            categoryNameField.endEditing(true)
        }
    }
    
    
    // MARK: TextField Delegate Method
    
    func textFieldDidBeginEditing(textField: UITextField) {
        oldCategoryName = textField.text
        
        isEditingName = true
        doneButtonItem.title = "Done"
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        let newCategoryName = textField.text
        if (CategoryStore.sharedInstance.categoryExists(newCategoryName!) == true && newCategoryName != oldCategoryName) {
            let alert = UIAlertController(title: "Unable to Change Name", message: "There already exists another category with the same name as \"\(newCategoryName)\".", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(okAction)
            
            textField.text = oldCategoryName
            
            presentViewController(alert, animated: true, completion: nil)
        } else if newCategoryName == oldCategoryName {
            print("Current name is already that...")
        } else {
            currentCategory.name = newCategoryName!
        }
        
        isEditingName = false
        doneButtonItem.title = "Save"
    }
}
