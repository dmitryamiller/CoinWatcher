//
//  synched.swift
//  CoinWatch
//
//  Created by Dmitry Miller on 8/30/17.
//  Copyright © 2017 Dmitry Miller. All rights reserved.
//

import Foundation

func synced(_ lock: Any, closure: () -> ()) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}
