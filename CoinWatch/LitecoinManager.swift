//
//  LitecoinManager.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 11/16/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import PromiseKit
import RealmSwift

class LitecoinManager: NSObject {
    public static let instance = LitecoinManager()
    private static let divider: Double = 100000000
    
    override private init() {
    }
    
    func updateWalletBalances() -> Promise<Void> {
        let wallets = Wallet.fetchWith(coinTypeId: CoinType.litecoin.rawValue)
        
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
        
        return Promise<[String: Double]> { fulfill, reject in
            let urlStr = "https://api.blockcypher.com/v1/ltc/main/addrs/\(addresses.joined(separator: "%3B"))/balance"
            let url = URL(string: urlStr)!
            let request = URLRequest(url: url)
            let session = URLSession.shared
            
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let data = data {
                    if let json = (try? JSONSerialization.jsonObject(with: data, options: [.allowFragments, .mutableContainers])) {
                        var balances = [String : Double]()
                        
                        var addressNodes: Array<[String : Any]>!
                        if let nodes = json as? Array<[String : Double]> {
                            addressNodes = nodes
                        } else if let node = json as? [String : Any] {
                            addressNodes = [node]
                        } else {
                            reject(CoinWatcherError.badJSON)
                            return
                        }
                        
                        for addrNode in addressNodes {
                            guard let adress = addrNode["address"] as? String,
                                let balance = addrNode["balance"] as? Double
                                else {
                                    continue
                            }
                            
                            balances[adress] = balance / LitecoinManager.divider
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
            let urlStr = "https://api.blockcypher.com/v1/ltc/main/addrs/\(address)"
            let url = URL(string: urlStr)!
            let request = URLRequest(url: url)
            let session = URLSession.shared
            
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let data = data {
                    if let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String : Any] {
                        guard let transactions = json["txrefs"] as? Array<[String : Any]> else { reject(CoinWatcherError.badJSON); return }
                        
                        
                        let realm = try! Realm()
                        realm.beginWrite()
                        
                        guard let wallet = Wallet.fetchWith(address: address, coinTypeId: CoinType.litecoin.rawValue) else { fulfill(); return }
                        
                        for txJson in transactions {
                            guard let txHash = txJson["tx_hash"] as? String,
                                let amount = txJson["value"] as? Double,
                                let input   = txJson["tx_input_n"] as? Int,
                                let dateConfirmed = txJson["confirmed"] as? String,
                                let balance = txJson["ref_balance"] as? Double
                                else { continue }
                            
                            if CoinTransaction.transaction(with: txHash, wallet: wallet) != nil {
                                continue
                            }
                            
                            let tx = CoinTransaction()
                            
                            tx.wallet = wallet
                            tx.txHash = txHash
                            tx.date = LitecoinManager.parse(dateStr: dateConfirmed)
                            tx.nativeAmount = (input == 0 ? Double(-1) : Double(1)) * amount / LitecoinManager.divider
                            tx.nativeBalance = balance / LitecoinManager.divider
                            realm.add(tx)
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
    
    private static func parse(dateStr: String) -> Date? {
        if let dateWithMiliseconds = self.dateFormatterWithMiliseconds.date(from: dateStr) {
            return dateWithMiliseconds
        } else if let dateWithoutMiliseconds = self.dateFormatterNoMiliseconds.date(from: dateStr) {
            return dateWithoutMiliseconds
        } else {
            return nil
        }
    }
    
    private static let dateFormatterWithMiliseconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter
    }()
    
    private static let dateFormatterNoMiliseconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }()
    
}
