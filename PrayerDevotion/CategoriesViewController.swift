//
//  ViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 5/11/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import UIKit
import PDKit

// Segue IDs
let PresentPrayersSegueID = "PresentPrayersSegueID"
let EditCategorySegueID = "EditCategorySegueID"
let MovePrayersSegueID = "MovePrayersSegueID"

class CategoriesViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Button to click to sort categories
    private var sortBarButton: UIBarButtonItem!

    // This is a private variable that holds all fetchedCategories
    private var fetchedCategories: NSMutableArray!
    private var categoryCount = 0 // The number of categories in the fetchedCategories array
    
    // A boolean that is passed to MovePrayersViewController telling it that the user is deleting a prayer after the move
    private var isDeletingCategory: Bool = false
    
    // This is a private variable passed to numerous ViewControllers that holds the instance of the current Category
    // that was selected
    private var selectedCategory: PDCategory?
    
    // This is the singleton instance of the NSUserDefaults (or the user preferences)
    private var userPrefs = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This is the sorting feature - it calls the userPrefs "categoriesSortKey" (a String) and then
        // passes that key along to the PrayerStore for the NSSortDescriptor
        // In the instance that the sort key is nil (meaning it isn't set yet - such as the first time opening the application)
        // the sort key is automatically set to "creationDate" to sort by the date the categories were created
        var sortKey: String? = userPrefs.stringForKey("categoriesSortKey")
        if sortKey == nil { sortKey = "creationDate"; userPrefs.setObject("creationDate", forKey: "categoriesSortKey") }
        
        // Ascending or Descending
        var ascending = userPrefs.boolForKey("categoriesAscending")
        
        // Now fetch the categories data from the SQLite Database via a CoreData request
        CategoryStore.sharedInstance.fetchCategoriesData(nil, sortKey: sortKey!, ascending: ascending)
        println("Fetched Categories")
        
        // TODO: Stop using "fetchedCategories" and use "CategoriesStore.allCategories() instead!
        fetchedCategories = CategoryStore.sharedInstance.allCategories().mutableCopy() as! NSMutableArray
        categoryCount = fetchedCategories.count
        
        // Set the sort key title
        var sortBy = sortKey == "name" ? "Alphabetically" : "By Date Created"
        
        // Create the toolbar and its buttons
        sortBarButton = UIBarButtonItem(title: "Sorting: \(sortBy)", style: .Plain, target: self, action: "sortTable")
        var toolbarSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
        
        toolbarItems = [toolbarSpace, sortBarButton, toolbarSpace]
        navigationController?.toolbarHidden = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleURL:", name: "HandleURLNotification", object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Custom Functions
    func sortTable() {
        var sortMenu = UIAlertController(title: "Sort Items", message: "Sort Prayer Categories By...", preferredStyle: .ActionSheet)
        
        var objectsBeforeSorting = fetchedCategories
        
        var sortKey = userPrefs.stringForKey("categoriesSortKey")
        
        var alphabeticalAction = UIAlertAction(title: "Alphabetically", style: .Default, handler: { alertAction in
            self.userPrefs.setObject("name", forKey: "categoriesSortKey")
            self.userPrefs.setBool(true, forKey: "categoriesAscending")
            
            self.sortBarButton.title = "Sorting: Alphabetically"
            
            self.sortItems(sortKey: "name", ascending: true)
        })
        sortMenu.addAction(alphabeticalAction)
        alphabeticalAction.enabled = sortKey != "name"
        
        var creationDateAction = UIAlertAction(title: "By Creation Date", style: .Default, handler: { alertAction in
            self.userPrefs.setObject("creationDate", forKey: "categoriesSortKey")
            self.userPrefs.setBool(false, forKey: "categoriesAscending")
            
            self.sortBarButton.title = "Sorting: By Date Created"
            
            self.sortItems(sortKey: "creationDate", ascending: false)
        })
        sortMenu.addAction(creationDateAction)
        creationDateAction.enabled = sortKey != "creationDate"
        
        var cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        sortMenu.addAction(cancelAction)
        
        presentViewController(sortMenu, animated: true, completion: nil)
    }
    
    func sortItems(sortKey: String = "name", ascending: Bool = false) {
        let objectsBeforeSorting = fetchedCategories
        
        CategoryStore.sharedInstance.fetchCategoriesData(nil, sortKey: sortKey, ascending: ascending)
        fetchedCategories = CategoryStore.sharedInstance.allCategories().mutableCopy() as! NSMutableArray
        
        tableView.beginUpdates()
        for var i = 0; i < fetchedCategories.count; i++ {
            var newRow = fetchedCategories.indexOfObject(objectsBeforeSorting[i])
            tableView.moveRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0), toIndexPath: NSIndexPath(forRow: newRow, inSection: 0))
        }
        tableView.endUpdates()
    }

    // MARK: IBActions
    @IBAction func createNewCategory(sender: AnyObject) {
        println("Adding new category to the database")
        
        tableView.editing = false
        
        var alertController = UIAlertController(title: "Create New Personal Category", message: "Enter a name below and press Create to create a new personal category", preferredStyle: .Alert)
        
        var cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        var createAction = UIAlertAction(title: "Create", style: .Default, handler: { (_) in
            let textField = alertController.textFields![0] as! UITextField
            let categoryName = textField.text
                
            if (CategoryStore.sharedInstance.categoryExists(categoryName) == false) {
                CategoryStore.sharedInstance.addCategoryToDatabase(categoryName, dateCreated: NSDate())
                    
                CATransaction.begin()
                CATransaction.setCompletionBlock({
                        self.tableView.reloadData()
                        
                    var sortKey: String! = self.userPrefs.stringForKey("categoriesSortKey")
                    var ascending = self.userPrefs.boolForKey("categoriesAscending")
                        
                    self.sortItems(sortKey: sortKey, ascending: ascending)
                })
                    
                self.tableView.beginUpdates()
                CategoryStore.sharedInstance.fetchCategoriesData(nil)
                self.fetchedCategories = CategoryStore.sharedInstance.allCategories().mutableCopy() as! NSMutableArray
                self.categoryCount += 1
                    
                self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Right)
                
                self.tableView.endUpdates()
                    
                CATransaction.commit()
            } else {
                var errorAlert = UIAlertController(title: "Unable to Create Category", message: "There is already a category with the name \"\(categoryName!)\"", preferredStyle: .Alert)
                var okAction = UIAlertAction(title: "OK", style: .Default, handler: { alertAction in
                    self.createNewCategory(self)
                })
                errorAlert.addAction(okAction)
                    
                self.presentViewController(errorAlert, animated: true, completion: nil)
            }
        })
        createAction.enabled = false
        
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Enter Category Name..."
            textField.autocapitalizationType = .Words
            
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue(), usingBlock: { (notification) in
                createAction.enabled = textField.text != ""
            })
        }
        
        alertController.addAction(createAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: TableView Methods
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryCount
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CategoryCellID", forIndexPath: indexPath) as! CategoryCell
        
        //println("All Categories include: \(fetchedCategories)")
        
        let currentCategory = fetchedCategories[indexPath.row] as! PDCategory
        println("Current IndexPath is row \(indexPath.row) in section \(indexPath.section)")
        
        let categoryName = (fetchedCategories[indexPath.row] as! PDCategory).name
        println("Category Name for this indexPath is: \(categoryName)")
        
        cell.categoryNameLabel.text = currentCategory.name
        cell.prayerCountLabel.text = "\(currentCategory.prayerCount)"
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Don't add anything here yet...
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        
        //cell.contentView.backgroundColor = UIColor(red: 255/255.0, green: 249/255.0, blue: 187/255.0, alpha: 1)
        //cell.backgroundColor = UIColor(red: 255/255.0, green: 249/255.0, blue: 187/255.0, alpha: 1)
        
        //tableView.separatorColor = UIColor(red: 252/255.0, green: 212/255.0, blue: 128/255.0, alpha: 1)
        
        cell.contentView.backgroundColor = UIColor.whiteColor()
        cell.backgroundColor = UIColor.whiteColor()
        
        if !tableView.editing {
            let category = fetchedCategories[indexPath.row] as! PDCategory
            selectedCategory = category
            
            performSegueWithIdentifier(PresentPrayersSegueID, sender: cell)
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var editAction = UITableViewRowAction(style: .Normal, title: "Edit", handler: { rowAction, indexPath in
            println("Editing category")
            
            let category = self.fetchedCategories[indexPath.row] as! PDCategory
            self.selectedCategory = category
            
            self.performSegueWithIdentifier(EditCategorySegueID, sender: self)
        })
        editAction.backgroundColor = UIColor.grayColor()
        
        var deleteAction = UITableViewRowAction(style: .Normal, title: "Delete", handler: { rowAction, indexPath in
            let categoryName = (self.fetchedCategories[indexPath.row] as! PDCategory).name
            
            var alertController = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete category \"\(categoryName)\"? All prayers under this category will be deleted along with it, and this action is irreversable.\n\nYou can also move all prayers under this category to another category before deletion.", preferredStyle: .Alert)
            
            var cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { alertAction in
                
            })
            alertController.addAction(cancelAction)
            
            var moveAction = UIAlertAction(title: "Move Prayers", style: .Default, handler: { alertAction in
                self.selectedCategory = self.fetchedCategories[indexPath.row] as? PDCategory
                self.isDeletingCategory = true
                self.performSegueWithIdentifier(MovePrayersSegueID, sender: self)
            })
            moveAction.enabled = !(PrayerStore.sharedInstance.prayerCountForCategory(self.fetchedCategories[indexPath.row] as! PDCategory) == 0 || self.categoryCount <= 1)
            alertController.addAction(moveAction)
            
            var confirmAction = UIAlertAction(title: "Confirm", style: .Destructive, handler: { alertAction in
                self.tableView.beginUpdates()
                CategoryStore.sharedInstance.deleteCategory(self.fetchedCategories[indexPath.row] as! PDCategory)
                CategoryStore.sharedInstance.fetchCategoriesData(nil)
                self.fetchedCategories = CategoryStore.sharedInstance.allCategories().mutableCopy() as! NSMutableArray
                
                self.categoryCount -= 1
                
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                self.tableView.endUpdates()
            })
            alertController.addAction(confirmAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        })
        deleteAction.backgroundColor = UIColor.redColor()
        
        var moveAction = UITableViewRowAction(style: .Normal, title: "Move", handler: { rowAction, indexPath in
            if self.categoryCount > 1 {
                if PrayerStore.sharedInstance.prayerCountForCategory(self.fetchedCategories[indexPath.row] as! PDCategory) == 0 {
                    var alertController = UIAlertController(title: "Not Enough Prayers", message: "There are no prayers to move.", preferredStyle: .Alert)
                    
                    var okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                    alertController.addAction(okAction)
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
                } else {
                    self.selectedCategory = self.fetchedCategories[indexPath.row] as? PDCategory
                    self.isDeletingCategory = false
                    self.performSegueWithIdentifier(MovePrayersSegueID, sender: self)
                }
            } else {
                var alertController = UIAlertController(title: "Not Enough Categories", message: "There are no other categories to move the prayers to.", preferredStyle: .Alert)
                
                var okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alertController.addAction(okAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        })
        if categoryCount > 1 {
            if PrayerStore.sharedInstance.prayerCountForCategory(fetchedCategories[indexPath.row] as! PDCategory) > 0 {
                moveAction.backgroundColor = UIColor(red: 50/255.0, green: 205/255.0, blue: 50/255.0, alpha: 1)
            } else {
                moveAction.backgroundColor = UIColor.lightGrayColor()
            }
        } else {
            moveAction.backgroundColor = UIColor.lightGrayColor()
        }
        //moveAction.backgroundColor = categoryCount > 1 || PrayerStore.sharedInstance.prayerCountForCategory(fetchedCategories[indexPath.row] as! Category) == 0 ? UIColor(red: 50/255.0, green: 205/255.0, blue: 50/255.0, alpha: 1) : UIColor.lightGrayColor()
        
        return [deleteAction, moveAction, editAction]
    }
    
    // MARK: Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case PresentPrayersSegueID:
            let toVC = (segue.destinationViewController as! UINavigationController).viewControllers[0] as! PersonalPrayerViewController
            
            if let category = selectedCategory {
                toVC.currentCategory = category
            } else {
                println("ERROR!! Something went wrong! Category is nil!!")
            }
            
        case EditCategorySegueID:
            let toVC = (segue.destinationViewController as! UINavigationController).viewControllers[0] as! EditCategoriesViewController
            
            if let category = selectedCategory {
                toVC.currentCategory = category
            } else {
                println("ERROR!! Something went wrong! Category is nil!!")
            }
            
        case MovePrayersSegueID:
            let toVC = (segue.destinationViewController as! UINavigationController).viewControllers[0] as! MovePrayersViewController
            
            if let category = selectedCategory {
                toVC.fromCategory = category
                toVC.deletingCategory = isDeletingCategory
            } else {
                println("ERROR!! Something went wrong! Category is nil!!")
            }
        
        default:
            break
        }
    }
    
    @IBAction func prepareForUnwindFromEdit(segue: UIStoryboardSegue) {
        println("Unwinding from Editing Category")
        
        fetchedCategories = CategoryStore.sharedInstance.allCategories().mutableCopy() as! NSMutableArray
        categoryCount = fetchedCategories.count
        
        tableView.reloadData()
    }
    
    @IBAction func prepareForUnwindFromPrayers(segue: UIStoryboardSegue) {
        println("Unwinding from Prayers")
        
        var sortKey: String? = userPrefs.stringForKey("categoriesSortKey")
        var ascending = userPrefs.boolForKey("categoriesAscending")
        
        CategoryStore.sharedInstance.fetchCategoriesData(nil, sortKey: sortKey!, ascending: ascending)
        fetchedCategories = CategoryStore.sharedInstance.allCategories().mutableCopy() as! NSMutableArray
        categoryCount = fetchedCategories.count
        
        tableView.reloadData()
    }
    
    @IBAction func prepareForUnwindFromMovingPrayers(segue: UIStoryboardSegue) {
        println("Unwinding from Moving Prayers")
        
        fetchedCategories = CategoryStore.sharedInstance.allCategories().mutableCopy() as! NSMutableArray
        categoryCount = fetchedCategories.count
        
        tableView.reloadData()
    }
    
    @IBAction func prepareForUnwindFromToday(segue: UIStoryboardSegue) {
        println("Unwinding from Today Tab")
        
        fetchedCategories = CategoryStore.sharedInstance.allCategories().mutableCopy() as! NSMutableArray
        categoryCount = fetchedCategories.count
        
        tableView.reloadData()
    }
    
    // MARK: Notifications
    
    // MARK: Notifications
    
    func handleURL(notification: NSNotification) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let notificationInfo = notification.userInfo!
        let command = notificationInfo["command"] as! String
        
        if command == "open-today" {
            let prayerNavController = storyboard.instantiateViewControllerWithIdentifier(SBTodayNavControllerID) as! UINavigationController
            
            presentViewController(prayerNavController, animated: true, completion: nil)
        } else if command == "open-prayer" {
            let prayerID = Int32((notificationInfo["prayerID"] as! String).toInt()!)
            
            let prayerNavController = storyboard.instantiateViewControllerWithIdentifier(SBPrayerDetailsNavControllerID) as! UINavigationController
            let prayerDetailsController = prayerNavController.topViewController as! PrayerDetailsViewController_New
            prayerDetailsController.currentPrayer = PrayerStore.sharedInstance.getPrayerForID(prayerID)!
            
            presentViewController(prayerNavController, animated: true, completion: nil)
        }
    }
    
}