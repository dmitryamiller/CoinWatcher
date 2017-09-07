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
    case dash = "DSH"
    
    static let all: [CoinType] = [.bitcoin, .etherium]
    
    var name: String {
        switch self {
            case .bitcoin: return NSLocalizedString("Bitcoin", comment: "Bitcoin")
            case .etherium: return NSLocalizedString("Etherium", comment: "Etherium")
            case .dash: return NSLocalizedString("Dash", comment: "Dash")
        }
    }
    
    var addressScheme: String {
        get {
            switch self {
                case .bitcoin: return "bitcoin"
                case .etherium: return "etherium"
                case .dash: return "dash"
            }
        }
    }
    
    func validate(address: String) -> Bool {
        switch self {
            case .bitcoin: return self.validateBitcoin(address: address)
            case .etherium: return self.validateEtherium(address: address)
            case .dash: return self.validateDash(address: address)
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
        if address.characters.count != 34 {
            // could be xpub
            if address.hasPrefix("xpub") {
                return address.characters.count == 111
            }
            
            return false
        }
        
        if address.characters.first != "1" && address.characters.first != "3" {
            return false
        }
        
        return true
    }
}

extension CoinType {
    fileprivate func validateEtherium(address: String) -> Bool {
        if address.characters.count != 40 {
            return false
        }
        
        return address.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil
    }
}

extension CoinType {
    fileprivate func validateDash(address: String) -> Bool {
        return true
    }
}
