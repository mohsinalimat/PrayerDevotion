//
//  DeviceList.swift
//  PrayerDevotion
//
//  Created by Jonathan Hart on 12/8/15.
//  Copyright © 2015 Jonathan Hart. All rights reserved.
//

import Foundation
import CoreData

extension NSURL {
    func forceSyncFile(dispatchQueue: dispatch_queue_t, completionHandler: ((syncCompleted: Bool) -> Void)) {
        
        //print("URL = \(self)")
        
        // Query if the file has been downloaded. We can exit if the query succeeds and the file is reported as downloaded
        var isDownloaded: AnyObject?
        do {
            try self.getResourceValue(&isDownloaded, forKey: NSURLUbiquitousItemDownloadingStatusKey)
            
            if let isDownloaded = isDownloaded {
                if (isDownloaded as! String) == NSURLUbiquitousItemDownloadingStatusCurrent {
                    completionHandler(syncCompleted: true)
                    return
                }
            }
        } catch let error as NSError {
            print("Error checking isDownloaded when syncing file with code \(error.code): \(error), \(error.localizedDescription)")
        }
        
        // Query if the file is downloading
        var isDownloading: AnyObject?
        do {
            try self.getResourceValue(&isDownloading, forKey: NSURLUbiquitousItemIsDownloadingKey)
        } catch let error as NSError {
            print("Error 1: \(error), \(error.localizedDescription)")
            //print("Error checking isDownloading when syncing file with code \(error.code): \(error), \(error.localizedDescription)")
            isDownloading = nil
        }
        
        // Start the file downloading if it is not already downloading
        if isDownloading == nil || !isDownloading!.boolValue {
            do {
                try NSFileManager.defaultManager().startDownloadingUbiquitousItemAtURL(self)
            } catch let error as NSError {
                print("Error: \(error), \(error.localizedDescription)")
                completionHandler(syncCompleted: false)
                return
            }
        }
        
        // Check again after a small delay
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC))), dispatchQueue, {
            self.forceSyncFile(dispatchQueue, completionHandler: completionHandler)
        })
    }
}

class DeviceList: NSObject, NSFilePresenter {
    var deviceListURL: NSURL? = nil
    var operationQueue: NSOperationQueue! = NSOperationQueue()
    
    convenience init(withURL fileURL: NSURL, queue: NSOperationQueue) {
        self.init()
        
        deviceListURL = fileURL
        operationQueue = queue
    }
    
    var presentedItemURL: NSURL? {
        return deviceListURL
    }
    
    var presentedItemOperationQueue: NSOperationQueue {
        return operationQueue
    }
    
    func presentedItemDidChange() {
        dispatch_async(dispatch_get_main_queue(), {
            // PrayerDevotionCloudStore.sharedInstance.deviceListChanged(nil)
        })
    }
    
    func accommodatePresentedItemDeletionWithCompletionHandler(completionHandler: (NSError?) -> Void) {
        dispatch_async(dispatch_get_main_queue(), {
            // PrayerDevotionCloudStore.sharedInstance.deviceListChanged(nil)
        })
        
        completionHandler(nil)
    }
    
}