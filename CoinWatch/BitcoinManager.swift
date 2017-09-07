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
    static let minIntervalBetweenCalls: TimeInterval = 10.0
    static let maxDelay: TimeInterval = 30
    
    static let instance = BitcoinManager()

    private let internalQueue = DispatchQueue.global(qos: .default)
    private var nextCallTime: TimeInterval = 0
    
    fileprivate func calculateDelayForThisCallAndScheduleNext() throws -> TimeInterval {
        return 0
//        var delay: TimeInterval = 0
//        try self.internalQueue.sync {
//            let nextCallTime = max(self.nextCallTime, Date().timeIntervalSince1970)
//            delay = nextCallTime - Date().timeIntervalSince1970
//            if delay >= BitcoinManager.maxDelay {
//                print("Delay \(delay) is too large. Aborting ....")
//                throw BitcoinManagerError.tooManyCallsInQueue
//            }
//            
//            self.nextCallTime = nextCallTime + BitcoinManager.minIntervalBetweenCalls
//            print("Next call in: \(delay)")
//        }
//        
//        return delay
    }
    
    override private init() {
        super.init()
        
    }
    
    func updateWalletBalances() -> Promise<Void> {
        let wallets = Wallet.fetchWith(coinTypeId: CoinType.bitcoin.rawValue)
        
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
}


extension BitcoinManager {
    func fetchBalances(for addresses: [String]) -> Promise <[String : Double]> {
        return Promise<[String : Double]> { [weak self] fulfill, reject in
            guard let unwrappedSelf = self else { reject(NSError(domain: "nil", code: 0, userInfo: nil)); return }
            
            
            var delay: TimeInterval!
            do {
                delay = try unwrappedSelf.calculateDelayForThisCallAndScheduleNext()
            } catch let error {
                reject(error)
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                let urlStr = "https://blockchain.info/balance?active=\(addresses.joined(separator: "%7C"))"
                let url = URL(string: urlStr)!
                let request = URLRequest(url: url)
                let session = URLSession.shared
                let dataTask = session.dataTask(with: request) { data, response, error in
                    if let data = data {
                        if let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String : Any] {
                            var balances = [String : Double]()
                            
                            for addr in addresses {
                                if let balanceNode = json[addr] as? [String : Any] {
                                    if let balance = balanceNode["final_balance"] as? Double {
                                        balances[addr] = balance / 100000000
                                    }
                                }
                            }
                            
                            fulfill(balances)
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
}

extension BitcoinManager {
    func fetchTransactions(for address: String) -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            var delay: TimeInterval!
            
            do {
                delay = try self.calculateDelayForThisCallAndScheduleNext()
            } catch let error {
                reject(error)
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
                let urlStr = "https://blockchain.info/multiaddr?active=\(address)"
                let url = URL(string: urlStr)
                let request = URLRequest(url: url!)
                let session = URLSession.shared
                
                let dataTask = session.dataTask(with: request) { data, response, error in
                    if let data = data {
                        if let response = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String : Any] {
                            if let wallet = Wallet.fetchWith(address: address, coinTypeId: CoinType.bitcoin.rawValue) {
                                self.processBalancesAndTransactions(json: response, for: wallet)
                            }
                            fulfill()
                        } else {
                            reject(BitcoinManagerError.badResponse)
                        }
                    } else if let error = error {
                        reject(error)
                    } else {
                        reject(BitcoinManagerError.badResponse)
                    }
                }
                
                dataTask.resume()


            }
        }
    }
    
    private func processBalancesAndTransactions(json: [String : Any], for wallet: Wallet) {
        let realm = try! Realm()
        realm.beginWrite()

        if let transactions = json["txs"] as? Array<[String : Any]> {
            for txJson in transactions {
                guard let amount = txJson["result"] as? Double,
                      let hash = txJson["hash"] as? String
                else { continue }

                
                if CoinTransaction.transaction(with: hash, wallet: wallet) != nil {
                    continue
                }

                guard let outJson = (txJson["out"] as? Array<[String : Any]>)?.first else { continue }
                let xpub = (outJson["xpub"] as? [String : Any])?["m"] as? String
                var address = xpub
                if address == nil {
                    address = outJson["addres"] as? String
                }

                let tx:CoinTransaction = CoinTransaction()

                tx.txHash = hash
                tx.nativeAmount = amount / 100000000

                if let balance = txJson["balance"] as? Double {
                    tx.nativeBalance = balance / 100000000
                } else {
                    tx.nativeBalance = -1
                }

                if let time = txJson["time"] as? TimeInterval {
                    tx.date = Date(timeIntervalSince1970: time)
                }

                tx.wallet = wallet

                realm.add(tx)
            }
        }
        
        try? realm.commitWrite()
    }
}

extension BitcoinManager {
    enum BitcoinManagerError : Error {
        case tooManyCallsInQueue
        case badResponse
    }
}


