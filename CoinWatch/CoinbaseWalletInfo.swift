//
//  CoinbaseWalletInfo.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 12/12/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import RealmSwift

class CoinbaseWalletInfo: Object {
    dynamic var uuid: String = UUID().uuidString
    dynamic var accountId: String?
    dynamic var coinbaseAccount: CoinbaseAccount?
    
    override class func primaryKey() -> String? {
        return #keyPath(CoinbaseWalletInfo.uuid);
    }
}
