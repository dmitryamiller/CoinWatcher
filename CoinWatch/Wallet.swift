//
//  Wallet.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/22/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import RealmSwift

class Wallet: Object {
    dynamic var uuid: String = UUID().uuidString
    dynamic var coinTypeId: String = CoinType.bitcoin.rawValue
    dynamic var name: String = ""
    dynamic var nativeBalance: Double = 0
    dynamic var address: String = ""
    dynamic var addressValid: Bool = true
    dynamic var sortIndex: Int = 0
    dynamic var lastUpdatedAt: TimeInterval = 0
    dynamic var ticker: CoinTicker?
    
    var coinType: CoinType {
        get {
            return CoinType(rawValue: self.coinTypeId)!
        }
    }
    
    override class func primaryKey() -> String? {
        return #keyPath(Wallet.uuid);
    }
            
    static func fetchWith(address: String, coinTypeId: String) -> Wallet? {
        let realm = try! Realm()
        
        return realm.objects(Wallet.self).filter("%K = %@ AND %K = %@", #keyPath(Wallet.address), address, #keyPath(Wallet.coinTypeId), coinTypeId).first
    }
    
    static func fetchWith(coinTypeId: String) -> Results<Wallet> {
        let realm = try! Realm()
        return realm.objects(Wallet.self).filter("%K = %@", #keyPath(Wallet.coinTypeId), coinTypeId)
    }
    
    static func exists(with address: String, coinType: CoinType) -> Bool {
        let realm = try! Realm()
        return realm.objects(Wallet.self).filter("%K = %@ AND %K = %@", #keyPath(Wallet.address), address, #keyPath(Wallet.coinTypeId), coinType.rawValue).first != nil
    }
    
    static func create(coinType: CoinType, address: String, name: String, nativeBalance: Double = -1) -> Wallet? {
        let realm = try! Realm()
        realm.beginWrite()
        let w = Wallet()
        w.address = address
        w.coinTypeId = coinType.rawValue
        w.name = name
        w.nativeBalance = nativeBalance
        w.sortIndex = Wallet.sortIndex(forWalletWith: coinType)
        w.ticker = realm.object(ofType: CoinTicker.self, forPrimaryKey: CoinTicker.uuid(forCoinTypeId: coinType.rawValue, currencyId: UserPreferences.current().currencyType))
        realm.add(w, update: true)
        
        
        
        
        try! realm.commitWrite()
        
        return realm.object(ofType: Wallet.self, forPrimaryKey: w.uuid)        
    }
    
    static func delete(wallet: Wallet) {
        let realm = try! Realm()
        
        realm.beginWrite()
        if let w = realm.object(ofType: Wallet.self, forPrimaryKey: wallet.uuid) {
            for tx in CoinTransaction.transactions(for: w) {
                realm.delete(tx)
            }
            
            realm.delete(w)
        }
        
        try? realm.commitWrite()
    }
    
    static func defaultName(for coinType: CoinType) -> String {
        let realm = try! Realm()
        let numExisting  = realm.objects(Wallet.self).filter("%K = %@", #keyPath(Wallet.coinTypeId), coinType.rawValue).count
        
        return numExisting > 0 ? "\(coinType.name) Wallet \(numExisting + 1)" : "\(coinType.name) Wallet" 
    }
    
    static func sortIndex(forWalletWith coinType: CoinType) -> Int {
        let realm = try! Realm()
        let walletWithMaxSortIndex = realm.objects(Wallet.self)
                                           .filter("%K = %@", #keyPath(Wallet.coinTypeId), coinType.rawValue)
                                           .max() { $0.sortIndex > $1.sortIndex }
        return walletWithMaxSortIndex?.sortIndex ?? 0 + 1
    }
}
