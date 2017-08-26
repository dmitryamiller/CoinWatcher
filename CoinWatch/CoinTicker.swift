//
//  CoinTicker.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/24/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import RealmSwift

class CoinTicker: Object {
    dynamic var uuid: String = ""
    dynamic var coinTypeId: String = CoinType.bitcoin.rawValue
    dynamic var currencyId: String = Currency.usd.rawValue
    dynamic var price: Double = 0.0
    
    override class func primaryKey() -> String? {
        return #keyPath(CoinTicker.uuid)
    }
    
    static func uuid(forCoinTypeId coinTypeId: String, currencyId: String) -> String {
        return "\(coinTypeId)-\(currencyId)"
    }
}
