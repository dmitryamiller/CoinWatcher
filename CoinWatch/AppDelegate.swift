//
//  AppDelegate.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/22/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import HockeySDK
import RealmSwift
import PromiseKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        BITHockeyManager.shared().configure(withIdentifier: "a096f12b4bd94188b8995a299b5e4dfb")
        BITHockeyManager.shared().start()
        BITHockeyManager.shared().authenticator.authenticateInstallation() 
        
        // init realm
        var config = Realm.Configuration()
        config.fileURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.goblin77.CoinWatch")!.appendingPathComponent("default.realm")
        Realm.Configuration.defaultConfiguration = config
        
        _ = UserPreferences.current() // ensure the preferences exist
        _ = CoinTickerManager.instance
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if !CoinbaseManager.instance.canOpenUrl(url) {
            return false
        } else {
            CoinbaseManager.instance.finishAuthentication(with: url).then { () -> Void in
                NotificationCenter.default.post(name: .coinbaseAuthenticationSuccess, object: nil)
            }.catch { error in
                 NotificationCenter.default.post(name: .coinbaseAuthenticationFailure, object: error)
            }
            
            return true
        }
    }
}

