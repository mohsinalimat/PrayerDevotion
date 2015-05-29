//
//  ViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 5/11/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import UIKit

// Segue IDs
let PresentPrayersSegueID = "PresentPrayersSegueID"
let EditCategorySegueID = "EditCategorySegueID"

class CategoriesViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var sortBarButton: UIBarButtonItem!

    private var fetchedCategories: NSMutableArray!
    private var categoryCount = 0
    
    private var selectedCategory: Category?
    
    private var userPrefs = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        var sortKey: String? = userPrefs.stringForKey("categoriesSortKey")
        if sortKey == nil { sortKey = "creationDate"; userPrefs.setObject("creationDate", forKey: "categoriesSortKey") }
        
        var ascending = userPrefs.boolForKey("categoriesAscending")
        
        PrayerStore.sharedInstance.fetchCategoriesData(nil, sortKey: sortKey!, ascending: ascending)
        println("Fetched Categories")
        fetchedCategories = PrayerStore.sharedInstance.allCategories().mutableCopy() as! NSMutableArray
        categoryCount = fetchedCategories.count
        
        // Add Edit button to the top right
        navigationItem.leftBarButtonItem = editButtonItem()
        
        var sortBy = sortKey == "name" ? "Alphabetically" : "By Date Created"
        
        sortBarButton = UIBarButtonItem(title: "Sorting: \(sortBy)", style: .Plain, target: self, action: "sortTable")
        var toolbarSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
        
        toolbarItems = [toolbarSpace, sortBarButton, toolbarSpace]
        navigationController?.toolbarHidden = false
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
        
        PrayerStore.sharedInstance.fetchCategoriesData(nil, sortKey: sortKey, ascending: ascending)
        fetchedCategories = PrayerStore.sharedInstance.allCategories().mutableCopy() as! NSMutableArray
        
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
        
        var alertController = UIAlertController(title: "Create New Personal Category", message: "Enter a name below and press Create to create a new personal category", preferredStyle: .Alert)
        
        var cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        var createAction = UIAlertAction(title: "Create", style: .Default, handler: { (_) in
            let textField = alertController.textFields![0] as! UITextField
            let categoryName = textField.text
                
            if (PrayerStore.sharedInstance.categoryExists(categoryName) == false) {
                PrayerStore.sharedInstance.addCategoryToDatabase(categoryName, dateCreated: NSDate())
                    
                CATransaction.begin()
                CATransaction.setCompletionBlock({
                        self.tableView.reloadData()
                        
                    var sortKey: String! = self.userPrefs.stringForKey("categoriesSortKey")
                    var ascending = self.userPrefs.boolForKey("categoriesAscending")
                        
                    self.sortItems(sortKey: sortKey, ascending: ascending)
                })
                    
                self.tableView.beginUpdates()
                PrayerStore.sharedInstance.fetchCategoriesData(nil)
                self.fetchedCategories = PrayerStore.sharedInstance.allCategories().mutableCopy() as! NSMutableArray
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
        
        let currentCategory = fetchedCategories[indexPath.row] as! Category
        println("Current IndexPath is row \(indexPath.row) in section \(indexPath.section)")
        
        let categoryName = (fetchedCategories[indexPath.row] as! Category).name
        println("Category Name for this indexPath is: \(categoryName)")
        
        cell.categoryNameLabel.text = currentCategory.name
        cell.prayerCountLabel.text = "\(currentCategory.prayerCount)"
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Don't add anything here yet...
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        
        if !tableView.editing {
            let category = fetchedCategories[indexPath.row] as! Category
            selectedCategory = category
            
            performSegueWithIdentifier(PresentPrayersSegueID, sender: cell)
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var editAction = UITableViewRowAction(style: .Normal, title: "Edit", handler: { rowAction, indexPath in
            println("Editing category")
            
            let category = self.fetchedCategories[indexPath.row] as! Category
            self.selectedCategory = category
            
            self.performSegueWithIdentifier(EditCategorySegueID, sender: self)
        })
        editAction.backgroundColor = UIColor.grayColor()
        
        var deleteAction = UITableViewRowAction(style: .Normal, title: "Delete", handler: { rowAction, indexPath in
            let categoryName = (self.fetchedCategories[indexPath.row] as! Category).name
            
            var alertController = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete category \"\(categoryName)\"? All prayers under this category will be deleted along with it, and this action is irreversable.", preferredStyle: .Alert)
            
            var cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { alertAction in
                
            })
            alertController.addAction(cancelAction)
            
            var confirmAction = UIAlertAction(title: "Confirm", style: .Destructive, handler: { alertAction in
                self.tableView.beginUpdates()
                PrayerStore.sharedInstance.deleteCategory(self.fetchedCategories[indexPath.row] as! Category)
                PrayerStore.sharedInstance.fetchCategoriesData(nil)
                self.fetchedCategories = PrayerStore.sharedInstance.allCategories().mutableCopy() as! NSMutableArray
                
                self.categoryCount -= 1
                
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                self.tableView.endUpdates()
            })
            alertController.addAction(confirmAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        })
        deleteAction.backgroundColor = UIColor.redColor()
        
        return [deleteAction, editAction]
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
        
        default:
            break
        }
    }
    
    @IBAction func prepareForUnwindFromEdit(segue: UIStoryboardSegue) {
        println("Unwinding from Editing Category")
        
        fetchedCategories = PrayerStore.sharedInstance.allCategories().mutableCopy() as! NSMutableArray
        categoryCount = fetchedCategories.count
        
        tableView.reloadData()
    }
    
    @IBAction func prepareForUnwindFromPrayers(segue: UIStoryboardSegue) {
        println("Unwinding from Prayers")
        
        var sortKey: String? = userPrefs.stringForKey("categoriesSortKey")
        var ascending = userPrefs.boolForKey("categoriesAscending")
        
        PrayerStore.sharedInstance.fetchCategoriesData(nil, sortKey: sortKey!, ascending: ascending)
        fetchedCategories = PrayerStore.sharedInstance.allCategories().mutableCopy() as! NSMutableArray
        categoryCount = fetchedCategories.count
        
        tableView.reloadData()
    }
    
}