//
//  ViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 5/11/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import UIKit
import PDKit

class CategoriesViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Button to click to sort categories
    private var sortBarButton: UIBarButtonItem!

    // This is a private variable that holds all fetchedCategories
    private var fetchedCategories: [PDCategory]!
    private var categoryCount = 0 // The number of categories in the fetchedCategories array
    
    // A boolean that is passed to MovePrayersViewController telling it that the user is deleting a prayer after the move
    private var isDeletingCategory: Bool = false
    
    // This is a private variable passed to numerous ViewControllers that holds the instance of the current Category
    // that was selected
    private var selectedCategory: PDCategory?
    
    // This is the singleton instance of the NSUserDefaults (or the user preferences)
    private var userDefaults = NSUserDefaults.standardUserDefaults()
    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var prayersViewController: PersonalPrayerViewController!
    var selectedIndex: NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: nil, action: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleURL:", name: "HandleURLNotification", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // This is the sorting feature - it calls the userPrefs "categoriesSortKey" (a String) and then
        // passes that key along to the PrayerStore for the NSSortDescriptor
        // In the instance that the sort key is nil (meaning it isn't set yet - such as the first time opening the application)
        // the sort key is automatically set to "creationDate" to sort by the date the categories were created
        var sortKey: String? = userDefaults.stringForKey("categoriesSortKey")
        if sortKey == nil { sortKey = "creationDate"; userDefaults.setObject("creationDate", forKey: "categoriesSortKey") }
        
        // Ascending or Descending
        var ascending = userDefaults.boolForKey("categoriesAscending")
        
        // Now fetch the categories data from the SQLite Database via a CoreData request
        CategoryStore.sharedInstance.fetchCategoriesData(NSPredicate(format: "name != %@", "Uncategorized"), sortKey: sortKey!, ascending: ascending)
        println("Fetched Categories")
        
        // TODO: Stop using "fetchedCategories" and use "CategoriesStore.allCategories() instead!
        fetchedCategories = CategoryStore.sharedInstance.allCategories()
        categoryCount = fetchedCategories.count
        
        // Set the sort key title
        var sortBy = sortKey == "name" ? "Alphabetically" : "By Date Created"
        
        // Create the toolbar and its buttons
        sortBarButton = UIBarButtonItem(title: "Sorting: \(sortBy)", style: .Plain, target: self, action: "sortTable")
        var toolbarSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
        //var actionButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "showActions:")
        
        toolbarItems = [toolbarSpace, sortBarButton, toolbarSpace]
        navigationController?.toolbarHidden = false
        
        tableView.reloadData()
        navigationItem.backBarButtonItem?.title = ""
        
        navigationController!.navigationBar.tintColor = delegate.themeTintColor
        tableView.backgroundColor = delegate.themeBackgroundColor
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Custom Functions
    func sortTable() {
        var sortMenu = UIAlertController(title: "Sort Items", message: "Sort Prayer Categories By...", preferredStyle: .ActionSheet)
        
        var objectsBeforeSorting = fetchedCategories
        
        var sortKey = userDefaults.stringForKey("categoriesSortKey")
        
        var alphabeticalAction = UIAlertAction(title: "Alphabetically", style: .Default, handler: { alertAction in
            self.userDefaults.setObject("name", forKey: "categoriesSortKey")
            self.userDefaults.setBool(true, forKey: "categoriesAscending")
            
            self.sortBarButton.title = "Sorting: Alphabetically"
            
            self.sortItems(sortKey: "name", ascending: true)
        })
        sortMenu.addAction(alphabeticalAction)
        alphabeticalAction.enabled = sortKey != "name"
        
        var creationDateAction = UIAlertAction(title: "By Creation Date", style: .Default, handler: { alertAction in
            self.userDefaults.setObject("creationDate", forKey: "categoriesSortKey")
            self.userDefaults.setBool(false, forKey: "categoriesAscending")
            
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
        
        CategoryStore.sharedInstance.fetchCategoriesData(NSPredicate(format: "name != %@", "Uncategorized"), sortKey: sortKey, ascending: ascending)
        fetchedCategories = CategoryStore.sharedInstance.allCategories()
        
        tableView.beginUpdates()
        for var i = 0; i < fetchedCategories.count; i++ {
            var newRow = find(fetchedCategories, objectsBeforeSorting[i])! //fetchedCategories.indexOfObject(objectsBeforeSorting[i])
            tableView.moveRowAtIndexPath(NSIndexPath(forRow: i, inSection: 1), toIndexPath: NSIndexPath(forRow: newRow, inSection: 1))
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
                        
                    var sortKey: String! = self.userDefaults.stringForKey("categoriesSortKey")
                    var ascending = self.userDefaults.boolForKey("categoriesAscending")
                        
                    self.sortItems(sortKey: sortKey, ascending: ascending)
                })
                    
                self.tableView.beginUpdates()
                CategoryStore.sharedInstance.fetchCategoriesData(NSPredicate(format: "name != %@", "Uncategorized"))
                self.fetchedCategories = CategoryStore.sharedInstance.allCategories()
                self.categoryCount += 1
                    
                self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 1)], withRowAnimation: .Right)
                
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
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 3 }
        return categoryCount
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("CategoryCellID", forIndexPath: indexPath) as! CategoryCell
            
            switch indexPath.row {
            case 0:
                cell.categoryNameLabel.text = "All Prayers"
                cell.prayerCountLabel.text = "\(PrayerStore.sharedInstance.allPrayersCount())"
                
            case 1:
                let category = CategoryStore.sharedInstance.categoryForString("Uncategorized")!
                cell.categoryNameLabel.text = "Uncategorized"
                cell.prayerCountLabel.text = "\(PrayerStore.sharedInstance.prayerCountForCategory(category))"
                
            case 2:
                cell.categoryNameLabel.text = "Answered"
                cell.prayerCountLabel.text = "\(PrayerStore.sharedInstance.answeredPrayerCount())"
                
                
            default: break
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("CategoryCellID", forIndexPath: indexPath) as! CategoryCell
            
            let currentCategory = fetchedCategories[indexPath.row]
            println("Current IndexPath is row \(indexPath.row) in section \(indexPath.section)")
            
            let categoryName = fetchedCategories[indexPath.row].name
            println("Category Name for this indexPath is: \(categoryName)")
            
            cell.categoryNameLabel.text = currentCategory.name
            cell.prayerCountLabel.text = "\(PrayerStore.sharedInstance.prayerCountForCategory(currentCategory))"
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 0 { return false }
        else { return true }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Don't add anything here yet...
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return "" }
        
        return fetchedCategories.count == 0 ? "" : "USER CATEGORIES"
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        var prayersVC = storyboard.instantiateViewControllerWithIdentifier(SBPrayersViewControllerID) as! PersonalPrayerViewController
        
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                prayersVC.currentCategory = CategoryStore.sharedInstance.categoryForString("Uncategorized")
                prayersVC.isAllPrayers = true
                
            case 1:
                prayersVC.currentCategory = CategoryStore.sharedInstance.categoryForString("Uncategorized")!
                
            case 2:
                let answeredPrayersVC = storyboard.instantiateViewControllerWithIdentifier(SBAnsweredPrayersViewControllerID) as! AnsweredPrayersViewController
                answeredPrayersVC.navigationItem.title = "Answered"
                
                navigationController?.pushViewController(answeredPrayersVC, animated: true)
                return
                
            default: break
            }
        } else {
            prayersVC.currentCategory = fetchedCategories[indexPath.row]
        }
        
        navigationController?.pushViewController(prayersVC, animated: true)
    }
    
    override func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndex = indexPath
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        if indexPath.section == 1 {
            var editAction = UITableViewRowAction(style: .Normal, title: "Edit", handler: { rowAction, indexPath in
                println("Editing category")
            
                let category = self.fetchedCategories[indexPath.row]
                self.selectedCategory = category
            
                self.performSegueWithIdentifier(EditCategorySegueID, sender: self)
            })
            editAction.backgroundColor = UIColor.grayColor()
        
            var deleteAction = UITableViewRowAction(style: .Normal, title: "Delete", handler: { rowAction, indexPath in
                let categoryName = self.fetchedCategories[indexPath.row].name
            
                var alertController = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete category \"\(categoryName)\"? All prayers under this category will be deleted along with it, and this action is irreversable.\n\nYou can also move all prayers under this category to another category before deletion.", preferredStyle: .Alert)
            
                var cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { alertAction in
                
                })
                alertController.addAction(cancelAction)
            
                var moveAction = UIAlertAction(title: "Move Prayers", style: .Default, handler: { alertAction in
                    self.selectedCategory = self.fetchedCategories[indexPath.row]
                    self.isDeletingCategory = true
                    self.performSegueWithIdentifier(MovePrayersSegueID, sender: self)
                })
                moveAction.enabled = !(PrayerStore.sharedInstance.prayerCountForCategory(self.fetchedCategories[indexPath.row]) == 0 || self.categoryCount <= 1)
                alertController.addAction(moveAction)
            
                var confirmAction = UIAlertAction(title: "Confirm", style: .Destructive, handler: { alertAction in
                    self.tableView.beginUpdates()
                    CategoryStore.sharedInstance.deleteCategory(self.fetchedCategories[indexPath.row])
                    CategoryStore.sharedInstance.fetchCategoriesData(NSPredicate(format: "name != %@", "Uncategorized"))
                    self.fetchedCategories = CategoryStore.sharedInstance.allCategories()
                
                    self.categoryCount -= 1
                
                    CATransaction.begin()
                    CATransaction.setCompletionBlock({
                        self.tableView.reloadData()
                    })
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                    self.tableView.endUpdates()
                    
                    (tableView.headerViewForSection(1))?.textLabel.text = self.tableView(tableView, titleForHeaderInSection: 1)
                    
                    CATransaction.commit()
                })
                alertController.addAction(confirmAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
            })
            deleteAction.backgroundColor = UIColor.redColor()
        
            var moveAction = UITableViewRowAction(style: .Normal, title: "Move", handler: { rowAction, indexPath in
                if self.categoryCount > 1 {
                    if PrayerStore.sharedInstance.prayerCountForCategory(self.fetchedCategories[indexPath.row]) == 0 {
                        var alertController = UIAlertController(title: "Not Enough Prayers", message: "There are no prayers to move.", preferredStyle: .Alert)
                        
                        var okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                        alertController.addAction(okAction)
                    
                        self.presentViewController(alertController, animated: true, completion: nil)
                    } else {
                        self.selectedCategory = self.fetchedCategories[indexPath.row]
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
                if PrayerStore.sharedInstance.prayerCountForCategory(fetchedCategories[indexPath.row]) > 0 {
                    moveAction.backgroundColor = UIColor(red: 50/255.0, green: 205/255.0, blue: 50/255.0, alpha: 1)
                } else {
                    moveAction.backgroundColor = UIColor.lightGrayColor()
                }
            } else {
                moveAction.backgroundColor = UIColor.lightGrayColor()
            }
        
            return [deleteAction, moveAction, editAction]
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        var headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel.textColor = delegate.themeTextColor
    }
    
    // MARK: Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case PresentPrayersSegueID:
            let toVC = (segue.destinationViewController as! UINavigationController).viewControllers[0] as! PersonalPrayerViewController
            
            if selectedIndex.section == 0 {
                switch selectedIndex.row {
                case 0:
                    toVC.currentCategory = nil
                    toVC.isAllPrayers = true
                    
                case 1:
                    toVC.currentCategory = CategoryStore.sharedInstance.categoryForString("Uncategorized")!
                    
                case 2: break
                default: break
                }
            } else {
                toVC.currentCategory = fetchedCategories[selectedIndex.row]
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
        
        fetchedCategories = CategoryStore.sharedInstance.allCategories()
        categoryCount = fetchedCategories.count
        
        tableView.reloadData()
    }
    
    @IBAction func prepareForUnwindFromPrayers(segue: UIStoryboardSegue) {
        println("Unwinding from Prayers")
        
        var sortKey: String? = userDefaults.stringForKey("categoriesSortKey")
        var ascending = userDefaults.boolForKey("categoriesAscending")
        
        CategoryStore.sharedInstance.fetchCategoriesData(NSPredicate(format: "name != %@", "Uncategorized"), sortKey: sortKey!, ascending: ascending)
        fetchedCategories = CategoryStore.sharedInstance.allCategories()
        categoryCount = fetchedCategories.count
        
        tableView.reloadData()
    }
    
    @IBAction func prepareForUnwindFromMovingPrayers(segue: UIStoryboardSegue) {
        println("Unwinding from Moving Prayers")
        
        fetchedCategories = CategoryStore.sharedInstance.allCategories()
        categoryCount = fetchedCategories.count
        
        tableView.reloadData()
    }
    
    // MARK: Notifications
    
    func handleURL(notification: NSNotification) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let notificationInfo = notification.userInfo!
        let command = notificationInfo["command"] as! String
        
        if command == "open-today" {
            (UIApplication.sharedApplication().delegate as! AppDelegate).switchTabBarToTab(0)
        } else if command == "open-prayer" {
            let prayerID = Int32((notificationInfo["prayerID"] as! String).toInt()!)
            
            let prayerNavController = storyboard.instantiateViewControllerWithIdentifier(SBPrayerDetailsNavControllerID) as! UINavigationController
            let prayerDetailsController = prayerNavController.topViewController as! PrayerDetailsViewController
            prayerDetailsController.currentPrayer = PrayerStore.sharedInstance.getPrayerForID(prayerID)!
            prayerDetailsController.previousViewController = self
            
            presentViewController(prayerNavController, animated: true, completion: nil)
        }
    }
    
}