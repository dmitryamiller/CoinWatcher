//
//  CoinType.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/24/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

enum CoinType: String {
    case bitcoin = "BTC"
    case etherium = "ETH"
    case dash = "DASH"
    case bitcoinCash = "BCH"
    
    static let all: [CoinType] = [.bitcoin, .bitcoinCash, .etherium, .dash]
    
    var name: String {
        switch self {
            case .bitcoin: return NSLocalizedString("Bitcoin", comment: "Bitcoin")
            case .bitcoinCash: return NSLocalizedString("Bitcoin Cash", comment: "Bitcoin Cash")
            case .etherium: return NSLocalizedString("Etherium", comment: "Etherium")
            case .dash: return NSLocalizedString("Dash", comment: "Dash")
        }
    }
    
    var addressScheme: String {
        get {
            switch self {
                case .bitcoin: return "bitcoin"
                case .bitcoinCash: return "bitcoincash"
                case .etherium: return "etherium"
                case .dash: return "dash"
            }
        }
    }
    
    func validate(address: String) -> Bool {
        switch self {
            case .bitcoin: return self.validateBitcoin(address: address)
            case .bitcoinCash: return self.validateBitcoinCash(address:address)
            case .etherium: return self.validateEtherium(address: address)
            case .dash: return self.validateDash(address: address)
        }
    }
    
    func normalize(address: String) throws -> String {
        if !self.validate(address: address) {
            throw CoinTypeError.invalidAddress
        }
        switch self {
            case .bitcoin:
                return address
            case .bitcoinCash:
                return address
            case .dash:
                return address
            case .etherium:
                if address.hasPrefix("0x") {
                    let index = address.index(address.startIndex, offsetBy: 2)
                    return address.substring(from: index).lowercased()
                } else {
                    return address.lowercased()
                }
        }
    }
    
    static func coinType(for qrCodeUrl: URL) -> CoinType? {
        guard let scheme = qrCodeUrl.standardized.scheme else { return nil }
        
        for c in all {
            if c.addressScheme == scheme {
                return c
            }
        }
        
        return nil
    }
}

extension CoinType {
    fileprivate func validateBitcoin(address: String) -> Bool {
        if address.count != 34 {
            // could be xpub
            if address.hasPrefix("xpub") {
                return address.count == 111
            }
            
            return false
        }
        
        if address.first != "1" && address.first != "3" {
            return false
        }
        
        return true
    }
}

extension CoinType {
    fileprivate func validateBitcoinCash(address: String) -> Bool {
        let isValid = self.validateBitcoin(address: address)
        if isValid {
            return true
        }
        
        return address.count == 40
    }
}

extension CoinType {
    fileprivate func validateEtherium(address: String) -> Bool {
        var normalizedAddress = address
        if address.hasPrefix("0x") {
            let index = address.index(address.startIndex, offsetBy: 2)
            normalizedAddress = address.substring(from: index)
        }
        if normalizedAddress.count != 40 {
            return false
        }
        
        return normalizedAddress.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil
    }
}

extension CoinType {
    fileprivate func validateDash(address: String) -> Bool {
        return true
    }
}

extension CoinType {
    enum CoinTypeError : Error {
        case invalidAddress
    }
}

