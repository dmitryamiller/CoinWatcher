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
                    let name = Wallet.defaultName(for: coinType)
                    _ = Wallet.create(coinType: coinType, address: address, name: name)
                    unwrappedSelf.dismissSelf()
                }
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
    
}
