//
//  CoinbaseAccount.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 12/12/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import RealmSwift

class CoinbaseAccount: Object {
    dynamic var uuid: String = UUID().uuidString
    dynamic var login: String?
    dynamic var accessToken: String?
    dynamic var accessTokenExpirationDate: Date?
    
    override class func primaryKey() -> String? {
        return #keyPath(CoinbaseAccount.uuid);
    }
    
    func isAuthenticationValid() -> Bool {
        guard let accessTokenExpirationDate = self.accessTokenExpirationDate else { return false }
        return accessTokenExpirationDate.timeIntervalSince1970 - Date().timeIntervalSince1970 > 0
    }
}
