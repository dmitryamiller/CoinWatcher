//
//  BitcoinCashManager.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 11/15/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import PromiseKit
import RealmSwift

class BitcoinCashManager: NSObject {
    public static let instance = BitcoinCashManager()
    
    private static let apiKey = "6cff8089ecce84fc7fa66abf9c2ef33e702439c2"
    private static let satoshi: Double = 100000000
    
    override private init() {
        
    }
    
    func updateWalletBalances() -> Promise<Void> {
        let wallets = Wallet.fetchWith(coinTypeId: CoinType.bitcoinCash.rawValue)
        
        if wallets.count == 0 {
            return Promise<Void>()
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
        
        var promises = [Promise<(address: String, balance: Double)>]()
        for address in addresses {
            promises.append(self.fetchBalance(for: address))
        }
        
        return  Promise<[String : Double]> { fulfill, reject in
            _ = when(fulfilled: promises).then { balances -> Void in
                var balanceMap = [String : Double]()
                for b in balances {
                    balanceMap[b.address] = b.balance
                }
                
                fulfill(balanceMap)
            }.catch { error in
                reject(error)
            }
        }
    }
    
    private func fetchBalance(for address: String) -> Promise<(address:String, balance: Double)> {
        return Promise { fulfill, reject in
            let urlStr = "https://api.blocktrail.com/v1/bcc/address/\(address)?api_key=\(BitcoinCashManager.apiKey)"
            let url = URL(string: urlStr)!
            let request = URLRequest(url: url)
            let session = URLSession.shared
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let data = data {
                    if let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String : Any] {
                        if let balance = json["balance"] as? Double {
                            fulfill((address: address, balance: balance / BitcoinCashManager.satoshi))
                        } else {
                            reject(NSError(domain: "badResponse", code: 0, userInfo: nil))
                        }
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
    
    func fetchTransactions(for address: String) -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            let urlStr = "https://api.blocktrail.com/v1/bcc/address/\(address)/transactions?api_key=\(BitcoinCashManager.apiKey)&sort_dir=desc"
            let url = URL(string: urlStr)!
            let request = URLRequest(url: url)
            let session = URLSession.shared
            
            let dataTask = session.dataTask(with: request) { data, response, error in
                if let data = data {
                    if let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String : Any] {
                        guard let transactions = json["data"] as? Array<[String : Any]> else { reject(CoinWatcherError.badJSON); return }
                        
                        
                        let realm = try! Realm()
                        realm.beginWrite()
                        
                        guard let wallet = Wallet.fetchWith(address: address, coinTypeId: CoinType.bitcoinCash.rawValue) else { fulfill(); return }
                        
                        for txJson in transactions {
                            guard let txHash = txJson["hash"] as? String,
                                let amount = txJson["estimated_value"] as? Double,
                                let date = txJson["time"] as? String
                            else { continue }
                            
                            if CoinTransaction.transaction(with: txHash, wallet: wallet) != nil {
                                continue
                            }
                            
                            let tx = CoinTransaction()
                            
                            let isTxAmountNegative = BitcoinCashManager.isNegative(address: address, txJson)
                            
                            tx.wallet = wallet
                            tx.txHash = txHash
                            tx.date = BitcoinCashManager.dateFormatter.date(from: date)
                            tx.nativeAmount = (isTxAmountNegative ? Double(-1) : Double(1)) * amount / BitcoinCashManager.satoshi
                            tx.nativeBalance = -1
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
    
    private static func isNegative(address: String, _ json:[String : Any]) -> Bool {
        guard let inputs = json["inputs"] as? Array<[String : Any]> else { return false }
        guard let fromAddress = inputs.first?["address"] as? String else { return false }
        return fromAddress == address // if outgoing address is the same as wallet address then we have a 
    }
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ssZZZ"
        return formatter
    }()
    
}
