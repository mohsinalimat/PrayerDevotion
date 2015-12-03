//
//  ViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 5/11/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import UIKit
import PDKit
import CoreLocation
import Foundation

protocol CategoriesViewControllerDelegate: class {
    func categories(categoriesViewController: CategoriesViewController, didSelectCategory category: PDCategory, isAllPrayers allPrayers: Bool)
}

class CategoriesViewController: UITableViewController, CLLocationManagerDelegate {
    
    // Button to click to sort categories
    private var sortBarButton: UIBarButtonItem!

    // This is a private variable that holds all fetchedCategories
    private var fetchedCategories = [PDCategory]()
    private var categoryCount = 0 // The number of categories in the fetchedCategories array
    
    // A boolean that is passed to MovePrayersViewController telling it that the user is deleting a prayer after the move
    private var isDeletingCategory: Bool = false
    
    // This is a private variable passed to numerous ViewControllers that holds the instance of the current Category
    // that was selected
    private var selectedCategory: PDCategory?
    
    // This is the singleton instance of the NSUserDefaults (or the user preferences)
    private var userDefaults = NSUserDefaults.standardUserDefaults()
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let prayerStore = PrayerDevotionStore()
    
    var prayersViewController: PersonalPrayerViewController!
    var selectedIndex: NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    
    weak var delegate: CategoriesViewControllerDelegate?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: nil, action: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleURL:", name: "HandleURLNotification", object: nil)
        
        prayerStore.requestProductInfo()
        
        self.navigationController?.tabBarController?.tabBar.translucent = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshUI()
        
        navigationItem.backBarButtonItem?.title = ""
        
        navigationController!.navigationBar.tintColor = appDelegate.themeTintColor
        tableView.backgroundColor = appDelegate.themeBackgroundColor
    }
    
    func showSearch(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier(ShowSearchSegueID, sender: sender)
    }
    
    func refreshUI() {
        let searchButton = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: "showSearch:")
        
        if !(self.traitCollection.userInterfaceIdiom == .Pad && self.splitViewController!.collapsed == false) {
            self.navigationItem.rightBarButtonItem = searchButton
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
        
        // This is the sorting feature - it calls the userPrefs "categoriesSortKey" (a String) and then
        // passes that key along to the PrayerStore for the NSSortDescriptor
        // In the instance that the sort key is nil (meaning it isn't set yet - such as the first time opening the application)
        // the sort key is automatically set to "creationDate" to sort by the date the categories were created
        var sortKey: String? = userDefaults.stringForKey("categoriesSortKey")
        if sortKey == nil { sortKey = "creationDate"; userDefaults.setObject("creationDate", forKey: "categoriesSortKey") }
        
        // Ascending or Descending
        let ascending = userDefaults.boolForKey("categoriesAscending")
        
        // Now fetch the categories data from the SQLite Database via a CoreData request
        CategoryStore.sharedInstance.fetchCategoriesData(NSPredicate(format: "name != %@", "Uncategorized"), sortKey: sortKey!, ascending: ascending)
        print("Fetched Categories")
        
        // TODO: Stop using "fetchedCategories" and use "CategoriesStore.allCategories() instead!
        fetchedCategories = CategoryStore.sharedInstance.allCategories()
        categoryCount = fetchedCategories.count
        
        // Set the sort key title
        let sortBy = sortKey == "name" ? "Alphabetically" : "By Date Created"
        
        // Create the toolbar and its buttons
        sortBarButton = UIBarButtonItem(title: "Sorting: \(sortBy)", style: .Plain, target: self, action: "sortTable:")
        sortBarButton.tintColor = appDelegate.themeTintColor
        let toolbarSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
        //var actionButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "showActions:")
        
        toolbarItems = [toolbarSpace, sortBarButton, toolbarSpace]
        navigationController?.toolbarHidden = false
        
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    // MARK: Custom Functions
    func sortTable(sender: UIBarButtonItem) {
        let sortMenu = UIAlertController(title: "Sort Items", message: "Sort Prayer Categories By...", preferredStyle: .ActionSheet)
        
        // let objectsBeforeSorting = fetchedCategories
        
        let sortKey = userDefaults.stringForKey("categoriesSortKey")
        
        let alphabeticalAction = UIAlertAction(title: "Alphabetically", style: .Default, handler: { alertAction in
            self.userDefaults.setObject("name", forKey: "categoriesSortKey")
            self.userDefaults.setBool(true, forKey: "categoriesAscending")
            
            self.sortBarButton.title = "Sorting: Alphabetically"
            
            self.sortItems("name", ascending: true)
        })
        sortMenu.addAction(alphabeticalAction)
        alphabeticalAction.enabled = sortKey != "name"
        
        let creationDateAction = UIAlertAction(title: "By Creation Date", style: .Default, handler: { alertAction in
            self.userDefaults.setObject("creationDate", forKey: "categoriesSortKey")
            self.userDefaults.setBool(false, forKey: "categoriesAscending")
            
            self.sortBarButton.title = "Sorting: By Date Created"
            
            self.sortItems("creationDate", ascending: false)
        })
        sortMenu.addAction(creationDateAction)
        creationDateAction.enabled = sortKey != "creationDate"
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        sortMenu.addAction(cancelAction)
        
        sortMenu.popoverPresentationController?.barButtonItem = sender
        sortMenu.popoverPresentationController?.sourceView = self.view
        
        presentViewController(sortMenu, animated: true, completion: nil)
    }
    
    func sortItems(sortKey: String = "name", ascending: Bool = false) {
        let objectsBeforeSorting = fetchedCategories
        
        CategoryStore.sharedInstance.fetchCategoriesData(NSPredicate(format: "name != %@", "Uncategorized"), sortKey: sortKey, ascending: ascending)
        fetchedCategories = CategoryStore.sharedInstance.allCategories()
        
        tableView.beginUpdates()
        for var i = 0; i < fetchedCategories.count; i++ {
            let newRow = fetchedCategories.indexOf(objectsBeforeSorting[i])! //fetchedCategories.indexOfObject(objectsBeforeSorting[i])
            tableView.moveRowAtIndexPath(NSIndexPath(forRow: i, inSection: 2), toIndexPath: NSIndexPath(forRow: newRow, inSection: 2))
        }
        tableView.endUpdates()
    }
    
    func determinePurchasedStatus() -> Bool {
        let purchased = appDelegate.didBuyAdditionalFeatures
        
        if categoryCount == 5 {
            if !purchased {
                prayerStore.askForAdditionalFeatures(true, completion: { successful in
                    if successful {
                        self.createNewCategory(self)
                    }
                })
                return false
            }
        }
        
        return true
    }

    // MARK: IBActions
    @IBAction func createNewCategory(sender: AnyObject) {
        print("Adding new category to the database")
        
        determinePurchasedStatus()
        
        tableView.editing = false
        
        let alertController = UIAlertController(title: "Create New Personal Category", message: "Enter a name below and press Create to create a new personal category", preferredStyle: .Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let createAction = UIAlertAction(title: "Create", style: .Default, handler: { (_) in
            let textField = alertController.textFields![0] 
            let categoryName = textField.text
                
            if (CategoryStore.sharedInstance.categoryExists(categoryName!) == false) {
                CategoryStore.sharedInstance.addCategoryToDatabase(categoryName!, dateCreated: NSDate())
                    
                CATransaction.begin()
                CATransaction.setCompletionBlock({
                        self.tableView.reloadData()
                        
                    let sortKey: String! = self.userDefaults.stringForKey("categoriesSortKey")
                    let ascending = self.userDefaults.boolForKey("categoriesAscending")
                        
                    self.sortItems(sortKey, ascending: ascending)
                })
                    
                self.tableView.beginUpdates()
                CategoryStore.sharedInstance.fetchCategoriesData(NSPredicate(format: "name != %@", "Uncategorized"))
                self.fetchedCategories = CategoryStore.sharedInstance.allCategories()
                self.categoryCount += 1
                    
                self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 2)], withRowAnimation: .Right)
                
                self.tableView.endUpdates()
                    
                CATransaction.commit()
            } else {
                let errorAlert = UIAlertController(title: "Unable to Create Category", message: "There is already a category with the name \"\(categoryName!)\"", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "OK", style: .Default, handler: { alertAction in
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
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return 3 }
        if section == 1 { return 1 }
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
            
            cell.categoryImageView.image = nil
            
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("CategoryCellID", forIndexPath: indexPath) as! CategoryCell
            
            cell.categoryNameLabel.text = "Prayer Locations"
            cell.prayerCountLabel.text = "\(LocationStore.sharedInstance.locationCount())"
            cell.categoryImageView.image = UIImage(named: "CurrentLocation")
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("CategoryCellID", forIndexPath: indexPath) as! CategoryCell
            
            let currentCategory = fetchedCategories[indexPath.row]
            print("Current IndexPath is row \(indexPath.row) in section \(indexPath.section)")
            
            let categoryName = fetchedCategories[indexPath.row].name
            print("Category Name for this indexPath is: \(categoryName)")
            
            cell.categoryNameLabel.text = currentCategory.name
            cell.prayerCountLabel.text = "\(PrayerStore.sharedInstance.prayerCountForCategory(currentCategory))"
            cell.categoryImageView.image = nil
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 0 || indexPath.section == 1 { return false }
        else { return true }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Don't add anything here yet...
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 || section == 1 { return "" }
        
        return fetchedCategories.count == 0 ? "" : "USER CATEGORIES"
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //let cell = tableView.cellForRowAtIndexPath(indexPath)!
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let prayersVC: PersonalPrayerViewController!
        
        /*if self.traitCollection.userInterfaceIdiom == .Pad && UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation) == true {
            let navController = self.splitViewController!.viewControllers.last as! UINavigationController
            prayersVC = navController.visibleViewController as! PersonalPrayerViewController
        } else {
            prayersVC = storyboard.instantiateViewControllerWithIdentifier(SBPrayersViewControllerID) as! PersonalPrayerViewController
        }*/
        var viewController: UIViewController?
        var category: PDCategory?
        
        //prayersVC = storyboard.instantiateViewControllerWithIdentifier(SBPrayersViewControllerID) as! PersonalPrayerViewController
        
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0, 1:
                viewController = storyboard.instantiateViewControllerWithIdentifier(SBPrayersViewControllerID) as! PersonalPrayerViewController
                self.delegate = (viewController as! PersonalPrayerViewController)
                (viewController as! PersonalPrayerViewController).isAllPrayers = indexPath.row == 0
                category = CategoryStore.sharedInstance.categoryForString("Uncategorized")!
            case 2:
                viewController = storyboard.instantiateViewControllerWithIdentifier(SBAnsweredPrayersViewControllerID) as! AnsweredPrayersViewController
            default: break
            }
        } else if indexPath.section == 1 {
            viewController = storyboard.instantiateViewControllerWithIdentifier(SBPrayerLocationsViewControllerID) as! PrayerLocationsViewController
        } else {
            viewController = storyboard.instantiateViewControllerWithIdentifier(SBPrayersViewControllerID) as! PersonalPrayerViewController
            self.delegate = (viewController as! PersonalPrayerViewController)
            (viewController as! PersonalPrayerViewController).isAllPrayers = false
            category = fetchedCategories[indexPath.row]
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let viewController = viewController {
            if self.traitCollection.userInterfaceIdiom == .Pad && self.splitViewController!.collapsed == false {
                setSplitViewDetailView(viewController)
            } else {
                self.navigationController?.pushViewController(viewController, animated: true)
            }
            
            if let category = category {
                delegate?.categories(self, didSelectCategory: category, isAllPrayers: (indexPath.section == 0 && indexPath.row == 0))
            }
        }
        /*if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                let prayersViewController = storyboard.instantiateViewControllerWithIdentifier(SBPrayersViewControllerID) as! PersonalPrayerViewController
                prayersViewController.currentCategory = CategoryStore.sharedInstance.categoryForString("Uncategorized")
                setSplitViewDetailView(prayersViewController)
                delegate?.categories(self, didSelectCategory: CategoryStore.sharedInstance.categoryForString("Uncategorized")!, isAllPrayers: true)
                
            case 1:
                let prayersViewController = storyboard.instantiateViewControllerWithIdentifier(SBPrayersViewControllerID) as! PersonalPrayerViewController
                prayersViewController.currentCategory = CategoryStore.sharedInstance.categoryForString("Uncategorized")
                setSplitViewDetailView(prayersViewController)
                delegate?.categories(self, didSelectCategory: CategoryStore.sharedInstance.categoryForString("Uncategorized")!, isAllPrayers: false)
                
            case 2:
                let answeredPrayersVC = storyboard.instantiateViewControllerWithIdentifier(SBAnsweredPrayersViewControllerID) as! AnsweredPrayersViewController
                
                if self.traitCollection.userInterfaceIdiom == .Pad {
                    setSplitViewDetailView(answeredPrayersVC)
                } else {
                    navigationController?.pushViewController(answeredPrayersVC, animated: true)
                }
                
            default: break
            }
        } else if indexPath.section == 1 {
            let prayerLocationsVC = storyboard.instantiateViewControllerWithIdentifier(SBPrayerLocationsViewControllerID) as! PrayerLocationsViewController
            
            if self.traitCollection.userInterfaceIdiom == .Pad {
                setSplitViewDetailView(prayerLocationsVC)
            } else {
                navigationController?.pushViewController(prayerLocationsVC, animated: true)
            }
        } else {
            let prayersViewController = storyboard.instantiateViewControllerWithIdentifier(SBPrayersViewControllerID) as! PersonalPrayerViewController
            setSplitViewDetailView(prayersViewController)
            delegate?.categories(self, didSelectCategory: fetchedCategories[indexPath.row], isAllPrayers: false)
        }
        
        /*if self.traitCollection.userInterfaceIdiom == .Phone {
            navigationController?.pushViewController(prayersVC, animated: true)
        }*/
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)*/
    }
    
    func setSplitViewDetailView(newViewController: UIViewController) {
        let newDetailNavVC = UINavigationController()
        newDetailNavVC.pushViewController(newViewController, animated: true)
        
        let newViewControllers = [self.splitViewController!.viewControllers[0], newDetailNavVC]
        self.splitViewController!.viewControllers = newViewControllers
    }
    
    override func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndex = indexPath
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        if indexPath.section == 2 {
            let editAction = UITableViewRowAction(style: .Normal, title: "Edit", handler: { rowAction, indexPath in
                print("Editing category")
            
                let category = self.fetchedCategories[indexPath.row]
                self.selectedCategory = category
            
                self.performSegueWithIdentifier(EditCategorySegueID, sender: self)
            })
            editAction.backgroundColor = UIColor.grayColor()
        
            let deleteAction = UITableViewRowAction(style: .Normal, title: "Delete", handler: { rowAction, indexPath in
                let categoryName = self.fetchedCategories[indexPath.row].name
            
                let alertController = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete category \"\(categoryName)\"? All prayers under this category will be deleted along with it, and this action is irreversable.\n\nYou can also move all prayers under this category to another category before deletion.", preferredStyle: .Alert)
            
                let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { alertAction in
                
                })
                alertController.addAction(cancelAction)
            
                let moveAction = UIAlertAction(title: "Move Prayers", style: .Default, handler: { alertAction in
                    self.selectedCategory = self.fetchedCategories[indexPath.row]
                    self.isDeletingCategory = true
                    self.performSegueWithIdentifier(MovePrayersSegueID, sender: self)
                })
                moveAction.enabled = !(PrayerStore.sharedInstance.prayerCountForCategory(self.fetchedCategories[indexPath.row]) == 0 || self.categoryCount <= 1)
                alertController.addAction(moveAction)
            
                let confirmAction = UIAlertAction(title: "Confirm", style: .Destructive, handler: { alertAction in
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
                    
                    (tableView.headerViewForSection(2))?.textLabel!.text = self.tableView(tableView, titleForHeaderInSection: 2)
                    
                    CATransaction.commit()
                })
                alertController.addAction(confirmAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
            })
            deleteAction.backgroundColor = UIColor.redColor()
        
            let moveAction = UITableViewRowAction(style: .Normal, title: "Move", handler: { rowAction, indexPath in
                if self.categoryCount > 1 {
                    if PrayerStore.sharedInstance.prayerCountForCategory(self.fetchedCategories[indexPath.row]) == 0 {
                        let alertController = UIAlertController(title: "Not Enough Prayers", message: "There are no prayers to move.", preferredStyle: .Alert)
                        
                        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                        alertController.addAction(okAction)
                    
                        self.presentViewController(alertController, animated: true, completion: nil)
                    } else {
                        self.selectedCategory = self.fetchedCategories[indexPath.row]
                        self.isDeletingCategory = false
                        self.performSegueWithIdentifier(MovePrayersSegueID, sender: self)
                    }
                } else {
                    let alertController = UIAlertController(title: "Not Enough Categories", message: "There are no other categories to move the prayers to.", preferredStyle: .Alert)
                
                    let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
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
        let headerView = view as! UITableViewHeaderFooterView
        
        headerView.textLabel!.textColor = appDelegate.themeTextColor
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
            } else if selectedIndex.section == 2 {
                toVC.currentCategory = fetchedCategories[selectedIndex.row]
            } else {
                return
            }
            
        case EditCategorySegueID:
            let toVC = (segue.destinationViewController as! UINavigationController).viewControllers[0] as! EditCategoriesViewController
            
            if let category = selectedCategory {
                toVC.currentCategory = category
            } else {
                print("ERROR!! Something went wrong! Category is nil!!")
            }
            
        case MovePrayersSegueID:
            let toVC = (segue.destinationViewController as! UINavigationController).viewControllers[0] as! MovePrayersViewController
            
            if let category = selectedCategory {
                toVC.fromCategory = category
                toVC.deletingCategory = isDeletingCategory
            } else {
                print("ERROR!! Something went wrong! Category is nil!!")
            }
        
        default:
            break
        }
    }
    
    @IBAction func prepareForUnwindFromEdit(segue: UIStoryboardSegue) {
        print("Unwinding from Editing Category")
        
        fetchedCategories = CategoryStore.sharedInstance.allCategories()
        categoryCount = fetchedCategories.count
        
        tableView.reloadData()
    }
    
    @IBAction func prepareForUnwindFromPrayers(segue: UIStoryboardSegue) {
        print("Unwinding from Prayers")
        
        let sortKey: String? = userDefaults.stringForKey("categoriesSortKey")
        let ascending = userDefaults.boolForKey("categoriesAscending")
        
        CategoryStore.sharedInstance.fetchCategoriesData(NSPredicate(format: "name != %@", "Uncategorized"), sortKey: sortKey!, ascending: ascending)
        fetchedCategories = CategoryStore.sharedInstance.allCategories()
        categoryCount = fetchedCategories.count
        
        tableView.reloadData()
    }
    
    @IBAction func prepareForUnwindFromMovingPrayers(segue: UIStoryboardSegue) {
        print("Unwinding from Moving Prayers")
        
        fetchedCategories = CategoryStore.sharedInstance.allCategories()
        categoryCount = fetchedCategories.count
        
        tableView.reloadData()
    }
    
    @IBAction func prepareForUnwindFromLocations(segue: UIStoryboardSegue) {
        print("Unwinding from Prayer Locations")
        
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
            appDelegate.switchTabBarToTab(0)
        } else if command == "open-prayer" {
            let prayerID = Int32(Int((notificationInfo["prayerID"] as! String))!)
            
            let prayerNavController = storyboard.instantiateViewControllerWithIdentifier(SBPrayerDetailsNavControllerID) as! UINavigationController
            let prayerDetailsController = prayerNavController.topViewController as! PrayerDetailsViewController
            prayerDetailsController.currentPrayer = PrayerStore.sharedInstance.getPrayerForID(prayerID)!
            prayerDetailsController.previousViewController = self
            
            presentViewController(prayerNavController, animated: true, completion: nil)
        }
    }
    
}