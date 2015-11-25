//
//  CategoriesSplitViewController.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 11/24/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import UIKit
import PDKit 

class CategoriesSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        self.preferredDisplayMode = .AllVisible
        
        configureViews()
    }
    
    func configureViews() {
        let prayersVC = (self.viewControllers.last as! UINavigationController).topViewController as! PersonalPrayerViewController
        
        prayersVC.currentCategory = CategoryStore.sharedInstance.categoryForString("Uncategorized")
        prayersVC.isAllPrayers = true
        
        //print("PrayersVC currentCategory = \(prayersVC.currentCategory!.name)")
    }
    
    // MARK: UISplitViewController Delegate Methods
    
    // When rotating to portrait, make sure Master View Controller is show
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        return true
    }
    
    // When rotating into split view make sure everything is displayed correctly.
    func splitViewController(splitViewController: UISplitViewController, separateSecondaryViewControllerFromPrimaryViewController primaryViewController: UIViewController) -> UIViewController? {
        if primaryViewController is UINavigationController {
            for controller in (primaryViewController as! UINavigationController).viewControllers {
                if controller is UINavigationController && (controller as! UINavigationController).visibleViewController is PersonalPrayerViewController {
                    return controller
                }
            }
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navController = storyboard.instantiateViewControllerWithIdentifier(SBPersonalCategoriesNavID) as! UINavigationController
        
        //let prayersVC = navController.topViewController as! PersonalPrayerViewController
        //prayersVC.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Categories", style: .Plain, target: self.splitViewController!.displayModeButtonItem().target, action: self.splitViewController!.displayModeButtonItem().action)
        
        return navController
    }
    
    func splitViewControllerSupportedInterfaceOrientations(splitViewController: UISplitViewController) -> UIInterfaceOrientationMask {
        if self.traitCollection.userInterfaceIdiom == .Pad {
            return .All
        }
        
        return .Portrait
    }

    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if self.traitCollection.userInterfaceIdiom == .Pad {
            let isPortrait: Bool = size.height > size.width
            
            if isPortrait {
                self.preferredDisplayMode = .AllVisible
            }
            
            coordinator.animateAlongsideTransition({ context in
                if isPortrait {
                    self.preferredDisplayMode = .AllVisible
                }
                //self.dividerView.hidden = isPortrait
            }, completion: {context in
                self.preferredDisplayMode = .AllVisible
            })
        }
    }
}