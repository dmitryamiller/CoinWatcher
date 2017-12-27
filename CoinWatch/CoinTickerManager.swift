//
//  CoinTickerManager.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/28/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import PromiseKit
import RealmSwift

class CoinTickerManager: NSObject {
    
    static let pollInterval: TimeInterval = 15
    static let instance = CoinTickerManager()
    
    private var invalidator:Invalidator!
    private var walletNotificationToken: NotificationToken!
    
    private var isPollPending = true
    private var isPolling = false
    
    required override init() {
        super.init()
        
        self.invalidator = Invalidator(interval: 0.1) { [weak self] in
            self?.sync()
        }
        
        self.loadAndWatchUserPreferences()
    }
    
    private func updateCoinTickersForAllWallets() {
        let realm = try! Realm()
        realm.beginWrite()
        let currencyType = UserPreferences.current().currencyType
        
        for wallet in realm.objects(Wallet.self) {
            let coinTicker: CoinTicker = {
                if let existingTicker = realm.object(ofType: CoinTicker.self, forPrimaryKey: CoinTicker.uuid(forCoinTypeId: wallet.coinTypeId, currencyId: currencyType)) {
                    return existingTicker
                } else {
                    let ticker = CoinTicker()
                    ticker.uuid = CoinTicker.uuid(forCoinTypeId: wallet.coinTypeId, currencyId: currencyType)
                    ticker.price = 0
                    realm.add(ticker)
                    
                    return ticker
                }
            }()
            
            wallet.ticker = coinTicker
        }
        try? realm.commitWrite()
    }
    
    private func loadAndWatchUserPreferences() {
        let userPreferences = UserPreferences.current()
        self.watch(object: userPreferences, propertyName: #keyPath(UserPreferences.currencyType)) { [weak self] in
            self?.updateCoinTickersForAllWallets()
            self?.invalidator.invalidate()
        }
    }
    
    private func sync() {
        if isPolling {
            self.isPollPending = true
            return
        }
        
        self.isPolling = true
        NetworkIndicatorManager.instance.show()
        CoinTickerManager.fetchTickers(for: UserPreferences.current().currency).then { [weak self] ()-> Void in
                if self?.isPollPending ?? false {
                    DispatchQueue.main.async {
                        self?.invalidator.invalidate()
                    }
                    
                    self?.isPollPending = false
                } else {
                    self?.scheduleNextSync()
                }
            }.catch { [weak self] error in
                self?.isPollPending = false
                DispatchQueue.main.async {
                    self?.sync()
                }
            }.always { [weak self] () -> Void in
                self?.isPolling = false
                NetworkIndicatorManager.instance.hide()
            }
    }    
    
    private func scheduleNextSync() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + CoinTickerManager.pollInterval) { [weak self] in
            self?.invalidator.invalidate()
        }
    }
}

extension CoinTickerManager {
    fileprivate static func fetchTickers(for currency: Currency) -> Promise<Void> {
        return Promise { fulfill, reject in
            let urlString = "https://api.coinmarketcap.com/v1/ticker/?convert=\(currency.rawValue)"
            
            guard let url = URL(string: urlString) else { reject(NSError(domain: "url", code: 0, userInfo: nil)); return }
            let request = URLRequest(url: url)
            let session = URLSession.shared
            
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let data = data {
                    guard let tickers = try? JSONSerialization.jsonObject(with: data, options: [.allowFragments, .mutableContainers]) as? Array<[String: Any]> else { reject(NSError(domain: "json", code: 0, userInfo: nil)); return  }
                    
                    self.process(tickers: tickers!)
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
            
            let tickerUUID = CoinTicker.uuid(forCoinTypeId: coinType.rawValue, currencyId: userPreferences.currency.rawValue)
            let ticker = realm.object(ofType: CoinTicker.self, forPrimaryKey: tickerUUID)
            if ticker == nil {
                let ticker = CoinTicker()
                ticker.coinTypeId = coinType.rawValue
                ticker.currencyId = userPreferences.currency.rawValue
                ticker.price = Double(priceInCurrentCurrencyStr) ?? 0
                ticker.uuid = tickerUUID
                realm.add(ticker)
            } else {
                ticker?.price = Double(priceInCurrentCurrencyStr) ?? 0
            }
            
            // get the wallets that don't have ticker for that coin type yet
            if let ticker = ticker {
                let wallets = Wallet.fetchWith(coinTypeId: ticker.coinTypeId).filter("%K = nil", #keyPath(Wallet.ticker))
                for w in wallets {
                    w.ticker = ticker
                }
            }
        }
        
        try? realm.commitWrite()
    }
}
