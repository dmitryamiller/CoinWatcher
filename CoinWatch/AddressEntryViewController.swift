//
//  AddressEntryViewController.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/26/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

class AddressEntryViewController: UIViewController {
    @IBOutlet weak var scannerContainerView: UIView!
    @IBOutlet weak var manualEntryContainerView: UIView!
    
    private var scannerViewController: ScanQRViewController!
    private var manualEntryViewController: SingleFieldEntryViewController!
    
    private var hasBeenLoaded = false
    var entryType = EntryType.qr {
        didSet {
            if self.hasBeenLoaded {
                self.syncViewsWithEntryType()
            }
        }
    }
    var coinType: CoinType?
    
    var didGetAddressWithCoinType: ((String, CoinType?)->())?
    
    override func viewDidLoad() {
        self.hasBeenLoaded = true
        self.syncViewsWithEntryType()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let scanner = segue.destination as? ScanQRViewController {
            self.scannerViewController = scanner
            scanner.delegate = self
        } else if let singleFieldEntry = segue.destination as? SingleFieldEntryViewController {
            self.manualEntryViewController = singleFieldEntry
            self.manualEntryViewController.promptText = "Address"
            self.manualEntryViewController.placeholderText = "Enter address"
            self.manualEntryViewController.isEntryValid = { [weak self] entry in
                guard let entry = entry else { return false }
                
                if let coinType = self?.coinType {
                    return coinType.validate(address: entry)
                }
                
                return entry.characters.count > 0
            }
            
            self.manualEntryViewController.didCompleteEntry = { [weak self] entry in
                guard let entry = entry else { return }
                self?.didGetAddressWithCoinType?(entry, self?.coinType)
            }
        }
    }
    
    // MARK: - Misc
    
    func restartIfApplicable() {
        switch self.entryType {
            case .qr:
                self.scannerViewController.start()
                self.manualEntryViewController.textField.resignFirstResponder()
            case .manual:
                self.scannerViewController.stop()
                self.manualEntryViewController.textField.becomeFirstResponder()
        
        }
    }
    private func syncViewsWithEntryType() {
        switch self.entryType {
            case .qr:
                self.scannerViewController.start()
                self.manualEntryViewController.textField.resignFirstResponder()
                UIView.transition(from: self.manualEntryContainerView, to: self.scannerContainerView, duration: 0.5, options: [.showHideTransitionViews, .transitionCrossDissolve], completion: nil)
            case .manual:
                self.scannerViewController.stop()
                self.manualEntryViewController.textField.becomeFirstResponder()
                UIView.transition(from: self.scannerContainerView, to: self.manualEntryContainerView, duration: 0.5, options: [.showHideTransitionViews, .transitionCrossDissolve], completion: nil)
        }
    }
    
}

extension AddressEntryViewController {
    enum EntryType : Int {
        case qr, manual
    }
}

extension AddressEntryViewController : ScanQRViewControllerDelegate {
    func scanner(_ scanner: ScanQRViewController, didScanCode codeURL: URL) {
        if let coinType = CoinType.coinType(for: codeURL) {
            guard let address = self.address(from: codeURL) else { return  }
            
            if  !coinType.validate(address: address) {
                return
            }
            
            if false == Wallet.exists(with: address, coinType: coinType)  {
                scanner.stop()
                self.didGetAddressWithCoinType?(address, coinType)
            }
        } else if codeURL.scheme == nil {
            let address = codeURL.absoluteString
            
            // we know just the address
            // try it for all the known coin types
            var availableCoinTypes = [CoinType]()
            for coinType in CoinType.all {
                if coinType.validate(address: address) {
                    availableCoinTypes.append(coinType)
                }
            }
            
            if availableCoinTypes.count == 0 {
                return
            } else if availableCoinTypes.count == 1 {
                scanner.stop()
                self.didGetAddressWithCoinType?(address, availableCoinTypes[0])
            } else {
                scanner.stop()
                self.didGetAddressWithCoinType?(address, nil)
            }
        }
    }
    
    func scanner(_: ScanQRViewController, isValid codeURL: URL?) -> Bool {
        guard let url = codeURL else { return false }
        
        // we know the type and the address
        if let coinType = CoinType.coinType(for: url) {
            guard let address = self.address(from: url) else { return false }
            if  !coinType.validate(address: address) {
                return false
            }
            
            return false == Wallet.exists(with: address, coinType: coinType)
        } else if url.scheme == nil {
            let address = url.absoluteString
            
            // we know just the address
            // try it for all the known coin types
            for coinType in CoinType.all {
                if coinType.validate(address: address) {
                    return true
                }
            }
            
            return false
        }
        
        return false
    }
    
    private func address(from url: URL?) -> String? {
        guard let url = url else { return nil }
        return url.absoluteString.replacingOccurrences(of: "\(url.scheme ?? ""):", with: "")
    }
}
