//
//  UserPreferences.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/22/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import RealmSwift



class UserPreferences: Object {
    static let DEFAULT_ID: Int = 0
    
    dynamic var id: Int = UserPreferences.DEFAULT_ID
    dynamic var currencyType: String = Currency.usd.rawValue
    
    var currency: Currency {
        get {
            return Currency(rawValue: self.currencyType)!
        }
    }
    
    override class func primaryKey() -> String? {
        return #keyPath(UserPreferences.id)
    }
    
    static func current() -> UserPreferences {
        let realm = try! Realm()
        if let userPreferences = realm.object(ofType: UserPreferences.self, forPrimaryKey: UserPreferences.DEFAULT_ID) {
            return userPreferences
        } else {
            realm.beginWrite()
            let defaultUserPreferences = UserPreferences()
            realm.add(defaultUserPreferences)
            try! realm.commitWrite()
            return defaultUserPreferences            
        }
    }
}
