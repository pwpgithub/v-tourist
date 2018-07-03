//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Ping Wu on 3/5/18.
//  Copyright © 2018 SHDR. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

// MARK: - AppDelegate: UIResponder, UIApplicationDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: Properties
    var window: UIWindow?
    let dataController = DataController(modelName: "VirtualTourist")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        dataController.load()
        
        let navController = window?.rootViewController as! UINavigationController
        let mapVC = navController.topViewController as! MapViewController
        
        let store = PhotoStore()
        store.dataController = dataController
        
        mapVC.photoStore = store
        
        return true
    }
   

    func applicationDidEnterBackground(_ application: UIApplication) {
        saveViewContext()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
        saveViewContext()
    }
    
    
    func saveViewContext() {
        try? dataController.viewContext.save()
    }
}

