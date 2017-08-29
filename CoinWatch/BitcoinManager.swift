//
//  BitcoinManager.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/28/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import PromiseKit
import RealmSwift

class BitcoinManager: NSObject {
    static let pollTimeout: TimeInterval = 10.5
    
    static let instance = BitcoinManager()
    
    private var walletsToken: NotificationToken!
    private var syncInProgress = false
    
    override init() {
        super.init()
        self.loadAndWatchWallets()
    }
    
    
    private func loadAndWatchWallets() {
        self.walletsToken = Wallet.fetchWith(coinTypeId: CoinType.bitcoin.rawValue).addNotificationBlock() { [weak self] changes in
            switch changes {
                case .initial(let wallets):
                    if wallets.count > 0 {
                        self?.sync()
                    }
                case .update(let wallets, let deletions, let insertions, _):
                    if wallets.count > 0 && (deletions.count > 0 || insertions.count > 0) {
                        self?.sync()
                    }
                case .error:
                    break
            }
        }
    }
    
    private func scheduleNextSync() {
        let newTask = DispatchWorkItem { [weak self] in
            self?.sync()
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + BitcoinManager.pollTimeout, execute: newTask)
    }
    
    private func sync() {
        if self.syncInProgress {
            return
        }
        
        self.syncInProgress = true
        
        if let w = Wallet.fetchWith(coinTypeId: CoinType.bitcoin.rawValue).sorted(byKeyPath: #keyPath(Wallet.lastUpdatedAt), ascending: true).first {
                let walletUUID = w.uuid
                NetworkIndicatorManager.instance.show()
                BitcoinManager.fetchAmount(forBitcoinAddress: w.address).then { nativeBalance -> Void in
                        print("Fetched native balance: \(nativeBalance)")
                        let realm = try! Realm()
                        realm.beginWrite()
                    
                        if let wallet = realm.object(ofType: Wallet.self, forPrimaryKey: walletUUID) {
                            wallet.nativeBalance = nativeBalance
                            wallet.lastUpdatedAt = Date().timeIntervalSince1970
                        }
                        
                        try? realm.commitWrite()
                    }.catch { error in
                        print("Error retrieving Bitcoin balance:" + error.localizedDescription)
                    }.always { [weak self] in
                        NetworkIndicatorManager.instance.hide()
                        self?.syncInProgress = false
                        self?.scheduleNextSync()
                    }            
        } else {
            self.syncInProgress = false
            self.scheduleNextSync()
        }
    }
    
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

}
