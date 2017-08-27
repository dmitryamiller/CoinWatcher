//
//  CoinWatcher.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/24/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import Foundation
import RealmSwift
import PromiseKit

class CoinWatcher: NSObject {
    static let walletUpddateTimeout: TimeInterval = 15
    
    static let instance = CoinWatcher()
    
    private var lastSync: TimeInterval = 0
    private var syncPending: Bool = false
    private var syncInProgress: Bool = false
    
    private var walletNotificationToken: NotificationToken!
    private var userPreferencesNotificationToken: NotificationToken!
    
    
    private var invalidator: Invalidator!
    
    required override init() {
        super.init()
        
        self.invalidator = Invalidator(interval: 0.5) { [weak self] in
            self?.sync()
        }
        self.loadAndWatchWalletsAndUserPreferences()
    }
    
    private func updateCoinTickersForAllWallets() {
        let realm = try! Realm()
        realm.beginWrite()
        let currencyType = UserPreferences.current().currencyType
        
        for wallet in realm.objects(Wallet.self) {
            wallet.ticker = realm.object(ofType: CoinTicker.self, forPrimaryKey: CoinTicker.uuid(forCoinTypeId: wallet.coinTypeId, currencyId: currencyType))
            wallet.lastUpdatedAt = 0
        }
        try? realm.commitWrite()
    }
    
    private func loadAndWatchWalletsAndUserPreferences() {
        let realm = try! Realm()
        self.walletNotificationToken = realm.objects(Wallet.self).addNotificationBlock { [weak self] changes in
            switch (changes) {
                case .initial(_): self?.invalidator.invalidate()
                case .update(_, let deletions, let insertions, _):
                    if deletions.count > 0 || insertions.count > 0 {
                        self?.invalidator.invalidate()
                    }
                case .error: break
            }
        }
        
        let userPreferences = UserPreferences.current()
        self.watch(object: userPreferences, propertyName: #keyPath(UserPreferences.currencyType)) { [weak self] in
            self?.updateCoinTickersForAllWallets()
            self?.invalidator.invalidate()
        }
    }
    
    private func scheduleNextSync() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + CoinWatcher.walletUpddateTimeout) { [weak self] in
            self?.invalidator.invalidate()
        }
    }
    
    private func sync() {
        if self.syncInProgress {
            self.syncPending = true
            self.scheduleNextSync()
            return
        }
        
        self.syncPending = false
        
        let userPreferences = UserPreferences.current()
        let walletPromises = self.walletPromises(for: userPreferences.currency)
        
        self.syncInProgress = true
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        _ = self.fetchTickers(for: userPreferences.currency).then() { _ in
                return when(resolved: walletPromises)
            }.always { [weak self] in
                guard let unwrappedSelf = self else { return }
                unwrappedSelf.lastSync = Date().timeIntervalSince1970
                unwrappedSelf.syncInProgress = false
                
                if unwrappedSelf.syncPending {
                    DispatchQueue.main.async {
                        unwrappedSelf.sync()
                    }
                } else {
                    unwrappedSelf.scheduleNextSync()
                }
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
    }
    
    private func walletPromises(for currency: Currency) -> [Promise<Void>] {
        let realm = try! Realm()
        let wallets = realm.objects(Wallet.self)
        
        var walletPromises = [Promise<Void>]()
        let currentTime = Date().timeIntervalSince1970
        for w in wallets {
            if !w.addressValid {
                continue
            }
            
            if currentTime - w.lastUpdatedAt < CoinWatcher.walletUpddateTimeout {
                continue
            }
            switch w.coinType {
                case .bitcoin:
                    walletPromises.append(CoinWatcher.fetchBitcoinBalance(for: w.address, currency: currency))
                case .etherium:
                    continue
            }
        }
        
        return walletPromises
    }
}

// Tickers

extension CoinWatcher {
    fileprivate func fetchTickers(for currency: Currency) -> Promise<Void> {
        return Promise { fulfill, reject in
            let urlString = "https://api.coinmarketcap.com/v1/ticker/?convert=\(currency.rawValue)"
            
            guard let url = URL(string: urlString) else { reject(NSError(domain: "url", code: 0, userInfo: nil)); return }
            let request = URLRequest(url: url)
            let session = URLSession.shared
            
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let data = data {
                    guard let tickers = try? JSONSerialization.jsonObject(with: data, options: [.allowFragments, .mutableContainers]) as? Array<[String: Any]> else { reject(NSError(domain: "json", code: 0, userInfo: nil)); return  }
                    
                    CoinWatcher.process(tickers: tickers!)
                    
                    fulfill()
                } else if let error = error {
                    reject(error)
                } else {
                    reject(NSError(domain: "nothing", code: 0, userInfo: nil))
                }
            }
            
            dataTask.resume()
        }
    }
    
    private static func process(tickers: Array<[String: Any]>) {
        let realm = try! Realm()
        
        let userPreferences = UserPreferences.current()
        let priceKey = "price_\(userPreferences.currency.rawValue.lowercased())"
        
        realm.beginWrite()
        
        for json in tickers {
            guard let symbol = json["symbol"] as? String,
                  let priceInCurrentCurrencyStr = json[priceKey] as? String
            else { continue }
            
            guard let coinType = CoinType(rawValue: symbol) else { continue }
            
            let ticker = realm.object(ofType: CoinTicker.self, forPrimaryKey: CoinTicker.uuid(forCoinTypeId: coinType.rawValue, currencyId: userPreferences.currency.rawValue))
            if ticker == nil {
                let ticker = CoinTicker()
                ticker.coinTypeId = coinType.rawValue
                ticker.currencyId = userPreferences.currency.rawValue
                ticker.price = Double(priceInCurrentCurrencyStr) ?? 0
                ticker.uuid = CoinTicker.uuid(forCoinTypeId: ticker.coinTypeId, currencyId: ticker.currencyId)
                realm.add(ticker)
            } else {
                ticker?.price = Double(priceInCurrentCurrencyStr) ?? 0
            }
        }
        
        try? realm.commitWrite()
    }
}


// BitCoin
extension CoinWatcher {
    static func fetchAmount(forBitcoinAddress address: String) -> Promise<Double> {
        return Promise { fulfill, reject in
            let urlString = "https://blockchain.info/q/addressbalance/\(address)"
            
            guard let url = URL(string: urlString) else { reject(NSError(domain: "url", code: 0, userInfo: nil)); return }
            let request = URLRequest(url: url)
            let session = URLSession.shared
            
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let data = data {
                    guard let stringResponse = String(data: data, encoding: String.Encoding.utf8) else { reject(NSError(domain: "null", code: 0, userInfo: nil)); return  }
                    
                    
                    if let amount = Double(stringResponse) {
                        fulfill(amount / Double(100000000))
                    } else {
                        reject(NSError(domain: "invalidAddress", code: 0, userInfo: nil))
                    }
                } else if let error = error {
                    reject(error)
                } else {
                    reject(NSError(domain: "nothing", code: 0, userInfo: nil))
                }
            }
            
            dataTask.resume()
                
        }
    }
    
    static func fetchBitcoinBalance(for publicKey: String, currency: Currency) -> Promise <Void> {
        return Promise { fulfill, reject in
            let urlString = "https://blockchain.info/q/addressbalance/\(publicKey)?confirmations=6"
                        
            guard let url = URL(string: urlString) else { reject(NSError(domain: "url", code: 0, userInfo: nil)); return }
            let request = URLRequest(url: url)
            let session = URLSession.shared
            
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let data = data {
                    guard let stringResponse = String(data: data, encoding: String.Encoding.utf8) else { reject(NSError(domain: "null", code: 0, userInfo: nil)); return  }
                    
                    let realm = try! Realm()
                    realm.beginWrite()
                    
                    guard let wallet = Wallet.fetchWith(address: publicKey, coinTypeId: CoinType.bitcoin.rawValue) else { realm.cancelWrite(); fulfill(); return }
                    
                    
                    
                    guard let coinTicker = realm.object(ofType: CoinTicker.self, forPrimaryKey: CoinTicker.uuid(forCoinTypeId: CoinType.bitcoin.rawValue, currencyId: currency.rawValue)) else { reject(NSError(domain: "noTickerFound", code: 0, userInfo: ["coinType" : CoinType.bitcoin, "currencyType" : currency])); realm.cancelWrite(); return  }
                    
                    
                    
                    if let nativeBalance = Double(stringResponse) {
                        wallet.nativeBalance = nativeBalance / Double(100000000)
                        wallet.addressValid = true
                    } else {
                        wallet.addressValid = false
                    }
                    
                    wallet.ticker = coinTicker
                    wallet.lastUpdatedAt = Date().timeIntervalSince1970
                    
                    try? realm.commitWrite()
                    
                    fulfill()
                } else if let error = error {
                    reject(error)
                } else {
                    reject(NSError(domain: "nothing", code: 0, userInfo: nil))
                }
            }
            
            dataTask.resume()
        }
    }
}
