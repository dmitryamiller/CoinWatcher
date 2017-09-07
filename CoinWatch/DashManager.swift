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
            let urlStr = "https://api.blockcypher.com/v1/dash/main/addrs/\(address)/full)"
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
                            if let txs = json["txs"] as? Array<[String : Any]>{
                                return txs
                            } else {
                                return Array<[String : Any]>()
                            }
                        }()
                        
                        for node in transactions {
                            guard let txHash = txJson["hash"] as? String,
                                let amount = txJson["total"] as? Double,
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
                            tx.date = EtheriumManager.dateFormatter.date(from: dateConfirmed)
                            tx.nativeAmount = (input == 0 ? Double(-1) : Double(1)) * amount / EtheriumManager.divider
                            tx.nativeBalance = balance / EtheriumManager.divider
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
}
