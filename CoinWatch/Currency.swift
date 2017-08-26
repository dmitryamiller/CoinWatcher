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
    case jpy = "JPY"
    case cny = "CNY"
    
    var symbol: String {
        get {
            switch self {
                case .usd: return "$"
                case .jpy, .cny: return "¥"
            }
        }
    }
}
