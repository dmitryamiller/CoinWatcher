//
//  Results+toArray.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 12/21/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import RealmSwift

extension Results {
    public func toArray() -> [T] {
        var array = [T]()
        for item in self {
            array.append(item)
        }
        
        return array
    }
}
