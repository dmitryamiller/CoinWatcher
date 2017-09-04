//
//  AddWalletViewController.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/26/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit
import PromiseKit

class AddWalletViewController: UIViewController {
    private var coinType: CoinType?
    private var address: String?
    
    private var addressEntry: AddressEntryViewController?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let addressEntry = segue.destination as? AddressEntryViewController {
            self.addressEntry = addressEntry
            addressEntry.didGetAddressWithCoinType = { [weak self] address, coinType in
                guard let unwrappedSelf = self else { return }
                unwrappedSelf.coinType = coinType
                unwrappedSelf.address = address
                
                if let coinType = unwrappedSelf.coinType {
                    unwrappedSelf.validateAndSaveCoin(withType: coinType, address: address)
                } else {
                    unwrappedSelf.performSegue(withIdentifier: "coinType", sender: self)
                }
            }
        } else if let coinTypeSelection = segue.destination as? CoinTypeViewController {
            coinTypeSelection.coinType = self.coinType
            coinTypeSelection.didSelectCointype = { [weak self] coinType in
                guard let address = self?.address else { return }
                coinTypeSelection.navigationController?.popViewController(animated: true)
                self?.validateAndSaveCoin(withType: coinType, address: address)
            }
        }
    }
    
    @IBAction func handleEntryTypeChange(_ sender: UISegmentedControl) {
        guard let addressEntry = self.addressEntry else { sender.selectedSegmentIndex = 0; return }
        switch addressEntry.entryType {
            case .qr:
                addressEntry.entryType = .manual
            case .manual:
                addressEntry.entryType = .qr
        }
    }
    
    private func validateAndSaveCoin(withType coinType: CoinType, address: String) {
        if !coinType.validate(address: address) {
            let alert = UIAlertController(title: "Invalid Address", message: "Address apperas to be in invalid format", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { [weak self] _ in
                if self?.addressEntry?.entryType == .manual {
                    self?.navigationController?.popViewController(animated: true)
                } else {
                    self?.addressEntry?.restartIfApplicable()
                }
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        // check if we already have this wallet
        if Wallet.exists(with: address, coinType: coinType) {
            let alert = UIAlertController(title: "Wallet Exists", message: "Looks like a wallet with this address already exists", preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .default) { [weak self] _ in
                if self?.addressEntry?.entryType == .manual {
                    self?.navigationController?.popViewController(animated: true)
                } else {
                    self?.addressEntry?.restartIfApplicable()
                }
            }
            alert.addAction(dismissAction)
            self.present(alert, animated: true, completion: nil)
            return
        }

        BusyIndicatorManager.instance.show()
        self.fetchNativeBalance(for: address, coinType)
        .then { [weak self] nativeBalance in
            _ = Wallet.create(coinType: coinType, address: address, name: Wallet.defaultName(for: coinType), nativeBalance: nativeBalance)
            self?.dismiss(animated: true, completion: nil)
            return AnyPromise(Promise<Void>())
        }
        .catch {[weak self] error in
            let alert = UIAlertController(title: "Validation Failed", message: "Failed to validate this address. Would you like to try again?", preferredStyle: .alert)
            let tryAgainAction = UIAlertAction(title: "Try Again", style: .default) { _ in
                self?.validateAndSaveCoin(withType: coinType, address: address)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                self?.addressEntry?.restartIfApplicable()
            }
            
            alert.addAction(tryAgainAction)
            alert.addAction(cancelAction)
            
            self?.present(alert, animated: true, completion: nil)
        }.always {
            BusyIndicatorManager.instance.hide()
        }
    }
    
    private func fetchNativeBalance(for address: String, _ coinType: CoinType) -> Promise<Double> {
        switch coinType {
        case .bitcoin:
            return BitcoinManager.instance.fetchBalances(for: [address]).then { balances in
                if let balance = balances[address] {
                    return Promise<Double>(value: balance)
                } else {
                    return Promise<Double>(error: CoinBalanceError.notFound)
                }
            }
        case .etherium:
            return Promise<Double>(error: CoinBalanceError.notFound)
        }
    }
}

extension AddWalletViewController {
    enum CoinBalanceError : Error {
        case notFound
    }
}

