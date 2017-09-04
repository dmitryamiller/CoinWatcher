//
//  EtheriumManager.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 9/3/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import PromiseKit
import RealmSwift

class EtheriumManager: NSObject {
    static let instance = EtheriumManager()
    static let divider: Double = 1000000000000000000
    
    func fetchBalances(for addresses: [String]) -> Promise<[String : Double]> {
        if addresses.count == 0 {
            return Promise(value: [String : Double]())
        }
        
        return Promise<[String: Double]> { fulfill, reject in
            let urlStr = "https://api.blockcypher.com/v1/eth/main/addrs/\(addresses.joined(separator: "%3B"))/balance"
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
                            
                            balances[adress] = balance / EtheriumManager.divider
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
            let urlStr = "https://api.blockcypher.com/v1/eth/main/addrs/\(address)"
            let url = URL(string: urlStr)!
            let request = URLRequest(url: url)
            let session = URLSession.shared
            
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let data = data {
                    if let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String : Any] {
                        guard let transactions = json["txrefs"] as? Array<[String : Any]> else { reject(CoinWatcherError.badJSON); return }
                        
                        
                        let realm = try! Realm()
                        realm.beginWrite()
                        
                        guard let wallet = Wallet.fetchWith(address: address, coinTypeId: CoinType.etherium.rawValue) else { fulfill(); return }
                        
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
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ss'Z'"
        return formatter
    }()
}


