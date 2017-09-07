//
//  DashManager.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 9/4/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import PromiseKit
import RealmSwift

class DashManager: NSObject {
    static let instance = DashManager()
    
    private static let balanceAmountDivider: Double = 100000000
    
    func updateWalletBalances() -> Promise<Void> {
        let wallets = Wallet.fetchWith(coinTypeId: CoinType.dash.rawValue)
        
        if wallets.count == 0 {
            return Promise()
        }
        
        return self.fetchBalances(for: wallets.map { $0.address } )
            .then { balances -> Void in
                
                let realm = try! Realm()
                realm.beginWrite()
                for w in wallets {
                    if let balance = balances[w.address] {
                        w.nativeBalance = balance
                        w.lastBalanceSync = Date()
                    }
                }
                try? realm.commitWrite()
        }
    }
    
    func fetchBalances(for addresses: [String]) -> Promise<[String : Double]> {
        if addresses.count == 0 {
            return Promise(value: [String : Double]())
        }
        
        return Promise<[String : Double]> { fulfill, reject in
            let urlStr = "https://api.blockcypher.com/v1/dash/main/addrs/\(addresses.joined(separator: "%3B"))"
            let url = URL(string: urlStr)!
            let request = URLRequest(url: url)
            let session = URLSession.shared
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let data = data {
                    if let json = (try? JSONSerialization.jsonObject(with: data, options: [])) {
                        let nodes: Array<[String: Any]> = {
                            if let nodes = json as? Array<[String: Any]> {
                                return nodes
                            } else if let node = json as? [String : Any] {
                                return [node]
                            } else {
                                return Array<[String: Any]>()
                            }
                        }()
                        
                        var balances = [String : Double]()
                        
                        for node in nodes {
                            guard let address = node["address"] as? String,
                                  let balance = node["balance"] as? Double
                            else { continue }
                            
                            balances[address] = balance / DashManager.balanceAmountDivider
                        }
                        
                        fulfill(balances)
                    } else {
                        reject(CoinWatcherError.badJSON)
                    }
                } else if let error = error {
                    reject(error)
                } else {
                    reject(CoinWatcherError.badJSON)
                }
            }
            
            dataTask.resume()
        }
    }
    
    func fetchTransactions(for address: String) -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            let urlStr = "https://api.blockcypher.com/v1/dash/main/addrs/\(address)"
            let url = URL(string: urlStr)!
            let request = URLRequest(url: url)
            let session = URLSession.shared
            
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let data = data {
                    if let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String : Any] {
                        let realm = try! Realm()
                        realm.beginWrite()
                        
                        guard let wallet = Wallet.fetchWith(address: address, coinTypeId: CoinType.dash.rawValue) else { fulfill(); return }
                        
                        let transactions: Array<[String : Any]> = {
                            if let txs = json["txrefs"] as? Array<[String : Any]>{
                                return txs
                            } else {
                                return Array<[String : Any]>()
                            }
                        }()
                        
                        var transactionLookup = [String : CoinTransaction]()
                        
                        for txJson in transactions {
                            guard let txHash = txJson["tx_hash"] as? String,
                                let amount = txJson["value"] as? Double,
                                let dateConfirmed = txJson["confirmed"] as? String
                            else { continue }
                            
                            
                            let tx: CoinTransaction = {
                                if let processedTx = transactionLookup[txHash] {
                                    return processedTx
                                } else {
                                    let tx = CoinTransaction()
                                    tx.txHash = txHash
                                    
                                    tx.date = DashManager.date(from: dateConfirmed)
                                    
                                    transactionLookup[txHash] = tx
                                    return tx
                                }
                            }()
                            
                            let multiplier: Double = txJson["spent"] as? Bool ?? false ? 1 : -1
                            tx.nativeAmount += multiplier * amount                            
                        }
                        
                        for (txHash, tempTx) in transactionLookup {
                            
                            let tx: CoinTransaction = {
                                if let existingTx = CoinTransaction.transaction(with: txHash, wallet: wallet) {
                                    return existingTx
                                } else {
                                    let newTx = CoinTransaction()
                                    newTx.txHash = txHash
                                    newTx.wallet = wallet
                                    realm.add(newTx)
                                    return newTx
                                }
                            }()
                            
                            tx.date = tempTx.date
                            tx.nativeAmount = tempTx.nativeAmount / DashManager.balanceAmountDivider
                        }
                        
                        try? realm.commitWrite()
                        
                        fulfill()
                    } else {
                        reject(CoinWatcherError.badJSON)
                    }
                } else if let error = error {
                    reject(error)
                } else {
                    reject(CoinWatcherError.badJSON)
                }
            }
            
            dataTask.resume()
            
        }
    }
    
    
    static func date(from strDate: String) -> Date? {
        for dateFormatter in [DashManager.dateFormatter_Long1, DashManager.dateFormatter_Long2, DashManager.dateFormatter_Long3, DashManager.dateFormatter_Short] {
            if let date = dateFormatter.date(from: strDate) {
                return date
            }
        }
        
        return nil
    }
    
    static let dateFormatter_Long1: DateFormatter = {
        let formatter = DateFormatter()
        formatter.isLenient = true
        formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ss.S'Z'"
        return formatter
    }()
    
    static let dateFormatter_Long2: DateFormatter = {
        let formatter = DateFormatter()
        formatter.isLenient = true
        formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ss.SS'Z'"
        return formatter
    }()
    
    static let dateFormatter_Long3: DateFormatter = {
        let formatter = DateFormatter()
        formatter.isLenient = true
        formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }()
    
    static let dateFormatter_Short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.isLenient = true
        formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }()
    
}

