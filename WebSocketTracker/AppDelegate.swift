//
//  AppDelegate.swift
//  WebSocketTracker
//
//  Created by Douglas Barbosa on 27/05/17.
//  Copyright © 2017 Douglas Barbosa. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        //We close connection everytime the app enters in background mode
        SocketManager.sharedInstance.closeConnection()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        //We close connection everytime the app starts
        SocketManager.sharedInstance.establishConnection()
    }

}

