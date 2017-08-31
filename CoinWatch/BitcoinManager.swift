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
    static let pollTimeout: TimeInterval = 11
    
    static let instance = BitcoinManager()
    
    private var walletsToken: NotificationToken!
    private var syncInProgress = false
    private var timer: Timer!
    
    override init() {
        super.init()
        self.timer = Timer.scheduledTimer(withTimeInterval: BitcoinManager.pollTimeout, repeats: true) { [weak self] _ in
            print("Timer fire")
            self?.sync()
        }
        
        self.timer.fire()
    }
    
    private func sync() {
        // only one at a time
        if self.syncInProgress {
            return
        }
        
        self.syncInProgress = true
        
        let wallets = Wallet.fetchWith(coinTypeId: CoinType.bitcoin.rawValue)
        if wallets.count > 0 {
            NetworkIndicatorManager.instance.show()
            
            BitcoinManager.fetchBalanceAndTransactions(for: wallets.map({ $0.address })).then { json -> Void in
                BitcoinManager.processBalancesAndTransactions(json: json)
            }.catch { error in
                print("Error retrieving Bitcoin balance:" + error.localizedDescription)
            }.always { [weak self] in
                NetworkIndicatorManager.instance.hide()
                self?.syncInProgress = false
            }
        }
        else {
            self.syncInProgress = false
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

    private static func processBalancesAndTransactions(json: [String : Any]) {
        let realm = try! Realm()
        realm.beginWrite()
        
        if let addresses = json["addresses"] as? Array<[String : Any ]> {
            for addrJson in addresses {
                guard let addr = addrJson["address"] as? String,
                      let nativeBalance = addrJson["final_balance"] as? Double else { continue }
                guard let wallet = Wallet.fetchWith(address: addr, coinTypeId: CoinType.bitcoin.rawValue) else { continue }
                wallet.nativeBalance = nativeBalance / 100000000
                
                
            }
        }
        
        try? realm.commitWrite()
    }
}



extension BitcoinManager {
    static func fetchBalanceAndTransactions(for addresses: [String]) -> Promise <[String : Any]> {
        return Promise <[String : Any]> { fulfill, reject in
            //https://blockchain.info/multiaddr?active=xpub6CRM8u6Fo9XJyG7xdvcvm7e4Rb1BXQGM6QR9GPLhx9nYvXoCpBb4Nt1ibNgFSYsckvzqSscs9HhpivGQkkYRULjYHwe9D6n2gMgY3ZBhpNX|19Px1fDwhWZULgPr4NvUcNULDo1V6gKhpd&format=json&currency=EUR
            
            let urlStr = "https://blockchain.info/multiaddr?active=\(addresses.joined(separator: "%7C"))&format=json"
            let url = URL(string: urlStr)
            let request = URLRequest(url: url!)
            let session = URLSession.shared
            
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let data = data {
                    if let response = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String : Any] {
                        fulfill(response)
                    } else {
                        reject(NSError(domain: "badResponse", code: 0, userInfo: nil))
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
