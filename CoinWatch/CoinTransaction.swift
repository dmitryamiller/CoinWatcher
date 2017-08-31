//
//  CoinTransaction.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/30/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import Foundation
import RealmSwift

class CoinTransaction: Object {
    dynamic var uuid: String = UUID().uuidString
    dynamic var txHash: String?
    dynamic var date: Date?
    dynamic var nativeAmount: Double = 0
    dynamic var nativeBalance: Double = 0
    dynamic var wallet: Wallet?
    
    override class func primaryKey() -> String? {
        return #keyPath(CoinTransaction.uuid);
    }
    
    static func transactions(for wallet: Wallet) -> Results<CoinTransaction> {
        let realm = try! Realm()
        return realm.objects(CoinTransaction.self).filter("%K = %@", #keyPath(CoinTransaction.wallet), wallet)
    }
    
    static func transaction(withHash txHash: String, coinType: CoinType) -> CoinTransaction? {
        let realm = try! Realm()
        return realm.objects(CoinTransaction.self).filter("%K = %@ AND %K = %@", #keyPath(CoinTransaction.txHash), txHash, #keyPath(CoinTransaction.wallet.coinTypeId), coinType.rawValue).first
    }
}
