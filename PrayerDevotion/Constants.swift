//
//  Constants.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 7/21/15.
//  Copyright (c) 2015 Jonathan Hart. All rights reserved.
//

import Foundation

// Segue IDs
let PresentPrayersSegueID = "PresentPrayersSegueID" // This is the ID of the segue that used to present the PersonalPrayersViewController (unused)
let EditCategorySegueID = "EditCategorySegueID" // This is the ID of the segue that presents EditCategoriesViewController
let MovePrayersSegueID = "MovePrayersSegueID" // This is the ID of the segue that presents the MovePrayersViewController
let ShowSearchSegueID = "ShowSearchSegueID" // This is the ID of the segue that presents the PrayerSearchViewController
let PresentPrayerDetailsSegueID = "PresentPrayerDetailsSegueID" // This is the ID of the segue that presents the PrayerDetailsViewController

// Unwind Segue IDs
let UnwindFromCategories = "UnwindFromCategories" // This is the ID of the unwind segue from the Categories (unused)
let UnwindFromEditID = "UnwindFromEditID" // This is the ID of the unwind segue from the EditCategoriesViewController
let UnwindFromMoveID = "UnwindFromMoveID" // This is the ID of the unwind segue from the MovePrayersViewController
let UnwindFromAnsweredID = "UnwindFromAnsweredID" // This is the ID of the unwind segue from the AnsweredPrayersViewController
let UnwindFromPrayersID = "UnwindFromPrayersID" // This is the ID of the unwind segue from the PersonalPrayersViewController

// Cell IDs

// -- MovePrayersViewController
let MoveCategoriesCellID = "MoveCategoriesCellID" // This is the cell ID of the cell used in MovePrayersViewController

// -- PersonalPrayersViewController / TodayPrayersViewController
let CreatePrayerCellID = "CreatePrayerCellID" // This is the cell ID of the cell containing the textField used in PersonalPrayersVC and TodayPrayersVC
let PrayerCellID = "PrayerCellID" // This is the cell ID of the cell used to display prayers in PersonalPrayersVC and AnsweredPrayersVC

// -- PrayerDetailsViewController
let EnterPrayerNameCellID = "EnterPrayerNameCellID" // This is the cell ID of the cell that holds the textView for changing prayer name
let DetailsExtendedCellID = "DetailsExtendedCellID" // This is the cell ID of the cell that holds the extended prayer details textView
let PrayerAlertCellID = "PrayerAlertCellID" // This is the cell ID of the cell that shows an alert added to the prayer
let AddNewAlertCellID = "AddNewAlertCellID" // This is the cell ID of the cell that shows "Add New Alert"
let AnsweredPrayerCellID = "AnsweredPrayerCellID" // This is the cell ID of the cell that holds the checkmark for answered or not
let AnsweredPrayerNotesCellID = "AnsweredPrayerNotesCellID" // This is the cell ID of the cell that holds the prayer answered notes textView (unused)
let SetPrayerDateCellID = "SetPrayerDateCellID" // This is the cell ID of the cell that allows you to set the prayer date
let PriorityCellID = "PriorityCellID" // This is the cell ID of the cell that holds the UISegmentedController for prayer priority
let PrayerCategoryCellID = "PrayerCategoryCellID" // This is the cell ID of the cell that holds the prayer category
let ChangeCategoryCellID = "ChangeCategoryCellID" // This is the cell ID of the cell that holds the pickerView to change prayer category

// -- TodayPrayersViewController
let TodayCellID = "TodayPrayerCellID" // This is the cell ID of the cell that is used in TodayPrayersViewController to display the prayer

// -- PrayerSearchViewController
let PrayerSearchCellID = "PrayerSearchCellID" // This is the cell ID of the cell used in PrayerSearchViewController to display search results

// Storyboard View Controller IDs
let SBPrayersViewControllerID = "SBPrayersViewControllerID" // This is the storyboard ID of the PersonalPrayersViewController
let SBAnsweredPrayersViewControllerID = "SBAnsweredPrayersViewControllerID" // This is the storyboard ID of the AnsweredPrayersViewController
let SBTodayNavControllerID = "SBTodayNavControllerID" // This is the storyboard ID of the TodayPrayersViewController's NavigationController
let SBPrayerDetailsNavControllerID = "SBPrayerDetailsNavControllerID" // This is the storyboard ID of the PrayerDetailsViewController's NavigationController