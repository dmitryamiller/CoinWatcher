//
//  CoinbaseManager.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 12/12/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import coinbase_official
import PromiseKit
import RealmSwift

class CoinbaseManager: NSObject {
    static let clientId = "a053ebbbc43bf6e83368210e921d74008bd488a9d5e04e7ec18f2f2c7252df8b"
    static let secret = "f09bee69c60267e490a72d4daa725d6e14f34495b4edd031350a79f9bd7234c3"
    static let scope  = "balance transactions user"
    static let redirectUrlPrefix = "com.goblin77.coinbase.coinwatch-oauth"
    static let redirectUrl = "com.goblin77.coinbase.coinwatch-oauth://coinbase-oauth"
    
    static let instance = CoinbaseManager()
    
    override private init() {
        
    }
    
    func canOpenUrl(_ url: URL) -> Bool {
        return url.scheme?.lowercased() == CoinbaseManager.redirectUrlPrefix
    }
    
    func startAuthentication() {
        CoinbaseOAuth.startAuthentication(withClientId: CoinbaseManager.clientId, scope: CoinbaseManager.scope, accountAccess: .all, redirectUri: CoinbaseManager.redirectUrl, meta: nil, layout: nil)
    }
    
    func finishAuthentication(with url: URL) -> Promise<Void> {
        return Promise<(accessToken:String, expirationDate: Date)>{ fulfill, reject in
            if !self.canOpenUrl(url) {
                reject(CoinbaseError.invalidUrl)
            } else {
                CoinbaseOAuth.finishAuthentication(for: url, clientId: CoinbaseManager.clientId, clientSecret: CoinbaseManager.secret) { result, error in
                    if let error = error {
                        reject(error)
                    } else {
                        if let accessToken = (result as? [String : Any])?["access_token"] as? String, let expiresIn = (result as? [String : Any])?["expires_in"] as? Double {
                            let expirationDate = Date().addingTimeInterval(expiresIn)
                            fulfill((accessToken: accessToken, expirationDate: expirationDate))
                        } else {
                            reject(CoinbaseError.unknownError)
                        }
                    }
                }
            }
        }.then { [weak self] authInfo in
            guard let weakSelf = self,
                  let client = Coinbase(oAuthAccessToken: authInfo.accessToken)
            else { return  Promise(error: CoinbaseError.unknownError) }
            
            return weakSelf.synchAccountInfoAndWallets(client: client, accessToken: authInfo.accessToken, accessTokenExpirationDate: authInfo.expirationDate)
        }
    }
    
    private func synchAccountInfoAndWallets(client: Coinbase, accessToken: String? = nil, accessTokenExpirationDate: Date? = nil) -> Promise<Void> {
        let userPromise = self.fetchAccountInfo(client: client)
        let accountsPromise = self.fetchCoinbaseAccounts(client: client)
        
        return when(fulfilled: [userPromise.asVoid(), accountsPromise.asVoid()]).then { [weak self] _ in
            guard let weakSelf = self,
                  let coinbaseUser = userPromise.value,
                  let coinbaseAccounts = accountsPromise.value
            else { return Promise<Void>(error: CoinbaseError.unknownError) }
            
            let realm = try! Realm()
            realm.beginWrite()
            
            // coinbase account
            let coinbaseAccount = weakSelf.createCoinbaseAccountIfApplicable(realm: realm, coinbaseUser: coinbaseUser)
            
            if let accessToken = accessToken {
                coinbaseAccount.accessToken = accessToken
            }
            
            if let accessTokenExpirationDate = accessTokenExpirationDate {
                coinbaseAccount.accessTokenExpirationDate = accessTokenExpirationDate
            }
            
            // coinbase related wallets
            weakSelf.synchCoinbaseWallets(with: coinbaseAccounts, coinbaseAccount, realm: realm)            
            
            try? realm.commitWrite()
            
            return Promise<Void>()
        }
    }
    
    private func fetchAccountInfo(client: Coinbase) -> Promise<CoinbaseUser> {
        return Promise<CoinbaseUser> { fulfill, reject in
            client.getCurrentUser({ user, error in
                if let error = error {
                    reject(error)
                } else {
                    if let user = user {
                        fulfill(user)
                    } else {
                        reject(CoinbaseError.unknownError)
                    }
                }
            })
        }
    }
    
    private func fetchCoinbaseAccounts(client: Coinbase) -> Promise<[coinbase_official.CoinbaseAccount]> {
        return Promise<[coinbase_official.CoinbaseAccount]> { fulfill, reject in
            client.getAccountsList({ accounts, _, error in
                if let error = error {
                    reject(error)
                } else {
                    var coinbaseAccounts = [coinbase_official.CoinbaseAccount]()
                    if let accountList = accounts {
                        coinbaseAccounts = accountList.map{ $0 as! coinbase_official.CoinbaseAccount }
                    }
                    
                    fulfill(coinbaseAccounts)
                }
            })
        }
    }
    
    private func createCoinbaseAccountIfApplicable(realm: Realm, coinbaseUser: CoinbaseUser) -> CoinbaseAccount {
        if let existingAccount = realm.objects(CoinbaseAccount.self).filter("%K == %@", #keyPath(CoinbaseAccount.login), coinbaseUser.email).first {
            return existingAccount
        } else {
            let account = CoinbaseAccount()
            account.login = coinbaseUser.email
            realm.add(account)
            return account
        }
    }
    
    private func synchCoinbaseWallets(with coinbaseAccounts: [coinbase_official.CoinbaseAccount], _ account: CoinbaseAccount, realm: Realm) {
        let initialWallets = realm.objects(Wallet.self).filter("%K == %@", #keyPath(Wallet.coinbaseWalletInfo.coinbaseAccount), account)
        var currentWalletUUIDs = Set<String>()
        for coinbaseAccount in coinbaseAccounts {
            guard let coinType = CoinType(rawValue: coinbaseAccount.balance.currency) else { continue } // we only include supported coins
            
            let wallet: Wallet = {
                if let existing = realm.objects(Wallet.self).filter("%K == %@ AND %K == %@", #keyPath(Wallet.coinbaseWalletInfo.coinbaseAccount), account, #keyPath(Wallet.coinbaseWalletInfo.accountId), coinbaseAccount.accountID).first {
                    return existing
                } else {
                    let coinbaseWalletInfo = CoinbaseWalletInfo()
                    coinbaseWalletInfo.accountId = coinbaseAccount.accountID
                    coinbaseWalletInfo.coinbaseAccount = account
                    return Wallet.create(coinType: coinType, address: "", name: coinbaseAccount.name, nativeBalance: 0, coinbaseWalletInfo: coinbaseWalletInfo, commit: false)!
                }
            }()
            
            if let nativeBalance = Double(coinbaseAccount.balance.amount) {
                wallet.nativeBalance = nativeBalance
            }
            
            wallet.lastBalanceSync = Date()
            currentWalletUUIDs.insert(wallet.uuid)
        }
        
        var walletsToBeDeleted = [Wallet]()
        for wallet in initialWallets {
            if !currentWalletUUIDs.contains(wallet.uuid) {
                walletsToBeDeleted.append(wallet)
            }
        }
        
        for deletedWallet in walletsToBeDeleted {
            Wallet.delete(wallet: deletedWallet, commit: false)
        }
    }
}

extension CoinbaseManager {
    enum CoinbaseError : Error {
        case invalidUrl
        case notAuthenticated
        case unknownError
    }
}
