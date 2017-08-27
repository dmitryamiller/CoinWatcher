//
//  AddWalletViewController.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/26/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

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
        
        
        _ = Wallet.create(coinType: coinType, address: address, name: Wallet.defaultName(for: coinType))
        self.dismissSelf()
        
//        CoinWatcher.fetchAmount(forBitcoinAddress: address).then { [weak self] balance -> Void in
//            _ = Wallet.create(coinType: coinType, address: address, name: Wallet.defaultName(for: coinType), nativeBalance: balance)
//            self?.dismissSelf()            
//        }
//        .catch() { [weak self] error in
//            let alert = UIAlertController(title: "Verification Failure", message: "Could not verify your wallet. Add this wallet anyway?", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
//                _ = Wallet.create(coinType: coinType, address: address, name: Wallet.defaultName(for: coinType))
//                self?.dismissSelf()
//            }))
//            
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
//                if self?.addressEntry?.entryType == .manual {
//                    self?.navigationController?.popViewController(animated: true)
//                } else {
//                    self?.addressEntry?.restartIfApplicable()
//                }
//            }))
//            self?.present(alert, animated: true, completion: nil)
//        }
    }
    
}
