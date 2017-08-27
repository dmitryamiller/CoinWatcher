//
//  Currency.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/24/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import UIKit

enum Currency: String {
    case usd = "USD"
    case eur = "EUR"
    case aud = "AUD"
    case jpy = "JPY"
    case cny = "CNY"
    case rub = "RUB"
    case gbp = "GBP"
    case cad = "CAD"
    case chf = "CHF"
    case sek = "SEK"
    case nzd = "NZD"
    case mxn = "MXN"
    
    var symbol: String {
        get {
            switch self {
                case .usd: return "$"
                case .eur: return "€"
                case .aud: return "A$"
                case .jpy: return "¥"
                case .cny: return "元"
                case .rub: return "₽"
                case .gbp: return "£"
                case .cad: return "C$"
                case .chf: return "Fr"
                case .sek: return "kr"
                case .nzd: return "NZ$"
                case .mxn: return "$"
            }
        }
    }
    
    static let all: [Currency] = [.usd, .eur, .jpy, .aud, .cad, .chf, .cny, .sek, .nzd, .mxn, .rub]
}
